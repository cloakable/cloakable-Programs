local component = require("component")
local sides = require("sides")

local storageSide = sides.top
local conveyorSide = sides.east

local function search(item)
    for address in component.list("transposer") do
        for slot = 1, component.invoke(address, "getInventorySize", storageSide) do
            value = component.invoke(address, "getStackInSlot", storageSide, slot).label)
            if value = string.match(item) then
                return address, slot
            end
        end
    end
end

local function get(count, item)
    local itemsTotal = 0
    local itemsLeft = count
    while itemsTotal < count do
        local address, slot = search(item)
        local itemsMoved = component.invoke(address, "transferItem", storageSide, conveyorSide, itemsLeft, slot)
        local itemsTotal = itemsTotal + itemsMoved
        local itemsLeft = itemsLeft - itemsMoved
    end
end

