local salt = table.deepcopy(data.raw.tile.dirt)
salt.name = "arcade_mode-salt"
salt.autoplace = water_autoplace_settings(0)
salt.layer = 50
salt.variants.main[1].picture = "__ArcadeMode__/graphics/tiles/salt/salt1.png"
salt.variants.main[2].picture = "__ArcadeMode__/graphics/tiles/salt/salt2.png"
salt.variants.main[3].picture = "__ArcadeMode__/graphics/tiles/salt/salt4.png"
salt.variants.inner_corner.picture = "__ArcadeMode__/graphics/tiles/salt/salt-inner-corner.png"
salt.variants.outer_corner.picture = "__ArcadeMode__/graphics/tiles/salt/salt-outer-corner.png"
salt.variants.side.picture = "__ArcadeMode__/graphics/tiles/salt/salt-side.png"
salt.map_color={r=0.8, g=0.8, b=0.5}

local deep_salt = table.deepcopy(data.raw.tile["dirt-dark"])
deep_salt.name = "arcade_mode-deep-salt"
deep_salt.autoplace = water_autoplace_settings(250)
deep_salt.layer = 55
deep_salt.variants.main[1].picture = "__ArcadeMode__/graphics/tiles/deep-salt/deep-salt1.png"
deep_salt.variants.main[2].picture = "__ArcadeMode__/graphics/tiles/deep-salt/deep-salt2.png"
deep_salt.variants.main[3].picture = "__ArcadeMode__/graphics/tiles/deep-salt/deep-salt4.png"
deep_salt.variants.inner_corner.picture = "__ArcadeMode__/graphics/tiles/deep-salt/deep-salt-inner-corner.png"
deep_salt.variants.outer_corner.picture = "__ArcadeMode__/graphics/tiles/deep-salt/deep-salt-outer-corner.png"
deep_salt.variants.side.picture = "__ArcadeMode__/graphics/tiles/deep-salt/deep-salt-side.png"
deep_salt.map_color={r=1, g=1, b=0.8}

data:extend{salt, deep_salt}