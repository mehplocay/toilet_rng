Task: STRONGER REBIRTH REWARDS (branch feature/rebirthvalues, this worktree; do not commit).

Read AGENTS.md, docs/audit.md, docs/audit2.md, docs/design/economy-v2.md, docs/design/rebirth.md, docs/design/upgrades.md, docs/design/monetization.md, docs/monetization-catalog.md, docs/design/merge-permanent-validation.md and the relevant src. Rule 12 applies. English only, quality first, audit-grade rigor: extend the scripts/check-audit.ps1 harness; keep stylua, rojo build -o build.rbxl, all scripts/check-*.luau, scripts/balance.luau, check-audit.ps1, check-ui.ps1, check-visuals.ps1 and check-world.ps1 passing (baseline is 184 audit scenarios). Another session runs in parallel in its own worktree (feature/catalog2: monetization): keep shared-file edits minimal and additive. Short honest final report.

OWNER FEEDBACK: the Rebirth window showed REBIRTH 15/15 with only Permanent +160% cash, +30% luck, +20% speed. That is far too weak for about 96 hours of play.

Retune ONLY the rebirth reward tables/config (and the Rebirth window text), keeping the pacing (first rebirth about 24 min, R5 about 2 h, R15 about 96 h, Galaxy about 36 min), toilets/upgrades/display persistent through rebirth, the 10x total luck cap with diminishing returns for rare items, and the speed floors intact.

New targets (cumulative permanent bonuses; luck stays inside the cap; speed inside the floor):
- Rebirth 1: cash +50%, luck +5%, speed +3%.
- Rebirth 5: cash +300%, luck +25%, speed +10%, and FREE Auto Collect (same behaviour as the Auto Collect pass, free unlock).
- Rebirth 10: cash +800%, luck +60%, speed +25%, and +2 display slots (within plot capacity).
- Rebirth 15: cash +1500% (x16), luck +100%, speed +50%, exclusive Legend toilet skin (cosmetic aura and golden glow, no stat change beyond the above), golden title and aura.
- Front-loaded jumps in the first five rebirths; every second rebirth an extra visible perk (title, trail colour, plot sign trim, chat tag) from a cosmetics list in config.
- Use an explicit 15-row table in config.

Stacking: cash bonuses stack ADDITIVELY with Cash Boost upgrade levels and MULTIPLY with toilet display multipliers as in economy-v2 (document the rule) and must not break the catalog multiplier cap (Double Cash and VIP).

UI: update the Rebirth window to show current permanent bonuses, the next level's bonus preview and the perks list; show the new numbers on the rebirth stairs signs.

Proof: re-run scripts/balance.luau and rebirth simulations for casual, normal and grinder archetypes and show: pacing targets still hold, late-game income stays inside ledger caps (9e15 safe numbers), no overflow with Double Cash and VIP and R15 simultaneously. Update docs/design/rebirth.md and economy-v2.md. Add tests (bonus table lookup, stacking, caps, migration of existing rebirth levels which keep their level but receive the new bonuses).
