local mod_gui =  require "mod-gui"

local get_charges = MOD.interfaces.get_charges
local get_limits = MOD.interfaces.get_limits

local gui = {}

-- gui.version = 1
gui.name = "arcade_mode-gui_counter"
gui.name_pattern = "arcade_mode%-gui_sources"

--############################################################################--
--                                    PICK                                    --
--############################################################################--

local function update_gui(player, charges, limit, button)
  button = button or mod_gui.get_button_flow(player)[gui.name.."_hud"]
  if not button then return end

  local force = player.force.name
  limit = limit or get_limits(force).charges
  charges = charges or get_charges(force)

  button.caption = {"gui-caption.arcade_mode-counter-hud", charges}
  button.tooltip = {"gui-caption.arcade_mode-counter-hud-tooltip", limit}

  button.style.visible = limit > 0
end

local function on_gui(player)
  local button_flow = mod_gui.get_button_flow(player)
  local button = button_flow[gui.name.."_hud"]
  if button then button.destroy() end
  button = button_flow.add{
    type = "button",
    name = gui.name.."_hud",
    style = mod_gui.button_style,
    caption = {"gui-caption.arcade_mode-counter-hud"},
    tooltip = {"gui-caption.arcade_mode-counter-hud-tooltip"}
  }
  button.style.left_padding = 5
  button.style.right_padding = 5

  update_gui(player, nil, nil, button)
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function gui.on_player_changed_force(event)
  if not event.force then return end

  for _, player in pairs(event.force.players) do
    update_gui(player)
  end
end

function gui.on_charges_changed(event)
  if not event.force then return end

  for _, player in pairs(event.force.players) do
    update_gui(player, event.amount)
  end
end

function gui.on_charge_limit_changed(event)
  if not event.force then return end

  for _, player in pairs(event.force.players) do
    update_gui(player, nil, event.amount)
  end
end

function gui.on_player_created(event)
  local player = game.players[event.player_index]
  if not (player and player.valid) then return end
  on_gui(player)
end

function gui.on_click(event)
  return event
end

function gui.on_init()
end

function gui.on_configuration_changed()
end

return gui