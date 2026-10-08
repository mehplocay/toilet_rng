# Toilet RNG – Bericht (Stand 8. Oktober 2026, ca. 07:15)

## Kurzfassung
Das Spiel ist technisch fertig und gepusht (`main`, Commit `6c6bf36`). Alle Prüfungen sind grün. **Nicht erledigt** sind die Hub-Beschreibungen (siehe unten, brauchen deine Zustimmung im Creator Hub) und die Veröffentlichung aus Studio (kann ich nicht).

## Prüfergebnisse (selbst nachgeprüft auf `main`)
- `rojo build`: ok
- Audit-Regressionen: **425 bestanden, 0 fehlgeschlagen**
- UI-Laufzeit-Checks (alle 12 Bildschirmgrößen, 972 Layout-Fälle): bestanden
- Visuals-Check, World-Check (12 Plots, 49.152 Freunde-Fälle): bestanden
- Nicht möglich: Selene (fehlt die Roblox-Standardbibliothek), echter Live-Test in Roblox/Studio, echte Käufe (Billing/DataStore live)

## Was seit gestern dazukam (alles in `main`)
- Social-Text: großer Text-Block entfernt, nur noch kleiner Link „Invite friends for extra luck“ im Passes-Fenster
- Luck-Cap komplett entfernt (nur technische Grenze: endliche Zahlen, Überlauf wird abgelehnt)
- Audit 4: 4 Befunde behoben (Rundungsgewinne, Pending-Inflation, Kauf-Antwortfluten, wachsende API-Wartevorgänge), 17 neue Negativtests
- Handy-HUD: kompakte Leiste, freie Daumenzonen, lesbares FLUSH/AUTO, aufklappbarer Statuschip; extreme Luck-Werte passen jetzt ins Layout
- Visual-Review: 11 UI/UX-Probleme behoben (12 Bildschirmgrößen, 47 Items, 9 Seltenheiten)
- Test-Anpassungen für den entfernten Luck-Cap (Cash/Offline-Tank L100 dürfen 5 % früher fertig sein; sonst keine Balance-Ziele geändert)

## WICHTIG: Hub-Beschreibungen noch ALT (du musst das tun oder mir kurz Bescheid geben)
Im Creator Hub liegt über jeder Seite ein Fenster **„Updated Agreements“** (neue Roblox-Nutzungsbedingungen). Dem stimmst nur du zu. Danach fügst du diese Texte ein (Dashboard > Creations > Toilet RNG > Monetization > Passes / Developer Products > Beschreibung):

Im VIP-Pass steht noch „Total luck capped at 10x“. Das stimmt nicht mehr und muss vor der Veröffentlichung weg.

**VIP (Pass 2013872290):**
1.5x cash, +1 path speed step, +50% offline tank, daily chest, VIP hub pad, gold star, trail and sign trim. +25% luck, a permanent random-item odds boost. Multiplies with other luck sources without a total luck cap. Luck unavailable in restricted regions.

**2x Luck (Pass 2014088425):**
Permanent 2x luck: a random-item odds boost for rare items. Multiplies with other luck sources without a total luck cap. Unavailable in restricted regions. Review Info: all item odds before purchase.

**Ultimate Bundle (Pass 2013272293):**
Includes all 15 other passes: Sparkle Trail, Star Tag, Custom Plot Color, Fast Flush, Double Cash, Auto Collect, Offline Plus, VIP, Rainbow Name, Confetti Reveal, Golden Name, Dance Pack, Toilet Glow, Companion and 2x Luck. Includes permanent random-item odds boosts: VIP +25% luck and 2x Luck. Luck sources multiply without a total luck cap. Luck unavailable in restricted regions. No consumables.

**Lucky Flush (Product 3716998840):**
1 single-use 10x luck charge. Each charge multiplies your current luck by 10 for one flush without a total luck cap. Each item check is at most 100%. Unavailable in restricted regions. Review all item odds before purchase and use.

**Lucky Flush 5-Pack (Product 3716998876):**
5 single-use 10x luck charges. Each charge multiplies your current luck by 10 for one flush without a total luck cap. Each item check is at most 100%. Unavailable in restricted regions. Review all item odds before purchase and use.

**Lucky Flush 20-Pack (Product 3716998923):**
20 single-use 10x luck charges. Each charge multiplies your current luck by 10 for one flush without a total luck cap. Each item check is at most 100%. Unavailable in restricted regions. Review all item odds before purchase and use.

(Quelle der Texte: `docs/design/no-luck-cap.md`, Abschnitt „Exact replacement Creator Hub descriptions“.)

**Erlebnis-Beschreibung (Configure > Settings), Absatz für Social-Boosts ergänzen:**
Join the Dreadlight Studio group for +10% coins, play with friends for +5% coins per friend in your server (up to +55%), and invite friends for a temporary +20% luck boost (30 minutes per qualified invite, up to 5 per day).
(Mein Entwurf nach `docs/design/social-boosts.md`: Gruppe 1,10x, Freunde +5 % je Freund bis +55 %, qualifizierte Einladung 1,20x. Bitte gegenlesen.)

## Was nur du tun kannst
1. **Studio-Test** mit `build.rbxl` (liegt in `C:\Users\mehme\toilet-balance\build.rbxl`): kurz durchspielen (Flush, Rebirth, Shop-Fenster, Handy-Ansicht über den Emulator).
2. **Veröffentlichen** aus Studio (File > Publish to Roblox). Dafür habe ich kein Werkzeug.
3. **Auf Public stellen** (Spiel ist noch Privat). Das ist deine Entscheidung.
4. **Echten Test-Kauf** eines Lucky Flush (Live-Billing ist nicht getestet).
5. Roblox-Zustimmungen im Creator Hub („Updated Agreements“) bestätigen.
6. Detail-Page-Thumbnails im Hub nachladen (nur Home-Thumbnails sind oben).

## Offene Entscheidung
- Speed-Cap 5x ist noch drin. Du hattest „kein Cap“ gesagt, dazu hast du dich noch nicht geäußert. Ich ändere es nur mit deinem Wort.
- Soll die Einladungs-Belohnung (+20 % Coins, 30 Min) stattdessen Luck sein?

## Marketing (du machst das selbst)
- 5 fertige Clips (je 15 s, 1080×1920) liegen in `C:\Users\mehme\toilet-clips\assets\marketing\clips\` (animierte Assets, nicht echtes Gameplay).
- Das Flow-Video (`Downloads\gameplay_clean3_1080p_20261007222002.mp4`) ist von der KI erfunden: andere Welt, falsche Untertitel. Nicht als echtes Gameplay posten.
- Deine Aufnahme zeigt Admin-Reveal und Admin-Panel. Für Werbung nur den sauberen Teil (Flug durch die Welt, ab 1:05) oder eine neue Aufnahme mit normalem Flush verwenden.

## Codex-Verbrauch (Tokens, nach Modell)
- **Astra high:** Audit 4 ca. 508k, Visual-Review ca. 853k, No-Luck-Cap ca. 341k
- **Sol medium:** Handy-HUD ca. 536k, Marketing-Clips ca. 224k, HUD-Fix ca. 90k
- **Luna medium:** Social-Text ca. 174k, Merge Handy-HUD ca. 48k, Merge Visual-Review ca. 461k
- Flow: 2 Generierungen (12 + 20 Punkte)

## Ehrlicher Hinweis zur Nacht
Ich habe nach deinem Schlafengehen aufgehört und erst um 06:09 wieder gearbeitet, weil ich keinen Wecker gesetzt hatte. Seitdem lief alles durchgehend.
