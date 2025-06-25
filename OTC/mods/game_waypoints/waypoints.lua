local window = nil
local minimapWindow = nil
local selectedEntry = nil
local teleportButton = nil
local EXTENDED_OPCODE_WAYPOINTS = 56

function init()
  connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })

  ProtocolGame.registerExtendedJSONOpcode(EXTENDED_OPCODE_WAYPOINTS, parseOpcode)
  if g_game.isOnline() then
    onGameStart()
  end
end

function onGameStart()
  window = g_ui.displayUI('waypoints')
  window:setVisible(false)
  minimapWindow = window:recursiveGetChildById('minimapPanel')
  teleportButton = window:recursiveGetChildById('teleportButton')
  if teleportButton then
    teleportButton.onClick = function()
      if selectedEntry and selectedEntry.locationLabel then
        sendOpcode({ topic = "teleport", location = selectedEntry.locationLabel })
        window:setVisible(false)
      else
        displayErrorBox("Error", "Select a location first!")
      end
    end
  end
end

function onGameEnd()
  if window then window:destroy() window = nil end
  minimapWindow = nil
  if selectedEntry then
    selectedEntry:setBackgroundColor("alpha")
    selectedEntry = nil
  end
end

function terminate()
  disconnect(g_game, { onGameEnd = onGameEnd })
  ProtocolGame.unregisterExtendedJSONOpcode(EXTENDED_OPCODE_WAYPOINTS, parseOpcode)
  onGameEnd()
end

function sendOpcode(data)
  local proto = g_game.getProtocolGame()
  if not proto then return end
  proto:sendExtendedJSONOpcode(EXTENDED_OPCODE_WAYPOINTS, data)
end

function parseOpcode(protocol, opcode, data)
  if opcode ~= EXTENDED_OPCODE_WAYPOINTS or type(data) ~= "table" then return end
  if not window then return end

  if data.topic == "available-locations" and type(data.locations) == "table" then
    local list = window:recursiveGetChildById("locationsList")
    if not list then return end

    list:destroyChildren()

    local player = g_game.getLocalPlayer()
    if player then
      local pos = player:getPosition()
      minimapWindow:setCameraPosition(pos)
      minimapWindow:setCrossPosition(pos)
      minimapWindow:setZoom(2)
    end
    
    for _, entry in ipairs(data.locations) do
      local label = g_ui.createWidget("WaypointLabel", list)
      label.locationLabel = entry.label or "Unknown"
      label:setText(label.locationLabel)
      label.onMouseRelease = function(self, mousePosition, mouseButton)
        if mouseButton == MouseLeftButton then
          if selectedEntry then
            selectedEntry:setBackgroundColor("alpha")
          end
          selectedEntry = self
          selectedEntry:setBackgroundColor("gray")

          local pos = {
          x = tonumber(entry.x),
          y = tonumber(entry.y),
          z = tonumber(entry.z)  
          }
          minimapWindow:setCameraPosition(pos)
          minimapWindow:setCrossPosition(pos)
        end
      end
    end
    window:setVisible(true)
  elseif data.topic == "close" then
    window:setVisible(false)
  end
end

function hide()
  if not window then return end
  window:hide()
end