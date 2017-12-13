require("mod-gui")

local gui = {}
gui.version = 1

function gui.init()
  if global.gui ~= nil then return end
  global.gui = {}
  global.gui.version = gui.version

end

function gui.gui_init(player)
  local button_flow = mod_gui.get_button_flow(player)
  local button = button_flow["arcade_mode-gui-toggle-button"]
  if not button then
    button = button_flow.add {
      type = "sprite-button",
      name = "arcade_mode-gui-toggle-button",
      sprite = "item-group/other",
      style = mod_gui.button_style,
      tooltip = {"gui-caption.arcade_mode-toggle-button"}
    }
    button.style.visible = true
  end

  local frame_flow = mod_gui.get_frame_flow(player)
  local frame = frame_flow["arcade_mode-gui-frame"]
  if not frame then
    frame = frame_flow.add {
      type = "frame",
      name = "arcade_mode-gui-frame",
      direction = "vertical",
      caption = {"gui-caption.arcade_mode-frame"},
      style = mod_gui.frame_style
    }
    frame.style.visible = false

    local resource_table = frame.add {
      type = "table",
      name = "arcade_mode-gui-resource-table",
      colspan = 1
    }

    resource_table.add {
      type = "table",
      name = "arcade_mode-gui-item-resource-table",
      colspan = 6
    }
    -- resource_table.add {
    --   type = "label",
    --   name = "arcade_mode-gui-resources-fluids-label",
    --   caption = {"gui-caption.arcade_mode-gui-fluids-label"},
    --   style = "caption_label_style"
    -- }
    resource_table.add {
      type = "table",
      name = "arcade_mode-gui-fluid-resource-table",
      colspan = 6
    }
  end

  local resource_table = frame["arcade_mode-gui-resource-table"]
  local item_table = resource_table["arcade_mode-gui-item-resource-table"]
  local fluid_table = resource_table["arcade_mode-gui-fluid-resource-table"]
  item_table.clear()
  fluid_table.clear()

  for i, recipe in ipairs(global.items) do
    local result = recipe.products[1].name
    item_table.add {
      type = "sprite-button",
      name = "arcade_mode-gui-select-"..i.."-button",
      sprite =  "item/"..result,
      style = mod_gui.button_style,
      tooltip = recipe.localised_name
    }
  end
  for i, recipe in ipairs(global.fluids) do
    local result = recipe.products[1].name
    fluid_table.add {
      type = "sprite-button",
      name = "arcade_mode-gui-select-"..(i + #global.items).."-button",
      sprite =  "fluid/"..result,
      style = mod_gui.button_style,
      tooltip = recipe.localised_name
    }
  end

  gui.gui_update(player)
end

function gui.gui_update(player)
  local button_flow = mod_gui.get_button_flow(player)
  local button = button_flow["arcade_mode-gui-toggle-button"]

  local index = global.filter[player.index]
  if not index or index > #global.items + #global.fluids then
    global.filter[player.index] = 1
    index = global.filter[player.index]
  end

  if not index then
    button.sprite = "item-group/other"
    button.tooltip = {"gui-caption.arcade_mode-toggle-button"}
  else
    local recipe = global.items[index] or global.fluids[index - #global.items]
    button.sprite = recipe.products[1].type.."/"..recipe.products[1].name
    button.tooltip = {"gui-caption.arcade_mode-toggle-button-filtered", recipe.localised_name}
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