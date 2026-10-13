// Erzeugt Lucas eigenes Aussehen (luca.app + luca.ent als WolvenKit-JSON) aus Original-Spieldateien.
//
// Grundlage: Arbeiter-Look "generic_worker_02" aus service__worker_ma.app
//   - Kopfbedeckungen (h1_*: Kappe, Maske, Brille) und das Fern-Proxy-Mesh entfernt
//   - T-Shirt in Grün
//   - Vokuhila samt Haarphysik (hair_dangle) wie beim Tyger-Claws-NPC "_mq029__james_ito"
//   - Schnurrbart passend zum Kopf h0_001 (am face_rig, wie die Augenbrauen). Bart-Meshes bestehen aus
//     Teilen (Schnurrbart, Kinnbärtchen, Kinn, Koteletten), per chunkMask bleibt nur der Schnurrbart sichtbar
//   - Heller Hautton für Kopf und Körper, braune Augenbrauen
//   - Ohne Warnweste, grüne Arbeitshose statt der Original-Hose
//
// Aufruf: node make-luca.js <service__worker_ma.app.json> <service__worker_ma.ent.json> <gang__tyger_ma.app.json> <Ausgabeordner>
const fs = require("fs");
const path = require("path");

const LOOK = {
    shirtColor: "green_flag",
    hairColor: "brown_liquorice",
    mustacheColor: "brown_liquorice",
    skin: "02_ca_limestone",   // gilt für Kopf (h0_001) und Körper (t0_000)
    eyebrows: "brown_05",
    pantsColor: "green"
};
const MUSTACHE_MESH = "base\\characters\\head\\ma\\h0_001_ma_c__basehead\\hb_001_ma_c__handlebar_stache.mesh";
const MUSTACHE_CHUNKS = "1"; // Bit 0 = Teil "mustache"
const PANTS_MESH = "base\\characters\\garment\\citizen_casual\\legs\\l1_030_pants__worker\\l1_030_ma_pants__worker.mesh";
const APP_PATH = "mod\\anothercastle\\characters\\luca.app";
const ENT_PATH = "mod\\anothercastle\\characters\\luca.ent";
const APPEARANCE = "luca";        // Name in der .app
const ENT_APPEARANCE = "ac_luca"; // Name in der .ent, damit wird gespawnt

const [workerAppFile, workerEntFile, tygerAppFile, outDir] = process.argv.slice(2);
const load = f => JSON.parse(fs.readFileSync(f, "utf8"));
const clone = o => JSON.parse(JSON.stringify(o));

// Ersetzt alle Handle-Verweise (HandleRefId) durch eine Kopie der Daten. Danach ist jedes Teil
// eigenständig und lässt sich in eine andere Datei übernehmen, ohne dass sich Handle-IDs überschneiden.
function inlineHandles(doc) {
    const handles = {};
    (function collect(o) {
        if (!o || typeof o !== "object") return;
        if (o.HandleId !== undefined && o.Data !== undefined) handles[o.HandleId] = o.Data;
        for (const k in o) collect(o[k]);
    })(doc);

    (function inline(o) {
        if (!o || typeof o !== "object") return;
        for (const k in o) {
            const v = o[k];
            if (v && typeof v === "object" && v.HandleRefId !== undefined) {
                o[k] = { HandleId: "0", Data: clone(handles[v.HandleRefId]) };
            }
            inline(o[k]);
        }
    })(doc);
    return doc;
}

// Vergibt am Ende alle Handle-IDs der Datei neu und eindeutig
function renumberHandles(doc) {
    let next = 0;
    (function walk(o) {
        if (!o || typeof o !== "object") return;
        if (o.HandleId !== undefined) o.HandleId = String(next++);
        for (const k in o) walk(o[k]);
    })(doc);
}

const cname = v => ({ $type: "CName", $storage: "string", $value: v });
const noResource = () => ({ DepotPath: { $type: "ResourcePath", $storage: "uint64", $value: "0" }, Flags: "Soft" });
const resource = p => ({ DepotPath: { $type: "ResourcePath", $storage: "string", $value: p }, Flags: "Soft" });
const compName = c => c.name.$value;
const meshPath = c => (c.mesh && c.mesh.DepotPath.$value) || "";

// --- luca.app ---
const app = inlineHandles(load(workerAppFile));
const tyger = inlineHandles(load(tygerAppFile));

const base = app.Data.RootChunk.appearances.find(a => a.Data.name.$value === "generic_worker_02");
const luca = base.Data;
luca.name = cname(APPEARANCE);

const removed = luca.components.filter(c =>
    /\\head\\h1_/.test(meshPath(c)) ||           // Kappe, Maske, Brille
    /\\t2_114_ma_vest__hi_vis/.test(meshPath(c)) || // Warnweste samt Aufdruck
    compName(c) === "AppearanceProxyMesh");
const removedPaths = new Set(removed.map(meshPath).concat([luca.proxyMesh.DepotPath.$value]));
let components = luca.components.filter(c => !removed.includes(c));

