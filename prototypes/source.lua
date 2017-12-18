local Prototype = require "prototypes/prototype"

local base = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
base.name = "arcade_mode-source"
base.icon = "__ArcadeMode__/graphics/source/icon-item.png"
base.minable = {mining_time = 1, result = "arcade_mode-source"}
base.collision_box = {{-2.4, -0.4}, {0.5, 0.4}}
base.selection_box = {{-2.5, -0.5}, {0.5, 0.5}}
base.collision_mask = {"player-layer"}
base.item_slot_count = 6
base.circuit_wire_max_distance = 0
base.sprites = {
  filename = "__ArcadeMode__/graphics/source/icon-item.png",
  width = 32,
  height = 32,
  direction_count = 1
}
base.activity_led_sprites = Prototype.empty_sprite()

local container = {
  type = "infinity-container",
  icon = "__ArcadeMode__/graphics/source/icon-item-container.png",
  icon_size = 32,
  name = "arcade_mode-source_item-container",
  flags = {"not-on-map", "player-creation"},
  collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  drawing_box = {{-0.5, -0.5}, {0.5, 0.5}},
  alert_icon_shift = util.by_pixel(3, -34),
  erase_contents_when_mined = true,
  inventory_size = 1,
  -- selectable_in_game = false,
  picture = Prototype.empty_sprite(),
}

local item = {
  type = "item",
  name = "arcade_mode-source",
  flags = {"goes-to-quickbar", "hidden"},
  icon = "__ArcadeMode__/graphics/source/icon-item.png",
  icon_size = 32,
  place_result = "arcade_mode-source",
  stack_size = 1,
}

data:extend{base, container, item}

local function generate_loader(index, speed, color)
  color = util.color(color)

  local loader = table.deepcopy(data.raw.loader["loader"])
  loader.name = "arcade_mode-source_item-loader_"..index
  loader.flags = {"not-on-map", "player-creation"}
  loader.icon = nil
  loader.icons = {{
    icon = "__ArcadeMode__/graphics/source/icon-item-loader.png",
    width = 32,
    height = 32,
    tint = color
  }}
  loader.icon_size = 32
  loader.minable = nil
  loader.selectable_in_game = false
  loader.structure.direction_in = Prototype.empty_sheet()
  loader.structure.direction_out = Prototype.empty_sheet()
  loader.structure.direction_in.east = {
    filename = "__ArcadeMode__/graphics/source/item-tint.png",
    width = 96,
    height = 32,
    tint = color
  }
  loader.fast_replaceable_group = "arcade_mode-source_item-loader"
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
  source.collision_box = {{-0.4, -0.4}, {0.4, 0.4}}
  source.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
  source.icon = "__ArcadeMode__/graphics/source/icon-fluid.png"
  source.circuit_wire_max_distance = 0
  source.picture = {
    layers = {{
      filename = "__ArcadeMode__/graphics/source/fluid.png",
      width = 32*3,
      height = 32,
    }, {
      filename = "__ArcadeMode__/graphics/source/fluid-tint.png",
      width = 96,
      height = 32,
      tint = fluid.base_color
    }}
  }
  source.fast_replaceable_group = "arcade_mode-source_fluid"

  data:extend{source}
end

MOD.ArcadeMode.generate_loader = generate_loader
MOD.ArcadeMode.generate_fluid_source = generate_fluid_source
