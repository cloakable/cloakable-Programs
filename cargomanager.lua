local component = require("component")
local sides = require("sides")

local storageSide = sides.top
local conveyorSide = sides.east

local function search(item)
    for address in component.list("transposer") do
        for slot = 1, component.invoke(address, "getInventorySize", storageSide) do
            value = component.invoke(address, "getStackInSlot", storageSide, slot).label)
            if value = string.match(item) then
                print(component.invoke(address, "getStackInSlot", storageSide, slot).amount, component.invoke(address, "getStackInSlot", storageSide, slot).label)
                return address
            end
        end
    end
end

local function get(item, count)
    local target = search(item)
    local itemsTotal = 0
    local itemsLeft = count
    while itemsTotal < count do
        local itemsMoved = component.invoke(target, "transferItem", storageSide, conveyorSide, itemsLeft)
        local itemsTotal = itemsTotal + itemsMoved
        local itemsLeft = itemsLeft - itemsMoved
    end
end

