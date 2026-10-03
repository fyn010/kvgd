-- language: Lua, file: kill_aura.lua
-- kill aura: prioriza duelo, senão proximidade. Toggle: K

getgenv().KVGD_kill_aura = function(Core)
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local cfg = Core.config.aura

	local lastAttack = 0
	local CANDIDATES = { "ShootGun", "KnifeStab", "KnifeThrow", "ReplicateShot", "GiveRodaShot" }
	local remotes = {}

	local function collect_remotes()
		remotes = {}
		for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				for _, name in ipairs(CANDIDATES) do
					if obj.Name == name then
						table.insert(remotes, obj)
						break
					end
				end
			end
		end
		if cfg.verbose then
			print("[AURA] " .. #remotes .. " remotes")
		end
	end

	local function get_by_duel()
		local myDuel = LP:GetAttribute("CurrentDuel")
		if not myDuel then return nil end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p:GetAttribute("CurrentDuel") == myDuel then
				local char, hum, hrp = Core.get_character(p)
				if char then
					return { player = p, hrp = hrp, hum = hum }
				end
			end
		end
		return nil
	end

	local function get_by_proximity()
		local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not me then return nil end
		local best, bestD = nil, cfg.fallback_range or 200
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and not Core.is_teammate(p) then
				local char, hum, hrp = Core.get_character(p)
				if char then
					local d = (hrp.Position - me.Position).Magnitude
					if d < bestD then
						best, bestD = { player = p, hrp = hrp, hum = hum }, d
					end
				end
			end
		end
		return best
	end

	local function get_target()
		local t = get_by_duel()
		if t then return t, "duelo" end
		t = get_by_proximity()
		if t then return t, "proximidade" end
		return nil, nil
	end

	local function has_tool()
		local char = LP.Character
		if not char then return false end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") then return true end
		end
		return false
	end

	local function fire(remote, args)
		pcall(function()
			if remote:IsA("RemoteEvent") then
				remote:FireServer(table.unpack(args))
			else
				remote:InvokeServer(table.unpack(args))
			end
		end)
	end

	local function attack()
		if not cfg.enabled then return end
		if cfg.require_tool and not has_tool() then return end

		local now = tick()
		if now - lastAttack < (cfg.cooldown or 0.45) then return end
		lastAttack = now

		local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not me then return end

		local target, mode = get_target()
		if not target then
			if cfg.verbose then print("[AURA] nenhum alvo") end
			return
		end

		local dir = (target.hrp.Position - me.Position).Unit
		for _, remote in ipairs(remotes) do
			fire(remote, { dir })
			fire(remote, { me.Position, dir })
		end

		if cfg.verbose then
			print("[AURA] " .. target.player.Name .. " (" .. mode .. ")")
		end
	end

	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.ButtonR2 then
			attack()
		end
	end)

	UserInputService.TouchStarted:Connect(function()
		attack()
	end)

	Core.bind_toggle(cfg.keybind or "K", function() return cfg.enabled end, function(v) cfg.enabled = v end, "AURA")

	ReplicatedStorage.DescendantAdded:Connect(function(obj)
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			for _, name in ipairs(CANDIDATES) do
				if obj.Name == name then
					table.insert(remotes, obj)
					break
				end
			end
		end
	end)

	getgenv().AuraToggle = function(v) cfg.enabled = v and true or false; Core.save(); print("[AURA] " .. tostring(cfg.enabled)) end
	getgenv().AuraCooldown = function(v) cfg.cooldown = tonumber(v) or cfg.cooldown; Core.save() end
	getgenv().AuraVerbose = function(v) cfg.verbose = v and true or false end
	getgenv().AuraRequireTool = function(v) cfg.require_tool = v and true or false end
	getgenv().AuraRange = function(v) cfg.fallback_range = tonumber(v) or cfg.fallback_range; Core.save(); print("[AURA] range = " .. cfg.fallback_range) end

	collect_remotes()
	print("[AURA] carregado — click ataca | " .. (cfg.keybind or "K") .. " toggle")
end

print("[AURA] módulo definido")
