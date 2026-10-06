# Income-first economy: numeric and persistence review

Checked 2026-10-06. No secrets or player data were sent in research requests.

- Luau numbers are IEEE-754 doubles; exact integers stop at 2^53. Keep wallet and Earned at 9e15, and separately bound the entire 6,000-subcoin ledger at 9e15 units. Never scale a 9e15-coin ceiling by 6,000. Division near the ceiling needs a multiply-back correction before collection. Source: https://luau.org/syntax/#number-literals
- DataStore calls can fail; UpdateAsync transforms cannot yield and returning nil cancels a write. Existing session ownership, immutable snapshots, retry and fail-closed collection remain. Source: https://create.roblox.com/docs/cloud-services/data-stores ; API signature: https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore
- Roblox staff's player-data guidance stresses ordering operations/retries per key. The existing save guard and atomic pending/wallet snapshot remain essential when awards reach billions. Source: https://devforum.roblox.com/t/implementing-player-data-and-purchasing-systems/2839941
- Platform-change check: consulted the release-note listing and indexed 709 thread. The direct thread returned a JavaScript challenge; search activity dates are not release dates. This does not establish exhaustive latest-release coverage. No new engine API or changed backend behavior is assumed. Sources: https://devforum.roblox.com/c/updates/release-notes/62/l/latest?no_subcategories=false&page=1 ; https://devforum.roblox.com/t/release-notes-for-709/4407584
- Tool references: Rojo's official project template uses build -o; StyLua documents --check and line-ending configuration. Selene needs the configured standard library. Sources: https://github.com/rojo-rbx/rojo/blob/master/assets/project-templates/place/README.md ; https://github.com/JohnnyMorganz/StyLua ; https://github.com/kampfkarren/selene/blob/main/docs/src/usage/std.md

The precision, cap and retry conclusions are implementation decisions tested locally, not claims that headless mocks establish live DataStore durability. Selene 0.31.0 is installed but cannot load this workspace's missing roblox standard library.
