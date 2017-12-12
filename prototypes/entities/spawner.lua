local Prototype = require "scripts/prototype"

local display = {
  type = "simple-entity",
  name = "arcade_mode-spawner-display",
  collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  selectable_in_game = false,
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
  crafting_speed = 4,
  energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    emissions = 0
  },
  energy_usage = "150kW",
}

table.insert(data.raw["assembling-machine"]["assembling-machine-2"].crafting_categories, "arcade_mode-spawn")

local link_pump = table.deepcopy(data.raw.pump.pump)
link_pump.name = "arcade_mode-spawner-pump"
link_pump.flags = {"not-on-map", "player-creation"}
link_pump.minable = nil
link_pump.selectable_in_game = false
-- link_pump.collision_box = {{-0.4, -0.4}, {0.4, 0.4}}
-- link_pump.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
link_pump.collision_mask = {}
-- link_pump.fluid_box.pipe_connections = {
--   { position = {0, -1}, type = "output" },
--   { position = {0, 1}, type = "input" },
-- }
link_pump.energy_source.emissions = 0
link_pump.animations = {
  north = Prototype.empty_animation(),
  east = Prototype.empty_animation(),
  south = Prototype.empty_animation(),
  west = Prototype.empty_animation(),
}
link_pump.circuit_wire_max_distance = 0

-- local link_loader = table.deepcopy(data.raw.loader.loader)
-- link_loader.name = "arcade_mode-spawner-loader"
-- link_loader.flags = {"player-creation"}
-- link_loader.minable = nil
-- link_loader.selectable_in_game = false
-- link_loader.collision_box = {{-0.4, -0.4}, {0.4, 0.4}}
-- link_loader.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
-- link_loader.structure.direction_in.sheet = {
--   filename = "__ArcadeMode__/graphics/entities/spawner/link.png",
--   priority = "extra-high",
--   width = 32,
--   height = 32,
-- }
-- link_loader.structure.direction_out.sheet = table.deepcopy(link_loader.structure.direction_in.sheet)
-- link_loader.structure.direction_out.sheet.y = 32

data:extend{display, base, link_pump}