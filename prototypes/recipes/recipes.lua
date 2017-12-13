local recipes = {}

function recipes.validate_resources(input)
  local validated = {}

  for _, name in pairs(input) do
    local type = (data.raw["item"][name] and "item") or (data.raw["fluid"][name] and "fluid") or nil

    if type then table.insert(validated, {name = name, type = type}) end
  end

  return validated
end

function recipes.add_resource(resource)
  local recipe = {
    type = "recipe",
    name = "arcade_mode-spawn-"..resource.name,
    category = "arcade_mode-spawn",
    enabled = true,
    energy_required = 0.5,
    ingredients = {},
    results = {{
      name = resource.name,
      type = resource.type,
    }},
    allow_decomposition = false,
    subgroup = "arcade_mode-spawn-"..resource.type
    -- requester_paste_multiplier = 10,
  }

  if resource.type == "item" then
    recipe.results[1].amount = data.raw[resource.type][resource.name].stack_size or 25
  elseif resource.type == "fluid" then
    recipe.results[1].amount = 3000
  end

  data:extend{recipe}
end

function recipes.add_resources(resources)
  for _, r in pairs(resources) do
    recipes.add_resource(r)
  end
end

return recipes
