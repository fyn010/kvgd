-- language: Lua, file: loader.lua
-- puxa módulos do repo e inicializa.

local BASE_URL = "https://raw.githubusercontent.com/fyn010/kvgd/main/"

local function fetch(name)
	local url = BASE_URL .. name .. ".lua"
	local ok, res = pcall(function()
		if request then
			local r = request({ Url = url, Method = "GET" })
			return r and r.Body
		end
		return game:HttpGet(url)
	end)
	if not ok or not res then
		warn("[LOADER] fetch falhou: " .. url)
		return nil
	end
	if type(res) == "string" and res:find("404") and #res < 200 then
		warn("[LOADER] 404: " .. url)
		return nil
	end
	return res
end

local function run_module(name)
	local code = fetch(name)
	if not code then return false end
	local fn, err = loadstring(code)
	if not fn then
		warn("[LOADER] syntax " .. name .. ": " .. tostring(err))
		return false
	end
	local ok, e = pcall(fn)
	if not ok then
		warn("[LOADER] runtime " .. name .. ": " .. tostring(e))
		return false
	end
	return true
end

print("[LOADER] baixando módulos...")

if not run_module("core") then
	warn("[LOADER] core falhou — abortando")
	return
end

local Core = getgenv().KVGD
if not Core then
	warn("[LOADER] Core não encontrado")
	return
end

local modules = {
	{ "esp", "KVGD_esp" },
	{ "silent_aim", "KVGD_silent_aim" },
	{ "hitbox", "KVGD_hitbox" },
	{ "kill_aura", "KVGD_kill_aura" },
}

for _, m in ipairs(modules) do
	if run_module(m[1]) then
		local fn = getgenv()[m[2]]
		if fn then
			pcall(fn, Core)
		end
	end
end

Core.attach()

print("[KVGD] pronto")
print("  ESP     → " .. (Core.config.esp.keybind or "Delete"))
print("  AIM     → " .. (Core.config.silent.keybind or "End"))
print("  HITBOX  → " .. (Core.config.hitbox.keybind or "H"))
print("  AURA    → " .. (Core.config.aura.keybind or "K"))
