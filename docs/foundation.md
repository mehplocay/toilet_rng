# Foundation and UI/world

The server builds the plaza and ten plots on startup. Slots are assigned on join
and released on leave. More than ten players are asked to join another server.
All gameplay text is English. Placeholder geometry and colors are configured in
`src/shared/Config/World.luau`; no external asset IDs are supplied.

## Remote contract

Client requests: `Flush()`, `Sell(itemId, integerCount)`, `BuyToilet(toiletId)`,
`Display(itemIdOrNil, integerSlot)`, and `State()` for an initial snapshot.
`Display(nil, slot)` removes a display. Each displayed copy reserves one owned
inventory item against sale. State snapshots contain coins, inventory, lifetime
collection, toilet tier, display capacity and assignments. Successful mutations
send a snapshot. All request remotes are validated and token-bucket limited.
Flush additionally checks proximity to the assigned plot and the tier cooldown.

`Result(action, payload)` supplies flush drops and operation outcomes.
Teleport uses the replicated own-plot position locally; it has no custom remote.
Shop opens Toilet Upgrades. Sound settings apply only to the current session.

## Probability

Each non-Poop item is checked independently, rarest first, with probability
`min(1, luck / X)`. Poop is the guaranteed fallback. The simulation reports the
resulting probabilities including the chance that earlier checks failed.
Pools are cumulative: Basic through Fish, Dirty adds Duck, Golden adds Golden
Poop, Diamond adds Toilet Baby, Radioactive adds Sewer Shark and King Poop,
Demon adds Alien Toilet, Galaxy adds Mystery. King Poop is Mythic.
Upgrade cooldowns/luck are provisional. Default display capacity is three.
The hub leaderboard ranks current inventory value, including displayed copies.

## Persistence and validation

DataStore `ToiletRNG_v1` retains coins, inventory, lifetime discoveries, tier,
displays and stats. A 180-second session lease is renewed by 60-second autosaves;
four retry attempts use exponential backoff. Failure stops gameplay. Settings
are not saved. Enable published-place Studio API access to test persistence.

Run `rojo build -o build.rbxl`, `stylua --check src scripts`,
`luau scripts/check-foundation.luau`, `luau scripts/check-display.luau`, and
`luau scripts/simulate.luau`. Selene needs its missing Roblox standard library.
Studio checks remain necessary for multiplayer prompts, layout on mobile,
particles/tweens, teleport replication, sound hooks and DataStore lease behavior.
Server-wide special-drop events remain outside this task.
