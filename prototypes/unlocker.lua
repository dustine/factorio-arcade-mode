local tool = {
  -- This allows loading the selection-tool type item when mods are removed
  type = "selection-tool",
  name = "arcade_mode-unlocker",
  icon = "__ArcadeMode__/graphics/unlocker/item.png",
  icon_size = 32,
  flags = {"goes-to-quickbar"},
  subgroup = "tool",
  order = "c[automated-construction]-z-[ArcadeMode]",
  stack_size = 1,
  stackable = false,
  selection_color = { r = 1, g = 1, b = 0 },
  alt_selection_color = { r = 1, g = 0, b = 0 },
  selection_mode = {"buildable-type", "matches-force"},
  alt_selection_mode = {"buildable-type", "matches-force"},
  selection_cursor_box_type = "copy",
  alt_selection_cursor_box_type = "not-allowed"
}

local recipe = {
  type = "recipe",
  name = "arcade_mode-unlocker",
  result = "arcade_mode-unlocker",
  enabled = true,
  ingredients = {}
}

data:extend{tool, recipe}

--[[ TECH ]]

local unlock_template = {
  type = "technology",
  name = "arcade_mode-unlocker-unlock-",
  icon = "__ArcadeMode__/graphics/unlocker/unlock.png",
  icon_size = 128,
  effects = {{
    type = "nothing",
    effect_description = "technology-effect.arcade_mode-unlocker-unlock"
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
    unlock.prerequisites = {"arcade_mode-unlocker-unlock-"..last_unlock}
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
  name = "arcade_mode-unlocker-upgrade-1",
  icon = "__ArcadeMode__/graphics/unlocker/upgrade-1.png",
  icon_size = 128,
  unit = {
    count_formula = "240",
    ingredients = {
      {"science-pack-1", 1},
      {"science-pack-2", 1},
    },
    time = 60
  },
  prerequisites = {"arcade_mode-unlocker-unlock-2", "logistics-2"},
  effects = {{
    type = "nothing",
    effect_description = "technology-effect.arcade_mode-unlocker-upgrade"
  },{
    type = "nothing",
    effect_description = "technology-effect.arcade_mode-unlocker-upgrade-1"
  }},
}}

make_unlock({"science-pack-1", "science-pack-2", "science-pack-3"}, "20*L", 49)
make_unlock({"science-pack-1", "science-pack-2", "science-pack-3", "production-science-pack"}, "10*L", 99)

data:extend {{
  type = "technology",
  name = "arcade_mode-unlocker-upgrade-2",
  icon = "__ArcadeMode__/graphics/unlocker/upgrade-2.png",
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
  prerequisites = {"arcade_mode-unlocker-unlock-50", "arcade_mode-unlocker-upgrade-1", "logistics-3"},
  effects = {{
    type = "nothing",
    effect_description = "technology-effect.arcade_mode-unlocker-upgrade-2"
  }},
  upgrade = true
}}

make_unlock({"science-pack-1", "science-pack-2", "science-pack-3", "production-science-pack", "high-tech-science-pack"}, "5*L", 249)
make_unlock({"science-pack-1", "science-pack-2", "science-pack-3", "production-science-pack", "high-tech-science-pack", "space-science-pack"}, "2*L", "infinite")

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