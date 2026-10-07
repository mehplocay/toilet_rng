# Auto Collect anywhere

Auto Collect (149 R$ pass, Ultimate Bundle or free Rebirth 5 perk) collects existing pending display coins every five seconds anywhere on the map. It retains the living owner, assigned-plot ownership, session lease and save guards. IncomeAccrual:Collect transfers exactly the manual jar amount, preserving fractions and wallet/earned caps. No client amount, new collection remote, income multiplier or offline earning change was added.

The existing MonetizationService.Activity/PlayerActivity idle clock pauses both automations after 30 minutes without accepted reports. Auto Collect works with Auto Flush off. Input before unlock updates that same clock; toggles, rebirth and respawn preserve it while entitled. The existing Still-there action resumes it. A server-only 1/5s budget and the shared CollectIncome budget bound transfers; no missed ticks are replayed. The existing HUD chip displays collect ON / 5s, WAITING or PAUSED, including idle warnings. Its status cache only publishes transitions on empty ticks and is cleared on leave.

Changed implementation: CommerceService, MonetizationService, HUD and Config/Remotes. Updated copy: Config/Monetization, Config/Shop, Config/Rebirth, monetization catalog and affected design/balance descriptions. Extended both PS1 bundlers with actual-service and HUD regressions; retained the older paid/free guard and ledger tests with unrestricted distance.

Validation: 339 audit scenarios passed; all 23 standalone check-*.luau entrypoints passed (audit/UI runtime use their PS1 harnesses); check-ui.ps1 passed including 972 layout cases; check-visuals.ps1 and check-world.ps1 passed all six template modes. StyLua verification and full Windows-ending check passed; rojo build -o build.rbxl and git diff --check passed. balance.luau (including income-balance.Print), wave1-balance.luau, rebirth-values-simulations.luau, rebirth-balance.Print and simulate.luau passed. Narrow portrait/landscape HUD snapshots were rendered and inspected using the existing headless renderer.

Limitations: no live Studio or published-server playtest was performed. The installed Selene cannot load the configured Roblox standard library and exposes no Roblox generation command; no clean Selene result is claimed. Assumption: living character and assigned owned plot remain required, as for Auto Flush; position is unrestricted. Work remains uncommitted on feature/autocollect-anywhere.

Owner action: edit the Auto Collect pass description in Creator Hub to "Collect display coins every 5 seconds, anywhere on the map."
