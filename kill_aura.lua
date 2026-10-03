-- language: Lua, file: kill_aura.lua
-- kill aura: espama KnifeStab + ShootGun em todo inimigo num raio.
-- K toggle.

getgenv().KVGD_kill_aura = function(Core)
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local state = {
        enabled = false,
        range = 30,
        delay = 0.05,
        use_knife = true,
        use_gun = true
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

    local function get_enemies_in_range(range)
        local list = {}
        local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not me then return list end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not is_teammate(p) then
                local char = p.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local d = (hrp.Position - me.Position).Magnitude
                    if d <= range then
                        table.insert(list, p)
                    end
                end
            end
        end
        return list
    end

    task.spawn(function()
        while true do
            task.wait(state.delay)
            if state.enabled then
                local targets = get_enemies_in_range(state.range)
                if #targets > 0 then
                    local kn = state.use_knife and find_remote("KnifeStab") or nil
                    local gun = state.use_gun and find_remote("ShootGun") or nil
                    local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if me then
                        for _, p in ipairs(targets) do
                            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local vec = (hrp.Position - me.Position).Unit
                                pcall(function()
                                    if kn then kn:FireServer(vec) end
                                end)
                                pcall(function()
                                    if gun then gun:FireServer(vec) end
                                end)
                            end
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
    getgenv().AuraRange = function(v) state.range = v; print("[AURA] range = " .. v) end
    getgenv().AuraDelay = function(v) state.delay = v; print("[AURA] delay = " .. v) end
    getgenv().AuraKnife = function(v) state.use_knife = v end
    getgenv().AuraGun = function(v) state.use_gun = v end

    print("[AURA] carregado — K toggle | AuraRange(n) | AuraDelay(s)")
end

print("[AURA] módulo definido")
