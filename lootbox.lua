-- language: Lua, file: lootbox.lua

getgenv().KVGD_lootbox = function(Core)
    local RS = game:GetService("ReplicatedStorage")

    local function describe(v, d)
        d = d or 0
        local t = typeof(v)
        if t == "Instance" then return "Instance(" .. v:GetFullName() .. ")"
        elseif t == "Vector3" then return string.format("V3(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
        elseif t == "table" then
            if d > 1 then return "tbl{...}" end
            local p = {}
            for k, sub in pairs(v) do p[#p+1] = tostring(k).."="..describe(sub, d+1) end
            return "{" .. table.concat(p, ",") .. "}"
        elseif t == "string" then return '"' .. v .. '"'
        else return tostring(v) end
    end

    -- procura SOMENTE RemoteEvent/RemoteFunction com esse nome, ignora TextButton
    local function find_remote(name)
        for _, obj in ipairs(RS:GetDescendants()) do
            if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                return obj
            end
        end
        return nil
    end

    -- PurchaseBox
    task.spawn(function()
        local box
        local tries = 0
        while not box and tries < 60 do
            box = find_remote("PurchaseBox")
            if not box then task.wait(0.5); tries = tries + 1 end
        end
        if not box then
            warn("[LOOTBOX] PurchaseBox (RemoteEvent) não achado")
            return
        end
        print("[LOOTBOX] PurchaseBox -> " .. box:GetFullName() .. " (" .. box.ClassName .. ")")

        local mt = getrawmetatable(box)
        if not mt then warn("[LOOTBOX] sem metatable"); return end
        setreadonly(mt, false)
        local old = mt.__index
        mt.__index = function(t, k)
            if k == "FireServer" or k == "InvokeServer" then
                return function(self, ...)
                    local args = {...}
                    print("[LOOTBOX] OUT " .. k .. ":")
                    for i, v in ipairs(args) do
                        print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
                    end
                    return old(self, k)(self, ...)
                end
            end
            return old(t, k)
        end
        setreadonly(mt, true)
        print("[LOOTBOX] PurchaseBox hookado")
    end)

    -- BoxOpeningClient
    task.spawn(function()
        local remote
        local tries = 0
        while not remote and tries < 60 do
            remote = find_remote("BoxOpeningClient")
            if not remote then task.wait(0.5); tries = tries + 1 end
        end
        if remote then
            remote.OnClientEvent:Connect(function(...)
                local args = {...}
                print("[LOOTBOX] IN BoxOpeningClient:")
                for i, v in ipairs(args) do
                    print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
                end
            end)
            print("[LOOTBOX] monitorando BoxOpeningClient")
        end
    end)

    -- BoxOpenedMessageClient
    task.spawn(function()
        local remote
        local tries = 0
        while not remote and tries < 60 do
            remote = find_remote("BoxOpenedMessageClient")
            if not remote then task.wait(0.5); tries = tries + 1 end
        end
        if remote then
            remote.OnClientEvent:Connect(function(...)
                local args = {...}
                print("[LOOTBOX] IN BoxOpenedMessageClient:")
                for i, v in ipairs(args) do
                    print("  [" .. i .. "] " .. typeof(v) .. " = " .. describe(v))
                end
            end)
            print("[LOOTBOX] monitorando BoxOpenedMessageClient")
        end
    end)

    print("[LOOTBOX] monitor ativo — abra uma caixa")
end

print("[LOOTBOX] módulo definido")
