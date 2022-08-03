--setup components
local component = require("component")
local event = require("event")
local battery = component.big_battery
local modem = component.modem

--open the port, Igor!
modem.open(45)
--if wireless, set wireless strength
if modem.isWireless() then
    modem.setStrength(64)
end

--at what (battery) percentage should the generator be turned off at
local batMax = 95
---...and back on at
local batMin = 25

--work out how full the battery is
local function batPercent()
    local percent = ( battery.getEnergyStored() / battery.getMaxEnergyStored() ) * 100
    return percent
end

--enable computer control of the connected diesel generators
local function enableDigitalControl()
    for address in component.list("ie_diesel_generator") do
        component.invoke(address, "enableComputerControl", true)
    end
end

--iterates over all local diesel generators an either switches them on or off
local function generatorEnabled(enabled)
    for address in component.list("ie_diesel_generator") do
        component.invoke(address, "setEnabled", enabled)
    end
end

--we have our information, time for some logic!
function powerToggle() 
    if batPercent() > batMax then
        --we're over the max fill percentage, turn off the generators.
        generatorEnabled(false)
    elseif batPercent() < batMin then
        --we're under! time to turn the generators back on
        generatorEnabled(true)
    else
        --we're somewhere between the two, do nothing
        return
    end
end

function networkMessage(event, localAddress, remoteAddress)
    modem.send(remoteAddress, 45, batPercent(), battery.getEnergyStored(), battery.getMaxEnergyStored())
end
    

function start(config)
    event.timer(1, powerToggle, math.huge)
    event.listen("modem_message", networkMessage)
end
