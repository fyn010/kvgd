-- language: Lua, file: lootbox.lua

getgenv().KVGD_lootbox = function(Core)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local function describe(v)
        local t = typeof(v)
        if t == "Instance" then return "Instance(" .. v:GetFullName() .. ")"
        elseif t == "Vector3" then
            return string.format("Vector3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
        elseif t == "table" then return "table[" .. #v .. "]"
        elseif t == "string" then return '"' .. v .. '"'
        else return tostring(v) end
    end

    task.spawn(function()
        local box
        local tries = 0
        while not box and tries < 60 do
            box = ReplicatedStorage:FindFirstChild("PurchaseBox", true)
            if not box then task.wait(0.5); tries = tries + 1 end
        end
        if not box then
            warn("[LOOTBOX] PurchaseBox não apareceu em 30s")
            return
        end
        print("[LOOTBOX] PurchaseBox achado em: " .. box:GetFullName())

        local mt = getrawmetatable(box)
        if not mt then return end
        setreadonly(mt, false)
        local old_index = mt.__index
        mt.__index = function(t, k)
            if k == "FireServer" or k == "InvokeServer" then
                return function(self, ...)
                    local args = {...}
                    print("[LOOTBOX] OUT " .. k .. ":")
                    for i, v in ipairs(args) do
                        print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
                    end
                    return old_index(self, k)(self, ...)
                end
            end
            return old_index(t, k)
        end
        setreadonly(mt, true)
    end)

    local function watch_incoming(name)
        task.spawn(function()
            local remote
            local tries = 0
            while not remote and tries < 60 do
                remote = ReplicatedStorage:FindFirstChild(name, true)
                if not remote then task.wait(0.5); tries = tries + 1 end
            end
            if remote and remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function(...)
                    local args = {...}
                    print("[LOOTBOX] IN " .. name .. ":")
                    for i, v in ipairs(args) do
                        print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
                    end
                end)
                print("[LOOTBOX] monitorando " .. name)
            end
        end)
    end

    watch_incoming("BoxOpeningClient")
    watch_incoming("BoxOpenedMessageClient")

    print("[LOOTBOX] monitor ativo — abra uma caixa")
end

print("[LOOTBOX] módulo definido")
