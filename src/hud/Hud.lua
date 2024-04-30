require("GlobalTypes")
local si                              = require("Singletons")
local log, pub, input, calc, Template = si.log, si.pub, si.input, si.calc, require("Template")
local hudTemplate                     = library.embedFile("hud.html")

local updateInterval                  = 0.2

---@alias HudData {speed:number, maxSpeed:number}

---@class Hud
---@field New fun():Hud

local Hud                             = {}
Hud.__index                           = Hud

---@return Hud
function Hud.New()
    local s = {}
    local flightData = {} ---@type FlightData
    local routeInfo = {} ---@type table<string,integer>
    local routeName = ""
    local fuelByType = {} ---@type table<string,FuelTankInfo[]>
    local unitInfo = system.getItem(unit.getItemId())
    local isECU = unitInfo.displayNameWithSize:lower():match("emergency")

    system.showScreen(true)

    Task.New("HUD", function()
        local tpl = Template(hudTemplate, { log = log, tostring = tostring, round = calc.Round }, function(obj, err)
            log.Error("Error compiling template: ", err)
        end)

        local sw = Stopwatch.New()
        sw.Start()

        while true do
            if sw.Elapsed() >= updateInterval then
                sw.Restart()

                local html = tpl({
                    throttle = player.isFrozen() and
                        string.format("Throttle: %0.0f%% (Manual Control)", input.Throttle() * 100) or
                        "Automatic Control",
                    fuelByType = fuelByType,
                    isECU = isECU,
                    info = flightData.altitude and string.format("Alt: %.2fm", flightData.altitude),
                    routeName = routeName,
                    pointIx = routeInfo.ix,
                    pointRef = routeInfo.pointRef,
                })

                system.setScreen(html)
            end
            coroutine.yield()
        end
    end).Catch(function(t)
        log.Error(t.Name(), " ", t.Error())
    end)

    --tte
    pub.RegisterString("RouteName",
        ---@param _ string
        ---@param rname string
        function(_, rname)
            routeName = rname
        end)

    --tte
    pub.RegisterTable("RouteInfo",
        ---@param _ string
        ---@param data table<string,integer>
        function(_, data)
            routeInfo = data
        end)

    pub.RegisterTable("FlightData",
        ---@param _ string
        ---@param data FlightData
        function(_, data)
            flightData = data
        end)

    pub.RegisterTable("FuelByType",
        ---@param _ string
        ---@param data table<string,FuelTankInfo[]>
        function(_, data)
            fuelByType = data
        end)

    return setmetatable(s, Hud)
end

return Hud
