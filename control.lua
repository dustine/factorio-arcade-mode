MOD = {}
MOD.name = "ArcadeMode"
MOD.if_name = "arcade_mode"
MOD.interfaces = {}
MOD.commands = {}
-- MOD.config = require "control.config"

local source_gui = require("scripts/source-gui")
local sources = require("scripts/sources")


script.on_init(function()
  global.counter = global.counter or {}
  for _, force in pairs(game.forces) do
    global.counter[force.name] = 1
  end

  sources.on_init()
  source_gui.on_init()
end)

script.on_configuration_changed(function(event)
  sources.on_configuration_changed(event)
  source_gui.on_configuration_changed(event)
end)

MOD.commands.setcounter = function(event)
  local player = game.players[event.player_index]
  local number = tonumber(event.parameter)

  if number then global.counter[player.force.name] = number end
end

--[[script_raised_built]]

local function on_script_raised_built(event)
  if event.entity and event.entity.valid and event.entity.name == "arcade_mode-source" then
    sources.finish_source(event.entity)
  end
end

script.on_event(defines.events.script_raised_built, on_script_raised_built)

--[[others]]

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  if event.destination.name ~= "arcade_mode-source" then return end
  if event.source.name ~= "arcade_mode-source" then return end

  local player = game.players[event.player_index]
  local signal = sources.get_source(event.source).target

  if not sources.set_target(event.destination, signal) then
    player.surface.create_entity {
      name = "flying-text",
      position = player.position,
      text = {"status.arcade_mode-no-charges"},
      color = {r=1, g=0.5, b=0.5}
    }
  end
end)

-- script.on_event(defines.events.on_player_created, function(event)
--   validate_filter(game.players[event.player_index])
--   arcade_gui.on_player_created(event)
-- end)

script.on_event(defines.events.on_force_created, function(event)
  if not global.counter then
    log("Force-creating global.counter"); global.counter = {}
  end
  local force = event.force.name
  global.counter[force] = global.counter[force] or 1
end)

script.on_event(defines.events.on_research_finished, function(event)
  local force = event.research.force.name
  if event.research.name:match("arcade_mode%-unlocker") then
    global.counter[force] = global.counter[force] + 1
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "arcade_mode-resources-override" then
    sources.on_resources_changed()
    game.print("Resources changed", {r=0, g=0.5, b=1})
  end
end)

--[[ on_*_mined ]]

local function on_mined_entity(event)
  local entity = event.entity
  if entity.name ~= "arcade_mode-source" then return end
  sources.delete(entity)
end

script.on_event(defines.events.on_robot_mined_entity, on_mined_entity)
script.on_event(defines.events.on_player_mined_entity, on_mined_entity)

-- [[ GUI ]]

script.on_event(defines.events.on_gui_click, source_gui.on_gui_click)

script.on_event(defines.events.on_gui_opened, function(event)
  if event.entity and event.entity.name == "arcade_mode-source" then
    source_gui.on_source_opened(event.entity, game.players[event.player_index])
  end
end)

script.on_event(defines.events.on_gui_closed, source_gui.on_gui_closed)

-- [[interfaces]]

remote.add_interface(MOD.if_name, MOD.interfaces)
for name, command in pairs(MOD.commands) do
  commands.add_command(name, {"command-help."..name}, command)
end