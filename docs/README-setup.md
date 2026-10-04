# Toilet RNG setup

Install Rojo, StyLua and the Luau CLI. Run `rojo serve` from the project folder,
open Roblox Studio and connect the Rojo plugin to the local server. Alternatively,
run `rojo build -o build.rbxl` and open the generated place in Studio.

Publish a test experience with File > Publish to Roblox. In Game Settings >
Security, enable Studio Access to API Services to test DataStore persistence.
Use a separate test experience to avoid editing production player data. Set the
maximum player count to ten, matching the configured plot count. Test with
Studio's multiplayer server mode before publishing updates through File >
Publish to Roblox. Configure experience access and supported devices in the
Creator Dashboard and check the HUD on mobile.

Edit `src/shared/Config/Items.luau` for item odds (Chance is the denominator),
values and event flags. Edit `Toilets.luau` for prices, cooldowns, luck and unlock
pools. Pools are cumulative. Rolls check rarest first independently with luck;
Poop always supplies the fallback. Displayed odds are base odds.

`Events.luau` controls server luck duration, multiplier, visual cooldown and
tints. Event luck refreshes to five minutes without stacking. During the visual
cooldown, another event refreshes luck immediately and queues its announcement.
Personal and server luck multiply toilet luck. Auto Flush requires ownership
and still requires the player to stay near their toilet.

Sound hooks live in `Assets.luau`; empty strings play nothing. `Monetization.luau`
has zero IDs and makes no ownership requests until valid IDs are configured.
VIP Toilet, extra slots and the developer product are configuration stubs only;
there is no receipt handler or purchase flow. Do not sell the product until a
durable, idempotent receipt handler has been implemented.

Checks: `stylua --check src scripts`, `rojo build -o build.rbxl`,
`luau scripts/check-foundation.luau`, `luau scripts/check-display.luau`,
`luau scripts/simulate.luau`. Studio verification is needed for multiplayer
events, camera shake, particles, lighting, sound, ownership and DataStore saves.
