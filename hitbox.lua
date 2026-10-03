-- language: Lua, file: hitbox.lua
-- expand hitbox com cleanup e CharacterAdded. Toggle: H

getgenv().KVGD_hitbox = function(Core)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LP = Players.LocalPlayer
	local cfg = Core.config.hitbox

	local original = setmetatable({}, { __mode = "k" })
	local connections = {}

	local function restore_part(part)
		local size = original[part]
		if size then
			pcall(function()
				part.Size = size
				part.Transparency = 0
				part.CanCollide = true
			end)
			original[part] = nil
		end
	end

	local function restore_player(player)
		local char = player.Character
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				restore_part(part)
			end
		end
	end

	local function apply_player(player)
		if player == LP or Core.is_teammate(player) then return end
		local char = Core.get_character(player)
		if not char then return end

		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart")
				and part.Name ~= "HumanoidRootPart"
				and not string.find(part.Name, "HitboxPart") then
				if not original[part] then
					original[part] = part.Size
				end
				part.Size = Vector3.new(cfg.size, cfg.size, cfg.size)
				part.Transparency = cfg.transparency or 0.6
				part.CanCollide = false
			end
		end
	end

	local function setup_player(player)
		if connections[player] then
			for _, c in ipairs(connections[player]) do
				pcall(function() c:Disconnect() end)
			end
		end
		connections[player] = {}

		local function on_char(char)
			if not cfg.enabled then return end
			task.wait(0.15)
			apply_player(player)
		end

		table.insert(connections[player], Core.on_character(player, on_char))
		table.insert(connections[player], player.CharacterRemoving:Connect(function()
			restore_player(player)
		end))
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then setup_player(p) end
	end
	Players.PlayerAdded:Connect(function(p)
		if p ~= LP then setup_player(p) end
	end)
	Players.PlayerRemoving:Connect(function(p)
		restore_player(p)
		if connections[p] then
			for _, c in ipairs(connections[p]) do pcall(function() c:Disconnect() end) end
			connections[p] = nil
		end
	end)

	RunService.Heartbeat:Connect(function()
		if not cfg.enabled then return end
		for _, p in ipairs(Players:GetPlayers()) do
			apply_player(p)
		end
	end)

	local function set_enabled(state)
		cfg.enabled = state
		if not state then
			for _, p in ipairs(Players:GetPlayers()) do
				restore_player(p)
			end
		end
		Core.save()
	end

	Core.bind_toggle(cfg.keybind or "H", function() return cfg.enabled end, set_enabled, "HITBOX")

	getgenv().HitboxToggle = function(state)
		set_enabled(state and true or false)
		print("[HITBOX] " .. tostring(cfg.enabled))
	end

	getgenv().HitboxSize = function(v)
		cfg.size = tonumber(v) or cfg.size
		Core.save()
		print("[HITBOX] size = " .. cfg.size)
	end

	print("[HITBOX] carregado — " .. (cfg.keybind or "H") .. " toggle")
end

print("[HITBOX] módulo definido")
