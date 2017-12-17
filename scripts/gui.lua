require("mod-gui")

local gui = {}
gui.version = 1

function gui.on_init()
  if global.gui ~= nil then return end
  global.gui = {}
  global.gui.version = gui.version

  for _, player in pairs(game.players) do
    gui.gui_init(player)
  end
end

function gui.on_configuration_changed()
  -- reset gui
  for _, player in pairs(game.players) do
    gui.gui_init(player)
  end
end

function gui.gui_init(player)
  if not (player and player.valid) then return end

  local button_flow = mod_gui.get_button_flow(player)

  local best_button = button_flow["arcade_mode-gui-best-button"]
  if not best_button then
    best_button = button_flow.add {
      type = "button",
      elem_type = "item",
      name = "arcade_mode-gui-best-button",
      caption = "1",
      sprite = "item-group/other",
      style = mod_gui.button_style,
    }
    best_button.style.visible = true
  end

  local button = button_flow["arcade_mode-gui_button-toggle"]
  if not button then
    button = button_flow.add {
      type = "sprite-button",
      name = "arcade_mode-gui_button-toggle",
      sprite = "item-group/other",
      style = mod_gui.button_style,
      tooltip = {"gui-caption.arcade_mode-toggle"}
    }
    button.style.visible = true
  end

  local frame_flow = mod_gui.get_frame_flow(player)
  local frame = frame_flow["arcade_mode-gui-frame"]
  if not frame then
    frame = frame_flow.add {
      type = "frame",
      name = "arcade_mode-gui_frame",
      direction = "vertical",
      caption = {"gui-caption.arcade_mode-frame"},
      style = mod_gui.frame_style
    }
    frame.style.visible = false
    frame.add {
      type = "table",
      name = "arcade_mode-gui_table-resources",
      column_count = 6,
      style = "slot_table"
    }
    frame.add {
      type = "label",
      name = "arcade_mode-gui_label-modes",
      caption = {"gui-caption.arcade_mode-modes"},
      style = "caption_label"
    }

    local modes = frame.add {
      type = "flow",
      name = "arcade_mode-gui_table-modes",
      caption = {"gui-caption.arcade_mode-modes-2"},
      -- style = "caption_label"
      direction = "horizontal"
    }

    modes.add {
      type = "button",
      name = "arcade_mode-gui_button-upgrade-toggle",
      caption = {"gui-caption.arcade_mode-upgrade-toggle"},
    }
    modes.add {
      type = "sprite-button",
      name = "arcade_mode-gui_button-unlocker",
      caption = {"gui-caption.arcade_mode-unlocker"},
      sprite = {"item/arcade_mode-unlocker"}
    }
    modes.add {
      type = "button",
      name = "arcade_mode-gui_button-options",
      caption = {"gui-caption.arcade_mode-options"},
    }
  end

  local resource_table = frame["arcade_mode-gui_table-resources"]
  resource_table.clear()

  for i, item in ipairs(global.items) do
    local a = resource_table.add {
      type = "sprite-button",
      name = "arcade_mode-gui_button-select-"..i,
      sprite = "item/"..item.name,
      style = mod_gui.button_style,
      tooltip = item.localised_name
    }
    a.style.vertical_align = "bottom"
  end
  for i, fluid in ipairs(global.fluids) do
    resource_table.add {
      type = "sprite-button",
      name = "arcade_mode-gui-select-"..(i + #global.items).."-button",
      sprite =  "fluid/"..fluid.name,
      style = mod_gui.button_style,
      tooltip = fluid.localised_name
    }
  end

  gui.gui_update(player)
end

function gui.on_player_created(event)
  gui.gui_init(game.players[event.player_index])
end

function gui.gui_update(player)
  local button_flow = mod_gui.get_button_flow(player)
  local button = button_flow["arcade_mode-gui-toggle-button"]

  if not button then return end

  local filter = global.filter[player.index]
  local index = filter.index
  -- if not index or index > #global.items + #global.fluids then
  --   global.filter[player.index].index = 1
  --   index = global.filter[player.index]
  -- end

  if not index or index > #global.items + #global.fluids then
    button.sprite = "item-group/other"
    button.tooltip = {"gui-caption.arcade_mode-toggle-button"}
  else
    local resource, type
    if index > #global.items then
      type = "fluid"
      resource = global.fluids[index - #global.items]
    else
      type = "item"
      resource = global.items[index]
    end
    button.sprite = type.."/"..resource.name
    button.tooltip = {"gui-caption.arcade_mode-toggle-button-filtered", resource.localised_name}
  end
end

function gui.on_gui_click(event)
  local element = event.element
  local player = game.players[event.player_index]
  if not element.valid then return end

  if element.name:match("^arcade_mode%-gui") then
    local frame_flow = mod_gui.get_frame_flow(player)
    local frame = frame_flow["arcade_mode-gui-frame"]

    if element.name == "arcade_mode-gui-toggle-button" then
      frame.style.visible = not frame.style.visible
      return
    end

    if element.name:match("gui%-select") then
      local index = tonumber(element.name:match("gui%-select%-(%d*)"))
      global.filter[player.index] = index
      gui.gui_update(player)
    end
  end
end

return gui