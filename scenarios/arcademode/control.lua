local Position = require('stdlib/area/position')
local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

local silo_script = require("silo-script")
local arcade_gui = require("gui")

local version = 1


silo_script.add_remote_interface()
silo_script.add_commands()

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
  global.version = version

  global.counter = global.counter or {}
  for _, force in pairs(game.forces) do
    global.counter[force.name] = 1
  end
  global.filter = {}
  get_resources()

  silo_script.on_init()
  arcade_gui.on_init()
end)

script.on_configuration_changed(function(event)
  if global.version ~= version then
    global.version = version
  end

  get_resources()

  silo_script.on_configuration_changed(event)
  arcade_gui.on_configuration_changed(event)
end)

--[[on_chunk_generated]]

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

script.on_event(defines.events.on_chunk_generated, function(event)
  local chunk = Chunk.from_position(Area.center(event.area))
  if chunk.x >= 0 then return
  elseif chunk.x == -1 then
    generate_spawner_chunk(event)
  else
    generate_empty_chunk(event)
  end
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

script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]
  player.insert{name="iron-plate", count = 8}
  player.insert{name="pistol", count = 1}
  player.insert{name="firearm-magazine", count = 10}
  player.insert{name="stone-furnace", count = 1}
  player.insert{name="arcade_mode-unlocker", count = 1}

  if (#game.players <= 1) then
    game.show_message_dialog{text = {"msg-intro"}}
  else
    player.print({"msg-intro"})
  end

  silo_script.on_player_created(event)
  arcade_gui.on_player_created(event)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
  player.insert{name="arcade_mode-unlocker", count = 1}
end)

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

script.on_event(defines.events.on_gui_click, function(event)
  silo_script.on_gui_click(event)
  arcade_gui.on_gui_click(event)
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  silo_script.on_rocket_launched(event)
end)

--[[on_tick]]
script.on_event(defines.events.on_tick, function()
  arcade_gui.on_configuration_changed()

  -- run once
  script.on_event(defines.events.on_tick, nil)
end)