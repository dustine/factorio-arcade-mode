-- TODO: find the fastest belt, make it its loader

local recipes = require "prototypes.recipes.recipes"
local vanilla = require "prototypes.recipes.vanilla"

if not MOD.ArcadeMode.override then
  recipes.add_resources(vanilla)
end