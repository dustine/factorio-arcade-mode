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

  -- whitelist, make it into a set
  local whitelist = {"desert", "dirt", "enemy-base", "grass", "sand"}
  local whiteset = {}
  for _, value in pairs(whitelist) do
    whiteset[value] = true
  end

  local surface = game.surfaces.nauvis
  local settings = surface.map_gen_settings
  settings.water = "none"
  -- settings.seed = 730116874
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

  for chunk in surface.get_chunks() do
    if chunk.x >= 0 then surface.delete_chunk(chunk) end
    -- surface.request_to_generate_chunks(Area.center(Chunk.to_area(chunk)), 1)
  end
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  game.forces.player.set_spawn_position({-1,0}, surface.name)
end)

script.on_configuration_changed(function(event)
  if global.version ~= version then
    global.version = version
  end

  silo_script.on_configuration_changed(event)
end)

--[[on_chunk_generated]]

local function get_edge_type_type(x, y)
  if x < -4 then return "out-of-map"
  elseif x > 0 then return nil
  elseif y > 2 or y < -2 then return "arcade_mode-edge"
  elseif x < -2 then return "arcade_mode-edge" end
end

local function place_source(position, surface, force)
  local source = surface.create_entity {
    name = "arcade_mode-source",
    position = position,
    force = force
  }
  source.destructible = false
  source.rotatable = false
  source.minable = false
  script.raise_event(defines.events.script_raised_built, {entity = source})
end

script.on_event(defines.events.on_chunk_generated, function(event)
  local surface = event.surface
  if not(surface.valid and surface.name == "nauvis") then return end

  local center = Area.center(event.area)
  local chunk = Chunk.from_position(Area.center(event.area))

  local force = game.forces.player

  if chunk.x < 0 then
    -- add The Void to leftmost chunks
    local tiles = {}
    for x,y in Area.iterate(event.area) do
      if x < -4 then
        table.insert(tiles, {position = {x, y}, name = "out-of-map"})
      end
    end
    surface.set_tiles(tiles, true)
    return
  end
  if not global.left_cleared then return end

  if chunk.x * chunk.x + chunk.y * chunk.y <= 400 then
    -- erase remaining water with dry dirt
    local water_tile_types = {"water", "deepwater", "water-green", "deepwater-green"}
    local water_tiles = {}
    for _, water in pairs(water_tile_types) do
      for _, t in pairs(event.surface.find_tiles_filtered {name = water}) do
        table.insert(water_tiles, {name = "dry-dirt", position = t.position})
      end
    end
    surface.set_tiles(water_tiles)
  end

  if chunk.x == 0 then
    -- place the border... from the leftwards chunk!
    local tiles = {}
    local area = Area.tile_center_points(event.area)
    area = Area.construct(area.left_top.x-4, area.left_top.y, area.left_top.x, area.right_bottom.y)

    for x,y in Area.iterate(area) do
      table.insert(tiles, {
        position = {x, y},
        name = get_edge_type_type(x, y) or surface.get_tile({0.5, y}).name
      })
    end
    surface.set_tiles(tiles)

    for y = area.left_top.y, area.left_top.y+31 do
      -- logic for leaving the spawning alcove sourceless
      if y > 3 or y < -3 then place_source({-2.5, y}, surface, force) end
    end
  end
end)

--[[others]]

script.on_event(defines.events.on_player_created, function(event)

  local player = game.players[event.player_index]
  -- fixes death spawn
  player.teleport(player.force.get_spawn_position("nauvis"))

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

script.on_event(defines.events.on_tick, function()
  script.on_event(defines.events.on_tick, function()
    global.left_cleared = true
    script.on_event(defines.events.on_tick, nil)
  end)
end)
