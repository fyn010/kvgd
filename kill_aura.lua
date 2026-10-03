-- language: Lua, file: kill_aura.lua
-- ataca só o player do duelo atual. K toggle.

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
        cooldown = 0.5,
        require_tool = true,
    }

    local last_attack = 0
    local CANDIDATES = { "ShootGun", "KnifeStab", "KnifeThrow", "ReplicateShot", "GiveRodaShot" }
    local remotes = {}

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

    -- acha o oponente do duelo atual
    local function get_duel_opponent()
        local my_duel = LP:GetAttribute("CurrentDuel")
        if not my_duel then return nil end

        -- procura o player que tem o MESMO CurrentDuel
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p:GetAttribute("CurrentDuel") == my_duel then
                local char = p.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    return { player = p, char = char, hrp = hrp, hum = hum, duel = my_duel }
                end
            end
        end
        return nil
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

    local function attack_opponent()
        if not state.enabled then return end
        if state.require_tool and not has_tool_equipped() then return end

        local now = tick()
        if now - last_attack < state.cooldown then return end
        last_attack = now

        local me = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not me then return end

        local target = get_duel_opponent()
        if not target then
            if state.verbose then print("[AURA] sem oponente de duelo") end
            return
        end

        local vec_unit = (target.hrp.Position - me.Position).Unit
        local vec_pos  = target.hrp.Position
        local cf       = CFrame.new(me.Position, target.hrp.Position)

        for _, remote in ipairs(remotes) do
            fire(remote, { vec_unit })
        end

        if state.verbose then
            print("[AURA] atacou " .. target.player.Name .. " (duelo " .. tostring(target.duel) .. ")")
        end
    end

    CAS:BindAction("KVGD_AuraClick", function(_, s)
        if s == Enum.UserInputState.Begin then attack_opponent() end
        return Enum.ContextActionResult.Pass
    end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

    UIS.InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            attack_opponent()
        end
        if input.KeyCode == Enum.KeyCode.K and not gpe then
            state.enabled = not state.enabled
            print("[AURA] " .. tostring(state.enabled))
        end
    end)

    UIS.TouchStarted:Connect(function() attack_opponent() end)

    getgenv().AuraToggle = function(v) state.enabled = v; print("[AURA] " .. tostring(v)) end
    getgenv().AuraCooldown = function(v) state.cooldown = v; print("[AURA] cooldown = " .. v) end
    getgenv().AuraVerbose = function(v) state.verbose = v end
    getgenv().AuraRequireTool = function(v) state.require_tool = v end

    collect_remotes()
    print("[AURA] carregado — clica com a faca | K toggle")
end

print("[AURA] módulo definido")
