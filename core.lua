-- language: Lua, file: core.lua
-- hook via getrawmetatable + __index wrap. Solara-safe.

local Core = {}
Core.config = {}
Core.hooks = {}

local CONFIG_FILE = "kvgd_config.json"
local HttpService = game:GetService("HttpService")

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
        show_distance = true
    }
     Core.config.silent = Core.config.silent or {
        enabled = false,
        hit_part = "Head",
        fov = 200,
        keybind = Enum.KeyCode.End,
        team_check = true
    }
    Core.config.hitbox = Core.config.hitbox or {
        enabled = false,
        size = 8,
        transparency = 0.6
    }
end

function Core.register_hook(remote_path, method, cb)
    table.insert(Core.hooks, { path = remote_path, method = method, cb = cb })
end

function Core.attach()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local installed, failed = 0, 0

    for _, h in ipairs(Core.hooks) do
        local name = h.path:match("[^.]+$")
        local remote = ReplicatedStorage:FindFirstChild(name, true)

        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            local ok = pcall(function()
                local mt = getrawmetatable(remote)
                if not mt then error("sem metatable") end
                setreadonly(mt, false)
                local old_index = mt.__index
                mt.__index = function(t, k)
                    if k == h.method then
                        return function(self, ...)
                            local args = {...}
                            local new_args = h.cb(args)
                            if new_args then
                                return old_index(self, k)(self, table.unpack(new_args))
                            end
                            return old_index(self, k)(self, ...)
                        end
                    end
                    return old_index(t, k)
                end
                setreadonly(mt, true)
            end)

            if ok then
                installed = installed + 1
                print("[CORE] hook: " .. h.path .. ":" .. h.method)
            else
                failed = failed + 1
                warn("[CORE] falha: " .. h.path)
            end
        else
            failed = failed + 1
            warn("[CORE] remote não achado: " .. h.path)
        end
    end

    print("[CORE] hooks " .. installed .. "/" .. (installed + failed) .. " ativos")
end

load_config()

getgenv().KVGD = Core
print("[CORE] carregado")
