-- language: Lua, file: kill_aura.lua
-- spam FireServer em TODOS os inimigos do servidor, sem filtro de raio.
-- K toggle.

getgenv().KVGD_kill_aura = function(Core)
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local state = {
        enabled = false,
        delay = 0.05,
        use_knife = true,
        use_gun = true,
        only_current_weapon = true
    }

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        local a, b = LP.Team, player.Team
        return a and b and a == b
    end

    local function find_remote(name)
        for _, obj in ipairs(RS:GetDescendants()) do
            if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                return obj
            end
        end
        return nil
    end

    -- pega todos os inimigos vivos, sem filtro de distância
    local function get_all_enemies()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not is_teammate(p) then
                local char = p.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    table.insert(list, hrp)
                end
            end
        end
        return list
    end

    -- arma equipada no momento
    local function current_weapon()
        local char = LP.Character
        if not char then return nil end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                return tool.Name
            end
        end
        return nil
    end

    task.spawn(function()
        while true do
            task.wait(state.delay)
            if state.enabled and LP.Character then
                local targets = get_all_enemies()
                if #targets > 0 then
                    local me = LP.Character:FindFirstChild("HumanoidRootPart")
                    if me then
                        local weapon = current_weapon()
                        local kn = find_remote("KnifeStab")
                        local gun = find_remote("ShootGun")

                        for _, hrp in ipairs(targets) do
                            local vec = (hrp.Position - me.Position).Unit
                            pcall(function()
                                if kn and (not state.only_current_weapon or (weapon and weapon:lower():find("knife"))) then
                                    kn:FireServer(vec)
                                end
                            end)
                            pcall(function()
                                if gun and (not state.only_current_weapon or (weapon and not weapon:lower():find("knife"))) then
                                    gun:FireServer(vec)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.K then
            state.enabled = not state.enabled
            print("[AURA] " .. tostring(state.enabled))
        end
    end)

    getgenv().AuraToggle = function(v) state.enabled = v; print("[AURA] " .. tostring(v)) end
    getgenv().AuraDelay = function(v) state.delay = v; print("[AURA] delay = " .. v) end
    getgenv().AuraOnlyCurrent = function(v) state.only_current_weapon = v; print("[AURA] only_current = " .. tostring(v)) end
    getgenv().AuraKnife = function(v) state.use_knife = v end
    getgenv().AuraGun = function(v) state.use_gun = v end

    print("[AURA] carregado — K toggle | AuraDelay(s)")
end

print("[AURA] módulo definido")
