local Position = require('stdlib/area/position')
local Chunk = require('stdlib/area/chunk')
local Area = require('stdlib/area/area')

local silo_script = require("silo-script")

local version = 1


silo_script.add_remote_interface()
silo_script.add_commands()

script.on_init(function()
  log("init")

  global.version = version
  silo_script.on_init()

  -- 730116874

  -- whitelist, make it into a set
  local whitelist = {"desert", "dirt", "enemy-base", "grass", "sand"}
  local whiteset = {}
  for _, value in pairs(whitelist) do
    whiteset[value] = true
  end

  local surface = game.surfaces.nauvis
  local settings = surface.map_gen_settings
  settings.water = "none"
  settings.cliff_settings.cliff_elevation_0 = 1024
  settings.default_enable_all_autoplace_controls = false

  for name, control in pairs(settings.autoplace_controls) do
    if whiteset[name] then
      if name == "enemy-base" and control.size ~= "none" then
        control.frequency = "very-high"
        control.size = "very-big"
      end
    else
      settings.autoplace_controls[name] = nil
      end
    end

  surface.map_gen_settings = settings
  log(serpent.block(surface.map_gen_settings))

  for chunk in surface.get_chunks() do
    if chunk.x >= 0 then surface.delete_chunk(chunk) end
  end

  game.forces.player.set_spawn_position({-2,0}, "nauvis")
end)

script.on_configuration_changed(function(event)
  if global.version ~= version then
    global.version = version
  end

  silo_script.on_configuration_changed(event)
end)

--[[on_chunk_generated]]

local function generate_empty_chunk(event)
  -- clean off!
  local tiles = {}
  for x,y in Area.iterate(Area.shrink(event.area, 0.5)) do
    table.insert(tiles, {
      name = "out-of-map",
      position = Position.construct(x, y)
    })
  end
  event.surface.set_tiles(tiles, false)
end

local function generate_spawner_chunk(event, chunk)
  local surface = event.surface
  local area = event.area
  local force = game.forces.player

  -- set the stable bedrock
  local pavement = Area.shrink(event.area, 0.5)
  local tiles = {}
  for x,y in Area.iterate(pavement) do
    if x % 32 < 28 then
      table.insert(tiles, {
        name = "out-of-map",
        position = Position.construct(x, y)
      })
    elseif x % 32 > 31 then
      table.insert(tiles, {
        name = "hazard-concrete-right",
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
  for _, entity in pairs(surface.find_entities(event.area)) do
    if entity.valid and entity.type ~= "player" then entity.destroy() end
  end

  local min = ((chunk.y == 0 or chunk.y == -1) and 3) or 1
  local iterator = Position.increment({area.right_bottom.x-2.5, area.left_top.y-0.5}, 0, 1)
  if chunk.y == 0 then iterator(nil, 2) end

  for i=min,32 do
    local source = surface.create_entity {
      name = "arcade_mode-source",
      position = iterator(),
      force = force
    }
    source.destructible = false
    source.minable = false
    script.raise_event(defines.events.script_raised_built, {entity = source})
  end
end

script.on_event(defines.events.on_chunk_generated, function(event)
  local chunk = Chunk.from_position(Area.center(event.area))
  if chunk.x >= 0 then
    if chunk.x * chunk.x + chunk.y * chunk.y > 100 then return end
    -- erase water with dry dirt
    local water = event.surface.find_tiles_filtered {name = "water"}
    local deep_water = event.surface.find_tiles_filtered {name = "deepwater"}

    local dry_dirt = {}
    for _, t in pairs(deep_water) do
      table.insert(dry_dirt, {
        name = "dry-dirt",
        position = t.position
      })
    end
    for _, t in pairs(water) do
      table.insert(dry_dirt, {
        name = "dry-dirt",
        position = t.position
      })
    end
    event.surface.set_tiles(dry_dirt)
  elseif chunk.x == -1 then
    generate_spawner_chunk(event, chunk)
  else
    generate_empty_chunk(event, chunk)
  end
end)

--[[others]]

script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]
  player.insert{name="iron-plate", count = 8}
  player.insert{name="pistol", count = 1}
  player.insert{name="firearm-magazine", count = 10}
  player.insert{name="stone-furnace", count = 1}
  -- player.insert{name="arcade_mode-source", count = 10}

  if (#game.players <= 1) then
    game.show_message_dialog{text = {"msg-intro"}}
  else
    player.print({"msg-intro"})
  end

  silo_script.on_player_created(event)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
end)

script.on_event(defines.events.on_gui_click, function(event)
  silo_script.on_gui_click(event)
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  silo_script.on_rocket_launched(event)
end)
