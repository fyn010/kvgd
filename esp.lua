-- language: Lua, file: esp.lua
-- ESP com tracer, distância, team check. RightShift toggle.

getgenv().KVGD_esp = function(Core)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local LP = Players.LocalPlayer
    local cfg = Core.config.esp

    local tracked = {}

    local function is_teammate(player)
        if player == LP then return false end
        local my_team = LP.Team
        local their_team = player.Team
        return my_team and their_team and my_team == their_team
    end

    local function add(player)
        if player == LP or tracked[player] then return end
        local tracer = Drawing.new("Line")
        tracer.Thickness = cfg.tracer_thickness
        tracer.Transparency = 1
        tracer.Visible = false

        local dist_text = Drawing.new("Text")
        dist_text.Size = 13
        dist_text.Center = true
        dist_text.Outline = true
        dist_text.OutlineColor = Color3.new(0, 0, 0)
        dist_text.Visible = false

        tracked[player] = { tracer = tracer, dist = dist_text }
    end

    local function remove(player)
        local t = tracked[player]
        if t then
            pcall(function() t.tracer:Remove() end)
            pcall(function() t.dist:Remove() end)
            tracked[player] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do add(p) end
    Players.PlayerAdded:Connect(add)
    Players.PlayerRemoving:Connect(remove)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            cfg.enabled = not cfg.enabled
            Core.save()
            print("[ESP] " .. tostring(cfg.enabled))
        end
    end)

    RunService.RenderStepped:Connect(function()
        for player, t in pairs(tracked) do
            if not cfg.enabled then
                t.tracer.Visible = false
                t.dist.Visible = false
            else
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local pos, on_screen = Camera:WorldToViewportPoint(hrp.Position)
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

                    if on_screen and dist <= cfg.max_distance then
                        local color = is_teammate(player)
                            and Color3.fromRGB(table.unpack(cfg.team_color))
                            or Color3.fromRGB(table.unpack(cfg.enemy_color))

                        t.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        t.tracer.To = Vector2.new(pos.X, pos.Y)
                        t.tracer.Color = color
                        t.tracer.Visible = true

                        if cfg.show_distance then
                            t.dist.Text = string.format("%d", math.floor(dist))
                            t.dist.Position = Vector2.new(pos.X, pos.Y + 18)
                            t.dist.Color = Color3.fromRGB(table.unpack(cfg.distance_color))
                            t.dist.Visible = true
                        else
                            t.dist.Visible = false
                        end
                    else
                        t.tracer.Visible = false
                        t.dist.Visible = false
                    end
                else
                    t.tracer.Visible = false
                    t.dist.Visible = false
                end
            end
        end
    end)

    getgenv().ESPColor = function(which, r, g, b)
        local key = which .. "_color"
        if cfg[key] then
            cfg[key] = {r, g, b}
            Core.save()
            print("[ESP] " .. key .. " = " .. r .. "," .. g .. "," .. b)
        end
    end

    print("[ESP] carregado — RightShift toggle")
end

print("[ESP] módulo definido")
