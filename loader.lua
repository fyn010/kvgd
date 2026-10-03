-- language: Lua, file: loader.lua
-- puxa módulos do repo público.

local BASE_URL = "https://raw.githubusercontent.com/fyn010/kvgd/main/"

local function fetch(name)
    local url = BASE_URL .. name .. ".lua"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then
        warn("[LOADER] fetch falhou: " .. url)
        return nil
    end
    if res:find("404") and #res < 200 then
        warn("[LOADER] 404: " .. url)
        return nil
    end
    return res
end

local function run_module(name, ...)
    local code = fetch(name)
    if not code then return end
    local fn, err = loadstring(code)
    if not fn then
        warn("[LOADER] syntax " .. name .. ": " .. tostring(err))
        return
    end
    local ok, e = pcall(fn, ...)
    if not ok then
        warn("[LOADER] runtime " .. name .. ": " .. tostring(e))
    end
end

print("[LOADER] baixando módulos...")

run_module("core")
local Core = getgenv().KVGD
if not Core then
    warn("[LOADER] core falhou — abortando")
    return
end

run_module("esp")
if getgenv().KVGD_esp then getgenv().KVGD_esp(Core) end

run_module("silent_aim")
if getgenv().KVGD_silent_aim then getgenv().KVGD_silent_aim(Core) end

run_module("hitbox")
if getgenv().KVGD_hitbox then getgenv().KVGD_hitbox(Core) end

run_module("kill_aura")
if getgenv().KVGD_kill_aura then getgenv().KVGD_kill_aura(Core) end

Core.attach()

print("[KVGD] pronto. ESP=RightShift | AIM=RightAlt")
