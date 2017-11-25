local tool = {
  -- This allows loading the selection-tool type item when mods are removed
  type = "selection-tool",
  name = "arcade_mode-unlocker",
  icon = "__ArcadeMode__/graphics/items/unlocker.png",
  flags = {"goes-to-quickbar"},
  subgroup = "tool",
  order = "c[automated-construction]-a[blueprint]",
  stack_size = 1,
  stackable = false,
  selection_color = { r = 1, g = 1, b = 0 },
  alt_selection_color = { r = 1, g = 0, b = 0 },
  selection_mode = {"buildable-type", "matches-force"},
  alt_selection_mode = {"buildable-type", "matches-force"},
  selection_cursor_box_type = "copy",
  alt_selection_cursor_box_type = "copy"
}

local recipe = {
  type = "recipe",
  name = "arcade_mode-unlocker",
  result = "arcade_mode-unlocker",
  enabled = true,
  ingredients = {}
}

local technology = {
  type = "technology",
  name = "arcade_mode-unlocker-1",
  icon = "__base__/graphics/technology/mining-productivity.png",
  effects = {{
    type = "nothing",
    effect_key = "technology-effect.arcade_mode-unlocker"
  }},
  unit = {
    count_formula = "10*L",
    ingredients = {
      {"science-pack-1", 1},
      {"science-pack-2", 1},
    },
    time = 20
  },
  upgrade = true,
  max_level = "infinite",
  order = "c-k-f-e"
}

data:extend{tool, recipe, technology}