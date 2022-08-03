--setup components
local component = require("component")
local computer = require("computer")
local event = require("event")
local cart = component.computercart
if component.isAvailable("modem") then
    local modem = component.modem
    modem.open(46)
end
if component.isAvailable("generator") then
    local generator = component.generator
end

local energyTarget = 95

local function energyPercent()
    local percent = ( computer.energy() / computer.maxEnergy() ) * 100
    return percent
end

function doRecharge()
    if cart.hasNetworkRail() then
        if energyPercent() < energyTarget then
            cart.setBrake(true)
            return
        elseif energyPercent() >= energyTarget then
            cart.setBrake(false)
            return
        else
            return
        end
    elseif not cart.hasNetworkRail() and component.isAvailable("generator") then
        if energyPercent() < energyTarget then
            if generator.count() < 1
                generator.insert(1)
            else
                return
            end
        end
    end
end

function networkMessage()
end

event.listen("network_rail", doRecharge)
event.timer(5, doRecharge)
event.listen("modem_message", networkMessage)