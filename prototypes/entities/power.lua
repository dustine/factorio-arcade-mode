local Prototype = require "scripts/prototype"

local pole = table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
pole.name = "arcade_mode-power-pole"
pole.flags = {"player-creation"}
pole.collision_mask = {}
pole.minable = nil
pole.selectable_in_game = false
pole.maximum_wire_distance = 2.5
pole.radius_visualisation_picture = Prototype.empty_sprite()
pole.pictures = Prototype.empty_sprite()
pole.pictures.direction_count = 1
pole.connection_points = {{
  shadow = {copper = util.by_pixel(-17, 0)},
  wire = {copper = util.by_pixel(-17, 0)}
}}

local source = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
source.name = "arcade_mode-power-source"
source.flags = {"player-creation"}
source.collision_box = {{-0.15, -0.15}, {0.15, 0.15}}
source.selection_box = {{-0.4, -0.4}, {0.4, 0.4}}
source.collision_mask = {}
source.minable = nil
source.selectable_in_game = false
source.enable_gui = false
source.picture = Prototype.empty_sprite()
source.working_sound = nil

data:extend{pole, source}