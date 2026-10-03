-- language: Lua, file: kill_aura.lua
-- Knife VS Gun DUELS focused. Prioriza CurrentDuel, senão proximidade.
-- Remotes comuns: ShootGun, KnifeStab, KnifeThrow, ReplicateShot, GiveRodaShot

getgenv().KVGD_kill_aura = function(Core)
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local LP = Players.LocalPlayer
	local cfg = Core.config.aura

	local lastAttack = 0
	local CANDIDATES = {
		"ShootGun", "KnifeStab", "KnifeThrow", "ReplicateShot", "GiveRodaShot",
		"Shoot", "Fire", "ThrowKnife", "Stab", "Attack", "Hit"
	}
	local remotes = {}

	local function collect_remotes()
		remotes = {}
		for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				local n = obj.Name
				for _, cand in ipairs(CANDIDATES) do
					if n == cand or string.find(string.lower(n), string.lower(cand)) then
						table.insert(remotes, obj)
						break
					end
				end
			end
		end
		-- também procura em folders comuns de duelo
		local duelFolder = ReplicatedStorage:FindFirstChild("Duels") or ReplicatedStorage:FindFirstChild("Combat") or ReplicatedStorage:FindFirstChild("Remotes")
		if duelFolder then
			for _, obj in ipairs(duelFolder:GetDescendants()) do
				if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not table.find(remotes, obj) then
					local n = string.lower(obj.Name)
					if string.find(n, "shoot") or string.find(n, "knife") or string.find(n, "stab") or string.find(n, "throw") or string.find(n, "hit") or string.find(n, "attack") then
						table.insert(remotes, obj)
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
		if now - lastAttack < (cfg.cooldown or 0.35) then return end
		lastAttack = now

		local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not me then return end

		local target, mode = get_target()
		if not target then
			if cfg.verbose then print("[AURA] nenhum alvo") end
			return
		end

		local origin = me.Position
		local dir = (target.hrp.Position - origin).Unit
		local head = target.player.Character and target.player.Character:FindFirstChild("Head")
		local aimPos = head and head.Position or target.hrp.Position

		for _, remote in ipairs(remotes) do
			-- formatos comuns em Knife VS Gun DUELS / duelo pads
			fire(remote, { dir })
			fire(remote, { origin, dir })
			fire(remote, { aimPos })
			fire(remote, { origin, aimPos })
			fire(remote, { target.player })
		end

		if cfg.verbose then
			print("[AURA] " .. target.player.Name .. " (" .. mode .. ")")
		end
	end

	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.ButtonR2
			or input.KeyCode == Enum.KeyCode.E then -- E = throw knife no jogo
			attack()
		end
	end)

	UserInputService.TouchStarted:Connect(function()
		attack()
	end)

	Core.bind_toggle(cfg.keybind or "K", function() return cfg.enabled end, function(v) cfg.enabled = v end, "AURA")

	ReplicatedStorage.DescendantAdded:Connect(function(obj)
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			local n = string.lower(obj.Name)
			if string.find(n, "shoot") or string.find(n, "knife") or string.find(n, "stab") or string.find(n, "throw") or string.find(n, "hit") or string.find(n, "attack") or string.find(n, "fire") then
				table.insert(remotes, obj)
			end
		end
	end)

	getgenv().AuraToggle = function(v) cfg.enabled = v and true or false; Core.save(); print("[AURA] " .. tostring(cfg.enabled)) end
	getgenv().AuraCooldown = function(v) cfg.cooldown = tonumber(v) or cfg.cooldown; Core.save() end
	getgenv().AuraVerbose = function(v) cfg.verbose = v and true or false end
	getgenv().AuraRequireTool = function(v) cfg.require_tool = v and true or false end
	getgenv().AuraRange = function(v) cfg.fallback_range = tonumber(v) or cfg.fallback_range; Core.save(); print("[AURA] range = " .. cfg.fallback_range) end
	getgenv().AuraRefresh = function() collect_remotes(); print("[AURA] refreshed " .. #remotes) end

	collect_remotes()
	print("[AURA] carregado (Knife VS Gun DUELS) — click/E ataca | " .. (cfg.keybind or "K") .. " toggle")
end

print("[AURA] módulo definido")
