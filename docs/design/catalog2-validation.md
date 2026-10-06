# Extended monetization validation

2026-10-06, feature/catalog2. Work remains uncommitted; no push. The authoritative creation list is [monetization-catalog.md](../monetization-catalog.md): 16 passes and 8 developer products. Existing config keys and the enabled Star Tag ID are preserved.

## Delivered files

- Catalog and entitlement math: src/shared/Config/Monetization.luau, Shop.luau, Assets.luau, Remotes.luau; src/shared/PaidBenefits.luau, MonetizationRules.luau and CommerceProfile.luau.
- Server transactions and policy: new src/server/Services/LuckyService.luau and VIPPadService.luau; CommerceService, ReceiptService, FlushService, MonetizationService and server initialization. Lucky consumption, outcome and receipt grants use durable profile transactions. Paid auto-flush saves do not block other players.
- Cosmetics and shop: new src/client/CatalogEffects.luau and UI/LuckyOdds.luau; UI/Passes, UI/IconArt, VIPChat, CosmeticService and client initialization. Admin Runtime/Window expose the sanitized charge counter. default.project.json adds the baseline native TextChatService configuration required by the existing audit.
- Regressions: new scripts/audit-catalog2.luau and ui-catalog2.luau, wired into check-audit.ps1 and check-ui.ps1. Harness doubles and existing commerce/reward/UI expectations updated for the new catalog.
- Documentation: authoritative catalog, historical-design supersession note, this report and docs/research/catalog2-policy.md / catalog2-cosmetics.md. Rebirth reward tables were not edited.

## Executed validation

| Check | Result |
|---|---|
| scripts/check-audit.ps1 | 228 passed, 0 failed (184 baseline plus 44 new cases) |
| All scripts/check-*.luau | Passed: 21 standalone checks; check-audit and check-ui-runtime through their PowerShell bundlers |
| scripts/balance.luau | Balance targets and cohort replay passed |
| scripts/check-ui.ps1 | Passed, including 972 viewport cases and added catalog runtime/layout/cosmetic cases |
| scripts/check-visuals.ps1 | Passed |
| scripts/check-world.ps1 | Passed: Empty, Ready, Mixed, Invalid, Scaled and Late modes |
| stylua --check --line-endings Windows src scripts | Passed |
| rojo build -o build.rbxl | Passed |
| git diff --check on edited source/scripts/catalog/project paths | Passed |
| selene src scripts | Blocked: installed Selene cannot find the configured roblox standard library; no lint pass claimed |

New audit cases cover all eight product replay/double-grant/rejoin paths; pre/post-commit failures and departure during persistence; receipt delivery while policy is loading; restricted/failed/expired policy and policy changes across yields; exact item/rarity odds from the roll distribution at every tier; linear luck across every rarity; stale/malformed review tokens; atomic charge consumption and failed saves; bounded counters and id-zero offers; bundle implications and single slot grants; VIP chest/pad idempotency, cooldown and cap math. Existing chest UTC-day and every-multiplier regressions remain enabled.

UI regressions cover restricted/expired offer hiding, disclosure before prompt/use, tiny percentages, bundle owned states, phone/landscape action visibility, companion lifecycle/budgets, effect preferences and teardown, server cosmetic attributes and native-chat callback properties. Headless phone/desktop previews were rendered and inspected for layout. They are approximations, not native engine certification.

## Assumptions and remaining release work

- VIP pad uses five seconds of display income (10-10,000 coins), a saved five-minute cooldown and eight-stud range. The daily VIP chest uses the existing 600-second display-income reward with a 100-1,000,000,000 clamp. Neither credits a second cash multiplier.
- Lucky counter cap is 1,000. Each charge requires fresh explicit odds review. Eligible automatic flushing waits for that review; restricted players retain charges and can free-flush. Saturated/restricted pending purchases defer without acknowledging an ungranted receipt.
- Dance Pack uses the explicitly permitted four-effect fallback. Chat rainbow takes a hue when a message arrives; overhead rainbow animates continuously. No animation IDs were invented.
- All new IDs remain zero, with Coming soon states and vector icon fallbacks. The separate art session must supply/upload icons. Creator Hub creation/rename, external-sales settings and experience questionnaire remain manual release work. Unquoted external coin receipts use processing-time income; disable external sales for exact advance quotes. Lucky external sales must stay disabled.
- Native Marketplace receipts/prompts, PolicyService behavior, filtered chat rendering, streaming and device performance require Studio/isolated published QA. Retire old servers before enabling the new persistent schema. Existing datastore/lease and external rollback limitations remain.
- Five tracked rebirth-preview PNGs were already inaccessible/reported deleted in this worktree at task start. They were not modified or restored by this task.
- Temporary .catalog-* validation logs and preview directories remain untracked: the execution policy rejected their cleanup command as blocked by policy. They are review artifacts, not game assets.
