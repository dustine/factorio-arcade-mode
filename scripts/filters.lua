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

return filters