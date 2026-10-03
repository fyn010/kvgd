-- language: Lua, file: hitbox.lua
-- expande hitbox do inimigo. HitboxToggle(true/false).

getgenv().KVGD_hitbox = function(Core)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local cfg = Core.config.hitbox
    local original = {}

    local function is_teammate(p)
        if p == LP then return true end
        local a, b = LP.Team, p.Team
        return a and b and a == b
    end

    local function apply(player)
        if player == LP or is_teammate(player) then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
                and not part.Name:find("HitboxPart") then
                if not original[part] then
                    original[part] = part.Size
                end
                part.Size = Vector3.new(cfg.size, cfg.size, cfg.size)
                part.Transparency = cfg.transparency
                part.CanCollide = false
            end
        end
    end

    local function restore(player)
        local char = player.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if original[part] then
                part.Size = original[part]
                part.Transparency = 0
                part.CanCollide = true
                original[part] = nil
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        if not cfg.enabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            apply(p)
        end
    end)

    getgenv().HitboxToggle = function(state)
        cfg.enabled = state
        if not state then
            for _, p in ipairs(Players:GetPlayers()) do restore(p) end
        end
        Core.save()
        print("[HITBOX] " .. tostring(state))
    end

    print("[HITBOX] carregado — use HitboxToggle(true/false)")
end

print("[HITBOX] módulo definido")
