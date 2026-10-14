// Texte des Mods auf Deutsch und Englisch (benötigt Codeware).
// Jeder Text bekommt einen Schlüssel mit Präfix "AC-", Englisch ist die Rückfallsprache.
module AnotherCastle.Localization

import Codeware.Localization.*

public class LocalizationProvider extends ModLocalizationProvider {
    public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
        switch language {
            case n"de-de":
                return new German();
            default:
                return new English();
        }
    }

    public func GetFallback() -> CName {
        return n"en-us";
    }
}

public class English extends ModLocalizationPackage {
    protected func DefineTexts() -> Void {
        // Allgemein
        this.Text("AC-Name-Luca", "Luca Rossi");
        this.Text("AC-Name-Kinoko", "Kinoko");
        this.Text("AC-Hint-ToBeContinued", "To be continued...");

        // Kapitel 1 – Rohrbruch (die SMS stehen in texts/phone.json)
        this.Text("AC-Ch1-Objective-Meet", "New objective: Meet Luca Rossi");

        // Kapitel 1: Gespräch mit Luca
        this.Text("AC-Ch1-Choice-What", "What happened?");
        this.Text("AC-Ch1-What-1", "I was fixing pipes at the Hayashi place. Westbrook villa, gold faucets, the works.");
        this.Text("AC-Ch1-What-2", "Then there's a crash upstairs. Huge guy, armor plates on his back, like a... like a turtle.");
        this.Text("AC-Ch1-What-3", "He threw Momoko Hayashi over his shoulder. The tabloids call her the Princess of Westbrook.");

        this.Text("AC-Ch1-Choice-Why", "Why not go to the NCPD?");
        this.Text("AC-Ch1-Why-1", "The NCPD? That guy saw me. If I talk, I end up down the drain myself.");
        this.Text("AC-Ch1-Why-2", "Besides... she was nice to me. Brought me coffee. Nobody brings the plumber coffee.");

        this.Text("AC-Ch1-Choice-Accept", "I'll get her out.");
        this.Text("AC-Ch1-Accept-1", "Thanks, V. They used a van in Maelstrom colors. I followed it all the way to Northside.");
        this.Text("AC-Ch1-Accept-2", "An old warehouse. I'm sending you the location. And V... be careful.");
        this.Text("AC-Ch1-Objective-Castle1", "New objective: The warehouse in Northside");

        // Kapitel 2 (Vorschau)
        this.Text("AC-Kinoko-AnotherCastle", "Thank you, V! But the princess is in another castle!");
    }
}

public class German extends ModLocalizationPackage {
    protected func DefineTexts() -> Void {
        // Allgemein
        this.Text("AC-Name-Luca", "Luca Rossi");
        this.Text("AC-Name-Kinoko", "Kinoko");
        this.Text("AC-Hint-ToBeContinued", "Fortsetzung folgt ...");

        // Kapitel 1 – Rohrbruch (die SMS stehen in texts/phone.json)
        this.Text("AC-Ch1-Objective-Meet", "Neues Ziel: Triff Luca Rossi");

        // Kapitel 1: Gespräch mit Luca
        this.Text("AC-Ch1-Choice-What", "Was ist passiert?");
        this.Text("AC-Ch1-What-1", "Ich hab bei den Hayashis die Rohre gemacht. Villa in Westbrook, goldene Wasserhähne, das volle Programm.");
        this.Text("AC-Ch1-What-2", "Dann kracht es oben. Ein Riesentyp, Panzerplatten auf dem Rücken, wie eine ... wie eine Schildkröte.");
        this.Text("AC-Ch1-What-3", "Er hat sich Momoko Hayashi über die Schulter geworfen. Die Presse nennt sie die Prinzessin von Westbrook.");

        this.Text("AC-Ch1-Choice-Why", "Warum gehst du nicht zur NCPD?");
        this.Text("AC-Ch1-Why-1", "Zur NCPD? Der Typ hat mich gesehen. Wenn ich rede, lande ich selbst im Abfluss.");
        this.Text("AC-Ch1-Why-2", "Außerdem ... sie war nett zu mir. Hat mir Kaffee gebracht. Niemand bringt dem Klempner Kaffee.");

        this.Text("AC-Ch1-Choice-Accept", "Ich hole sie da raus.");
        this.Text("AC-Ch1-Accept-1", "Danke, V. Sie hatten einen Transporter in Maelstrom-Farben. Ich bin ihm bis nach Northside gefolgt.");
        this.Text("AC-Ch1-Accept-2", "Eine alte Lagerhalle. Ich schick dir die Position. Und V ... pass auf dich auf.");
        this.Text("AC-Ch1-Objective-Castle1", "Neues Ziel: Die Lagerhalle in Northside");

        // Kapitel 2 (Vorschau)
        this.Text("AC-Kinoko-AnotherCastle", "Danke, V! Aber die Prinzessin ist in einer anderen Burg!");
    }
}
