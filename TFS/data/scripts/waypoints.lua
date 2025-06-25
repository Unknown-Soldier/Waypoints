local waypoints_storage = 47000
local waypoints_opcode = 56

local waypoints_list = {
  [1] = {label = "Forest", position = Position(90, 99, 7)},
  [2] = {label = "Dry", position = Position(45, 103, 7)},
  [3] = {label = "Dirt", position = Position(26, 139, 7)},
  [4] = {label = "Desert", position = Position(54, 167, 7)},
  [5] = {label = "Jungle", position = Position(155, 160, 7)},
  [6] = {label = "Sand", position = Position(124, 153, 7)},
  [7] = {label = "Dead", position = Position(80, 61, 7)},
  [8] = {label = "Ice", position = Position(134, 61, 7)},
}

function teleportPlayer(player, locationName)
  for id, waypoint in pairs(waypoints_list) do
    if waypoint.label == locationName then
      if player:getStorageValue(waypoints_storage + id) == 1 then
        player:teleportTo(waypoint.position)
        waypoint.position:sendMagicEffect(CONST_ME_TELEPORT)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You have been teleported to " .. waypoint.label .. ".")
      else
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You don't have this waypoint unlocked.")
      end
      break
    end
  end
end

local LoginEvent = CreatureEvent("Waypoints_LoginEvent")
function LoginEvent.onLogin(player)
  player:registerEvent("Waypoints_ExtendedOpcode")
  return true
end
LoginEvent:type("login")
LoginEvent:register()

local opcode = CreatureEvent("Waypoints_ExtendedOpcode")
function opcode.onExtendedOpcode(player, opcode, buffer)
  if opcode == waypoints_opcode then
    local status, json_data = pcall(function() return json.decode(buffer) end)
    if not status or type(json_data) ~= "table" then return end

    local topic = json_data.topic
    if topic == "teleport" then
      local locationName = json_data.location
      if locationName then
        teleportPlayer(player, locationName)
      end
    end
  end
end
opcode:type("extendedopcode")
opcode:register()

local waypointsStepIn = MoveEvent()
function waypointsStepIn.onStepIn(player, item, position, fromPosition)
  if not player or fromPosition:getDistance(position) ~= 1 then return true end

  local available = {}

  for id, waypoint in pairs(waypoints_list) do
    if position == waypoint.position then
      local key = waypoints_storage + id
      if player:getStorageValue(key) ~= 1 then
        player:setStorageValue(key, 1)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Waypoint discovered:\n{ " .. waypoint.label .. ", #FFDE59 }")
        position:sendMagicEffect(181)
		  return true
      end
      break
    end
  end

  for id, waypoint in pairs(waypoints_list) do
    local key = waypoints_storage + id
    if player:getStorageValue(key) == 1 then
      table.insert(available, {
        label = waypoint.label,
        x = waypoint.position.x,
        y = waypoint.position.y,
        z = waypoint.position.z
      })
    end
  end

  if #available > 0 then
    local jsonString = json.encode({ topic = "available-locations", locations = available })
    player:sendExtendedOpcode(waypoints_opcode, jsonString)
  end

  return true
end
waypointsStepIn:aid(47000)
waypointsStepIn:register()

local waypointsStepOut = MoveEvent()
function waypointsStepOut.onStepOut(player, item, position, fromPosition)
  if not player then return true end
  if item:getActionId() == 47000 then
    player:sendExtendedOpcode(waypoints_opcode, json.encode({ topic = "close" }))
  end
  return true
end
waypointsStepOut:aid(47000)
waypointsStepOut:register()