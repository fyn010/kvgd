-- language: Lua, file: silent_aim.lua
-- Knife VS Gun DUELS: silent aim teleguiado (redirect do tiro).
-- Não depende de FOV nem de onde a câmera aponta. Toggle: End

getgenv().KVGD_silent_aim = function(Core)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Camera = workspace.CurrentCamera
	local LP = Players.LocalPlayer
	local cfg = Core.config.silent

	cfg.fov = cfg.fov or 9999 -- irrelevante pro teleguiado, só pro círculo opcional
	cfg.show_fov = cfg.show_fov == true -- default false

	local fovCircle = Drawing.new("Circle")
	fovCircle.Thickness = 1
	fovCircle.NumSides = 64
	fovCircle.Transparency = 0.4
	fovCircle.Filled = false
	fovCircle.Visible = false

	local function get_duel_opponent()
		local myDuel = LP:GetAttribute("CurrentDuel")
		if not myDuel then return nil end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p:GetAttribute("CurrentDuel") == myDuel then
				local char = p.Character
				if char then
					local part = char:FindFirstChild(cfg.hit_part or "Head") or char:FindFirstChild("Head")
					local hum = char:FindFirstChildOfClass("Humanoid")
					if part and hum and hum.Health > 0 then
						return part, p
					end
				end
			end
		end
		return nil
	end

	local function get_closest_enemy()
		local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not me then return nil end
		local best, bestD, bestP = nil, math.huge, nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and not (cfg.team_check and Core.is_teammate(p)) then
				local char = p.Character
				if char then
					local part = char:FindFirstChild(cfg.hit_part or "Head") or char:FindFirstChild("Head")
					local hum = char:FindFirstChildOfClass("Humanoid")
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if part and hum and hum.Health > 0 and hrp then
						local d = (hrp.Position - me.Position).Magnitude
						if d < bestD then
							best, bestD, bestP = part, d, p
						end
					end
				end
			end
		end
		return best, bestP
	end

	local function get_target()
		local part, player = get_duel_opponent()
		if part then return part, player end
		return get_closest_enemy()
	end

	-- redirect de args de tiro pro alvo
	local function redirect_args(args)
		local part = get_target()
		if not part then return args end

		local origin
		local char = LP.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local head = char:FindFirstChild("Head")
			origin = (head and head.Position) or (hrp and hrp.Position)
		end
		if not origin then
			origin = Camera.CFrame.Position
		end

		local aim = part.Position
		local dir = (aim - origin).Unit

		-- reescreve qualquer Vector3 que pareça direção/origem/ponto
		local newArgs = {}
		for i, v in ipairs(args) do
			if typeof(v) == "Vector3" then
				-- se parece direção (magnitude ~1) → troca pela dir pro alvo
				if math.abs(v.Magnitude - 1) < 0.15 then
					newArgs[i] = dir
				-- se parece origem (perto do player) → mantém ou força origin
				elseif origin and (v - origin).Magnitude < 15 then
					newArgs[i] = origin
				else
					-- ponto de impacto / alvo → força no hit part
					newArgs[i] = aim
				end
			else
				newArgs[i] = v
			end
		end

		-- se não tinha nenhum Vector3, injeta dir
		local hadVec = false
		for _, v in ipairs(newArgs) do
			if typeof(v) == "Vector3" then hadVec = true break end
		end
		if not hadVec then
			table.insert(newArgs, 1, dir)
		end

		return newArgs
	end

	-- hook __namecall em FireServer / InvokeServer
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		if not cfg.enabled then
			return oldNamecall(self, ...)
		end

		if typeof(self) == "Instance"
			and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
			and (method == "FireServer" or method == "InvokeServer") then
			local name = string.lower(self.Name)
			if string.find(name, "shoot")
				or string.find(name, "fire")
				or string.find(name, "gun")
				or string.find(name, "knife")
				or string.find(name, "stab")
				or string.find(name, "throw")
				or string.find(name, "hit")
				or string.find(name, "attack")
				or string.find(name, "bullet")
				or string.find(name, "projectile")
				or string.find(name, "replicate") then
				local args = { ... }
				local newArgs = redirect_args(args)
				return oldNamecall(self, table.unpack(newArgs))
			end
		end

		return oldNamecall(self, ...)
	end))

	-- também cobre o caso de :FireServer chamado via índice (sem namecall)
	local function hook_remote(remote)
		if not remote or remote:GetAttribute("KVGD_Hooked") then return end
		remote:SetAttribute("KVGD_Hooked", true)

		if remote:IsA("RemoteEvent") then
			local old
			old = hookfunction(remote.FireServer, newcclosure(function(self, ...)
				if not cfg.enabled then return old(self, ...) end
				local args = { ... }
				local newArgs = redirect_args(args)
				return old(self, table.unpack(newArgs))
			end))
		elseif remote:IsA("RemoteFunction") then
			local old
			old = hookfunction(remote.InvokeServer, newcclosure(function(self, ...)
				if not cfg.enabled then return old(self, ...) end
				local args = { ... }
				local newArgs = redirect_args(args)
				return old(self, table.unpack(newArgs))
			end))
		end
	end

	local function scan_remotes()
		for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				local n = string.lower(obj.Name)
				if string.find(n, "shoot") or string.find(n, "fire") or string.find(n, "gun")
					or string.find(n, "knife") or string.find(n, "stab") or string.find(n, "throw")
					or string.find(n, "hit") or string.find(n, "attack") or string.find(n, "bullet")
					or string.find(n, "projectile") or string.find(n, "replicate") then
					pcall(hook_remote, obj)
				end
			end
		end
	end

	scan_remotes()
	ReplicatedStorage.DescendantAdded:Connect(function(obj)
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			task.defer(function() pcall(hook_remote, obj) end)
		end
	end)

	Core.bind_toggle(cfg.keybind or "End", function() return cfg.enabled end, function(v) cfg.enabled = v end, "AIM")

	RunService.RenderStepped:Connect(function()
		if not cfg.show_fov then
			fovCircle.Visible = false
			return
		end
		local vp = Camera.ViewportSize
		fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
		fovCircle.Radius = 80
		fovCircle.Visible = cfg.enabled
		local t = get_target()
		fovCircle.Color = t and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(200, 200, 200)
	end)

	getgenv().AimPart = function(v)
		cfg.hit_part = tostring(v)
		Core.save()
		print("[AIM] hit = " .. cfg.hit_part)
	end

	getgenv().AimShowFOV = function(v)
		cfg.show_fov = v and true or false
		Core.save()
	end

	print("[AIM] teleguiado ativo — " .. (cfg.keybind or "End") .. " toggle | independente de FOV/câmera")
end

print("[AIM] módulo definido")
