-- language: Lua, file: lootbox.lua
-- FASE 1: só monitora os remotes de caixa.

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

    Core.register_hook("ReplicatedStorage.Remotes.Shop.PurchaseBox", "FireServer", function(args)
        print("[LOOTBOX] OUT PurchaseBox:")
        for i, v in ipairs(args) do
            print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
        end
        return nil
    end)

    local function watch_incoming(name)
        local remote = ReplicatedStorage:FindFirstChild(name, true)
        if remote and remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                local args = {...}
                print("[LOOTBOX] IN " .. name .. ":")
                for i, v in ipairs(args) do
                    print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
                end
            end)
            print("[LOOTBOX] monitorando " .. name)
        else
            warn("[LOOTBOX] não achou: " .. name)
        end
    end

    watch_incoming("BoxOpeningClient")
    watch_incoming("BoxOpenedMessageClient")

    print("[LOOTBOX] monitor ativo — abra uma caixa e veja o output")
end

print("[LOOTBOX] módulo definido")
