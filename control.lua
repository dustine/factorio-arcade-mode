local Position = require('stdlib/area/position')
local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

local arcade_gui = require("scripts/gui")

-- resets resources based on arcademode
local function get_resources()
  global.fluids = {}
  global.items = {}

  for name, recipe in pairs(game.recipe_prototypes) do
    if name:match("arcade_mode%-spawn%-") then
      if recipe.products[1].type == "fluid" then
        table.insert(global.fluids, recipe)
      else
        table.insert(global.items, recipe)
      end
    end
  end
end

script.on_init(function()
  global.counter = global.counter or {}
  for _, force in pairs(game.forces) do
    global.counter[force.name] = 1
  end
  global.filter = {}
  get_resources()

  arcade_gui.on_init()
end)

script.on_configuration_changed(function(event)
  get_resources()

  arcade_gui.on_configuration_changed(event)
end)


--[[on_player_selected_area + alt]]

local function flush_spawner(spawner)
  local position = Position.translate(spawner.position, defines.direction.east, 1)
  local pump = spawner.surface.find_entity("arcade_mode-spawner-pump", position)
  pump.fluidbox[1] = nil
end

script.on_event(defines.events.on_player_selected_area, function(event)
  if not event.item == "arcade_mode-unlocker" then return end
  local player = game.players[event.player_index]
  local force = player.force.name

  local index = global.filter[player.index]
  local recipe = global.items[index] or global.fluids[index - #global.items]

  if not recipe or not recipe.valid then return end

  for _, entity in pairs(event.entities) do
    if entity.name:match("arcade_mode%-spawner%-base") then
      if global.counter[force] > 0 and not entity.active then
        local display = entity.surface.find_entity("arcade_mode-spawner-display", entity.position)
        if display then display.graphics_variation = 2 end
        entity.active = true
        global.counter[force] = global.counter[force] - 1
        entity.set_recipe(recipe.name)
        flush_spawner(entity)
      elseif entity.active then
        entity.set_recipe(recipe.name)
        flush_spawner(entity)
      end
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

local function cycle_resource(player, quantity)
  local new_index = global.filter[player.index] + quantity
  -- 1-indexiiiing *shakes fists*
  global.filter[player.index] = (new_index - 1) % (#global.items + #global.fluids) + 1

  arcade_gui.gui_update(player)
end

script.on_event("arcade_mode-next-resource", function(event)
  cycle_resource(game.players[event.player_index], 1)
end)

script.on_event("arcade_mode-previous-resource", function(event)
  cycle_resource(game.players[event.player_index], -1)
end)

--[[others]]

script.on_event(defines.events.on_force_created, function(event)
  if not global.counter then log("yo"); global.counter = {} end
  local force = event.force.name
  global.counter[force] = global.counter[force] or 1
end)

script.on_event(defines.events.on_research_finished, function(event)
  local force = event.research.force.name
  if event.research.name:match("arcade_mode%-unlocker") then
    global.counter[force] = global.counter[force] + 1
  end
end)

script.on_event(defines.events.on_gui_click, arcade_gui.on_gui_click)

script.on_event(defines.events.on_player_created, arcade_gui.on_player_created)