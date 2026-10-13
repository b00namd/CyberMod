# Another Castle

Cyberpunk-2077-Questmod (Parodie auf „die Prinzessin aus der Burg retten“). Story: siehe [STORY.md](STORY.md).

## Voraussetzungen

Spielversion 2.31 und diese Frameworks (jeweils aktuelle Version von Nexus Mods):

- [RED4ext](https://www.nexusmods.com/cyberpunk2077/mods/2380)
- [redscript](https://www.nexusmods.com/cyberpunk2077/mods/1511)
- [Cyber Engine Tweaks](https://www.nexusmods.com/cyberpunk2077/mods/107)
- [Codeware](https://www.nexusmods.com/cyberpunk2077/mods/7780)
- [TweakXL](https://www.nexusmods.com/cyberpunk2077/mods/4197)
- [ArchiveXL](https://www.nexusmods.com/cyberpunk2077/mods/4198)

## Aufbau

`src/` bildet die Ordnerstruktur des Spielverzeichnisses nach:

- `src/bin/x64/plugins/cyber_engine_tweaks/mods/AnotherCastle/` – Quest-Logik (CET/Lua), Entwickler-Fenster im CET-Overlay
- `src/r6/scripts/AnotherCastle/` – redscript (Texte Deutsch/Englisch über Codeware)
- `src/r6/tweaks/AnotherCastle/` – TweakXL (eigene NPC-Einträge, Items, Gegner-Werte)
- `src/archive/pc/mod/AnotherCastle.archive` – Spieldateien (z.B. Lucas Aussehen), wird mit `build.ps1` gebaut
- `assets/` – Quellen der Spieldateien als WolvenKit-JSON
- `tools/make-luca.js` – erzeugt Lucas Aussehen (`assets/.../luca.app/.ent`) aus Original-Spieldateien

## Werkzeuge

Liegen außerhalb von Nextcloud unter `%LOCALAPPDATA%\AnotherCastle-tools`:
WolvenKit.CLI (Spieldateien entpacken, umwandeln, packen), eine lokale .NET-10-Runtime dafür und `redscript-cli.exe` (Skripte vorab prüfen).

Lua-Änderungen lassen sich im Spiel über CET „Reload all mods“ neu laden. Änderungen an `.reds`-Dateien brauchen einen Neustart des Spiels.
Im Spiel festgelegte Orte landen in `positions.txt` im CET-Mod-Ordner und bleiben beim Deploy erhalten.

## Entwickeln

```powershell
.\build.ps1             # assets\ -> AnotherCastle.archive (nach Änderungen an Spieldateien)
.\deploy.ps1            # Mod ins Spiel kopieren
.\deploy.ps1 -Remove    # Mod aus dem Spiel entfernen
.\deploy.ps1 -Package   # ZIP für Nexus nach dist\
```

Logs bei Problemen: `r6\logs\redscript_rCURRENT.log`, `red4ext\logs\`.
