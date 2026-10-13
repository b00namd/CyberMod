# Another Castle – Story-Konzept

> Arbeitstitel. Eine Cyberpunk-2077-Questreihe als Parodie auf „die Prinzessin aus der Burg retten“.
> Bewusst **ohne geschützte Namen** (Mario, Peach, Bowser, Toad …), damit der Mod veröffentlicht werden kann.
> Die Anspielungen stecken in Namen, Farben, Orten und Sprüchen.

## Pitch

Die Klatschpresse nennt sie „die Prinzessin von Westbrook“: Momoko Hayashi, Erbin eines Biotech-Konzerns.
Als sie entführt wird, sieht das nur ein Zeuge – ein nervöser Klempner, der gerade im Keller der Villa die
Rohre repariert hat. Er heuert V an. Die Spur führt von Versteck zu Versteck einer Maelstrom-Splittergruppe,
und jedes Mal heißt es: *Die Prinzessin ist in einer anderen Burg.*

## Figuren

| Figur | Rolle | Anspielung |
|---|---|---|
| **Momoko „Momo“ Hayashi** | Entführte Konzernerbin, fähige Netrunnerin. Schickt V aus der Gefangenschaft verschlüsselte Nachrichten. Späteres Love Interest. | *Momo* = japanisch „Pfirsich“; trägt Pink, fährt einen pinken Wagen |
| **Luca Rossi** | Schüchterner Klempner mit grüner Kappe, Auftraggeber. Hat die Entführung beobachtet. | Der ewige Zweite mit grüner Mütze |
| **„Shellback“** | Riesiger Borg, Anführer der Splittergruppe *Panzerbrut*. Rückenpanzerung, Flammenwerfer im Arm. | Schildkrötenpanzer, Feuer speien |
| **Kinoko** | Winzige Kurierin mit rot-weiß gepunktetem Helm. Wird in jedem Versteck gefangen gehalten und sagt *den* Satz. | *Kinoko* = japanisch „Pilz“ |
| **Die Panzerbrut** | Gegner-Gang, Maelstrom-Ableger | Die Schildkröten-Armee |
| **Drei Lieutenants** | Zwischenbosse der Verstecke | Die Burg-Zwischengegner |

## Kapitel

### 1 – Rohrbruch (Auftrag)
- SMS von Luca Rossi: „Ich bin nur Klempner, aber ich hab gesehen, wie sie die Prinzessin mitgenommen haben…“
- Treffen mit Luca in Westbrook, er übergibt einen Hinweis.
- Ziel auf der Karte: Burg 1.

### 2 – Burg 1: Northside (Watson) – Lagerhalle
- Industriegelände, Panzerbrut-Gegner, Lieutenant als Zwischenboss.
- Kinoko befreien: **„Danke, V! Aber die Prinzessin ist in einer anderen Burg!“**
- Erste verschlüsselte Nachricht von Momo.

### 3 – Burg 2: Badlands – Wüstencamp
- Anspielung auf die Wüstenwelt. Anreise über die Kanalisation bzw. „Warp-Röhre“ als Abkürzung.
- Zwischenboss, Kinoko (schon wieder), derselbe Spruch, Momos zweite Nachricht.

### 4 – Burg 3: Pacifica – geflutetes Kellergeschoss
- Anspielung auf die Wasserwelt. Zwischenboss, Kinoko, Spruch, Momo verrät, wo sie wirklich ist.

### 5 – Die letzte Burg: Santo Domingo – Stahlwerk
- Anspielung auf die Lava-Burg: Gießerei, glühende Metallbecken.
- Bosskampf gegen Shellback.
- *Optional / später:* Laufsteg über dem Schmelzbecken mit Notfall-Hebel (Brücke + Axt).
- Momo ist wirklich da. Ihre Antwort auf den Spruch: „Diesmal bin ich tatsächlich in dieser Burg.“

### 6 – Nachspiel: Romanze
- SMS-Unterhaltungen mit Antwortauswahl, Beziehungsstufen im Hintergrund.
- Date an einem besonderen Ort (z.B. Dachterrasse mit Blick auf die Stadt).
- Abschluss je nach Entscheidungen: Romanze oder Freundschaft.

## Kleine Anspielungen (Easter Eggs)

- Belohnung: genau 100 Eddies extra mit einem „1-Up“-Kommentar.
- Ein besonderer Stim als Belohnung („Super-Stim“, rot-weiß gepunktet).
- Rossis Klempnerwagen mit grün-rotem Logo „Rossi Bros. Plumbing“.
- Die Metro (NCART) als „Warp-Zone“ zwischen den Stadtteilen.

## Technische Umsetzung (erste Einschätzung)

| Baustein | Umsetzung | Aufwand |
|---|---|---|
| SMS / Nachrichten | redscript / Codeware | mittel |
| Karten-Marker & Ziele | redscript / CET | gering–mittel |
| Gegner und NPCs spawnen | Codeware (DynamicEntitySystem), vorhandene Spielmodelle | mittel |
| Zwischenbosse / Shellback | vorhandene Gegner-Records via TweakXL angepasst (Werte, Name, Ausrüstung) | mittel |
| Quest-Fortschritt speichern | eigene Variablen / Facts im Savegame | gering |
| Belohnungen & Items | TweakXL | gering |
| Dialogszenen mit Auswahl | erst Textlösung, später evtl. native Szenen (WolvenKit) | hoch |
| Eigene Figuren-Optik | zuerst vorhandene Erscheinungsbilder, später evtl. WolvenKit / ArchiveXL | hoch |
| Brücke über dem Schmelzbecken | später | hoch |

**Prototyp-Ziel:** Kapitel 1 und 2 spielbar (SMS → Treffen → Marker → Versteck → Gegner → Kinoko → Spruch).
