local resources = require "scripts/resources/resources"

local gui = {}

gui.version = 1
gui.name = "arcade_mode-gui_resources"
gui.name_pattern = "arcade_mode%-gui_resources"

local function on_gui_define(player)
  if not(player.valid and player.admin) then return end

  local name = gui.name.."-define"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.sources.open[player.index] = nil
    return
  end

  local pick = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"gui-caption.arcade_mode-pick"},
    direction = "vertical"
  }

  local resources_table = pick.add {
    type = "table",
    name = name.."-resources",
    column_count = 6,
    style = "slot_table"
  }

  for _, item in pairs(global.items) do
    make_smart_slot(resources_table, name.."-select-item/"..item.name, {name = item.name, type="item"}, "recipe_slot_button")
  end
  for i, fluid in pairs(global.fluids) do
    make_smart_slot(resources_table, name.."-select-fluid/"..fluid.name, {name = fluid.name, type="fluid"}, "recipe_slot_button")
  end

  local define = pick.add {
    type = "button",
    name = name.."-define",
    caption = {"gui-caption.arcade_mode-pick-define"},
    style = "slot_with_filter_button"
  }
  define.style.minimal_width = 32*6+2*5
  define.style.horizontally_stretchable = true
  define.style.horizontally_squashable = true

  player.opened = pick

end



function gui.on_click(event)
  local player = game.players[event.player_index]
  if not player or player.valid then return end

  local element = event.element
  if not(element.valid) then return end
  if element.name == "arcade_mode-gui_sources-pick-define" then
    -- gui-sources opens this gui remotely
    -- TODO: find a better way. event?
    on_gui_define(player)
    return
  end
  if not element.name:match(gui.name_pattern) then return end

  local entity = global.sources.open[player.index]
  if not(entity and entity.valid) then
    player.opened.destroy()
    return
  end
  local source = sources.get(entity)
end

function gui.on_closed(event)
  local element = event.element
  if not element or not element.name:match(gui.name_pattern) then return end
  element.destroy()
end

---------------------------------------------------

function gui.on_init()
  global.temp_resources = {}
end

function gui.on_configuration_changed()
end

return gui