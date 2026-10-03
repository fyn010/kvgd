-- language: Lua, file: silent_aim.lua
-- silent aim via mouse move (stealth) + restore. Toggle: End

getgenv().KVGD_silent_aim = function(Core)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Camera = workspace.CurrentCamera
	local LP = Players.LocalPlayer
	local cfg = Core.config.silent

	local fovCircle = Drawing.new("Circle")
	fovCircle.Thickness = 1
	fovCircle.NumSides = 64
	fovCircle.Transparency = 0.45
	fovCircle.Filled = false
	fovCircle.Visible = false

	local cachedTarget = nil
	local lastCache = 0

	local function get_target()
		local now = tick()
		if now - lastCache < 0.016 and cachedTarget and cachedTarget.Parent then
			return cachedTarget
		end
		lastCache = now

		local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		local best, bestD = nil, cfg.fov or 200

		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and not (cfg.team_check and Core.is_teammate(p)) then
				local char = p.Character
				if char then
					local part = char:FindFirstChild(cfg.hit_part or "Head") or char:FindFirstChild("Head")
					local hum = char:FindFirstChildOfClass("Humanoid")
					if part and hum and hum.Health > 0 then
						local sp, on = Camera:WorldToViewportPoint(part.Position)
						if on then
							local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
							if d < bestD then
								best, bestD = part, d
							end
						end
					end
				end
			end
		end

		cachedTarget = best
		return best
	end

	local function aim_mouse(target)
		if not target or not target.Parent then return end
		local sp, on = Camera:WorldToViewportPoint(target.Position)
		if not on then return end

		local mouse = UserInputService:GetMouseLocation()
		local dx = sp.X - mouse.X
		local dy = sp.Y - mouse.Y
		local smooth = 0.85

		if mousemoverel then
			mousemoverel(dx * smooth, dy * smooth)
		elseif mousemoveabs then
			mousemoveabs(mouse.X + dx * smooth, mouse.Y + dy * smooth)
		end
	end

	Core.bind_toggle(cfg.keybind or "End", function() return cfg.enabled end, function(v) cfg.enabled = v end, "AIM")

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not cfg.enabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.ButtonR2 then
			local t = get_target()
			if t then aim_mouse(t) end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local t = get_target()
		local vp = Camera.ViewportSize
		fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
		fovCircle.Radius = cfg.fov or 200
		fovCircle.Visible = cfg.enabled
		fovCircle.Color = t and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
	end)

	getgenv().AimFOV = function(v)
		cfg.fov = tonumber(v) or cfg.fov
		Core.save()
		print("[AIM] FOV = " .. cfg.fov)
	end

	getgenv().AimPart = function(v)
		cfg.hit_part = tostring(v)
		Core.save()
		print("[AIM] hit = " .. cfg.hit_part)
	end

	print("[AIM] carregado — " .. (cfg.keybind or "End") .. " toggle | mouse silent")
end

print("[AIM] módulo definido")
