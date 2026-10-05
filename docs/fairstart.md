# Fair start

Each accepted flush grants one real RNG item and the toilet's fixed `ServiceCoins`
award: Basic 1, Dirty 3, Golden 7, Diamond 15, Radioactive 30, Demon 65, Galaxy 140.
Awards update `Coins` and `Stats.Earned` on the server before visual effects/results.
The existing validated flush path covers the remote, proximity prompt and Auto-Flush.
The Flush result adds `ServiceCoins`; the client shows a gold `+N Coins` label that
rises and fades for 0.9 seconds. Wallet display still comes from State snapshots.

No profile migration, new remote or changes to sale values/prices are needed.
Normal profile autosave persists awards with the existing crash/durability limits.
At the existing 9e15 coin/accounting limit, reject the flush before awarding an
item or advancing its cooldown rather than grant a partial service amount.

## Balance evidence

Run `luau scripts/balance.luau`. Legacy sale-only targets remain within 2% of
1 / 4 / 10 / 25 / 60 / 120 minutes at 100% cooldown uptime. The new combined
model and seeded 2,000-player cohort use 75% uptime, no tutorial/daily income,
no boosts, no rebirth and no visit/sale/UI overhead beyond the uptime allowance.
Every flush conservatively charges a full cooldown, including the first flush.
These are simulation assumptions, not measured player timings.

The normal cohort sells every drop and retains wallet carryover after sequential
purchases. The guaranteed bounds start each stage with an empty wallet, so real
carryover can only shorten them. Poop currently sells for 5 Coins; the older
proposal's 1-Coin examples are not the shipped sale balance.

| Upgrade | Stage median | Stage p90 | Cumulative median | Cumulative p90 | Poop-only stage bound | No-sales stage bound |
|---|---:|---:|---:|---:|---:|---:|
| Dirty | 1.40 | 1.80 | 1.40 | 1.80 | 2.13 | 12.67 |
| Golden | 4.48 | 5.54 | 5.75 | 6.95 | 7.59 | 20.16 |
| Diamond | 9.36 | 10.92 | 14.89 | 17.09 | 14.79 | 25.36 |
| Radioactive | 17.87 | 20.05 | 32.44 | 35.90 | 25.60 | 34.13 |

All values are active minutes at 75% uptime. Dirty median meets the <=2-minute
task target without a tutorial reward. With only fallback Poop sales, the first
four upgrades take at most 50.12 minutes cumulatively. Keeping every item still
reaches all four with service Coins alone in at most 92.32 minutes. No rare drop
or sale is a prerequisite. The bounds use `ceil(price / income per flush)`.

`scripts/check-fairstart.luau` checks fixed tier awards, luck independence,
accounting, configuration/overflow rejection and the four-upgrade no-sales route.
Rojo build, changed-file StyLua check, balance and all `scripts/check-*.luau`
pass. Selene cannot run because its Roblox standard library is unavailable.
Studio QA remains: prompt/button/Auto-Flush credit exactly once, rejected requests
credit nothing, popup visibility/cleanup on desktop and touch, latency, and
save/rejoin persistence.
