-- language: Lua, file: silent_aim.lua
-- hook em ShootGun, KnifeStab, KnifeThrow. End toggle.

getgenv().KVGD_silent_aim = function(Core)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 1
    fov_circle.NumSides = 64
    fov_circle.Transparency = 0.5
    fov_circle.Filled = false

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        local my_team = LP.Team
        local their_team = player.Team
        return my_team and their_team and my_team == their_team
    end

    local function get_target()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local best, best_dist = nil, cfg.fov
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not is_teammate(p) then
                local char = p.Character
                local part = char and char:FindFirstChild(cfg.hit_part)
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < best_dist then
                            best, best_dist = part, d
                        end
                    end
                end
            end
        end
        return best
    end

    local function hook_remote(name, rewrite)
        task.spawn(function()
            local remote
            local tries = 0
            while not remote and tries < 40 do
                remote = game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
                if not remote then task.wait(0.5); tries = tries + 1 end
            end
            if not remote then
                warn("[AIM] remote não achado: " .. name)
                return
            end
            local mt = getrawmetatable(remote)
            if not mt then return end
            setreadonly(mt, false)
            local old_index = mt.__index
            mt.__index = function(t, k)
                if k == "FireServer" or k == "InvokeServer" then
                    return function(self, ...)
                        local args = {...}
                        local new = rewrite(args)
                        if new then
                            return old_index(self, k)(self, table.unpack(new))
                        end
                        return old_index(self, k)(self, ...)
                    end
                end
                return old_index(t, k)
            end
            setreadonly(mt, true)
            print("[AIM] hook: " .. remote:GetFullName())
        end)
    end

    local function rewrite(args)
        if not cfg.enabled then return nil end
        local tgt = get_target()
        if not tgt then return nil end
        local origin = Camera.CFrame.Position
        local modified = false
        for i, v in ipairs(args) do
            local t = typeof(v)
            if t == "Vector3" then
                args[i] = (tgt.Position - origin).Unit
                modified = true
            elseif t == "CFrame" then
                args[i] = CFrame.new(origin, tgt.Position)
                modified = true
            end
        end
        return modified and args or nil
    end

    hook_remote("ShootGun", rewrite)
    hook_remote("KnifeStab", rewrite)
    hook_remote("KnifeThrow", rewrite)

    RunService.RenderStepped:Connect(function()
        fov_circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fov_circle.Radius = cfg.fov
        fov_circle.Visible = cfg.enabled
        fov_circle.Color = get_target() and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.End then
            cfg.enabled = not cfg.enabled
            Core.save()
            print("[AIM] " .. tostring(cfg.enabled))
        end
    end)

    getgenv().AimFOV = function(v) cfg.fov = v; Core.save() end
    getgenv().AimPart = function(v) cfg.hit_part = v; Core.save() end

    print("[AIM] carregado — End toggle")
end

print("[AIM] módulo definido")
