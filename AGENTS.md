# Regeln für Codex (Entwickler) – Toilet RNG

Du bist der Entwickler. Der Manager (Claude) vergibt Aufgaben und reviewt deine Arbeit.

1. Lies zuerst `docs/GDD.md` und schau dir `docs/reference/mockups.png` an. Das ist die Spezifikation.
2. Arbeite nur an der gestellten Aufgabe, nichts Zusätzliches. Unklarheiten: sinnvolle Annahme treffen und im Abschlussbericht nennen.
3. Immer auf dem zugewiesenen Branch arbeiten, nie direkt auf `main`. Kleine, klare Commits.
4. Stack: Luau + Rojo (`default.project.json`). Nach Änderungen muss `rojo build -o build.rbxl` fehlerfrei laufen. Wenn `selene`/`stylua` verfügbar sind, nutzen.
5. Server-autoritativ: RNG/Coins/Käufe nie auf dem Client. Remotes validieren und rate-limiten.
6. Alles Datengetriebene (Items, Toiletten, Rarities, Preise) in `src/shared/Config/`.
7. Keine erfundenen Roblox-Asset-IDs. Platzhalter aus Parts/Text; IDs zentral in `src/shared/Config/Assets.luau`.
8. Abschlussbericht (kurz): was gebaut, welche Dateien, wie getestet, bekannte Lücken/Annahmen.
9. Nicht pushen – das macht der Manager nach dem Review.
10. **Sprache: Das gesamte Spiel ist ENGLISCH** (UI-Texte, Item-/Toiletten-Namen, Meldungen, Shop-Texte, Code-Kommentare, Commit-Messages). Die deutschen Texte in der GDD/dem Mockup (z. B. "Bessere Toiletten = neue Drops + hoehere Chancen!") sind nur Doku und muessen im Spiel auf Englisch stehen ("Better toilets = new drops + higher odds!").
11. Drop-Logik: Jeder Flush liefert IMMER ein Item. Wuerfle von selten nach haeufig (jede Chance 1/X unabhaengig, mit Luck), Poop ist der Fallback. Kein "kein Drop".
12. **Web research is mandatory for Roblox-related work.** Before using an API, check the current official sources instead of relying on training knowledge, because Roblox changes quickly:
    - Roblox Creator Docs (create.roblox.com/docs), Engine API reference, Luau reference
    - Roblox DevForum (devforum.roblox.com) for bugs, workarounds and best practices
    - Release notes / platform changes before relying on API behavior
    - Docs and issues of tools we use (Rojo, StyLua, Selene, MCP servers)
    Write important findings with their source URL to `docs/research/` (one short file per topic) so sessions do not repeat research. Never put secrets into web requests.
13. Git: work on your own branch per task and commit in small steps with clear English messages. If git is writable in your sandbox, commit; otherwise leave changes uncommitted and say so. The manager reviews, merges and pushes.
