Aufgabe 1 – Fundament (Branch feature/foundation). Lies AGENTS.md und docs/GDD.md.

Baue das Rojo-Grundgerüst plus den serverseitigen Kern, noch OHNE UI:
1. default.project.json (Rojo 7), src/server, src/client, src/shared. rojo build muss laufen.
2. src/shared/Config: Rarities.luau, Items.luau (alle Drops aus der GDD-Tabelle inkl. Chance 1/X, Rarity, Wert, Event-Flag), Toilets.luau (7 Toiletten: Preis, Cooldown, Luck-Multiplikator, Pool-Freischaltung), Assets.luau (Platzhalter).
3. src/server/Services: DataService (DataStore, Retry, Autosave, Leave-Save, Default-Profil), RollService (gewichtetes RNG nach 1/X, Luck, Toilettenpool; pure Funktion), FlushService (Remote "Flush" mit Cooldown + Validierung), EconomyService (Sell, Toilette kaufen, serverseitig validiert).
4. Remotes zentral definiert; Rate-Limit pro Spieler.
5. Simulationsmodul: RollService 1.000.000x, gemessene Häufigkeiten vs. Soll-Chancen ausgeben.
Kleine Commits, am Ende kurzer Abschlussbericht.
