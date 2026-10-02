-- language: Lua, file: silent_aim.lua
-- silent aim via camera snap. gira a câmera pro alvo no instante do disparo,
-- servidor recebe a direção nova, câmera volta ao normal depois.
-- End toggle.

getgenv().KVGD_silent_aim = function(Core)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local CAS = game:GetService("ContextActionService")
    local Camera = workspace.CurrentCamera
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 1
    fov_circle.NumSides = 64
    fov_circle.Transparency = 0.5
    fov_circle.Filled = false

    local saved_cframe = nil
    local snap_active = false

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        local my_team = LP.Team
        local their_team = player.Team
        return my_team and their_team and my_team == their_team
    end

    local function get_target()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local best, best_d = nil, cfg.fov
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not is_teammate(p) then
                local char = p.Character
                local part = char and (char:FindFirstChild(cfg.hit_part) or char:FindFirstChild("Head"))
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < best_d then best, best_d = part, d end
                    end
                end
            end
        end
        return best
    end

    -- handler de disparo: roda ANTES do handler do jogo
    local function on_fire(_, state)
        if state ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end
        if not cfg.enabled then
            return Enum.ContextActionResult.Pass
        end
        local t = get_target()
        if not t then
            return Enum.ContextActionResult.Pass
        end

        -- guarda a câmera atual
        saved_cframe = Camera.CFrame
        snap_active = true

        -- gira pro inimigo
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
        -- também ajusta o mouse look do Humanoid se existir
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = false
        end

        return Enum.ContextActionResult.Pass
    end

    -- devolve a câmera no próximo frame
    RunService.RenderStepped:Connect(function()
        if snap_active and saved_cframe then
            Camera.CFrame = saved_cframe
            saved_cframe = nil
            snap_active = false
        end

        fov_circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fov_circle.Radius = cfg.fov
        fov_circle.Visible = cfg.enabled
        fov_circle.Color = get_target() and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
    end)

    -- bind de ContextAction no início pra pegar o input antes do jogo
    CAS:BindAction("KVGD_SnapFire", on_fire, false,
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2,
        Enum.KeyCode.E
    )

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.End then
            cfg.enabled = not cfg.enabled
            Core.save()
            print("[AIM] " .. tostring(cfg.enabled))
        end
    end)

    getgenv().AimFOV = function(v) cfg.fov = v; Core.save(); print("[AIM] FOV = " .. v) end
    getgenv().AimPart = function(v) cfg.hit_part = v; Core.save(); print("[AIM] hit = " .. v) end

    print("[AIM] carregado — End toggle | snap no disparo")
end

print("[AIM] módulo definido")-- language: Lua, file: silent_aim.lua
-- silent aim via camera snap. gira a câmera pro alvo no instante do disparo,
-- servidor recebe a direção nova, câmera volta ao normal depois.
-- End toggle.

getgenv().KVGD_silent_aim = function(Core)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local CAS = game:GetService("ContextActionService")
    local Camera = workspace.CurrentCamera
    local LP = Players.LocalPlayer
    local cfg = Core.config.silent

    local fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 1
    fov_circle.NumSides = 64
    fov_circle.Transparency = 0.5
    fov_circle.Filled = false

    local saved_cframe = nil
    local snap_active = false

    local function is_teammate(player)
        if not cfg.team_check or player == LP then return true end
        local my_team = LP.Team
        local their_team = player.Team
        return my_team and their_team and my_team == their_team
    end

    local function get_target()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local best, best_d = nil, cfg.fov
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not is_teammate(p) then
                local char = p.Character
                local part = char and (char:FindFirstChild(cfg.hit_part) or char:FindFirstChild("Head"))
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < best_d then best, best_d = part, d end
                    end
                end
            end
        end
        return best
    end

    -- handler de disparo: roda ANTES do handler do jogo
    local function on_fire(_, state)
        if state ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end
        if not cfg.enabled then
            return Enum.ContextActionResult.Pass
        end
        local t = get_target()
        if not t then
            return Enum.ContextActionResult.Pass
        end

        -- guarda a câmera atual
        saved_cframe = Camera.CFrame
        snap_active = true

        -- gira pro inimigo
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
        -- também ajusta o mouse look do Humanoid se existir
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = false
        end

        return Enum.ContextActionResult.Pass
    end

    -- devolve a câmera no próximo frame
    RunService.RenderStepped:Connect(function()
        if snap_active and saved_cframe then
            Camera.CFrame = saved_cframe
            saved_cframe = nil
            snap_active = false
        end

        fov_circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fov_circle.Radius = cfg.fov
        fov_circle.Visible = cfg.enabled
        fov_circle.Color = get_target() and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
    end)

    -- bind de ContextAction no início pra pegar o input antes do jogo
    CAS:BindAction("KVGD_SnapFire", on_fire, false,
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2,
        Enum.KeyCode.E
    )

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.End then
            cfg.enabled = not cfg.enabled
            Core.save()
            print("[AIM] " .. tostring(cfg.enabled))
        end
    end)

    getgenv().AimFOV = function(v) cfg.fov = v; Core.save(); print("[AIM] FOV = " .. v) end
    getgenv().AimPart = function(v) cfg.hit_part = v; Core.save(); print("[AIM] hit = " .. v) end

    print("[AIM] carregado — End toggle | snap no disparo")
end

print("[AIM] módulo definido")
