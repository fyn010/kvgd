-- language: Lua, file: esp.lua
-- ESP: tracers + distância + team check. Toggle: Delete

getgenv().KVGD_esp = function(Core)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Camera = workspace.CurrentCamera
	local LP = Players.LocalPlayer
	local cfg = Core.config.esp
	local tracked = {}

	local function add(player)
		if player == LP or tracked[player] then return end
		local tracer = Drawing.new("Line")
		tracer.Thickness = cfg.tracer_thickness or 1
		tracer.Transparency = 1
		tracer.Visible = false

		local dist = Drawing.new("Text")
		dist.Size = 13
		dist.Center = true
		dist.Outline = true
		dist.OutlineColor = Color3.new(0, 0, 0)
		dist.Visible = false

		tracked[player] = { tracer = tracer, dist = dist }
	end

	local function remove(player)
		local t = tracked[player]
		if not t then return end
		pcall(function() t.tracer:Remove() end)
		pcall(function() t.dist:Remove() end)
		tracked[player] = nil
	end

	for _, p in ipairs(Players:GetPlayers()) do add(p) end
	Players.PlayerAdded:Connect(add)
	Players.PlayerRemoving:Connect(remove)

	Core.bind_toggle(cfg.keybind or "Delete", function() return cfg.enabled end, function(v) cfg.enabled = v end, "ESP")

	RunService.RenderStepped:Connect(function()
		local camPos = Camera.CFrame.Position
		local vp = Camera.ViewportSize
		local bottom = Vector2.new(vp.X / 2, vp.Y)

		for player, t in pairs(tracked) do
			if not cfg.enabled then
				t.tracer.Visible = false
				t.dist.Visible = false
			else
				local char, hum, hrp = Core.get_character(player)
				if not char then
					t.tracer.Visible = false
					t.dist.Visible = false
				else
					local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
					local distMag = (camPos - hrp.Position).Magnitude

					if onScreen and distMag <= (cfg.max_distance or 800) then
						local color = Core.is_teammate(player)
							and Color3.fromRGB(table.unpack(cfg.team_color))
							or Color3.fromRGB(table.unpack(cfg.enemy_color))

						t.tracer.From = bottom
						t.tracer.To = Vector2.new(pos.X, pos.Y)
						t.tracer.Color = color
						t.tracer.Visible = true

						if cfg.show_distance then
							t.dist.Text = string.format("%d", math.floor(distMag))
							t.dist.Position = Vector2.new(pos.X, pos.Y + 18)
							t.dist.Color = Color3.fromRGB(table.unpack(cfg.distance_color))
							t.dist.Visible = true
						else
							t.dist.Visible = false
						end
					else
						t.tracer.Visible = false
						t.dist.Visible = false
					end
				end
			end
		end
	end)

	getgenv().ESPColor = function(which, r, g, b)
		local key = which .. "_color"
		if cfg[key] then
			cfg[key] = {r, g, b}
			Core.save()
			print("[ESP] " .. key .. " = " .. r .. "," .. g .. "," .. b)
		end
	end

	print("[ESP] carregado — " .. (cfg.keybind or "Delete") .. " toggle")
end

print("[ESP] módulo definido")
