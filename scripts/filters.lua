local recipes = require("scripts/recipes/recipes")

local filters = {}

function filters.on_resources_changed()
  -- reset the resources up to recipe's autogen
  if not global.custom_resources then
    global.items, global.fluids = recipes.getDefaultResources()
    return
  end
end

function filters.on_init()
  global.filter = {}
  for _, p in pairs(game.players) do
    filters.on_player_init(p)
  end

  filters.on_resources_changed()
end

function filters.on_player_init(player)
end

function filters.get(player)
  local filter = global.filter[player.index]

  return filter, type
end

function filters.cycle(player, quantity)
  -- 1-indexiiiing *shakes fists*
  local filter = global.filter[player.index]

  filter.index = (filter.index + quantity - 1) % (#global.items + #global.fluids) + 1
  log((filter.index + quantity - 1) % (#global.items + #global.fluids) + 1)
  if filter.index > #global.items then
    filter.kind = "fluid/"..global.fluids[filter.index - #global.items].name
  else
    filter.kind = "item/"..global.items[filter.index].name
  end
end

return filters