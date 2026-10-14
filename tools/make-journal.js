// Erzeugt aus texts/phone.json das Journal (Handy-Kontakte, SMS, Antworten) und die Sprachdateien
// (onscreens) als WolvenKit-JSON. ArchiveXL fügt beides beim Spielstart ins Spiel ein (AnotherCastle.archive.xl).
//
// Als Vorlage für die Einträge dient eine echte SMS-Unterhaltung aus dem Spiel (Kontakt "zane" in
// base\journal\cooked_journal.journal), damit alle Felder so aussehen, wie das Spiel sie erwartet.
//
// Aufruf: node make-journal.js <cooked_journal.journal.json> <texts/phone.json> <assets-Ordner>
const fs = require("fs");
const path = require("path");

const JOURNAL_PATH = "mod\\anothercastle\\journal\\anothercastle.journal";
const ONSCREENS_PATH = lang => `mod\\anothercastle\\localization\\${lang}.json`;
const LANGUAGES = { "de-de": "de", "en-us": "en" };

const [gameJournalFile, textsFile, outDir] = process.argv.slice(2);
const load = f => JSON.parse(fs.readFileSync(f, "utf8"));
const clone = o => JSON.parse(JSON.stringify(o));
const data = h => h && (h.Data || h);

const gameJournal = load(gameJournalFile);
const texts = load(textsFile);

// --- Vorlagen aus dem Original-Journal ---
const gameRoot = data(gameJournal.Data.RootChunk.entry);
const gameContacts = gameRoot.entries.map(data).find(e => e.id === "contacts");
const zane = gameContacts.entries.map(data).find(e => e.id === "zane");
const zaneConversation = zane.entries.map(data)[0];
const templateFor = type => {
    const found = [];
    (function walk(e) { e = data(e); if (e.$type === type) found.push(e); (e.entries || []).forEach(walk); })(zane);
    if (!found.length) throw new Error("Keine Vorlage für " + type);
    return found[0];
};
const TEMPLATES = {
    contact: zane,
    conversation: zaneConversation,
    message: templateFor("gameJournalPhoneMessage"),
    choiceGroup: templateFor("gameJournalPhoneChoiceGroup"),
    choice: templateFor("gameJournalPhoneChoiceEntry")
};

// Neuer Eintrag aus einer Vorlage: Kinder entfernen, Felder überschreiben
function entry(template, fields) {
    const e = clone(template);
    if (e.entries) e.entries = [];
    Object.assign(e, fields);
    return e;
}
const handle = e => ({ HandleId: "0", Data: e });
const locString = key => ({ unk1: "0", value: key });

// --- Journal und Texte aufbauen ---
const onscreens = Object.fromEntries(Object.keys(LANGUAGES).map(lang => [lang, []]));
let primaryKey = 7770000;
function addText(key, values) {
    for (const [lang, short] of Object.entries(LANGUAGES)) {
        onscreens[lang].push({
            $type: "localizationPersistenceOnScreenEntry",
            femaleVariant: values[short],
            maleVariant: "",
            primaryKey: String(primaryKey),
            secondaryKey: key
        });
    }
    primaryKey++;
    return locString(key);
}

const contactEntries = [];
for (const [contactId, contact] of Object.entries(texts.contacts)) {
    const key = id => `AC-Phone-${contactId}-${id}`;
    const conversations = [];
    for (const [conversationId, conversation] of Object.entries(contact.conversations)) {
        const items = [];
        for (const item of conversation.items) {
            if (item.type === "message") {
                items.push(handle(entry(TEMPLATES.message, { id: item.id, sender: "NPC", text: addText(key(item.id), item) })));
            } else if (item.type === "choices") {
                const group = entry(TEMPLATES.choiceGroup, { id: item.id });
                group.entries = item.options.map(option => handle(entry(TEMPLATES.choice, {
                    id: option.id, text: addText(key(option.id), option), isQuestImportant: 1
                })));
                items.push(handle(group));
            } else {
                throw new Error("Unbekannter Typ: " + item.type);
            }
        }
        const c = entry(TEMPLATES.conversation, { id: conversationId, title: addText(key(conversationId + "_title"), conversation.title) });
        c.entries = items;
        conversations.push(handle(c));
    }
    const c = entry(TEMPLATES.contact, {
        id: contactId,
        name: addText(key("name"), contact.name),
        avatarID: { $type: "TweakDBID", $storage: "string", $value: contact.avatar },
        type: "Texter",
        isCallableDefault: 0
    });
    c.entries = conversations;
    contactEntries.push(handle(c));
}

// Journal-Datei: Wurzel -> "contacts" -> unsere Kontakte. ArchiveXL fügt sie über die IDs ins Spiel-Journal ein.
const journal = clone(gameJournal);
const root = data(journal.Data.RootChunk.entry);
const contactsFolder = entry(gameContacts, {});
contactsFolder.entries = contactEntries;
root.entries = [handle(contactsFolder)];
journal.Header.ArchiveFileName = JOURNAL_PATH;

let nextHandle = 0;
(function renumber(o) {
    if (!o || typeof o !== "object") return;
    if (o.HandleId !== undefined) o.HandleId = String(nextHandle++);
    for (const k in o) renumber(o[k]);
})(journal);

// --- Ausgabe ---
const write = (rel, doc) => {
    const file = path.join(outDir, rel + ".json");
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, JSON.stringify(doc, null, 2));
    console.log("geschrieben: " + file);
};
write(JOURNAL_PATH, journal);

for (const lang of Object.keys(LANGUAGES)) {
    write(ONSCREENS_PATH(lang), {
        Header: { WolvenKitVersion: journal.Header.WolvenKitVersion, WKitJsonVersion: journal.Header.WKitJsonVersion,
                  GameVersion: journal.Header.GameVersion, DataType: "CR2W", ArchiveFileName: ONSCREENS_PATH(lang) },
        Data: {
            Version: journal.Data.Version, BuildVersion: journal.Data.BuildVersion,
            RootChunk: { $type: "JsonResource", cookingPlatform: "PLATFORM_PC",
                root: { HandleId: "0", Data: { $type: "localizationPersistenceOnScreenEntries", entries: onscreens[lang] } } },
            EmbeddedFiles: []
        }
    });
}
console.log("Texte: " + onscreens["de-de"].length);
