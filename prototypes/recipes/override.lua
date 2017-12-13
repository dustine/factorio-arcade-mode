local recipes = require "recipes"
require 'stdlib/utils/string'

local override = recipes.validate_resources(string.split(settings.startup["arcade_mode-resources-override"].value, " "))
if #override > 0 then
  MOD.ArcadeMode.override = true
  log("Resources manually overriden.")
  recipes.add_resources(override)
end