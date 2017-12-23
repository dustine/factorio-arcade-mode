local edge = table.deepcopy(data.raw.tile["hazard-concrete-right"])
edge.name = "arcade_mode-edge"
edge.collision_mask = table.deepcopy(data.raw.tile["out-of-map"].collision_mask)
edge.minable = nil
-- edge.layer = 2

data:extend{edge}