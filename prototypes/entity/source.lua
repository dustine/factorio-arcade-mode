local Prototype = require "prototypes/prototype"

local base = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
base.name = "arcade_mode-source"
base.icon = "__ArcadeMode__/graphics/entity/source/icon-item.png"
base.minable = {mining_time = 1, result = "arcade_mode-source"}
base.collision_box = {{-1.8, -0.4}, {1.8, 0.4}}
base.selection_box = {{-2.0, -0.5}, {2.0, 0.5}}
base.collision_mask = {"object-layer", "player-layer"}
base.item_slot_count = 1

base.circuit_wire_max_distance = 0
base.sprites = {
  north = {
    filename = "__ArcadeMode__/graphics/entity/source/off.png",
    width = 32*4,
    height = 32,
    direction_count = 1,
  },
  south = Prototype.empty_sprite(),
  east = Prototype.empty_sprite(),
  west = Prototype.empty_sprite(),
}
-- base.sprites.west = table.deepcopy(base.sprites.east)
base.activity_led_sprites = Prototype.empty_sprite()

local container = {
  type = "infinity-container",
  icon = "__ArcadeMode__/graphics/entity/source/icon-item-container.png",
  icon_size = 32,
  name = "arcade_mode-source_item-container",
  flags = {"not-on-map", "player-creation"},
  collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  -- collision_mask = {},
  erase_contents_when_mined = true,
  inventory_size = 1,
  selectable_in_game = false,
  gui_mode = "none",
  picture = {
    filename = "__ArcadeMode__/graphics/entity/source/item.png",
    width = 32,
    height = 32,
    -- shift = util.by_pixel(-32, 0),
  }
}

local item = {
  type = "item",
  name = "arcade_mode-source",
  flags = {"goes-to-quickbar", "hidden"},
  icon = "__ArcadeMode__/graphics/entity/source/icon-item.png",
  icon_size = 32,
  place_result = "arcade_mode-source",
  stack_size = 10,
}

data:extend{base, container, item}

local function generate_loader(index, speed, color)
  color = util.color(color)
  color.a = 0.5

  local loader = table.deepcopy(data.raw.loader["loader"])
  loader.name = "arcade_mode-source_item-loader-"..index
  loader.flags = {"not-on-map", "player-creation"}
  loader.icon = nil
  loader.icons = {{
    icon = "__ArcadeMode__/graphics/entity/source/icon-item-loader.png",
    width = 32,
    height = 32,
    tint = color
  }}
  loader.icon_size = 32
  loader.minable = nil
  loader.selectable_in_game = false
  loader.structure.direction_in = Prototype.empty_sheet()
  loader.structure.direction_out = Prototype.empty_sheet()
  loader.structure.direction_out.west = {
    layers = {{
      filename = "__ArcadeMode__/graphics/entity/source/item.png",
      width = 32*2,
      height = 32,
      x = 32
      -- shift = util.by_pixel(-32, 0),
    },{
      filename = "__ArcadeMode__/graphics/entity/source/item-tint.png",
      width = 32*2,
      height = 32,
      x = 32,
      -- shift = util.by_pixel(-32, 0),
      tint = color
    }}
  }
  -- loader.structure.direction_out.west
  -- loader.fast_replaceable_group = "arcade_mode-source_item-loader"
  loader.speed = speed or data.raw["transport-belt"]["transport-belt"].speed

  data:extend{loader}
end

generate_loader(1, data.raw["transport-belt"]["transport-belt"].speed, "ff0")
generate_loader(2, data.raw["transport-belt"]["fast-transport-belt"].speed, "f00")
generate_loader(3, data.raw["transport-belt"]["express-transport-belt"].speed, "00f")

