MOD = {}
MOD.name = "ArcadeMode"
MOD.if_name = "arcade_mode"
MOD.interfaces = {}
MOD.commands = {}
-- MOD.config = require "control.config"

-- local Position = require('stdlib/area/position')
-- local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

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

--[[on_player_selected_area + alt]]

local function get_source_components(source)
  if source.type ~= "item" then return end

  local position = source.main.position
  source.components = {}

  for _, entity in pairs(source.main.surface.find_entities(Area.construct(
    position.x-1, position.y, position.x+1, position.y))) do
    local subtype = entity.name:match("arcade_mode%-source_item%-(.*)&")
    if subtype then
      source.components[subtype] = entity
    end
  end
end

local function get_source(entity)
  local type = entity.name:match("arcade_mode%-source_([^%-]+)&")
  if not type then return end
  local source = {
    main = entity,
    type = type
  }
  get_source_components(source)

  return source
end

script.on_event(defines.events.on_player_selected_area, function(event)
  if not event.item == "arcade_mode-unlocker" then return end

  local player = game.players[event.player_index]
  local force = player.force.name

  local filter = global.filter[player.index]
  local index = filter.index
  local recipe = global.items[index] or global.fluids[index - #global.items]

  if not recipe or not recipe.valid then return end

  for _, entity in pairs(event.entities) do
    local source = get_source(entity)
    if source then

    end
  end

  player.surface.create_entity {
    name = "flying-text",
    position = player.position,
    text = global.counter[player.force.name] or "???"
  }
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
  if not event.item == "arcade_mode-unlocker" then return end
  local player = game.players[event.player_index]
  local force = player.force.name

  for _, entity in pairs(event.entities) do
    if entity.name:match("arcade_mode%-spawner%-base") and entity.active then
      local display = entity.surface.find_entity("arcade_mode-spawner-display", entity.position)

      if display then display.graphics_variation = 1 end
      entity.active = false
      global.counter[force] = global.counter[force] + 1
      entity.set_recipe(nil)
      flush_spawner(entity)
    end
  end

  player.surface.create_entity {
    name = "flying-text",
    position = player.position,
    text = global.counter[player.force.name] or "???"
  }
end)

--[[on_cycle_resource]]

-- local function cycle_resource(player, quantity)
--   if filters.cycle(player, quantity) then
--     arcade_gui.gui_update(player)
--   end
-- end

-- script.on_event("arcade_mode-next-resource", function(event)
--   cycle_resource(game.players[event.player_index], 1)
-- end)

-- script.on_event("arcade_mode-previous-resource", function(event)
--   cycle_resource(game.players[event.player_index], -1)
-- end)

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

-- script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
--   filters.on_runtime_mod_setting_changed(event)
--   arcade_gui.on_runtime_mod_setting_changed(event)
-- end)

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