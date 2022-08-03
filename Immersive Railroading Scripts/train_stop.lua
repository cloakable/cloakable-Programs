local component = require("component")
local event = require("event")
local sides = require("sides")

local rs = component.redstone

-- The address of the first controller, ahead of the big speed brakes.
local slowdown_ctl = component.proxy("df0bff6f-4228-478e-82ac-abaf3957253d")

-- The address of the redstone IO that activates the big speed brakes.
local slowdown_rs = component.proxy("8e3fac6d-89ce-42cc-b165-0e3159a0ee12")

-- The address of the second controller that stops the train at the end.
local stop_ctl = component.proxy("6cae5f48-c6a1-4070-901a-ef587bbbaf43")

-- The address of the redstone IO that activates the secondary speed retarders.
local stop_rs = component.proxy("e01031c3-cc85-4b8b-b23c-0ba3fb39685c")

while true do
  print("Waiting for train...")
  event_name, address, augment_type, stock_uuid = event.pull("ir_train_overhead")
  if augment_type == "LOCO_CONTROL" and address == slowdown_ctl.address then
    print("Enabling speed retarders, reducing throttle, and preparing stopping area.")
    slowdown_ctl.setBrake(0)
    slowdown_ctl.setThrottle(0.5)
    slowdown_ctl.horn()
    -- Note: Depending on where you place your IO block, you may need a different side.
    slowdown_rs.setOutput(sides.north, 15)
    stop_rs.setOutput(sides.up, 15)
    print("Waiting 10 seconds for train to come to a complete stop.")
    os.sleep(10)
    print("Disabling speed retarders.")
    slowdown_rs.setOutput(sides.north, 0)
  elseif augment_type == "LOCO_CONTROL" and address == stop_ctl.address then
    print("Train has reached stopping point. Braking and setting throttle to 0.")
    stop_ctl.setBrake(1)
    stop_ctl.setThrottle(0)
    stop_ctl.horn()
    -- Once again, you may need to specify a different side.
    stop_rs.setOutput(sides.up, 0)
    print("Waiting a few seconds for train to stop.")
    os.sleep(3)
    print("Disabling brakes.")
    stop_ctl.setBrake(0)
    print("Brakes disabled. Train is ready.")
  end
end