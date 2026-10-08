# Mobile uncapped luck label fit

Checked 2026-10-07 for the mobile HUD / no-luck-cap merge regression.

- [UITextSizeConstraint](https://create.roblox.com/docs/reference/engine/classes/UITextSizeConstraint) constrains TextScaled but does not enlarge a label to fit its minimum. Reserve enough width and height instead of lowering the existing text floor.
- [TextLabel](https://create.roblox.com/docs/reference/engine/classes/TextLabel) supports TextScaled and TextWrapped. Explicit line breaks keep the scientific multiplier intact and separate the phone's friend bonus; the 44 px status button reserves 36 px for two lines at its existing 14 px minimum.
- [DevForum overflow discussion](https://devforum.roblox.com/t/how-do-i-block-a-textlabels-text-going-beyond-the-label/2040613) discusses wrapping/scaling rather than character truncation. Current Creator Docs remain authoritative; no workaround or new API dependency is needed.
- Phone Boosts geometry was zeroed by the compact layout. Keep its hidden luck label measurable inside the status rectangle while the visible status chip replaces it. Desktop chip sizing is restored on resize. Retain the original multiplier assertion and additionally check visible label width/height at the harness's text metrics.
- Existing [safe-area/platform and tool research](mobile-ui-safe-areas.md) applies unchanged: no inset, thumb-zone, Rojo, or StyLua behavior changes.
