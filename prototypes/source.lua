local Prototype = require "prototypes/prototype"

local none = {
  type = "simple-entity-with-force",
  name = "arcade_mode-source_none",
  collision_box = {{-1.4, -0.4}, {1.4, 0.4}},
  selection_box = {{-1.5, -0.5}, {1.5, 0.5}},
  -- selectable_in_game = false,
  icon = "__ArcadeMode__/graphics/source/icon-none.png",
  icon_size = 32,
  render_layer = "higher-object-above",
  flags = {"player-creation"},
  pictures = {{
    filename = "__ArcadeMode__/graphics/source/off.png",
    width = 32*3,
    height = 32,
  }},
}

local chest = {
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
  flags = {},
  icon = "__ArcadeMode__/graphics/source/icon-item.png",
  icon_size = 32,
  place_result = "arcade_mode-source_none",
  stack_size = 1,
}

data:extend{none, chest, item}

local function generate_loader(index, speed, color)
  color = util.color(color)
  
  local loader = table.deepcopy(data.raw.loader["express-loader"])
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
  loader.structure.direction_in = {
    north = Prototype.empty_sprite(),
    east = Prototype.empty_sprite(),
    south = Prototype.empty_sprite(),
    west = Prototype.empty_sprite(),
  }
  loader.structure.direction_out = {
    north = Prototype.empty_sprite(),
    east = Prototype.empty_sprite(),
    south = Prototype.empty_sprite(),
    west = Prototype.empty_sprite(),
  }
  loader.fast_replaceable_group = "arcade_mode-source_item-loader"
  loader.speed = speed or data.raw["transport-belt"]["transport-belt"].speed

  data:extend{none, loader}

  local display = data.raw["simple-entity-with-force"]["arcade_mode-source_item"] or {
    type = "simple-entity-with-force",
    name = "arcade_mode-source_item",
    collision_box = {{-1.4, -0.4}, {1.4, 0.4}},
    selection_box = {{-1.5, -0.5}, {1.5, 0.5}},
    collision_mask = {"ground-tile", "player-layer"},
    -- selectable_in_game = false,
    icon_size = 32,
    render_layer = "higher-object-above",
    flags = {"player-creation"},
    icon = "__ArcadeMode__/graphics/source/icon-item.png",
    pictures = {},
  }

  display.pictures[index] = {
    layers = {{
      filename = "__ArcadeMode__/graphics/source/item.png",
      width = 32,
      height = 32,
    },{
      filename = "__ArcadeMode__/graphics/source/item-tint.png",
      width = 32,
      height = 32,
      tint = color
    }}
  }

  if not data.raw["simple-entity-with-force"]["arcade_mode-source_item"] then data:extend{display} end
end

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
      width = 32*3,
      height = 32,
      tint = fluid.base_color
    }}
  }
  source.fast_replaceable_group = "arcade_mode-source_fluid"

  data:extend{source}
end

MOD.ArcadeMode.generate_loader = generate_loader
MOD.ArcadeMode.generate_fluid_source = generate_fluid_source

generate_loader(1, data.raw["transport-belt"]["transport-belt"].speed, "ff0")
generate_loader(2, data.raw["transport-belt"]["fast-transport-belt"].speed, "f00")
generate_loader(3, data.raw["transport-belt"]["express-transport-belt"].speed, "00f")
