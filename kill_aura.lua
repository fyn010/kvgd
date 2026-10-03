-- language: Lua, file: kill_aura.lua
-- tenta TODOS os remotes de arma com TODOS os formatos de args.
-- K toggle.

getgenv().KVGD_kill_aura = function(Core)
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local UIS = game:GetService("UserInputService")
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local state = {
        enabled = false,
        delay = 0.1,
        verbose = true
    }

    -- todos os remotes candidatos
    local CANDIDATES = {
        "ShootGun", "KnifeStab", "KnifeThrow",
        "ReplicateShot", "GiveRodaShot",
        "HitRemote", "DamageRemote", "Attack", "Hit"
    }

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        local a, b = LP.Team, player.Team
        return a and b and a == b
    end

    local remotes = {}

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

    -- dispara um remote com um formato específico de args
    local function fire(remote, args)
        local ok, err = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(table.unpack(args))
            else
                remote:InvokeServer(table.unpack(args))
            end
        end)
        return ok
    end

    task.spawn(function()
        while true do
            task.wait(state.delay)
            if state.enabled and LP.Character then
                local me = LP.Character:FindFirstChild("HumanoidRootPart")
                if me then
                    local targets = get_all_enemies()
                    for _, t in ipairs(targets) do
                        -- calcula formatos diferentes de argumento
                        local vec_unit = (t.hrp.Position - me.Position).Unit
                        local vec_pos  = t.hrp.Position
                        local cf       = CFrame.new(me.Position, t.hrp.Position)
                        local name     = t.player.Name
                        local char     = t.char
                        local hrp      = t.hrp

                        for _, remote in ipairs(remotes) do
                            -- tenta cada formato
                            fire(remote, { vec_unit })
                            fire(remote, { vec_pos })
                            fire(remote, { cf })
                            fire(remote, { hrp })
                            fire(remote, { char })
                            fire(remote, { name })
                            fire(remote, { me.Position, vec_unit })
                            fire(remote, { t.player })
                            fire(remote, { hrp.Position, hrp })
                            fire(remote, {})
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
            if state.enabled and #remotes == 0 then
                collect_remotes()
            end
            print("[AURA] " .. tostring(state.enabled))
        end
    end)

    getgenv().AuraToggle = function(v)
        state.enabled = v
        if v and #remotes == 0 then collect_remotes() end
        print("[AURA] " .. tostring(v))
    end
    getgenv().AuraDelay = function(v) state.delay = v end
    getgenv().AuraVerbose = function(v) state.verbose = v end
    getgenv().AuraRemotes = function() return remotes end

    collect_remotes()
    print("[AURA] carregado — K toggle")
end

print("[AURA] módulo definido")
