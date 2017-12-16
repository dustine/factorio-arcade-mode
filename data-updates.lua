-- TODO: find the fastest belt, make it its loader

-- local recipes = require "prototypes.recipes.recipes"
-- local vanilla = require "prototypes.recipes.vanilla"

-- if not MOD.ArcadeMode.override then
--   recipes.add_resources(vanilla)
-- end

for _, f in pairs(data.raw.fluid) do
  MOD.ArcadeMode.generate_fluid_source(f)
end