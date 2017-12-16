local recipes = {}
local vanilla = require "vanilla"

local function sortPrototype(lht, rht)
  if lht.order == rht.order then
    return lht.name < rht.name
  else return lht.order < rht.order end
end

function recipes.sortResources(t)
  table.sort(t, sortPrototype)
end

function recipes.formatResourceNames(items, fluids)
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

  recipes.sortResources(prototypes.items)
  recipes.sortResources(prototypes.fluids)

  return prototypes.items, prototypes.fluids
end

function recipes.getDefaultResources()
  return recipes.formatResourceNames(vanilla)
end

return recipes