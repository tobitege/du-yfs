local log = require("debug/Log")()
local cmd = require("commandline/CommandLine")()
require("util/Table")

local singleton
local Settings = {}
Settings.__index = Settings

function Settings:New(db)
    if not singleton then
        singleton = {}

        local subscribers = {}

        singleton.def = {
            engineWarmup = { key = "engineWarmup", default = 2 },
            speedP = {key = "speedp", default = 0.01},
            speedI = {key = "speedi", default = 0.001},
            speedD = {key = "speedd", default = 0},
        }

        local ensureSingle = function(data)
            -- Ensure only one option is given, ignore commandValue
            local len = TableLen(data)
            if len ~= 2 then
                -- commandValue and one setting
                log:Error("Please specify a single setting, got ", len)
                return false
            end

            return true
        end

        local getPair = function(data)
            for key, value in pairs(data) do
                if key ~= "commandValue" then
                    return key, value
                end
            end

            return nil, nil
        end

        local function publishToSubscribers(key, value)
            -- Notify subscribers for the key
            local subs = subscribers[key]
            if subs then
                for _, f in ipairs(subs) do
                    f(value)
                end
            end
        end

        local setFunc = function(data)
            if not ensureSingle(data) then
                return
            end

            local key, value = getPair(data)
            if key ~= nil then
                publishToSubscribers(key, value)
                log:Info("Setting '", key, "' to '", value, "'")
                db:Put(key, value)
            end
        end

        local getFunc = function(data)
            if not ensureSingle(data) then
                return
            end

            local key, value = getPair(data)
            if key ~= nil then
                log:Info(key, ": ", db:Get(key, value))
            end
        end

        ---@param key string The key to get notified of
        ---@param func function A function with signature function(value)
        function singleton:RegisterCallback(key, func)
            if not subscribers[key] then
                subscribers[key] = {}
            end

            table.insert(subscribers[key], func)
        end

        function singleton:Get(key, default)
            return db:Get(key, default)
        end

        function singleton:Reload()
            for _, setting in pairs(singleton.def) do
                local stored = singleton:Get(setting.key, setting.default)
                publishToSubscribers(setting.key, stored)
            end
        end

        local set = cmd:Accept("set", setFunc):AsEmpty()

        for _, setting in pairs(singleton.def) do
            -- Don't set defaults on these - prevents detecting which setting is to be set as they all have values then.
            set:Option("-" .. setting.key):AsNumber()
        end

        setmetatable(singleton, Settings)
    end

    return singleton
end

return Settings