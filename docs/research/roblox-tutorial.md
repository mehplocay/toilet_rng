# New-player tutorial

Checked 2026-10-05 against current Creator Hub documentation and DevForum.

- Beams join two attachments. `FaceCamera` makes the flat beam visible from
  different viewing angles. Both endpoints are local attachments on the character
  root and the owned toilet prompt's BasePart. Recreate them after respawn or
  toilet replacement; destroy them on Skip/completion. No texture asset is needed.
  https://create.roblox.com/docs/reference/engine/classes/Beam
- DevForum describes the same character-to-target attachment guide. A later
  report concerns animated beam textures; this guide uses an untextured beam.
  https://devforum.roblox.com/t/line-guide-thingy/2271479
  https://devforum.roblox.com/t/beam-not-moving-when-created-with-a-script/3884158
- `GuiButton.Activated` supports mouse, touch and gamepad. Skip uses the existing
  component helper, a 44-pixel-high touch target and no modal input capture.
  `ScreenInsets.CoreUISafeInsets` respects the top bar and device cutouts.
  https://create.roblox.com/docs/reference/engine/classes/GuiButton/Activated
  https://create.roblox.com/docs/reference/engine/classes/ScreenGui
- `MaxActivationDistance` defines prompt proximity. The client uses it only to
  switch the walking instruction to the flush instruction. Actual flush results,
  sells and purchases remain authoritative server outcomes.
  https://create.roblox.com/docs/reference/engine/classes/ProximityPrompt
- Remote inputs need validation and server rate limits. `TutorialDone()` accepts
  no arguments, checks the loaded profile, and only sets an idempotent dismissal
  preference. It does not award items, coins or upgrades. The existing profile
  save pipeline persists it, and State echoes the flag. Missing/invalid saved
  values sanitize to false; only boolean true survives.
  https://create.roblox.com/docs/scripting/security/client-server-boundary
  https://create.roblox.com/docs/scripting/events/remote

## Studio review still required

- Fresh profile: own-toilet beam, proximity step, successful flush, failed/successful
  sell, insufficient coins hint, successful first upgrade, four-second farewell.
- Skip at every step, rejoin after save, and completed-profile suppression.
- Respawn before first flush, delayed plot replication, two players with separate
  owned-toilet hints, and small touch screens with Collection/Upgrades open.
- Old profiles missing the flag start at step one; an existing tier above Basic
  satisfies the first-upgrade step after a successful sell. Intermediate tutorial
  steps restart on rejoin until completion or Skip; only completion is persisted.
