local Prototype = {}

--Quick to use empty sprite
function Prototype.empty_sprite()
  return {
    filename = "__core__/graphics/empty.png",
    priority = "extra-high",
    width = 1,
    height = 1
  }
end

--Quick to use empty animation
function Prototype.empty_animation()
  return {
    filename = Prototype.empty_sprite().filename,
    width = Prototype.empty_sprite().width,
    height = Prototype.empty_sprite().height,
    line_length = 1,
    frame_count = 1,
    shift = {0, 0},
    animation_speed = 1,
    direction_count = 1
  }
end

function Prototype.empty_sheet()
  return {
    north = Prototype.empty_sprite(),
    east = Prototype.empty_sprite(),
    south = Prototype.empty_sprite(),
    west = Prototype.empty_sprite(),
  }
end

-- render layers
----"tile-transition", "resource", "decorative", "remnants", "floor", "transport-belt-endings", "corpse", "floor-mechanics", "item", "lower-object", "object", "higher-object-above",
----"higher-object-under", "wires", "lower-radius-visualization", "radius-visualization", "entity-info-icon", "explosion", "projectile", "smoke", "air-object", "air-entity-info-con",
----"light-effect", "selection-box", "arrow", "cursor"

-- collision masks
----"ground-tile", "water-tile", "resource-layer", "floor-layer", "item-layer", "object-layer", "player-layer", "ghost-layer", "doodad-layer", "not-colliding-with-itself"

return Prototype