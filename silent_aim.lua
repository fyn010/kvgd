-- language: Lua, file: silent_aim.lua
-- silent aim via snap de câmera E corpo no instante do disparo.
-- funciona com ou sem shift lock. End toggle.

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

    local saved_cam = nil
    local saved_hrp = nil
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

    -- gira câmera E corpo pro alvo. guarda os CFrames originais.
    local function snap_to(target)
        saved_cam = Camera.CFrame

        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hrp then
            saved_hrp = hrp.CFrame
            -- gira o corpo pro alvo (mesma direção da câmera)
            local look = CFrame.new(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z))
            hrp.CFrame = look
        end

        if hum then
            hum.AutoRotate = false
        end

        -- câmera por cima do corpo
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)

        snap_active = true
    end

    local function restore()
        if saved_cam then
            Camera.CFrame = saved_cam
            saved_cam = nil
        end
        if saved_hrp then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = saved_hrp end
            saved_hrp = nil
        end
        snap_active = false
    end

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
        snap_to(t)
        return Enum.ContextActionResult.Pass
    end

    RunService.RenderStepped:Connect(function()
        -- devolve tudo no próximo frame
        if snap_active then restore() end

        fov_circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fov_circle.Radius = cfg.fov
        fov_circle.Visible = cfg.enabled
        fov_circle.Color = get_target() and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
    end)

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

    print("[AIM] carregado — End toggle | snap câmera+corpo")
end

print("[AIM] módulo definido")
