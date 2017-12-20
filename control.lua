MOD = {}
MOD.name = "ArcadeMode"
MOD.if_name = "arcade_mode"
MOD.interfaces = {}
MOD.commands = {}
-- MOD.config = require "control.config"

-- local recipes = require("scripts/recipes/recipes")

require "stdlib/utils/table"
local sources = require("scripts/sources")

local function init_force(force)
  global.limits = global.limits or {}
  global.limits[force.name] = {
    counter = 1,
    speed = {
      item = 1,
      fluid = 1
    }
  }
end

script.on_init(function()
  for _, force in pairs(game.forces) do
    init_force(force)
  end

  sources.on_init()
end)

script.on_configuration_changed(function(event)
  sources.on_configuration_changed(event)
end)

MOD.commands.setcounter = function(event)
  local player = game.players[event.player_index]
  local number = tonumber(event.parameter)

  if number then global.counter[player.force.name] = number end
end

--[[script_raised_built]]

local function on_script_raised_built(event)
  if event.entity and event.entity.valid and event.entity.name == "arcade_mode-source" then
    sources.finish(event.entity)
  end
end

script.on_event(defines.events.script_raised_built, on_script_raised_built)

--[[others]]

script.on_event(defines.events.on_entity_settings_pasted, function(event)
  if event.destination.name ~= "arcade_mode-source" then return end
  if event.source.name ~= "arcade_mode-source" then return end

  local player = game.players[event.player_index]
  local signal = sources.get(event.source).target

  if not sources.set_target(event.destination, player, signal) then
    player.surface.create_entity {
      name = "flying-text",
      position = player.position,
      text = {"status.arcade_mode-no-charges"},
      color = {r=1, g=0.5, b=0.5}
    }
    sources.refresh_display(event.destination)
  end
end)

-- script.on_event(defines.events.on_player_created, function(event)
--   validate_filter(game.players[event.player_index])
--   arcade_gui.on_player_created(event)
-- end)

script.on_event(defines.events.on_force_created, function(event)
  init_force(event.force)
end)

script.on_event(defines.events.on_research_finished, function(event)
  local force = event.research.force.name
  if not global.limits or not global.limits[force] then
    init_force(force)
  end
  if event.research.name:match("arcade_mode%-unlocker%-unlock") then
    global.limits[force].counter = math.max(global.limits[force].counter, event.research.level + 1)
  elseif event.research.name:match("arcade_mode%-unlocker%-upgrade") then
    global.limits[force].speed.item = math.max(global.limits[force].speed.item,event.research.level + 1)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting == "arcade_mode-resources-override" then
    sources.on_resources_changed()
    game.print("Resources changed", {r=5, g=0.8, b=1})
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

script.on_event(defines.events.on_gui_click, sources.gui.on_click)

script.on_event(defines.events.on_gui_opened, function(event)
  if event.entity and event.entity.name == "arcade_mode-source" then
    sources.gui.on_source_opened(event.entity, game.players[event.player_index])
  end
end)

script.on_event(defines.events.on_gui_closed, sources.gui.on_closed)

-- [[interfaces]]

remote.add_interface(MOD.if_name, MOD.interfaces)
for name, command in pairs(MOD.commands) do
  commands.add_command(name, {"command-help."..name}, command)
end