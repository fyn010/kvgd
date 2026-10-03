# kvgd

suite modular de scripts de combate para roblox (executor).

## módulos

| arquivo | função | toggle |
|---------|--------|--------|
| `core.lua` | config + helpers | — |
| `esp.lua` | tracers + distância | Delete |
| `silent_aim.lua` | silent aim (mouse) | End |
| `hitbox.lua` | expand hitbox | H |
| `kill_aura.lua` | auto ataque | K |
| `loader.lua` | entry point | — |

## uso

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/fyn010/kvgd/main/loader.lua"))()
```

## helpers runtime

```lua
ESPColor("enemy", 255, 0, 0)
AimFOV(180)
AimPart("Head")
HitboxToggle(true)
HitboxSize(10)
AuraToggle(true)
AuraRange(250)
AuraCooldown(0.4)
```

## notas

- config salva em `kvgd_config.json`
- silent aim usa `mousemoverel` (mais stealth que snap de CFrame)
- hitbox limpa memória com weak table + CharacterRemoving
- kill_aura prioriza `CurrentDuel`, senão proximidade
