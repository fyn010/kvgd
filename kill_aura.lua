-- language: Lua, file: kill_aura.lua
-- dispara em TODOS os inimigos quando você clica com faca equipada.
-- sem loop contínuo. K toggle ON/OFF.

getgenv().KVGD_kill_aura = function(Core)
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local state = {
        enabled = true,
        verbose = false,
        require_knife = true
    }

    local CANDIDATES = {
        "ShootGun", "KnifeStab", "KnifeThrow",
        "ReplicateShot", "GiveRodaShot",
    }

    local remotes = {}

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        local a, b = LP.Team, player.Team
        return a and b and a == b
    end

    local function collect_remotes()
        remotes = {}
        for _, obj in ipairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                for _, name in ipairs(CANDIDATES) do
                    if obj.Name == name then
                        table.insert(remotes, obj)
                        if state.verbose then
                            print("[AURA] candidato: " .. obj:GetFullName())
                        end
                        break
                    end
                end
            end
        end
        print("[AURA] " .. #remotes .. " remotes coletados")
    end

    local function get_all_enemies()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not is_teammate(p) then
                local char = p.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    table.insert(list, { player = p, char = char, hrp = hrp, hum = hum })
                end
            end
        end
        return list
    end

    -- verifica se tem faca equipada
    local function has_knife_equipped()
        local char = LP.Character
        if not char then return false end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("faca") or n:find("dagger") or n:find("blade") then
                    return true
                end
            end
        end
        return false
    end

    local function fire(remote, args)
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args))
            else
                remote:InvokeServer(table.unpack(args))
            end
        end)
    end

    local function attack_all()
        if not state.enabled then return end
        if state.require_knife and not has_knife_equipped() then return end

        local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not me then return end

        local targets = get_all_enemies()
        if #targets == 0 then return end

        for _, t in ipairs(targets) do
            local vec_unit = (t.hrp.Position - me.Position).Unit
            local vec_pos  = t.hrp.Position
            local cf       = CFrame.new(me.Position, t.hrp.Position)

            for _, remote in ipairs(remotes) do
                fire(remote, { vec_unit })
                fire(remote, { vec_pos })
                fire(remote, { cf })
                fire(remote, { t.hrp })
                fire(remote, { t.char })
            end
        end

        if state.verbose then
            print("[AURA] atacou " .. #targets .. " inimigo(s)")
        end
    end

    -- dispara no clique esquerdo
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.KeyCode == Enum.KeyCode.ButtonR2 then
            attack_all()
        end

        if input.KeyCode == Enum.KeyCode.K then
            state.enabled = not state.enabled
            print("[AURA] " .. tostring(state.enabled))
        end
    end)

    -- mobile: também captura toques
    UIS.TouchStarted:Connect(function()
        attack_all()
    end)

    getgenv().AuraToggle = function(v)
        state.enabled = v
        print("[AURA] " .. tostring(v))
    end
    getgenv().AuraRequireKnife = function(v)
        state.require_knife = v
        print("[AURA] require_knife = " .. tostring(v))
    end
    getgenv().AuraVerbose = function(v) state.verbose = v end

    collect_remotes()
    print("[AURA] carregado — clica com a faca equipada | K toggle")
end

print("[AURA] módulo definido")
