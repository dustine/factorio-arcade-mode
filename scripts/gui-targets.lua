local resources = require "scripts/resources/resources"

local gui = {}

gui.version = 1
gui.name = "arcade_mode-gui_targets"
gui.name_pattern = "arcade_mode%-gui_targets"

-- TODO: refactor this to common as both gui files use this
local function make_smart_slot(parent, name, signal, style)
  local rate = parent.add {
    type = "choose-elem-button",
    name = name,
    elem_type = "signal",
    style = style or "slot_button",
  }
  -- rate.locked = true
  rate.elem_value = signal
end

local function update_gui_define(player)
  local info = global.temp_targets[player.index]
  local name = gui.name.."-define"

  player.gui.center[name][name.."-options"][name.."-reset"].enabled = not info.reset
end

local function reset_gui_define(player)
  global.temp_targets[player.index] = {}
  local info = global.temp_targets[player.index]
  info.resources = {}
  info.reset = true

  for _, item in pairs(global.items) do
    table.insert(info.resources, {name = item.name, type="item"})
  end
  for _, fluid in pairs(global.fluids) do
    table.insert(info.resources, {name = fluid.name, type="fluid"})
  end

  local name = gui.name.."-define"
  local resources_table = player.gui.center[name][name.."-resources"]
  resources_table.clear()

  for i, resource in ipairs(info.resources) do
    make_smart_slot(resources_table, name.."-filter-"..i, resource)
  end
  make_smart_slot(resources_table, name.."-filter-"..(#info.resources+1))

  update_gui_define(player)
end

local function on_gui_define(player)
  if not(player.valid and player.admin) then return end

  local name = gui.name.."-define"
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.sources.open[player.index] = nil
    return
  end


  local define = player.gui.center.add {
    type = "frame",
    name = name,
    caption = {"gui-caption.arcade_mode-define"},
    direction = "vertical"
  }

  define.add {
    type = "table",
    name = name.."-resources",
    column_count = 6,
    style = "slot_table"
  }

  local options = define.add {
    type = "table",
    name = name.."-options",
    column_count = 2
  }
  options.style.align = "right"
  options.style.horizontally_stretchable = true

  options.add {
    type = "sprite-button",
    name = name.."-reset",
    tooltip = {"gui-caption.arcade_mode-define-reset"},
    sprite = "utility/reset",
    style = "not_available_slot_button"
  }

  local save = options.add {
    type = "button",
    name = name.."-save",
    caption = {"gui-caption.arcade_mode-define-save"},
    style = "slot_with_filter_button"
  }
  save.style.minimal_width = 32*5 + 2*5 - 5
  save.style.horizontally_stretchable = true
  save.style.horizontally_squashable = true

  reset_gui_define(player)
  player.opened = define
end

function gui.on_click(event)
  local player = game.players[event.player_index]
  if not(player and player.valid) then return end

  local element = event.element
  if not(element.valid) then return end
  if element.name == "arcade_mode-gui_sources-pick-define" then
    -- gui-sources opens this gui remotely
    -- TODO: find a better way. event?
    on_gui_define(player)
    return
  end
  if not element.name:match(gui.name_pattern) then return end

  if element.name:match("%-define%-reset$") then
    reset_gui_define(player)
  elseif element.name:match("%-define%-save$") then
    local info = global.temp_targets[player.index]
    if info.reset then resources.reset_admin_targets()
    else resources.set_admin_targets(info.resources) end
  end
end

function gui.on_elem_changed(event)
  local player = game.players[event.player_index]
  if not(player and player.valid) then return end

  local element = event.element
  if not element.valid then return end
  local index = tonumber(element.name:match(gui.name_pattern.."%-define%-filter%-(%d+)$"))
  if not index then return end

  local info = global.temp_targets[player.index]
  if not element.elem_value then
    -- cleared a slot
    local elem = element
    for i = index, #info.resources do
      local new_elem = element.parent[gui.name.."-define-filter-"..(i+1)]
      elem.elem_value = new_elem.elem_value
      elem = new_elem
    end

    table.remove(info.resources, index)
    elem.destroy()
    info.reset = false
  else
    -- set a slot
    if element.elem_value.type ~= "item" and element.elem_value.type ~= "fluid" then
      -- invalid signal, revert to previous value
      element.elem_value = info.resources[index]
    else
      info.resources[index] = element.elem_value
      if index >= #info.resources then
        -- last slot, add an extra one
        make_smart_slot(element.parent, gui.name.."-define-filter-"..(#info.resources+1))
      end
      info.reset = false
    end
  end

  log(serpent.line(info))
  update_gui_define(player)
end

function gui.on_closed(event)
  local element = event.element
  if not (element and element.valid and element.name:match(gui.name_pattern)) then return end
  element.destroy()
end

---------------------------------------------------

function gui.on_init()
  global.temp_targets = {}
end

function gui.on_configuration_changed()
end

return gui