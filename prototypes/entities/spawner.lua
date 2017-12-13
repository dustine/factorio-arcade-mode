local Prototype = require "prototypes/prototype"

data:extend {{
  type = "recipe-category",
  name = "arcade_mode-spawn"
},{
  type = "item-group",
  name = "arcade_mode-spawn",
  icon = "__ArcadeMode__/graphics/entities/spawner/base.png",
  icon_size = 32,
  order = "y"
},{
  type = "item-subgroup",
  name = "arcade_mode-spawn-item",
  group = "arcade_mode-spawn",
  order = "a"
},{
  type = "item-subgroup",
  name = "arcade_mode-spawn-fluid",
  group = "arcade_mode-spawn",
  order = "b"
}}

local display = {
  type = "simple-entity",
  name = "arcade_mode-spawner-display",
  collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  selectable_in_game = false,
  icon_size = 32,
  render_layer = "higher-object-above",
  flags = {"not-on-map"},
  icon = "__ArcadeMode__/graphics/entities/spawner/base.png",
  pictures = {{
    filename = "__ArcadeMode__/graphics/entities/spawner/disabled.png",
    width = 32,
    height = 32,
  },{
    filename = "__ArcadeMode__/graphics/entities/spawner/enabled.png",
    width = 32,
    height = 32,
  }},
}

local base = {
  type = "assembling-machine",
  name = "arcade_mode-spawner-base",
  flags = {"player-creation"},
  collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  drawing_box = {{-0.5, -0.5}, {0.5, 0.5}},
  alert_icon_shift = util.by_pixel(3, -34),
  selectable_in_game = false,
  fluid_boxes = {
    off_when_no_fluid_recipe = false, {
      production_type = "output",
      base_area = 10,
      base_level = 1,
      pipe_connections = {{ type="output", position = {0, -1} }},
      secondary_draw_orders = { north = -1 },
      pipe_covers = {
        north = Prototype.empty_sprite(),
        east = Prototype.empty_sprite(),
        south = Prototype.empty_sprite(),
        west = Prototype.empty_sprite(),
      },
      pipe_picture = {
        north = Prototype.empty_sprite(),
        east = Prototype.empty_sprite(),
        south = Prototype.empty_sprite(),
        west = Prototype.empty_sprite(),
      },
    },
  },
  animation = {
    filename = "__ArcadeMode__/graphics/entities/spawner/base.png",
    priority = "high",
    width = 32,
    height = 32,
    frame_count = 1,
    line_length = 1,
    -- shift = util.by_pixel(0, 4),
  },
  crafting_categories = {"arcade_mode-spawn"},
  ingredient_count = 0,
  crafting_speed = 2,
  energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    emissions = 0
  },
  energy_usage = "150kW",
}

local link_pump = table.deepcopy(data.raw.pump.pump)
link_pump.name = "arcade_mode-spawner-pump"
link_pump.flags = {"player-creation"}
link_pump.minable = nil
link_pump.selectable_in_game = false
link_pump.collision_mask = {"player-layer", "water-tile"}
link_pump.energy_source.emissions = 0
link_pump.animations = {
  filename = "__ArcadeMode__/graphics/entities/spawner/link.png",
  width = 64,
  height = 32,
  line_length = 1,
  frame_count = 1
}
link_pump.fluid_animation = {
  filename = "__ArcadeMode__/graphics/entities/spawner/link-fluid.png",
  apply_runtime_tint = true,
  width = 64,
  height = 32,
  line_length = 1,
  frame_count = 1
}
link_pump.glass_pictures = {
  north = Prototype.empty_animation(),
  east = Prototype.empty_animation(),
  south = Prototype.empty_animation(),
  west = Prototype.empty_animation(),
}
link_pump.fluid_box.pipe_covers = {
  north = Prototype.empty_sprite(),
  east = Prototype.empty_sprite(),
  south = Prototype.empty_sprite(),
  west = Prototype.empty_sprite(),
}
link_pump.working_sound = nil
-- link_pump.circuit_wire_max_distance = 0

local link_loader = table.deepcopy(data.raw.loader["express-loader"])
link_loader.name = "arcade_mode-spawner-loader"
link_loader.flags = {"player-creation"}
link_loader.minable = nil
link_loader.selectable_in_game = false
link_loader.structure.direction_in = {
  north = Prototype.empty_sprite(),
  east = Prototype.empty_sprite(),
  south = Prototype.empty_sprite(),
  west = Prototype.empty_sprite(),
}
link_loader.structure.direction_out = {
  north = Prototype.empty_sprite(),
  east = Prototype.empty_sprite(),
  south = Prototype.empty_sprite(),
  west = Prototype.empty_sprite(),
}

data:extend{display, base, link_pump, link_loader}