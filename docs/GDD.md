# Toilet RNG – Game Design Document (v0.1)

Referenzen: `docs/reference/mockups.png` (UI/Look), `docs/reference/original-idea.txt` (Ursprungsidee).
Ziel: simples, sofort verständliches Roblox-"Slop"-Game mit starkem RNG-Hook, Flex-Faktor und Monetarisierung.

## Core Loop
FLUSH → RNG-Drop → Collect → SELL oder DISPLAY → Toilette upgraden → bessere Drops → repeat

## Features v1 (MVP)
1. **Spawn/Hub**: Platz mit 8–12 Spieler-Plots, Shop-NPC/Bereich, Leaderboard. Spawn-Banner "TOILETS MAKE DREAMS COME TRUE!".
2. **Flush**: Proximity-Prompt/Button "E – FLUSH" an eigener Toilette. Cooldown (Basis 3s, per Upgrade/Boost kürzer). Wackel-/Spül-Animation, Sound, Drop erscheint physisch (Model + Name + Rarity-Label) über der Toilette.
3. **Drop-Tabelle (server-seitig gewürfelt!)**, Rarities: Common, Uncommon, Rare, Epic, Legendary, Mythic, Godly, Secret.
   | Item | Chance | Rarity | Basiswert (Coins) |
   |---|---|---|---|
   | Poop | 1/2 | Common | 1 |
   | Toilet Paper | 1/8 | Uncommon | 3 |
   | Rat | 1/25 | Rare | 10 |
   | Fish | 1/80 | Rare | 25 |
   | Duck | 1/250 | Epic | 80 |
   | Golden Poop | 1/1,000 | Legendary | 300 |
   | Toilet Baby | 1/5,000 | Mythic | 1,500 |
   | Sewer Shark | 1/25,000 | Godly | 8,000 |
   | King Poop | 1/100,000 | Mythic/Godly (Server-Event) | 50,000 |
   | Alien Toilet | 1/1,000,000 | Secret (Server-Event) | 400,000 |
   | ??? | 1/10,000,000 | Secret (Server-Event) | 5,000,000 |
   Alle Werte in einer Config-Datei, leicht änderbar.
4. **Collection UI** ("My Collection"): Kategorien-Filter nach Rarity, Suche, Raster mit Item-Karten, nicht gefundene als Silhouette "???". Zähler pro Item.
5. **Sell / Display**: Item verkaufen (Coins) oder auf einem Display-Sockel im eigenen Plot ausstellen (max. Slots, erweiterbar). Andere sehen Sammlung.
6. **Toilet Upgrades** (Shop): Basic (owned) → Dirty 500 → Golden 5,000 → Diamond 50,000 → Radioactive 250,000 → Demon 1,000,000 → Galaxy 5,000,000. Jede Toilette: eigenes Aussehen, kürzerer Cooldown, Luck-Multiplikator (klein), neue Drops freigeschaltet. Text im Shop: "Bessere Toiletten = neue Drops + höhere Chancen!"
7. **Eigener Plot** mit Namensschild ("<Name>'s Plot"), Toilette, Display-Sockel (Item + 1/X-Label).
8. **Server-Events**: Drops ab 1/100,000 → Server-weite Meldung ("YASAR JUST FLUSHED A 1 IN 100,000 KING POOP"), gelber Himmel/Partikel/Musik-Cue, Server-Luck-Boost (z. B. 2x für 5 Min.).
9. **Leaderboard** "Top Toilets" (Gesamtwert der Sammlung oder Rare-Score).
10. **Persistenz**: DataStore (Coins, Inventar/Collection, Toilettenstufe, Display-Slots, Stats) mit Retry, Session-Lock-light, Autosave.
11. **HUD**: linke Button-Leiste (Shop, Collection, Upgrades, Teleport, Settings), Coins-Anzeige, Rarity-Farben (Common grau, Uncommon grün, Rare blau, Epic lila, Legendary orange/gold, Mythic magenta, Godly rot, Secret schwarz/regenbogen).

## Features v2 (später, nicht jetzt)
Clog/Plunger/Super Flush/Mystery Flush (Coin-Sinks & Multiplayer-Chaos, anti-grief), Auto-Flush & Luck-Gamepasses (2x Luck, Auto Flush, VIP Toilet, Developer Products für Server-Luck), Rebirths, Sewer World, Trading, Daily Rewards, Index-Belohnungen.

## Monetarisierung (Vorbereitung)
Gamepass/Dev-Product-Hooks als Stubs mit klaren Platzhalter-IDs in Config; keine echten IDs hardcoden.

## Technische Leitplanken
- Luau, Rojo-Projekt, Ordnerstruktur `src/server`, `src/client`, `src/shared`.
- **Server-autoritativ**: RNG, Coins, Käufe nur auf dem Server. Client darf nur Requests über RemoteEvents/Functions schicken, mit Validierung + Rate-Limit.
- Items/Toiletten/Rarities rein datengetrieben (Config-Module).
- Keine externen Asset-IDs erfinden; Platzhalter-Modelle aus Parts/Meshes und Emoji/Text-Labels, Asset-IDs zentral in einer `Assets`-Config.
- Sauberer, kommentierter, modularer Code; keine Riesen-Skripte.
