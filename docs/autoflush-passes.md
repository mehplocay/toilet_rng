# Auto-Flush and passes handoff

Implementation on `feature/autoflush`; leave uncommitted for manager review. The task's explicit four-pass catalog overrides the proposal's different three cosmetics and speed restriction. No Lucky Flush or other paid RNG is configured.

## Behavior and integration

- `MonetizationRules` provides the pure unlock/range/cooldown reservation, ownership merge, palette gate and preference migration logic. `check-autoflush.luau` exercises it directly.
- Auto-Flush unlocks at 100 `Stats.Flushes`, starts OFF each session, shares the manual flush award/cooldown path, and turns OFF outside the existing 14-stud toilet range, on death/missing character, or character removal. Returning requires a new toggle. Server polls at 0.1s; scheduling can add up to one tick to the configured cooldown. No automatic reconnect.
- Fast Flush multiplies the tier cooldown by 0.8 for both manual and automatic flushes; no stacking or luck change. New ownership affects the next successful flush, without shortening an already reserved cooldown.
- Free saved `Settings.SkipAnimation` suppresses world wobble/flight/burst and local celebration effects. It retains an instant static physical drop, outcome text and event announcement; cooldowns/awards do not change. Other viewers also see the owner's static drop. It does not disable unrelated world idle animations.
- Cosmetic entitlement ownership stays in server session memory, recovered from Roblox on join and every 120 seconds or via Refresh owned passes. Failed API calls grant nothing and never erase a verified in-session purchase. Only the Roblox server completion event grants immediately; repeated events do not duplicate visuals/rewards. No developer-product receipts are involved.
- Server-created sparkle Trail/emitter and overhead VIP label return after respawn. The chat-window prefix reads only the server-replicated VIPStar attribute and preserves message text and existing prefixes. Plot colors affect lawn/stone borders only; default/unowned/departing owners restore builder colors. Saved `Settings.PlotColor` is a configured palette ID, never entitlement proof.
- Four placeholder pass IDs remain 0 in `Config/Monetization`. Buttons are disabled as Coming soon and show labeled planned prices. When real IDs are configured, the client retrieves the actual platform price and disables buying on metadata failure/off-sale status. BuyPass is allowlisted/rate-limited and prompts only after a server ownership check. Platform ownership recovers purchases completed during disconnect.
- Shared integration changes are additive remote entries (`AnimationSkip`, `PlotColor`, `BuyPass`, `RefreshPasses`), one lifetime-flush snapshot field, a cosmetics refresh hook, the expanded monetization Start arguments, two persisted settings fields, and UI module/navigation hooks. Existing Sound Settings remote payload remains unchanged.

## Verification / Studio checklist

Automated: StyLua on changed Luau files and its check, `rojo build -o build.rbxl`, all `scripts/check-*.luau`, `scripts/check-visuals.ps1` (headless construction/budgets), and `git diff --check`. Selene was attempted but the repository's configured `roblox` standard library is missing.

Studio/published-place tests still required:

1. At 99 flushes Auto-Flush is locked; 100 unlocks. Toggle near own toilet; spam manual requests alongside auto; verify one item/count per cooldown and unchanged odds. Walk beyond 14 studs, die/reset, teleport away, reconnect; confirm OFF and no automatic restart. Verify fastest toilet with Fast Flush runs near 1.44s plus tick delay.
2. Save/reload sound, animation skip, and selected palette without persisting active Auto-Flush. Compare skip/full drops and rare/server events; confirm results remain readable and animation settings do not affect grants.
3. With legitimate configured test passes, test successful/canceled/failed prompts, repeated completion, purchase then disconnect, web purchase then refresh/rejoin, and Marketplace API failure. Confirm idempotent cosmetics, server ownership gating, and no grants from client requests or saved settings alone. Test actual/regional price against Roblox's purchase prompt; IDs 0 must never prompt.
4. Multiplayer: trail/VIP overhead/chat star visible only for legitimate owners; default/team/whisper prefixes and filtering preserved. Verify `OnChatWindowAdded` with current platform-integrated chat and chat permissions before selling this advertised benefit.
5. Owner picks each palette, respawns/upgrades/leaves; next owner/unowned user gets builder default. Check touch UI, horizontal cards, all palette buttons, HUD/navigation, and ten-player rendering/performance.
