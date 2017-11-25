local Position = require('stdlib/area/position')
local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

local counter

local function on_load()
  counter = global.counter
end

script.on_init(function()
  global.counter = {}
  for _, force in pairs(game.forces) do
    global.counter[force.name] = 1
  end

  on_load()
end)

script.on_load(on_load)

script.on_event(defines.events.on_force_created, function(event)
  counter[event.force.name] = counter[event.force.name] or 1

  -- TODO: is it 1?
end)

script.on_event(defines.events.on_forces_merging, function(event)
  -- TODO
end)

script.on_event(defines.events.on_chunk_generated, function(event)
  local chunk = Chunk.from_position(Area.center(event.area))
  if chunk.x >= 0 then return end

  if chunk.x == -1 then
  else
    -- clean off!
    local surface = event.surface
    local tiles = {}
    for x,y in Area.iterate(event.area) do
      table.insert(tiles, {
        name = "out-of-map",
        position = Position.construct(x, y)
      })
    end
    surface.set_tiles(tiles)
  end
end)

local function create_spawner(surface, position, force)
  local link_position = Position.translate(position, defines.direction.east, 1)

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
    name = "express-loader",
    position = link_position,
    force = force,
    direction = defines.direction.east,
    type = "output"
  }

  base.teleport(base.position)

  base.active = false
  base.rotatable = false
  base.destructible = false
  display.destructible = false
  display.graphics_variation = 1
  link_pump.destructible = false
  link_loader.minable = false
  link_loader.destructible = false
end

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

local function activate_spawner(base)
  if counter[base.force.name] > 0 and not base.active then
    local display = base.surface.find_entity("arcade_mode-spawner-display", base.position)

    if display then display.graphics_variation = 2 else return false end
    base.active = true
    counter[base.force.name] = counter[base.force.name] - 1
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
  return true
end

local function on_unlocker(event, f)
  if event.item:match("arcade_mode%-unlocker") then
    for _, entity in pairs(event.entities) do
      if entity.name:match("arcade_mode%-spawner%-base") then f(entity) end
    end

    local player = game.players[event.player_index]
    if player then
      player.surface.create_entity {
        name = "flying-text",
        position = player.position,
        text = counter[player.force.name] or "???"
      }
    end
  end
end

script.on_event(defines.events.on_player_selected_area, function(event)
  on_unlocker(event, activate_spawner)
end)

script.on_event(defines.events.on_player_alt_selected_area, function(event)
  on_unlocker(event, reset_spawner)
end)
