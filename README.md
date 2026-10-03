# kvgd

suite modular para **Knife VS Gun DUELS** (place 120700541929930).

## módulos

| arquivo | função | toggle |
|---------|--------|--------|
| `core.lua` | config + helpers | — |
| `esp.lua` | tracers + distância | Delete |
| `silent_aim.lua` | silent aim (mouse) + prioriza CurrentDuel | End |
| `hitbox.lua` | expand hitbox | H |
| `kill_aura.lua` | auto ataque (ShootGun / KnifeThrow / etc) | K |
| `loader.lua` | entry point | — |

## uso

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/fyn010/kvgd/main/loader.lua"))()
```

## helpers

```lua
ESPColor("enemy", 255, 0, 0)
AimFOV(180)
AimPart("Head")
HitboxToggle(true)
HitboxSize(10)
AuraToggle(true)
AuraRange(250)
AuraCooldown(0.35)
AuraRefresh()
```

## notas (Knife VS Gun DUELS)

- silent aim e kill aura priorizam oponente com o mesmo `CurrentDuel`
- kill aura escuta click, R2 e **E** (throw knife)
- remotes: ShootGun, KnifeStab, KnifeThrow, ReplicateShot, GiveRodaShot + busca por nome parcial
- config em `kvgd_config.json`
