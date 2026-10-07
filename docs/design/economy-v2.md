# Economy v2: uncapped cash progression

Current contract (2026-10-07): [uncapped cash balance report](no-cash-cap.md), [numeric research](../research/uncapped-cash-numerics.md). Earlier dated balance reports are historical evidence, not active multiplier limits.

Cash = (1 + CashBoostEffect) * (1 + RebirthCash) * displayToiletFactor * every owned paid cash factor.

There is no free, paid, combined or rebirth cash multiplier cap. Display factor is 1 for service/sales. Milestone titles add no numerical bonus. L100 Cash Boost is 4.25x; R15 is 16x; together they give 68x free service/sales, or 204x with Double Cash and VIP. The current two paid factors happen to produce 3x; future cash passes continue multiplying. Ultimate Bundle grants entitlements once and does not multiply already-owned passes again.

Galaxy displays multiply by 13 and Infinity Flush by 325. At maximum progression, Infinity Flush is 22,100x free / 66,300x with all passes. Ten Secrets earn 22.1B/s free / 66.3B/s paid. The existing nominal slot/player base-rate limits remain (ten maximum-rarity slots; legacy 100-slot displays share that capacity). These limits scale with the entire cash stack.

Ordinary daily coins retain their paid-only rule. Starter/stamp/admin grants remain unboosted. Sale/service awards floor once per copy/award. Collection and quoted product/VIP chest credits never multiply a second time. Coin-pack/chest quote amounts retain their separate 100 to 1B product bounds; these are not cash multiplier caps.

Rebirth retains toilets, upgrades, capacity and exact displayed items, lifetime index, passes, cosmetics and settings. Wallet resets to starter coins; loose inventory, pending income and fresh flush count reset. Eligibility requires configured wallet coins and 300 fresh successful flushes. R5 free Auto Collect, R10 two free slots and R15 cosmetics are unchanged.

Normal pacing acceptance remains Dirty ~1.5min, Golden ~3min, Diamond ~6min, Radioactive ~12min, Demon ~20min, Galaxy 35-38min; R1 23-25min, R5 2-2.2h, R10 25-40h, R15 90-100h. Only late toilet/upgrade prices and rebirth coin requirements are retuned in Config. Cash effects, rarity rates, service awards, luck cap 10x, path speed cap 5x and cooldown floor 0.4s remain unchanged. Cash Boost and rebirth are now multiplicative, as required by the owner.

The ledger retains 6000 integer subcoins/Coin and a 9e15-subcoin ceiling (1.5T Coins). Wallet and lifetime Earned each retain 9e15 Coins. Products are bounded before multiplication; display rates sum base weights before multiplication and apportion within the technical total. Finite multiplier representation saturates only at the largest finite double. NaN/infinity are rejected. Fractional accumulation, corrected division and last-subcoin save/collect behavior are unchanged. Oversized sale batches fail atomically without consuming copies; a saturated single award can reach the technical ceiling but cannot wrap it.

At the theoretical maximum paid display rate the global storage fills in about 22.62 seconds (free 67.87 seconds). Actual per-slot/tank limits and collection cadence can bind earlier. These technical limits are not a promise of hours of storage at arbitrary income rates. Compact labels use K/M/B/T/Qa/Qi/Sx/Sp/Oc/No/Dc, then scientific notation.

Reproduce with luau --codegen -O2 scripts/balance.luau, scripts/wave1-balance.luau, scripts/rebirth-values-simulations.luau and scripts/no-cash-cap-payer.luau. The plain CLI runs the same rules without native acceleration. Short cohorts use 200 seeds, long cohorts 64, a 300h horizon and seeded replay. Casual/normal/grinder mean 30/75/100% flush uptime; displays earn continuously online. Buying policy and batching are documented in the scripts. All-pass cohorts include Fast Flush and Auto Collect from account creation; no coin packs, daily/events or offline grants. Native Studio/device/backend behavior is outside these headless checks.
