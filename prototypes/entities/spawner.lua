local recipe_category = {
  type = "recipe-category",
  name = "arcade_mode-spawner"
},

local display = {
  type = "simple-entity",
  name = "arcade_mode-spawner_display",
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
  name = "arcade_mode-spawner_base",
  collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  fluid_boxes = {
    off_when_no_fluid_recipe = true, {
      production_type = "output",
      pipe_picture = assembler2pipepictures(),
      pipe_covers = pipecoverspictures(),
      base_area = 10,
      base_level = 1,
      pipe_connections = {{ type="output", position = {0, 2} }},
      secondary_draw_orders = { north = -1 }
    },
  },
  crafting_categories = {"arcade_mode-spawner"},

}
local link_pipe
local link_loader