local function generate_fluid_source(fluid)
  local source = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
  source.name = "arcade_mode-source_fluid-"..fluid.name
  source.flags = {"player-creation"}
  source.minable = nil
  source.fluid = fluid.name
  source.collision_box = {{-0.4, -0.4}, {3.4, 0.4}}
  source.selection_box = {{-0.5, -0.5}, {3.5, 0.5}}
  source.selectable_in_game = false
  source.fluid_box.pipe_connections[1].position = {4, 0}
  source.adjacent_tile_collision_test = {"ground-tile"}
  source.collision_mask = { "object-layer", "player-layer" }
  -- source.fluid_box_tile_collision_test = { "water-tile" },
  -- source.adjacent_tile_collision_test = { "water-tile" },
  source.icon = "__ArcadeMode__/graphics/entity/source/icon-fluid.png"
  source.circuit_wire_max_distance = 0
  source.picture = {
    layers = {{
      filename = "__ArcadeMode__/graphics/entity/source/fluid.png",
      width = 32*4,
      height = 32,
      shift = util.by_pixel(32+16, 0),
    }, {
      filename = "__ArcadeMode__/graphics/entity/source/fluid-tint.png",
      width = 32*4,
      height = 32,
      tint = fluid.base_color,
      shift = util.by_pixel(32+16, 0)
    }}
  }
  source.picture.layers[2].tint.a = 0.5
  -- source.fast_replaceable_group = "arcade_mode-source_fluid"

  data:extend{source}
end

MOD.ArcadeMode.generate_loader = generate_loader
MOD.ArcadeMode.generate_fluid_source = generate_fluid_source

--[[ TECH ]]

local unlock_template = {
  type = "technology",
  name = "arcade_mode-unlock-",
  icon = "__ArcadeMode__/graphics/entity/source/unlock.png",
  icon_size = 128,
  effects = {{
    type = "nothing",
    effect_description = {"technology-effect.arcade_mode-unlock"}
  }},
  upgrade = true,
  order = "z-[ArcadeMode]-a-a"
}

local last_unlock = 0
local next_unlock = 1
local function make_unlock(science_packs, formula, max_level)
  local unlock = table.deepcopy(unlock_template)
  unlock.name = unlock.name..next_unlock
  unlock.unit = {
    count_formula = formula,
    ingredients = {},
    time = 60,
  }
  unlock.max_level = tostring(max_level)
  for _, type in pairs(science_packs) do
    table.insert(unlock.unit.ingredients, {type, 1})
  end
  if last_unlock > 0 then
    unlock.prerequisites = {"arcade_mode-unlock-"..last_unlock}
  end

  data:extend{unlock}
  last_unlock = next_unlock
  if max_level ~= "infinite" then
    next_unlock = max_level + 1
  end
end

make_unlock({"science-pack-1"}, "240", 1)
make_unlock({"science-pack-1", "science-pack-2"}, "80*L", 7)

data:extend {{
  type = "technology",
  name = "arcade_mode-upgrade-1",
  icon = "__ArcadeMode__/graphics/entity/source/upgrade-1.png",
  icon_size = 128,
  unit = {
    count_formula = "240",
    ingredients = {
      {"science-pack-1", 1},
      {"science-pack-2", 1},
    },
    time = 60
  },
  prerequisites = {"arcade_mode-unlock-2", "logistics-2"},
  effects = {{
    type = "nothing",
    effect_description = {"technology-effect.arcade_mode-upgrade", {"entity-name.fast-transport-belt"}}
  }}
}}

make_unlock({"science-pack-1", "science-pack-2", "science-pack-3"}, "20*L", 49)
make_unlock({"science-pack-1", "science-pack-2", "science-pack-3", "production-science-pack"}, "10*L", 99)

data:extend {{
  type = "technology",
  name = "arcade_mode-upgrade-2",
  icon = "__ArcadeMode__/graphics/entity/source/upgrade-2.png",
  icon_size = 128,
  unit = {
    count_formula = "600",
    ingredients = {
      {"science-pack-1", 1},
      {"science-pack-2", 1},
      {"science-pack-3", 1},
      {"production-science-pack", 1},
    },
    time = 60
  },
  prerequisites = {"arcade_mode-unlock-50", "arcade_mode-upgrade-1", "logistics-3"},
  effects = {{
    type = "nothing",
    effect_description = {"technology-effect.arcade_mode-upgrade", {"entity-name.express-transport-belt"}}
  }},
  upgrade = true
}}

make_unlock({"science-pack-1", "science-pack-2", "science-pack-3", "production-science-pack", "high-tech-science-pack"}, "5*L", 249)
make_unlock({"science-pack-1", "science-pack-2", "science-pack-3", "production-science-pack", "high-tech-science-pack", "space-science-pack"}, "1.75*(L-1)", "infinite")

--[[
  {"science-pack-1", 1},
  {"science-pack-2", 1},
  {"science-pack-3", 1},
  {"military-science-pack", 1},
  {"production-science-pack", 1},
  {"high-tech-science-pack", 1},
  {"space-science-pack", 1},

  time = 20, 30, 60
]]
