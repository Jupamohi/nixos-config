{ pkgs, lib, ... }:
let
  avatarUser = "jupamohi";
  avatarImage = ../../assets/icono.png;

  caelestia-sddm = pkgs.stdenvNoCC.mkDerivation {
    pname = "caelestia-sddm-locklike";
    version = "git";
    nativeBuildInputs = [ pkgs.python3 ];
    src = pkgs.fetchFromGitHub {
      owner = "ItsABigIgloo";
      repo = "caelestia-sddm";
      rev = "dd69abbb7eb122546cbabe84e116ba03e67a4ccc";
      hash = "sha256-xvTdX1tthiL7lHoODlGz4pbuSvhPa7LZHmFgxeIIO94=";
    };
    dontBuild = true;
    postPatch = ''
      substituteInPlace themes/locklike/theme.conf \
        --replace-fail "sessionPicker=false" "sessionPicker=true" \
        --replace-fail "enableWelcomeMessage=true" "enableWelcomeMessage=false"

      python3 << 'PY'
from pathlib import Path

p = Path("themes/locklike/components/SessionPicker.qml")
src = p.read_text()
marker = "    Rectangle {\n        id: labelRect"
tail = src[src.find(marker):] if marker in src else src[src.find("    Rectangle {"):]

header = """pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property bool expanded: false
    property int count: sessionModel ? sessionModel.count : 0
    property var items: []
    property int selectedIndex: sessionModel && sessionModel.count > 0
        ? Math.max(0, Math.min(sessionModel.lastIndex, sessionModel.count - 1))
        : 0
    property string currentText

    width: labelRect.width + expandBtn.width
    height: 40
    opacity: root.count > 0 ? 1 : 0
    enabled: root.count > 0

    Instantiator {
        id: sessionArray
        model: sessionModel
        property var sessions: []

        delegate: Item {
            required property int index
            required property var model

            Component.onCompleted: {
                if (index >= 0 && index < sessionModel.count) {
                    sessionArray.sessions[index] = { index: index, name: model.name }
                    root.rebuildFromSessions()
                }
            }
        }
    }

    function rebuildFromSessions() {
        const arr = []
        const sArr = sessionArray.sessions
        for (let i = 0; i < sArr.length; i++) {
            const s = sArr[i]
            arr.push(s && s.name ? s.name : "")
        }
        root.items = arr
        root.syncCurrentText()
    }

    function syncCurrentText() {
        const sArr = sessionArray.sessions
        if (root.selectedIndex >= 0 && root.selectedIndex < sArr.length) {
            const s = sArr[root.selectedIndex]
            if (s && s.name) {
                root.currentText = s.name
            }
        }
    }

    onSelectedIndexChanged: {
        root.syncCurrentText()
    }

    onCountChanged: {
        if (root.count > 0 && (root.selectedIndex < 0 || root.selectedIndex >= root.count)) {
            root.selectedIndex = sessionModel && sessionModel.count > 0
                ? Math.max(0, Math.min(sessionModel.lastIndex, sessionModel.count - 1))
                : 0
        }
        root.rebuildFromSessions()
    }

    Component.onCompleted: {
        root.rebuildFromSessions()
        root.syncCurrentText()
    }
"""
p.write_text(header + "\n\n" + tail)
PY

      python3 << 'PY'
from pathlib import Path

p = Path("themes/locklike/Main.qml")
s = p.read_text()
lines = s.splitlines(keepends=True)
remove = (
    'currentText: sessionPickerBtn.items.length > 0 ? sessionPickerBtn.items[0] : ""',
    "selectedIndex: 0",
)
matches = []
for i, line in enumerate(lines):
    if any(line.strip() == x for x in remove):
        matches.append(i)
if len(matches) != 2:
    raise SystemExit("Se esperaban 2 propiedades y se encontraron %d" % len(matches))
for i in reversed(matches):
    lines.pop(i)
s = "".join(lines)
needle = """            onSelectedIndexChanged: {
                root.sessionIndex = sessionPickerBtn.selectedIndex;
            }"""
replacement = """            onSelectedIndexChanged: {
                root.sessionIndex = sessionPickerBtn.selectedIndex;
            }

            Component.onCompleted: {
                root.sessionIndex = sessionPickerBtn.selectedIndex;
            }"""
if needle not in s:
    raise SystemExit("No se encontro el manejador onSelectedIndexChanged")
s = s.replace(needle, replacement, 1)
p.write_text(s)
PY

      python3 << 'PY'
from pathlib import Path

p = Path("themes/locklike/components/Avatar.qml")
s = p.read_text()

header = """    /// Avatar shape: "hexagon" (Material Design blob) or "circle"
    property string avatarShape: "hexagon"
"""
if header not in s:
    raise SystemExit("Avatar.qml: no se encontro la cabecera")
s = s.replace(header, header + """
    /// Optional user face (file URL); tried before the bundled fallbacks
    property url imageSource: ""
""", 1)

candidates_old = """        property var avatarCandidates: ["../assets/avatar.face.icon", "../assets/avatar.face", "../assets/avatar.jpg", "../assets/avatar.png"]
        property int avatarCandidateIndex: 0

        function loadNextAvatar() {
            if (avatarCandidateIndex < avatarCandidates.length) {
                source = avatarCandidates[avatarCandidateIndex];
                avatarCandidateIndex++;
            }
        }
"""
candidates_new = """        property var baseCandidates: ["../assets/avatar.face.icon", "../assets/avatar.face", "../assets/avatar.jpg", "../assets/avatar.png"]
        property int avatarCandidateIndex: 0

        function avatarCandidateCount() {
            return baseCandidates.length + (root.imageSource && String(root.imageSource).length > 0 ? 1 : 0)
        }

        function avatarCandidateAt(i) {
            if (root.imageSource && String(root.imageSource).length > 0) {
                if (i === 0)
                    return root.imageSource;

                return baseCandidates[i - 1]
            }
            return baseCandidates[i]
        }

        function loadNextAvatar() {
            if (avatarCandidateIndex < avatarCandidateCount()) {
                source = avatarCandidateAt(avatarCandidateIndex);
                avatarCandidateIndex++;
            }
        }
"""
if candidates_old not in s:
    raise SystemExit("Avatar.qml: no se encontro el bloque de candidatos")
s = s.replace(candidates_old, candidates_new, 1)

hover_old = """    onHoveredChanged: {
        if (root.avatarShape !== "hexagon")
            return;
        if (hovered) {
            root.hexIndex = 1;
        } else {
            root.hexIndex = 0;
        }
    }
"""
if hover_old not in s:
    raise SystemExit("Avatar.qml: no se encontro onHoveredChanged")
s = s.replace(hover_old, hover_old + """
    onImageSourceChanged: {
        if (avatarImage) {
            avatarImage.avatarCandidateIndex = 0;
            avatarImage.loadNextAvatar()
        }
    }
""", 1)

completed = "        Component.onCompleted: loadNextAvatar()\n"
if completed not in s:
    raise SystemExit("Avatar.qml: no se encontro Component.onCompleted")
s = s.replace(completed, "        Component.onCompleted: { avatarCandidateIndex = 0; loadNextAvatar() }\n", 1)

p.write_text(s)
PY

      python3 << 'PY'
from pathlib import Path

p = Path("themes/locklike/Main.qml")
s = p.read_text()

anchor = '    property int sessionIndex\n'
if anchor not in s:
    raise SystemExit("Main.qml: no se encontro sessionIndex")
s = s.replace(anchor, anchor + '    property string currentUserFace: ""\n', 1)

role = '        textRole: "name"\n'
if role not in s:
    raise SystemExit("Main.qml: no se encontro textRole")
s = s.replace(role, role + """        valueRole: "icon"
        onCurrentValueChanged: root.currentUserFace = (typeof currentValue === "string") ? currentValue : ""
        Component.onCompleted: root.currentUserFace = (typeof currentValue === "string") ? currentValue : ""
""", 1)

avatar = """                Avatar {
                    avatarShape: root.avatarShape
"""
if avatar not in s:
    raise SystemExit("Main.qml: no se encontro el Avatar")
s = s.replace(avatar, avatar + """                    imageSource: root.currentUserFace
""", 1)

p.write_text(s)
PY
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/sddm/themes
      cp -r themes/locklike $out/share/sddm/themes/caelestia-locklike
      runHook postInstall
    '';
  };
in
{
  environment.systemPackages = [ caelestia-sddm ];

  services.displayManager.sddm = {
    theme = "caelestia-locklike";
    extraPackages = with pkgs.kdePackages; [ qtdeclarative qt5compat qtsvg qtmultimedia ];
    settings.General.GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QML_XHR_ALLOW_FILE_READ=1,QML_DISABLE_DISK_CACHE=1";
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/AccountsService/icons/${avatarUser} - - - - ${avatarImage}"
  ];

  fonts.packages = with pkgs; [ material-symbols rubik roboto nerd-fonts.caskaydia-cove ];
}
