-- language: Lua, file: kill_aura.lua
-- on-click, com cooldown. K toggle.

getgenv().KVGD_kill_aura = function(Core)
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local UIS = game:GetService("UserInputService")
    local CAS = game:GetService("ContextActionService")
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local state = {
        enabled = true,
        verbose = true,
        require_knife = false,
        cooldown = 0.5,       -- tempo mínimo entre ataques (segundos)
        attack_once = true,   -- ataca só 1x por clique, não 5x por remote
    }

    local last_attack = 0
    local CANDIDATES = { "ShootGun", "KnifeStab", "KnifeThrow", "ReplicateShot", "GiveRodaShot" }
    local remotes = {}

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        -- checa Team E TeamColor (alguns jogos usam um ou outro)
        local a, b = LP.Team, player.Team
        if a and b then return a == b end
        local ca, cb = LP.TeamColor, player.TeamColor
        if ca and cb then return ca == cb end
        return false
    end

    local function collect_remotes()
        remotes = {}
        for _, obj in ipairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                for _, name in ipairs(CANDIDATES) do
                    if obj.Name == name then
                        table.insert(remotes, obj)
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

    local function has_tool_equipped()
        local char = LP.Character
        if not char then return false end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then return true end
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
        if state.require_knife and not has_tool_equipped() then return end

        -- cooldown global
        local now = tick()
        if now - last_attack < state.cooldown then return end
        last_attack = now

        local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not me then return end

        local targets = get_all_enemies()
        if #targets == 0 then
            if state.verbose then print("[AURA] nenhum inimigo") end
            return
        end

        for _, t in ipairs(targets) do
            local vec_unit = (t.hrp.Position - me.Position).Unit
            local vec_pos  = t.hrp.Position
            local cf       = CFrame.new(me.Position, t.hrp.Position)

            for _, remote in ipairs(remotes) do
                -- só um formato por vez (reduz volume de FireServer)
                fire(remote, { vec_unit })
                if not state.attack_once then
                    fire(remote, { vec_pos })
                    fire(remote, { cf })
                    fire(remote, { t.hrp })
                    fire(remote, { t.char })
                end
            end
        end

        if state.verbose then
            print("[AURA] atacou " .. #targets .. " inimigo(s)")
        end
    end

    CAS:BindAction("KVGD_AuraClick", function(_, state_)
        if state_ == Enum.UserInputState.Begin then
            attack_all()
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

    UIS.InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            attack_all()
        end

        if input.KeyCode == Enum.KeyCode.K and not gpe then
            state.enabled = not state.enabled
            print("[AURA] " .. tostring(state.enabled))
        end
    end)

    UIS.TouchStarted:Connect(function() attack_all() end)

    getgenv().AuraToggle = function(v) state.enabled = v; print("[AURA] " .. tostring(v)) end
    getgenv().AuraCooldown = function(v) state.cooldown = v; print("[AURA] cooldown = " .. v) end
    getgenv().AuraRequireKnife = function(v) state.require_knife = v end
    getgenv().AuraVerbose = function(v) state.verbose = v end
    getgenv().AuraAttackOnce = function(v) state.attack_once = v end

    collect_remotes()
    print("[AURA] carregado — clica | cooldown padrão 0.5s | K toggle")
end

print("[AURA] módulo definido")