for (const c of components) {
    const p = meshPath(c);
    if (/t1_079_ma_tshirt__casual/.test(p)) c.meshAppearance = cname(LOOK.shirtColor);
    if (/\\l1_064_ma_pants__chaps_worker\.mesh$/.test(p)) {
        removedPaths.add(p);
        c.name = cname("l1_030_ma_pants__worker");
        c.mesh.DepotPath = { $type: "ResourcePath", $storage: "string", $value: PANTS_MESH };
        c.meshAppearance = cname(LOOK.pantsColor);
    }
    if (/\\h0_001_ma_c__basehead\.mesh$/.test(p) || /\\t0_000_ma_base__full\.mesh$/.test(p)) c.meshAppearance = cname(LOOK.skin);
    if (/\\heb_001_ma_c__basehead\.mesh$/.test(p)) c.meshAppearance = cname(LOOK.eyebrows);
}

// Schnurrbart: Kopie der Augenbrauen (gleiche Bindung an face_rig) mit eigenem Mesh und eindeutiger ID
const eyebrows = components.find(c => /\\heb_001_ma_c__basehead\.mesh$/.test(meshPath(c)));
if (!eyebrows) throw new Error("Augenbrauen-Bauteil nicht gefunden");
const mustache = clone(eyebrows);
mustache.name = cname("hb_001_ma_c__handlebar_stache");
mustache.mesh.DepotPath = { $type: "ResourcePath", $storage: "string", $value: MUSTACHE_MESH };
mustache.meshAppearance = cname(LOOK.mustacheColor);
mustache.chunkMask = MUSTACHE_CHUNKS;
mustache.id = "7770000000000000001";
components.push(mustache);

// Hautfarbe passt nicht mehr zum Original-Tag
luca.visualTags.tags = luca.visualTags.tags.filter(t => t.$value !== "African");

const ito = tyger.Data.RootChunk.appearances.find(a => a.Data.name.$value === "_mq029__james_ito").Data;
const hairParts = ito.components
    .filter(c => ["hair_dangle", "hh_020_ma__mullet7683", "hh_041_ma__valentino_shadow_npc"].includes(compName(c)))
    .map(clone);
if (hairParts.length !== 3) throw new Error("Vokuhila-Bauteile nicht gefunden: " + hairParts.map(compName));
for (const c of hairParts) {
    if (/hh_020_ma__mullet/.test(meshPath(c))) c.meshAppearance = cname(LOOK.hairColor);
}
components = components.concat(hairParts);

luca.components = components;
// compiledData enthält dieselben Bauteile noch einmal, das Spiel lädt diese Fassung
luca.compiledData.Data.Chunks = components.map(clone);
luca.compiledData.Data.CruidDict = Object.fromEntries(components.map((c, i) => [String(i), c.id]));

// Keine Maske/Brille mehr: Tags entfernen, die z.B. die Stimme dämpfen
luca.inheritedVisualTags.tags = luca.inheritedVisualTags.tags
    .filter(t => !["Mask", "VO_PostprocessFaceCover", "PcOnly_Eyeware"].includes(t.$value));

// Abhängigkeiten: entfernte Teile raus, neue Ressourcen rein
luca.resolvedDependencies = luca.resolvedDependencies.filter(d => !removedPaths.has(d.DepotPath.$value));
const hairDeps = [MUSTACHE_MESH, PANTS_MESH];
for (const c of hairParts) {
    for (const key of ["mesh", "rig", "graph"]) {
        if (c[key] && c[key].DepotPath && c[key].DepotPath.$storage === "string") hairDeps.push(c[key].DepotPath.$value);
    }
}
for (const p of hairDeps) {
    if (!luca.resolvedDependencies.some(d => d.DepotPath.$value === p)) luca.resolvedDependencies.push(resource(p));
}
luca.proxyMesh = noResource();

app.Data.RootChunk.appearances = [base];
app.Data.RootChunk.commonCookData = noResource();
app.Header.ArchiveFileName = APP_PATH;
renumberHandles(app);

// --- luca.ent ---
const ent = inlineHandles(load(workerEntFile));
const entApp = clone(ent.Data.RootChunk.appearances[0]);
entApp.name = cname(ENT_APPEARANCE);
entApp.appearanceName = cname(APPEARANCE);
entApp.appearanceResource = resource(APP_PATH);
ent.Data.RootChunk.appearances = [entApp];
ent.Data.RootChunk.defaultAppearance = cname(ENT_APPEARANCE);
ent.Header.ArchiveFileName = ENT_PATH;
renumberHandles(ent);

// --- Ausgabe ---
const write = (rel, doc) => {
    const file = path.join(outDir, rel + ".json");
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, JSON.stringify(doc, null, 2));
    console.log("geschrieben: " + file);
};
write(APP_PATH, app);
write(ENT_PATH, ent);
console.log("Bauteile: " + components.map(compName).join(", "));
console.log("Entfernt: " + removed.map(compName).join(", "));
