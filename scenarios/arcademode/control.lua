local Position = require('stdlib/area/position')
local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

local silo_script = require("silo-script")

local version = 1


silo_script.add_remote_interface()
silo_script.add_commands()

script.on_init(function()
  global.version = version
  silo_script.on_init()

  local blacklist = {"coal", "copper-ore", "crude-oil", "iron-ore", "stone", "trees", "uranium-ore"}
  local settings = {
    autoplace_controls = {},
    seed = game.surfaces.nauvis.map_gen_settings.seed,
    water = "none",
    cliff_settings = {
      cliff_elevation_0 = 1024,
      cliff_elevation_interval = 10,
      name = "cliff"
    },
  }
  for _, c in pairs(blacklist) do
    settings.autoplace_controls[c] = {
      size = "none"
    }
  end
  game.create_surface("anulus", settings)

  game.forces.player.set_spawn_position({0,0}, "anulus")
  for _, p in pairs(game.forces.player.players) do
    p.teleport({0,0}, "anulus")
  end
  for c in game.surfaces.nauvis.get_chunks() do
    game.surfaces.nauvis.delete_chunk(c)
  end
end)

script.on_configuration_changed(function(event)
  if global.version ~= version then
    global.version = version
  end

  silo_script.on_configuration_changed(event)
end)

--[[on_chunk_generated]]

-- local function create_spawner(surface, position, force)
--   local link_position = Position.translate(table.deepcopy(position), defines.direction.east, 1)

--   local display = surface.create_entity {
--     name = "arcade_mode-spawner-display",
--     position = position,
--     force = force
--   }
--   local base = surface.create_entity {
--     name = "arcade_mode-spawner-base",
--     position = position,
--     force = force,
--     direction = defines.direction.east
--   }
--   local link_pump = surface.create_entity {
--     name = "arcade_mode-spawner-pump",
--     position = link_position,
--     force = force,
--     direction = defines.direction.east
--   }
--   local link_loader = surface.create_entity {
--     name = "arcade_mode-spawner-loader",
--     position = link_position,
--     force = force,
--     direction = defines.direction.east,
--     type = "output"
--   }

--   -- base.teleport(base.position)

--   base.active = false
--   base.operable = false
--   base.rotatable = false
--   base.destructible = false
--   display.destructible = false
--   display.graphics_variation = 1
--   link_pump.operable = false
--   link_pump.destructible = false
--   link_loader.operable = false
--   link_loader.destructible = false
-- end

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

  -- set the stable bedrock
  local pavement = Area.construct(
    area.left_top.x+0.1, area.left_top.y-0.1,
    area.left_top.x+3.9, area.right_bottom.y-0.1
  )
  local tiles = {}
  for x,y in Area.iterate(pavement) do
    if x % 32 == 3 then
      table.insert(tiles, {
        name = "hazard-concrete",
        position = Position.construct(x, y)
      })
    else
      table.insert(tiles, {
        name = "concrete",
        position = Position.construct(x, y)
      })
    end
  end
  event.surface.set_tiles(tiles)
  for _, entity in pairs(surface.find_entities {area = pavement}) do
    entity.destroy()
  end

  local iterator = Position.increment({area.left_top.x+0.5, area.left_top.y-0.5}, 0, 1)
  for i=1,32 do
    local source = surface.create_entity {
      name = "arcade_mode-item-source-display",
      position = iterator(0, 0),
      force = force
    }
    -- pole.operable = false
    source.destructible = false
    source.graphics_variation = 1
  end

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

  if player.surface.name ~= "anulus" then
    player.teleport({0,0}, "anulus")
  end
  silo_script.on_player_created(event)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
  player.insert{name="arcade_mode-unlocker", count = 1}
end)

script.on_event(defines.events.on_gui_click, function(event)
  silo_script.on_gui_click(event)
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  silo_script.on_rocket_launched(event)
end)
