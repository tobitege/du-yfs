local checks = require("CommonRequire").checks
local utc = system.getUtcTime

local targetPoint = {}
targetPoint.__index = targetPoint

local function new(origin, destination, maxSpeed)
    checks.IsVec3(origin, "origin", "targetPoint:new")
    checks.IsVec3(destination, "destination", "targetPoint:new")
    checks.IsNumber(maxSpeed, "maxSpeed", "targetPoint:new")

    local diff = destination - origin

    local instance = {
        origin = origin,
        destination = destination,
        distance = diff:len(),
        direction = diff:normalize(),
        maxSpeed = maxSpeed,
        startTime = nil,
        holdTime = 0,
        lastTime = 0
    }
    return setmetatable(instance, targetPoint)
end

function targetPoint:Current(chaserPosition, maxDistanceAhead)
    local now = utc()

    if self.startTime == nil then
        self.startTime = now
        self.lastTime = now
    end

    local rabbitPosition = self:position(now)

    -- Is the rabbit too far ahead?
    if (rabbitPosition - chaserPosition):len() > maxDistanceAhead then
        self.holdTime = self.holdTime + (now - self.lastTime)
    end

    local pos = self:position(now)
    self.lastTime = now
    return pos
end

function targetPoint:Elapsed(now)
    return now - self.startTime - self.holdTime
end

function targetPoint:position(now)
    local distance = self.maxSpeed * self:Elapsed(now)
    if distance >= self.distance then
        return self.destination
    else
        return self.origin + self.direction * distance
    end
end

-- The module
return setmetatable(
        {
            new = new
        },
        {
            __call = function(_, ...)
                return new(...)
            end
        }
)