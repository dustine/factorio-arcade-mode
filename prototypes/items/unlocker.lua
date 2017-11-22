local tool = {
  -- This allows loading the selection-tool type item when mods are removed
  type = "selection-tool",
  name = "arcade_mode-unlocker",
  icon = "__base__/graphics/icons/blueprint.png",
  flags = {"goes-to-quickbar"},
  subgroup = "tool",
  order = "c[automated-construction]-a[blueprint]",
  stack_size = 1,
  stackable = false,
  selection_color = { r = 1, g = 1, b = 0 },
  alt_selection_color = { r = 1, g = 0, b = 0 },
  selection_mode = {"blueprint"},
  alt_selection_mode = {"deconstruct"},
  selection_cursor_box_type = "copy",
  alt_selection_cursor_box_type = "copy"
}

local recipe = {
  type = "recipe",
  name = "arcade_mode-unlocker",
  result = "arcade_mode-unlocker",
  enabled = true
}

data:extend{tool, recipe}