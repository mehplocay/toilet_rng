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
