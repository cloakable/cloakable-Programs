local event = require("event")
local serial = require("serialization")
local component = require("component")
local fs = require("filesystem")
local keyboard = require("keyboard")

-- The name of the file which holds information about the switches.
local SWITCH_DEFINITION_FILE = "/home/switch.tbl"
-- The table of switch information, that is loaded from the above file on startup.
local switches = nil

local RUNNING = true

-- Loads the switch definition from a serialized table.
local function loadSwitchDefinitionFromFile(filename)
  local file = io.open(filename, "r")
  if file == nil then
    io.stderr:write("Could not open file "..filename.." for reading.\n")
    return nil
  end
  local tbl = serial.unserialize(file:read("*a"))
  file:close()
  return tbl
end

-- Gets a component address from the user.
local function inputComponentAddress()
  local address = nil
  repeat
    address = io.read()
    if address == nil or #address ~= 36 then
      print("Invalid component address. Please enter a 36-character string.")
    end
  until address ~= nil and #address == 36
  return address
end

-- Gets switch information from the user, and saves it to the file.
local function initSwitchDefinitionFile(filename)
  print("How many switches should this system control?")
  local switchCount = nil
  repeat
    switchCount = tonumber(io.read())
    if switchCount == nil or switchCount <= 0 then
      print("Invalid number of switches given. Please enter a positive number.")
    end
  until switchCount ~= nil and switchCount > 0
  
  print("You will now enter some information about each switch.")
  local tentative_switches = {}
  for i=1, switchCount do
    print("Switch "..i..":")
    
    print("What is the address of the detector augment before this switch?")
    local detector_address = inputComponentAddress()
    print("What is the address of the redstone component that controls this switch?")
    local rs_address = inputComponentAddress()
    
    print("What branch is does this switch direct traffic to when activated?")
    local switch_to = nil
    repeat
      switch_to = io.read()
    until switch_to ~= nil
    
    print("In summary, this switch has the following information:")
    print("  Detector: \""..detector_address.."\"")
    print("  Redstone I/O: \""..rs_address.."\"")
    print("  Switches when locomotive's tag contains: \""..switch_to.."\"")
    print("Is this information correct? [y/n]")
    local choice = io.read()
    
    if choice == "y" or choice == "yes" then
      tentative_switches[i] = {
        detector_address = detector_address,
        rs_address = rs_address,
        switch_to = switch_to
      }
    else
      i = i - 1
    end
  end
  print("Saving this switch definition to "..filename..".")
  local f = io.open(filename, "w")
  if f == nil then
    io.stderr:write("Could not open file "..filename.." for writing.\n")
    return nil
  end
  f:write(serial.serialize(tentative_switches))
  f:close()
  return tentative_switches
end

-- Sets the output of all switches to 0, to reset the system.
local function resetSwitches(switches)
  for index, switch in pairs(switches) do
    local redstone = component.proxy(switch.rs_address)
    redstone.setOutput({0, 0, 0, 0, 0, 0})
  end
end

-- What to do when a train runs over a detector, just before it reaches the switch.
local function onDetectorTriggered(detector_address, stock_uuid)
  local this_switch = nil
  for index, switch in pairs(switches) do
    if switch.detector_address == detector_address then
      this_switch = switch
    end
  end
  if this_switch == nil then
    io.stderr:write("Fatal error: Could not find a switch that has a detector with address: "..detector_address.."\n")
    return
  end
  
  local detector = component.proxy(detector_address)
  local redstone = component.proxy(this_switch.rs_address)
  
  local info = detector.info()
  if info == nil or info.throttle == nil then
    return
  end
  
  local tag = info.tag
  if tag == nil then
    tag = ""
  end
  
  print("Approaching locomotive has tag: \""..tag.."\"")
  if string.find(tag, this_switch.switch_to) then
    print("  Tag contains \""..this_switch.switch_to.."\", switching.")
    redstone.setOutput({15, 15, 15, 15, 15, 15})
  else
    print("  Tag doesn't contain \""..this_switch.switch_to.."\", not switching.")
    redstone.setOutput({0, 0, 0, 0, 0, 0})
  end
end

-- What to do when the user has typed some keys.
local function onKeyDown(code)
  local key = keyboard.keys[code]
  if (keyboard.isControlDown()) then
    if (key == "r") then
      print("Resetting switches to their default positions.")
      resetSwitches(switches)
    elseif (key == "q") then
      print("Quitting.")
      RUNNING = false
    end
  end
end

-- General purpose event handler that delegates different events to their own functions.
local function handleEvents()
  local event_name, p1, p2, p3, p4, p5 = event.pull()
  if event_name == "ir_train_overhead" then
    local component_address = p1
    local augment_type = p2
    local stock_uuid = p3
    if augment_type == "DETECTOR" then
      onDetectorTriggered(component_address, stock_uuid)
    end
  elseif event_name == "key_down" then
    local key_code = p3
    onKeyDown(key_code)
  end
end

-- Load the switch definitions from either a file, or from the user if it's the first time.
if (fs.exists(SWITCH_DEFINITION_FILE)) then
  switches = loadSwitchDefinitionFromFile(SWITCH_DEFINITION_FILE)
  print("Loaded switch definition from file.")
else
  print("No switch definition found, please create one now.")
  switches = initSwitchDefinitionFile(SWITCH_DEFINITION_FILE)
  print("Loaded switch definition from user input.")
end

if switches == nil then
  io.stderr:write("Fatal error: Could not load switch definition from file or user input.\n")
  return
end

print("Resetting switches to their starting positions.")
resetSwitches(switches)

print("Waiting for locomotives... Type CTRL + Q to quit, or CTRL + R to reset switches.")
-- The main loop of the program.
while RUNNING do
  handleEvents()
end