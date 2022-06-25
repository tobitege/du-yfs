local brakes = require("flight/Brakes")()
local construct = require("du-libs:abstraction/Construct")()
local calc = require("du-libs:util/Calc")
local ctrl = require("du-libs:abstraction/Library")():GetController()
local Enum = require("du-libs:util/Enum")
local visual = require("du-libs:debug/Visual")()
local nullVec = require("cpml/vec3")()
local sharedPanel = require("du-libs:panel/SharedPanel")()
local log = require("du-libs:debug/Log")()
local universe = require("du-libs:universe/Universe")()
local PID = require("cpml/pid")
require("flight/state/Require")
local CurrentPos = construct.position.Current
local Velocity = construct.velocity.Movement
local abs = math.abs

local FlightMode = Enum {
    "AXIS",
    "FREE"
}

local fsm = {}
fsm.__index = fsm

local function new()
    local instance = {
        current = nil,
        wStateName = sharedPanel:Get("FlightFSM"):CreateValue("State", ""),
        wDeviation = sharedPanel:Get("FlightFSM"):CreateValue("Deviation", "m"),
        wAcceleration = sharedPanel:Get("FlightFSM"):CreateValue("Acceleration", "m/s2"),
        nearestPoint = nil,
        acceleration = nil,
        deviationPID = PID(0, 0.8, 0.2),
        mode = FlightMode.AXIS
    }

    setmetatable(instance, fsm)
    instance:SetState(Idle(instance))
    return instance
end

function fsm:CheckPathAlignment(currentPos, chaseData)
    local res = true

    if self.mode == FlightMode.AXIS then
        local travelDir = Velocity():normalize_inplace()
        local speed = Velocity():len()

        local toRabbit = chaseData.rabbit - currentPos
        local toNearest = chaseData.nearest - currentPos

        local tolerance = 0.85
        if speed > 1 then
            res = travelDir:dot(toRabbit:normalize()) >= tolerance or travelDir:dot(toNearest:normalize()) >= tolerance
        end
    end

    return res
end

function fsm:FsmFlush(next, previous)

    local pos = CurrentPos()

    local c = self.current
    if c ~= nil then
        local chaseData = self:NearestPointBetweenWaypoints(previous, next, pos, 6)

        brakes:Set(false)

        -- Are we moving in the desired direction?
        if not self:CheckPathAlignment(pos, chaseData) then
            self:SetState(CorrectDeviation(self))
        end

        c:Flush(next, previous, chaseData)
        self.acceleration = (self.acceleration or nullVec) + self:AdjustForDeviation(chaseData, pos)

        c:Flush(next, previous, chaseData)

        visual:DrawNumber(9, chaseData.rabbit)
        visual:DrawNumber(8, chaseData.nearest)
        visual:DrawNumber(0, pos + self.acceleration:normalize() * 8)
    end

    self:ApplyAcceleration(self.acceleration or nullVec)
end

function fsm:AdjustForDeviation(chaseData, currentPos)
    -- Add counter to deviation from optimal path
    local rabbitDeviation = chaseData.rabbit - currentPos
    local nearDeviation = chaseData.nearest - currentPos
    local len = nearDeviation:len()
    self.deviationPID:inject(len)
    self.wDeviation:Set(calc.Round((chaseData.nearest - currentPos):len(), 4))

    local velocity = construct.velocity.Movement()
    if velocity:len() > 1 and velocity:normalize():dot(rabbitDeviation:normalize()) < 0.9 then
        brakes:Set(true)
    end

    local maxDeviationAcc = 2

    return nearDeviation:normalize() * utils.clamp(self.deviationPID:get(), 0, maxDeviationAcc)
end

function fsm:ApplyAcceleration(acceleration)
    -- Compensate for any gravity
    local gAcc = construct.world.GAlongGravity()

    acceleration = acceleration - gAcc

    ctrl.setEngineCommand("thrust,airfoil", { acceleration:unpack() }, { 0, 0, 0 }, 1, 1, "airfoil", "thrust")
end

function fsm:Update()
    local c = self.current
    if c ~= nil then
        self.wAcceleration:Set(calc.Round(construct.acceleration.Movement():len(), 2))
        c:Update()
    end
end

function fsm:WaypointReached(isLastWaypoint, next, previous)
    if self.current ~= nil then
        self.current:WaypointReached(isLastWaypoint, next, previous)
    end
end

function fsm:SetState(state)
    if self.current ~= nil then
        self.current:Leave()
    end

    if state == nil then
        self.wStateName:Set("No state!")
    else
        self.wStateName:Set(state:Name())
        state:Enter()
    end

    self.current = state
end

function fsm:SetFreeMode()
    self.mode = FlightMode.FREE
    log:Info("Free mode")
end

function fsm:SetAxisMode()
    self.mode = FlightMode.AXIS
    log:Info("Axis mode")
end

function fsm:DisableThrust()
    self.acceleration = nil
    ctrl.setEngineCommand("thrust", { 0, 0, 0 })
end

function fsm:Thrust(acceleration)
    self.acceleration = acceleration or nullVec
end

function fsm:NullThrust()
    self.acceleration = nullVec
end

function fsm:NearestPointBetweenWaypoints(wpStart, wpEnd, currentPos, ahead)
    local totalDiff = wpEnd.destination - wpStart.destination
    local dir = totalDiff:normalize()
    local nearestPoint = calc.NearestPointOnLine(wpStart.destination, dir, currentPos)

    ahead = (ahead or 0)
    local point = nearestPoint + dir * ahead
    local remaining = wpEnd.destination - point

    -- Is the point past the end (remaining points back towards start or we're very close to the destination)?
    if remaining:normalize():dot(dir) < 1 or remaining:len() < 0.01 then
        return { rabbit = wpEnd.destination, nearest = nearestPoint }
    else
        return { rabbit = point, nearest = nearestPoint }
    end
end

-- The module
return setmetatable(
        {
            new = new
        },
        {
            __call = function(_, ...)
                return new()
            end
        }
)