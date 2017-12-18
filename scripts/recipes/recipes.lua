local recipes = {}
local vanilla = require "vanilla"

local function sort_prototype(lht, rht)
  if lht.order == rht.order then
    return lht.name < rht.name
  else return lht.order < rht.order end
end

function recipes.sort_resources(t)
  table.sort(t, sort_prototype)
end

function recipes.format_resource_names(items, fluids)
  fluids = fluids or items.fluids
  items = (items and items.items) or items or {}

  local prototypes = {items = {}, fluids = {}}
  for _, item in pairs(items) do
    if game.item_prototypes[item] then
      table.insert(prototypes.items, game.item_prototypes[item])
    elseif not fluids and game.fluid_prototypes[item] then
      table.insert(prototypes.fluids, game.fluid_prototypes[item])
    end
  end
  if fluids then
    for _, fluid in pairs(fluids) do if game.fluid_prototypes[fluid] then
      table.insert(prototypes.fluids, game.fluid_prototypes[fluid])
    end end
  end

  recipes.sort_resources(prototypes.items)
  recipes.sort_resources(prototypes.fluids)

  return prototypes.items, prototypes.fluids
end

function recipes.get_default_resources()
  return recipes.format_resource_names(vanilla)
end

function recipes.get_belt(level)
  if level == 1 then return "transport-belt" end
  if level == 2 then return "fast-transport-belt" end
  if level == 3 then return "express-transport-belt" end
end

return recipes