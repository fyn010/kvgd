-- language: Lua, file: core.lua
-- núcleo: config persistente + utilitários compartilhados.

local Core = {}
Core.config = {}
Core.maids = {}

local CONFIG_FILE = "kvgd_config.json"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

function Core.save()
	if writefile and Core.config then
		pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(Core.config))
	end
end

local function load_config()
	if isfile and isfile(CONFIG_FILE) then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok and typeof(data) == "table" then
			Core.config = data
		end
	end

	Core.config.esp = Core.config.esp or {
		enabled = true,
		enemy_color = {255, 50, 50},
		team_color = {50, 200, 255},
		distance_color = {255, 255, 255},
		tracer_thickness = 1,
		max_distance = 800,
		show_distance = true,
		keybind = "Delete"
	}

	Core.config.silent = Core.config.silent or {
		enabled = false,
		hit_part = "Head",
		fov = 200,
		team_check = true,
		keybind = "End",
		method = "mouse"
	}

	Core.config.hitbox = Core.config.hitbox or {
		enabled = false,
		size = 8,
		transparency = 0.35,
		keybind = "H"
	}

	Core.config.aura = Core.config.aura or {
		enabled = true,
		verbose = false,
		cooldown = 0.35,
		require_tool = true,
		fallback_range = 200,
		keybind = "K"
	}
end

function Core.is_teammate(player)
	if player == LP then return true end
	local a, b = LP.Team, player.Team
	return a and b and a == b
end

function Core.get_character(player)
	local char = player and player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then
		return char, hum, hrp
	end
	return nil
end

function Core.on_character(player, callback)
	if player.Character then
		task.spawn(callback, player.Character)
	end
	return player.CharacterAdded:Connect(callback)
end

function Core.bind_toggle(keyName, getter, setter, label)
	local key = Enum.KeyCode[keyName]
	if not key then return end
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == key then
			local new = not getter()
			setter(new)
			Core.save()
			print(string.format("[%s] %s", label or keyName, tostring(new)))
		end
	end)
end

function Core.attach()
	print("[CORE] ready")
end

load_config()
getgenv().KVGD = Core
print("[CORE] carregado")
