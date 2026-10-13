// Entwicklungshilfen für NPC-Aussehen (benötigt Codeware). Lucas eigentliches Aussehen steckt in
// AnotherCastle.archive (assets\...\luca.app), das hier dient nur zum Ausprobieren und Untersuchen.
// Ohne Modul, damit CET die Klasse direkt als AnotherCastleLook aufrufen kann.

public class AnotherCastleLook {
    // Farbvariante aller Meshes ändern, deren Pfad meshPart enthält (live, zum Ausprobieren)
    public static func SetMeshAppearance(entity: ref<Entity>, meshPart: String, appearance: CName) -> Int32 {
        let changed = 0;
        for component in entity.GetComponents() {
            let skinned = component as entSkinnedMeshComponent;
            if IsDefined(skinned) && StrContains(AnotherCastleLook.MeshPath(skinned), meshPart) {
                skinned.meshAppearance = appearance;
                skinned.LoadAppearance();
                changed += 1;
            }
        }
        return changed;
    }

    public static func MeshPath(component: ref<entSkinnedMeshComponent>) -> String {
        return ResRef.ToString(ResourceAsyncRef.GetPath(component.mesh));
    }

    // Alle Bauteile eines Entities als Text, eine Zeile pro Bauteil
    public static func Describe(entity: ref<Entity>) -> String {
        let text = s"Template: \(ResRef.ToString(entity.GetTemplatePath())) / Appearance: \(NameToString(entity.GetCurrentAppearanceName()))\n";
        for component in entity.GetComponents() {
            text += s"\(NameToString(component.GetName())) [\(NameToString(component.GetClassName()))]";
            let skinned = component as entSkinnedMeshComponent;
            if IsDefined(skinned) {
                text += s" mesh=\(AnotherCastleLook.MeshPath(skinned)) app=\(NameToString(skinned.meshAppearance)) enabled=\(skinned.IsEnabled())";
            }
            let mesh = component as MeshComponent;
            if IsDefined(mesh) {
                text += s" mesh=\(ResRef.ToString(ResourceAsyncRef.GetPath(mesh.mesh))) app=\(NameToString(mesh.meshAppearance)) enabled=\(mesh.IsEnabled())";
            }
            text += "\n";
        }
        return text;
    }
}
