local targets = require "scripts/targets/targets"
-- local sources = require "scripts/sources"

local gui = {}

-- gui.version = 1
gui.name = "arcade_mode-gui_counter"
gui.name_pattern = "arcade_mode%-gui_counter"

--############################################################################--
--                                    GUI                                     --
--############################################################################--

local function update_gui_counter(player, doStatistics)
end

local function on_gui_counter(player)
  local counter = global.limits[player.force.name].counter

  local name = gui.name
  if player.gui.center[name] then
    player.gui.center[name].destroy()
    global.open_sources[player.index] = nil
    return
  end
end

--############################################################################--
--                                   EVENTS                                   --
--############################################################################--

function gui.on_init()
end

function gui.on_click(event)
end

return gui