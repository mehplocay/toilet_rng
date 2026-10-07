# Uncapped luck: numeric and paid-odds contract

Checked 2026-10-07; runtime API sources were reviewed before implementation.

- Roblox Creator Docs: https://create.roblox.com/docs/production/monetization/paid-random-items ? disclose every actual outcome and numerical percentage before purchase; final percentages must total 100%. Policy restrictions also cover paid odds modifiers. Keep the itemized Info dialog and refreshed odds token, including VIP, 2x Luck and Lucky Flush.
- PolicyService API: https://create.roblox.com/docs/reference/engine/classes/PolicyService ? GetPolicyInfoForPlayerAsync provides ArePaidRandomItemsRestricted. Existing protected lookup accepts only explicit false and unexpired cache entries; missing/failed/expired results fail closed. No API behavior or regional inference changed.
- Platform announcement: https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183 ? restrictions use the platform policy flag, not a local country list. The current Creator Docs above are authoritative over older forum discussion.
- Luau library: https://luau.org/library/ ? positive finite multipliers are validated before use; NaN fails ordered comparisons and infinity equals math.huge. Multiplication overflow is rejected, never converted to a gameplay cap. Existing math/string APIs suffice; no dependency on newly added finite-check APIs.
- Tool references: https://github.com/rojo-rbx/rojo.space/blob/master/docs/getting-started/new-game.mdx and https://github.com/JohnnyMorganz/StyLua ? build the configured Rojo project; format with --line-endings Windows. https://kampfkarren.github.io/selene/roblox.html covers the Roblox standard library required by the installed linter.

Implementation inference: rare-first independent probability is min(1, totalLuck / denominator); final odds include survival of earlier checks. Removing the multiplier ceiling does not remove the probability bound. UI largest-remainder rounding preserves a 100% displayed total to 12 decimal percentage places; raw subprecision nonzero percentages remain visible, and only actual probability 1 is labeled certain.
