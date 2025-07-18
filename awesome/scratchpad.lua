local awful = require("awful")

local scratchpad = {}

function scratchpad.toggle(cmd, geometry)
	local client_found = false

	-- Look for existing client with scratchpad in class name
	for _, c in ipairs(client.get()) do
		if c.class and c.class:lower():match("scratchpad") then
			client_found = true
			if c.hidden or not c:isvisible() then
				c.hidden = false
				c:raise()
				client.focus = c
			else
				c.hidden = true
			end
			break
		end
	end

	-- If no client found, spawn new one
	if not client_found then
		awful.spawn(cmd)

		-- Apply geometry after spawn if provided
		if geometry then
			local function apply_geometry(c)
				if c.class and c.class:lower():match("scratchpad") and not c.geometry_applied then
					c.geometry_applied = true
					local screen_geo = c.screen.workarea
					c:geometry({
						x = screen_geo.x + (screen_geo.width * geometry.x),
						y = screen_geo.y + (screen_geo.height * geometry.y),
						width = screen_geo.width * geometry.width,
						height = screen_geo.height * geometry.height,
					})
					client.disconnect_signal("manage", apply_geometry)
				end
			end
			client.connect_signal("manage", apply_geometry)
		end
	end
end

-- Helper functions
function scratchpad.terminal(geometry)
	geometry = geometry or { width = 0.6, height = 0.6, x = 0.2, y = 0.2 }
	scratchpad.toggle("alacritty --class=terminal-scratchpad", geometry)
end

function scratchpad.calculator(geometry)
	geometry = geometry or { width = 0.3, height = 0.4, x = 0.35, y = 0.3 }
	scratchpad.toggle("gnome-calculator", geometry)
end

function scratchpad.filemanager(geometry)
	geometry = geometry or { width = 0.7, height = 0.7, x = 0.15, y = 0.15 }
	scratchpad.toggle("thunar", geometry)
end

return scratchpad
