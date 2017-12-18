
require "mod-gui"
local source_gui = {}

local gui = {}
gui.version = 1
gui.name = "arcade_mode-gui_source"

function source_gui.on_init()
  if global.source_gui ~= nil then return end
  global.source_gui = {}
  global.source_gui.version = gui.version

  global.source_gui.source = {}
end

function source_gui.on_source_main(source, player)
  local name = gui.name.."-main"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.source_gui.source[player.index] = nil
    return
  end

  local counter = global.counter[player.force.name]
  local signal = source.get_control_behavior().get_signal(1)

  --[[ GUI ]]

  local main = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"entity-name.arcade_mode-source"},
    direction = "vertical"
  }

  main.add {
    type = "label",
    name = name.."-counter",
    caption = {"gui-caption.arcade_mode-main-counter", counter},
    style = (counter <= 0 and "bold_red_label") or "caption_label"
  }

  local main_frame = main.add {
    type = "flow",
    name = name.."-flow",
    direction = "horizontal"
  }

  local camera = main_frame.add {
    type = "camera",
    name = name.."-camera",
    position = source.position
  }
  camera.style.width = 100
  camera.style.height = 100

  local settings = main_frame.add {
    type = "table",
    name = name.."-settings",
    column_count = 2,
    style = "slot_table"
  }
  settings.style.vertical_spacing = 5

  local target = settings.add {
    type = "choose-elem-button",
    name = name.."-target",
    caption = {"gui-caption.arcade_mode-main-target"},
    elem_type = "signal",
    style = "slot_button",
  }
  target.elem_value = signal.signal
  target.locked = true

  settings.add {
    type = "sprite-button",
    name = name.."-target-reset",
    sprite = "utility/reset",
    style = "slot_button",
  }

  local rate = settings.add {
    type = "choose-elem-button",
    name = name.."-rate",
    -- caption = {"arcade_mode-main-target"},
    elem_type = "signal",
    style = "slot_button",
  }
  rate.locked = true
  rate.elem_value = {
    type = "item",
    name = "transport-belt"
  }

  local rate_adjust = settings.add {
    type = "table",
    name = name.."-rate-adjust",
    column_count = 2,
  }
  rate_adjust.style.horizontal_spacing = 0

  rate_adjust.add {
    type = "button",
    name = name.."-rate-minus",
    caption = "-",
    style = mod_gui.button_style
  }
  rate_adjust.add {
    type = "button",
    name = name.."-rate-plus",
    caption = "+",
    style = mod_gui.button_style
  }

  player.opened = main
end

function source_gui.on_source_pick(source, player)
  local counter = global.counter[player.force.name]

  if counter < 0 then
    player.surface.create_entity {
      name = "flying-text",
      position = player.position,
      text = {"status.arcade_mode-no-charges"},
      color = {r=1, g=0.5, b=0.5}
    }
    return
  end

  local name = gui.name.."-pick"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.source_gui.source[player.index] = nil
    return
  end

  --[[ GUI ]]

  local pick = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"gui-caption.arcade_mode-pick"},
    direction = "vertical"
  }

  local resources = pick.add {
    type = "table",
    name = name.."-resources",
    column_count = 6,
    style = "slot_table"
  }

  for i, item in ipairs(global.items) do
    local a = resources.add {
      type = "sprite-button",
      name = "arcade_mode-gui_button-select-"..i,
      sprite = "item/"..item.name,
      style = "recipe_slot_button",
      tooltip = item.localised_name
    }
    a.style.vertical_align = "bottom"
  end
  for i, fluid in ipairs(global.fluids) do
    resources.add {
      type = "sprite-button",
      name = "arcade_mode-gui-select-"..(i + #global.items).."-button",
      sprite =  "fluid/"..fluid.name,
      style = "recipe_slot_button",
      tooltip = fluid.localised_name
    }
  end

  local define = pick.add {
    type = "button",
    name = name.."-define",
    caption = {"arcade_mode-pick-define"},
    style = "slot_with_filter_button"
  }
  define.style.horizontally_stretchable = true

  player.opened = pick
end

function source_gui.on_source_opened(source, player)
  if not (player and player.valid) then return end

  global.source_gui.source[player.index] = source
  local signal = source.get_control_behavior().get_signal(1)
  log(serpent.block(signal))

  if not signal or not signal.signal then
    source_gui.on_source_pick(source, player)
  else
    source_gui.on_source_main(source, player)
  end
end

function source_gui.on_gui_click(event)
  local element = event.element
  if not element.valid then return end
  if not element.name:match(gui.name) then return end

  local player = game.players[event.player_index]
  local source = global.source_gui.source[player.index]

  if not source or not source.valid then return end
end

function source_gui.on_gui_closed(event)
  local player = game.players[event.player_index]
  local element = event.element

  if not element then return end

  if element.name:match("arcade_mode%-gui_source") then
    element.destroy()
  end
end

return source_gui