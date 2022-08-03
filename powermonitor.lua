--setup components
local component = require("component")
local event = require("event")
local modem = component.modem

local function displayPower()
    modem.open(45)
    modem.broadcast(45)
    local _, _, _, _, _, fillPercent, energyStored, maxEnergyStored = event.pull("modem_message")
    print("Battery Percentage: " .. math.floor(fillPercent) .. "% (" .. energyStored .. "/" .. maxEnergyStored .. ")")
    modem.close(45)
end

displayPower()