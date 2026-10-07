# Tutorial repair review

Branch: `fix/tutorial2`. No commit or push. The owner's exact published-test symptom
cannot be identified without its profile state/output; these are reproduced code
failures, not a claim that the owner's account hit every one of them.

## Confirmed causes

- The tutorial reused the five-second HUD hint. Repeated snapshots with the same
  message did not renew it. Baseline harness: visible on fresh State, invisible six
  seconds later.
- Opening Index, Upgrades, Settings or Passes hid the HUD parent, including the
  tutorial, Skip and navigation highlight.
- First copies cannot be sold, but Display did not advance the collection step.
  Buying a coin upgrade also did not advance the toilet-only upgrade goal. The
  current first toilet costs 7,500 coins; an entry coin upgrade costs 400.
- Only TutorialDone persisted. Intermediate progress restarted on rejoin; completed
  or previously skipped Studio profiles stayed silent with no replay/reset control.
- The flush step had no explicit highlight, and action highlights did not follow
  the buttons inside modal windows. Admin forced-drop Results could count as a flush.
- The old runtime test explicitly expected an expired tutorial to remain invisible.

## Result

The safe-area root owns the persistent guide. Modal windows reserve its banner space.
Reveals/toasts leave a compact Skip control and restore instructions afterward.
Highlights follow Home, FLUSH, Display/Sell, Coin Upgrades, and an affordable purchase;
nested scrolling reveals the action while retaining its price where possible.
Empty inventory and unaffordable upgrades point toward an exit or another flush.

TutorialStep and TutorialRun sanitize and persist with the existing profile pipeline.
Only actual server awards/placements/sales/purchases advance progress. Display removal,
failed actions, admin previews, Rebirth, purchases of passes, and Auto Collect do not.
Natural auto flush anywhere does count. Existing permanent upgrades satisfy the last
goal after a replaying/returning player uses their collection. No rebirth or paid
purchase is required; the farewell explains the single-click rebirth and optional passes.

Settings has **Replay tutorial**. The private owner panel has **Reset my tutorial**,
validated through its existing sender, owner authorization, argument rules, mutation
limit and guarded save. Both keep coins, inventory, toilets and upgrades; confirmation reveals the guide.
Skip retries a rejected dismissal; replay has a bounded pending state and can be retried.

Main files: `src/client/UI/Tutorial.luau`, `src/shared/TutorialProgress.luau`, HUD,
Collection/Upgrades/UpgradeTracks/Components, both bootstraps, DataService, FlushService,
EconomyService, DisplayService, UpgradeService, admin Rules/Mutations/Window, and Remotes.
Passes, CommerceService, item/toilet/economy configs and asset IDs are untouched.

## Validation and remaining limits

- StyLua with Windows line endings; `rojo build -o build.rbxl`.
- All standalone `scripts/check-*.luau`; bundled check-audit/check-ui runtime checks.
- Audit: 336 passing cases, including actual server handlers, malformed input,
  rate limits, every checkpoint save/rejoin, skip/replay, rebirth retention, owner reset,
  12 viewports, modal scrolling, reveal recovery and bootstrap Settings wiring.
- Full UI runtime/layout suite; visual checks; all six world mesh modes.
- Twelve tutorial layouts rendered offline; phone, short landscape and desktop
  reviewed directly. This is a UI-tree/raster approximation, not Studio rendering.
- Selene attempted, but this installed build lacks the Roblox standard library and
  generation support. See `tutorial2-runtime.md` for research and sources.

Still requires a published Studio/device smoke test. A stale deployment/server, an
unrelated bootstrap exception, failed profile loading/saving or session lease, and
delayed plot/prompt streaming can still prevent gameplay/onboarding. Studio's existing
NoPersistence fallback cannot retain progress between sessions. Saved TutorialDone
remains intentionally hidden until replay/reset. Home/FLUSH instruction switches on
local proximity; the saved checkpoint advances only when the server actually awards a flush.
