data:extend {{
  type = "recipe-category",
  name = "arcade_mode-spawn"
},{
  type = "item-group",
  name = "arcade_mode-spawn",
  icon = "__ArcadeMode__/graphics/entities/spawner/base.png",
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

local resources = {"iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "raw-wood", "crude-oil", "water"}

for _, r in pairs(resources) do
  local type = (data.raw["item"][r] and "item") or (data.raw["fluid"][r] and "fluid") or nil
  local resource = {
    type = "recipe",
    name = "arcade_mode-spawn-"..r,
    category = "arcade_mode-spawn",
    enabled = true,
    energy_required = 1,
    ingredients = {},
    allow_decomposition = false,
    -- requester_paste_multiplier = 10,
  }

  if type == "item" then
    resource.results = {{
      name = r,
      type = type,
      amount = 25
    }}
    -- resource.localized_name = {""}
    resource.subgroup = "arcade_mode-spawn-item"
  elseif type == "fluid" then
    resource.results = {{
      name = r,
      type = type,
      amount = 3000
    }}
    resource.subgroup = "arcade_mode-spawn-fluid"
  end

  if type then data:extend{resource} end
end