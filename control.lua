local Position = require('stdlib/area/position')
local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

local gui = require "scripts/gui"

local counter, filter, items, fluids

local function on_load()
  counter = global.counter
  filter = global.filter
  fluids = global.fluids
  items = global.items
end

-- resets resources based on arcademode
local function get_resources()
  global.fluids = {}
  global.items = {}
  fluids = global.fluids
  items = global.items

  for name, recipe in pairs(game.recipe_prototypes) do
    if name:match("arcade_mode%-spawn%-") then
      if recipe.products[1].type == "fluid" then
        table.insert(fluids, recipe)
      else
        table.insert(items, recipe)
      end
    end
  end
end

local function on_init()
  global.counter = global.counter or {}
  for _, force in pairs(game.forces) do
    global.counter[force.name] = 1
  end
  global.filter = {}
  get_resources()

  gui.init()
  for _, player in pairs(game.players) do
    gui.gui_init(player)
  end

  on_load()
end

local function on_configuration_changed()
  -- reset gui
  get_resources()
  for _, player in pairs(game.players) do
    gui.gui_init(player)
  end
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)


local function create_spawner(surface, position, force)
  local link_position = Position.translate(table.deepcopy(position), defines.direction.east, 1)

  local display = surface.create_entity {
    name = "arcade_mode-spawner-display",
    position = position,
    force = force
  }
  local base = surface.create_entity {
    name = "arcade_mode-spawner-base",
    position = position,
    force = force,
    direction = defines.direction.east
  }
  local link_pump = surface.create_entity {
    name = "arcade_mode-spawner-pump",
    position = link_position,
    force = force,
    direction = defines.direction.east
  }
  local link_loader = surface.create_entity {
    name = "arcade_mode-spawner-loader",
    position = link_position,
    force = force,
    direction = defines.direction.east,
    type = "output"
  }

  -- base.teleport(base.position)

  base.active = false
  base.operable = false
  base.rotatable = false
  base.destructible = false
  display.destructible = false
  display.graphics_variation = 1
  link_pump.operable = false
  link_pump.destructible = false
  link_loader.operable = false
  link_loader.destructible = false
end

local function generate_empty_chunk(event)
  -- clean off!
  local tiles = {}
  for x,y in Area.iterate(Area.shrink(event.area, 0.5)) do
    table.insert(tiles, {
      name = "out-of-map",
      position = Position.construct(x, y)
    })
  end
  event.surface.set_tiles(tiles)
end

local function generate_spawner_chunk(event)
  local surface = event.surface
  local area = event.area
  local force = game.forces.player

  -- generate the power source
  local start = Position.construct(area.left_top.x+0.5, area.left_top.y+0.5)

  local source = surface.create_entity {
    name = "arcade_mode-power-source",
    position = start,
    force = force
  }
  source.operable = false
  source.destructible = false

  -- then the poles/spawners
  local iterator = Position.increment({area.left_top.x+0.5, area.left_top.y-0.5}, 0, 1)
  for i=1,16 do
    create_spawner(surface, iterator(), force)
    create_spawner(surface, iterator(), force)
    local pole = surface.create_entity {
      name = "arcade_mode-power-pole",
      position = iterator(0, 0),
      force = force
    }
    pole.operable = false
    pole.destructible = false
  end
end

local function on_chunk_generated(event)
  local chunk = Chunk.from_position(Area.center(event.area))
  if chunk.x >= 0 then return
  elseif chunk.x == -1 then
    generate_spawner_chunk(event)
  else
    generate_empty_chunk(event)
  end
end

local function activate_spawner(base, player)
  local index = filter[player.index]
  local recipe_prototype = items[index] or fluids[index - #global.items]
  if not recipe_prototype or not recipe_prototype.valid then return false end
  -- local recipe = player.force.recipes[recipe_prototype.name]
  -- if not recipe or not recipe.valid then return false end

  if counter[base.force.name] > 0 and not base.active then
    local display = base.surface.find_entity("arcade_mode-spawner-display", base.position)

    if display then display.graphics_variation = 2 else return false end
    base.active = true
    counter[base.force.name] = counter[base.force.name] - 1

    base.set_recipe(recipe_prototype.name)
    return true
  elseif base.active then
    base.set_recipe(recipe_prototype.name)
    return true
  end
  return false
end

local function reset_spawner(base)
  if not base.active then return false end

  local display = base.surface.find_entity("arcade_mode-spawner-display", base.position)

  if display then display.graphics_variation = 1 else return false end
  base.active = false
  -- TODO: flush loader & pump
  counter[base.force.name] = counter[base.force.name] + 1

  base.recipe = nil
  return true
end

local function on_unlocker(event, f)
  if event.item:match("arcade_mode%-unlocker") then
    local player = game.players[event.player_index]

    for _, entity in pairs(event.entities) do
      if entity.name:match("arcade_mode%-spawner%-base") then f(entity, player) end
    end

    if player then
      player.surface.create_entity {
        name = "flying-text",
        position = player.position,
        text = counter[player.force.name] or "???"
      }
    end
  end
end

local function cycle_resource(player, quantity)
  local new_index = global.filter[player.index] + quantity
  -- 1-indexiiiing *shakes fists*
  global.filter[player.index] = (new_index - 1) % (#global.items + #global.fluids) + 1

  gui.gui_update(player)
end

script.on_event(defines.events.on_force_created, function(event)
  if not counter then
    global.counter = {}
    counter = global.counter
  end
  counter[event.force.name] = counter[event.force.name] or 1
end)

script.on_event(defines.events.on_chunk_generated, on_chunk_generated)

script.on_event(defines.events.on_built_entity, function(event)
  if event.created_entity.name == "wooden-chest" then
    local surface = event.created_entity.surface
    local position = event.created_entity.position
    local force = event.created_entity.force
    event.created_entity.destroy()
    create_spawner(surface, position, force)
  end
end)

script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name:match("arcade_mode%-unlocker") then
    counter[event.research.force.name] = counter[event.research.force.name] + 1
  end
end)

script.on_event(defines.events.on_player_selected_area, function(event)
  on_unlocker(event, activate_spawner)
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
  on_unlocker(event, reset_spawner)
end)

script.on_event(defines.events.on_player_created, function(event)
  gui.gui_init(game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_click, gui.on_gui_click)

script.on_event("arcade_mode-next-resource", function(event)
  cycle_resource(game.players[event.player_index], 1)
end)

script.on_event("arcade_mode-previous-resource", function(event)
  cycle_resource(game.players[event.player_index], -1)
end)