MOD = MOD or {}
MOD.ArcadeMode = MOD.ArcadeMode or {}

require "prototypes.entities.source"
require "prototypes.items.unlocker"
-- require "prototypes.recipes.override"
-- require "prototypes.tiles.salt"

local button_next = {
  type = "custom-input",
  name = "arcade_mode-next-resource",
  key_sequence = "O",
  consuming = "none"
}

local button_previous = {
  type = "custom-input",
  name = "arcade_mode-previous-resource",
  key_sequence = "SHIFT + O",
  consuming = "none"
}

data:extend{button_next, button_previous}