-- language: Lua, file: hitbox.lua
-- Knife VS Gun DUELS: expand só do oponente do duelo / inimigo próximo.
-- Não toca em HRP, não mexe CanCollide de tudo, restaura limpo. Toggle: H

getgenv().KVGD_hitbox = function(Core)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local cfg = Core.config.hitbox

	cfg.size = cfg.size or 6
	cfg.transparency = cfg.transparency or 0.7
	cfg.only_duel = cfg.only_duel ~= false -- default true: só oponente do duelo
	cfg.parts = cfg.parts or { "Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart" }
	-- por padrão NÃO expandimos HRP de verdade (só visual se quiser); lista acima é whitelist

	local original = setmetatable({}, { __mode = "k" })
	local applied = setmetatable({}, { __mode = "k" }) -- part -> true

	local function restore_part(part)
		if not part or not part.Parent then
			original[part] = nil
			applied[part] = nil
			return
		end
		local data = original[part]
		if data then
			pcall(function()
				part.Size = data.Size
				part.Transparency = data.Transparency
				-- não mexemos CanCollide de volta se o jogo já controla
			end)
			original[part] = nil
			applied[part] = nil
		end
	end

	local function restore_all()
		for part in pairs(original) do
			restore_part(part)
		end
	end

	local function should_expand_part(part)
		if not part:IsA("BasePart") then return false end
		if part.Name == "HumanoidRootPart" then return false end -- nunca expandir HRP (bug comum)
		local name = part.Name
		for _, allowed in ipairs(cfg.parts) do
			if name == allowed then return true end
		end
		-- fallback: só torso/head se a lista não bater
		if name == "Head" or name == "Torso" or name == "UpperTorso" or name == "LowerTorso" then
			return true
		end
		return false
	end

	local function apply_to_character(char)
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if should_expand_part(part) then
				if not original[part] then
					original[part] = {
						Size = part.Size,
						Transparency = part.Transparency
					}
				end
				local s = cfg.size
				-- não deixa menor que o original
				local ox, oy, oz = original[part].Size.X, original[part].Size.Y, original[part].Size.Z
				part.Size = Vector3.new(math.max(s, ox), math.max(s, oy), math.max(s, oz))
				part.Transparency = cfg.transparency
				applied[part] = true
			end
		end
	end

	local function get_targets()
		local list = {}
		local myDuel = LP:GetAttribute("CurrentDuel")

		if cfg.only_duel and myDuel then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP and p:GetAttribute("CurrentDuel") == myDuel then
					local char = Core.get_character(p)
					if char then table.insert(list, char) end
				end
			end
			return list
		end

		-- senão: inimigos vivos próximos
		local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not me then return list end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and not Core.is_teammate(p) then
				local char, hum, hrp = Core.get_character(p)
				if char and hrp and (hrp.Position - me.Position).Magnitude < 120 then
					table.insert(list, char)
				end
			end
		end
		return list
	end

	local function tick_expand()
		if not cfg.enabled then
			restore_all()
			return
		end

		local targets = get_targets()
		local keep = {}

		for _, char in ipairs(targets) do
			apply_to_character(char)
			for _, part in ipairs(char:GetDescendants()) do
				if applied[part] then keep[part] = true end
			end
		end

		-- restaura partes que não são mais target
		for part in pairs(original) do
			if not keep[part] then
				restore_part(part)
			end
		end
	end

	-- loop mais leve: Heartbeat mas com throttle
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc = acc + dt
		if acc < 0.1 then return end -- 10 Hz
		acc = 0
		tick_expand()
	end)

	local function set_enabled(state)
		cfg.enabled = state and true or false
		if not cfg.enabled then
			restore_all()
		end
		Core.save()
	end

	Core.bind_toggle(cfg.keybind or "H", function() return cfg.enabled end, set_enabled, "HITBOX")

	Players.PlayerRemoving:Connect(function()
		-- limpa refs mortas
		for part in pairs(original) do
			if not part.Parent then
				original[part] = nil
				applied[part] = nil
			end
		end
	end)

	getgenv().HitboxToggle = function(state)
		set_enabled(state and true or false)
		print("[HITBOX] " .. tostring(cfg.enabled))
	end

	getgenv().HitboxSize = function(v)
		cfg.size = tonumber(v) or cfg.size
		Core.save()
		print("[HITBOX] size = " .. cfg.size)
	end

	getgenv().HitboxOnlyDuel = function(v)
		cfg.only_duel = v and true or false
		Core.save()
		print("[HITBOX] only_duel = " .. tostring(cfg.only_duel))
	end

	print("[HITBOX] carregado — " .. (cfg.keybind or "H") .. " | só torso/head | only_duel=" .. tostring(cfg.only_duel))
end

print("[HITBOX] módulo definido")
