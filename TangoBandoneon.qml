//=============================================================================
// Tango Bandoneon - Plugin for MuseScore 4
// Based on "Bandoneon, 142 Button, Rheinische Tonlage" by Dave Ludlow
// Copyright © 2023 Dave Ludlow (original work)
// Copyright © 2026 Ignacio Irigaray (MuseScore 4 port & enhancements)
// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//=============================================================================

import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0

MuseScore {
    version: "0.3"
    title: "Tango Bandoneon"
    categoryCode: "composing-arranging-tools"

    Timer {
        id: pollTimer
        interval: 150
        repeat: true
        running: false
        onTriggered: mainWindow.updateColors()
    }

    ApplicationWindow {
        id: mainWindow
        width:  640
        height: 576
        title:  "Tango Bandoneon"
        visible: false

        property int    tick: 0
        property string currentBow:  "none"
        property string currentMode: "dual"   // "dual" | "split"
        readonly property real bsize: width / 28  // ≈ 22.9 px — diámetro de cada botón

        readonly property string color_opening: "#FFD600"
        readonly property string color_closing: "#F44336"
        readonly property string color_both:    "#00BCD4"
        readonly property string color_neither: "#EEEEEE"
        readonly property string color_border:  "#333333"

        function noteName(pitch) {
            var names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"];
            return names[pitch % 12] + Math.floor(pitch / 12 - 1);
        }

        // Convierte match de pitch en color según fuelle
        function colorFromMatch(op, cl) {
            if (!op && !cl) return color_neither;
            if (currentBow === "open")  return op ? color_opening : color_neither;
            if (currentBow === "close") return cl ? color_closing : color_neither;
            if (op && cl) return color_both;
            if (op)       return color_opening;
            return color_closing;
        }

        // Modo "dual": devuelve los segmentos de las notas seleccionadas
        // navegando Note → Chord → Segment por la cadena de padres.
        function getSelectedSegments() {
            var segs = [], seen = {};
            var elems = curScore.selection.elements;
            for (var i = 0; i < elems.length; i++) {
                var e = elems[i];
                if (e.type !== Element.NOTE) continue;
                var chord = e.parent;
                if (!chord) continue;
                var seg = chord.parent;
                if (!seg) continue;
                var key = seg.tick;
                if (!seen[key]) { seen[key] = true; segs.push(seg); }
            }
            return segs;
        }

        // Treble: tracks 0–3 de los segmentos seleccionados (modo dual)
        //         o notas seleccionadas en track < 4 (modo split)
        function getColorTreble(pitch_open, pitch_close) {
            if (typeof curScore === 'undefined' || !curScore) return color_neither;
            var op = false, cl = false;
            if (currentMode === "dual") {
                var segs = getSelectedSegments();
                for (var s = 0; s < segs.length; s++) {
                    for (var t = 0; t < 4; t++) {
                        var el = segs[s].elementAt(t);
                        if (!el || el.type !== Element.CHORD) continue;
                        var notes = el.notes;
                        for (var n = 0; n < notes.length; n++) {
                            if (notes[n].pitch === pitch_open)  op = true;
                            if (notes[n].pitch === pitch_close) cl = true;
                        }
                    }
                }
            } else {
                var elems = curScore.selection.elements;
                for (var i = 0; i < elems.length; i++) {
                    var e = elems[i];
                    if (e.type === Element.NOTE && e.track < 4) {
                        if (e.pitch === pitch_open)  op = true;
                        if (e.pitch === pitch_close) cl = true;
                    }
                }
            }
            return colorFromMatch(op, cl);
        }

        // Bass: tracks 4+ de los segmentos seleccionados (modo dual)
        //       o notas seleccionadas en track >= 4 (modo split)
        function getColorBass(pitch_open, pitch_close) {
            if (typeof curScore === 'undefined' || !curScore) return color_neither;
            var op = false, cl = false;
            if (currentMode === "dual") {
                var segs = getSelectedSegments();
                for (var s = 0; s < segs.length; s++) {
                    for (var t = 4; t < curScore.ntracks; t++) {
                        var el = segs[s].elementAt(t);
                        if (!el || el.type !== Element.CHORD) continue;
                        var notes = el.notes;
                        for (var n = 0; n < notes.length; n++) {
                            if (notes[n].pitch === pitch_open)  op = true;
                            if (notes[n].pitch === pitch_close) cl = true;
                        }
                    }
                }
            } else {
                var elems = curScore.selection.elements;
                for (var i = 0; i < elems.length; i++) {
                    var e = elems[i];
                    if (e.type === Element.NOTE && e.track >= 4) {
                        if (e.pitch === pitch_open)  op = true;
                        if (e.pitch === pitch_close) cl = true;
                    }
                }
            }
            return colorFromMatch(op, cl);
        }

        function updateColors() {
            tick = (tick + 1) % 1000000;
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // ── Barra de control bow ─────────────────────────────────────────
            Rectangle {
                width:  parent.width
                height: 44
                color:  "#1a1a1a"

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "Fuelle:"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#DDDDDD"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width:  110
                        height: 30
                        radius: 6
                        color:  mainWindow.currentBow === "open"
                                ? mainWindow.color_opening : "#333333"
                        border.color: mainWindow.currentBow === "open"
                                      ? "#CC9900" : "#666666"
                        border.width: mainWindow.currentBow === "open" ? 2 : 1
                        Text {
                            anchors.centerIn: parent
                            text: "⊓  Abriendo"
                            font.pixelSize: 13
                            color: mainWindow.currentBow === "open" ? "#222222" : "#CCCCCC"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mainWindow.currentBow = (mainWindow.currentBow === "open") ? "none" : "open";
                                mainWindow.updateColors();
                            }
                        }
                    }

                    Rectangle {
                        width:  110
                        height: 30
                        radius: 6
                        color:  mainWindow.currentBow === "close"
                                ? mainWindow.color_closing : "#333333"
                        border.color: mainWindow.currentBow === "close"
                                      ? "#AA0000" : "#666666"
                        border.width: mainWindow.currentBow === "close" ? 2 : 1
                        Text {
                            anchors.centerIn: parent
                            text: "⊔  Cerrando"
                            font.pixelSize: 13
                            color: mainWindow.currentBow === "close" ? "#FFFFFF" : "#CCCCCC"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mainWindow.currentBow = (mainWindow.currentBow === "close") ? "none" : "close";
                                mainWindow.updateColors();
                            }
                        }
                    }

                    Rectangle {
                        width:  80
                        height: 30
                        radius: 6
                        color:  mainWindow.currentBow === "none" ? "#555555" : "#333333"
                        border.color: "#666666"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Sin filtro"
                            font.pixelSize: 12
                            color: "#CCCCCC"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mainWindow.currentBow = "none";
                                mainWindow.updateColors();
                            }
                        }
                    }
                }
            }

            // ── Barra de modo ────────────────────────────────────────────────
            Rectangle {
                width:  parent.width
                height: 36
                color:  "#161616"

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "Modo:"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#AAAAAA"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Modo Dual
                    Rectangle {
                        width: 140; height: 24; radius: 5
                        color:  mainWindow.currentMode === "dual" ? "#1565C0" : "#2a2a2a"
                        border.color: mainWindow.currentMode === "dual" ? "#42A5F5" : "#555555"
                        border.width: mainWindow.currentMode === "dual" ? 2 : 1
                        Text {
                            anchors.centerIn: parent
                            text: "Dual (ambas claves)"
                            font.pixelSize: 11
                            color: mainWindow.currentMode === "dual" ? "#FFFFFF" : "#999999"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { mainWindow.currentMode = "dual"; mainWindow.updateColors(); }
                        }
                    }

                    // Modo Split
                    Rectangle {
                        width: 140; height: 24; radius: 5
                        color:  mainWindow.currentMode === "split" ? "#4a148c" : "#2a2a2a"
                        border.color: mainWindow.currentMode === "split" ? "#CE93D8" : "#555555"
                        border.width: mainWindow.currentMode === "split" ? 2 : 1
                        Text {
                            anchors.centerIn: parent
                            text: "Separado (por clave)"
                            font.pixelSize: 11
                            color: mainWindow.currentMode === "split" ? "#FFFFFF" : "#999999"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { mainWindow.currentMode = "split"; mainWindow.updateColors(); }
                        }
                    }

                    Text {
                        visible: mainWindow.currentMode === "dual"
                        text: "· Seleccioná cualquier nota — ambos teclados se actualizan"
                        font.pixelSize: 10
                        color: "#555555"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── Área de botones ──────────────────────────────────────────────
            Item {
                width:  parent.width
                height: parent.height - 44 - 36 - 36  // -fuelle -modo -leyenda

                // Fondo oscuro (visible en zonas transparentes de la imagen)
                Rectangle {
                    anchors.fill: parent
                    color: "#1a1a1a"
                }

                // Imagen real del instrumento: panel bajo (izquierda) + treble (derecha)
                Image {
                    anchors.fill: parent
                    source: "teclados_recortado_balanceado.png"
                    fillMode: Image.Stretch   // ratio imagen ≈ ratio área → distorsión mínima
                    opacity: 0.90
                }

                // Treble (mano derecha) — panel derecho de la imagen
                Repeater {
                    model: buttons_treble
                    Rectangle {
                        property real   bsize:    mainWindow.bsize
                        property string btnColor: { mainWindow.tick; return mainWindow.getColorTreble(model.pitch_open, model.pitch_close) }
                        width:  bsize
                        height: bsize
                        radius: bsize / 2
                        color:        btnColor
                        border.color: mainWindow.color_border
                        border.width: 1.5
                        opacity:      btnColor === mainWindow.color_neither ? 0 : 0.88
                        x: model.px - bsize/2
                        y: model.py - bsize/2

                        Text {
    			anchors.centerIn: parent
    			text: {
        				mainWindow.tick;
        				if (mainWindow.currentBow === "close")
            				return mainWindow.noteName(model.pitch_close);
        				return mainWindow.noteName(model.pitch_open);
    				}
    			font.pixelSize: parent.bsize * 0.28
    			font.bold: true
    			color: "#111111"
			}
                    }
                }

                // Bass (mano izquierda) — panel izquierdo de la imagen
                Repeater {
                    model: buttons_bass
                    Rectangle {
                        property real   bsize:    mainWindow.bsize
                        property string btnColor: { mainWindow.tick; return mainWindow.getColorBass(model.pitch_open, model.pitch_close) }
                        width:  bsize
                        height: bsize
                        radius: bsize / 2
                        color:        btnColor
                        border.color: mainWindow.color_border
                        border.width: 1.5
                        opacity:      btnColor === mainWindow.color_neither ? 0 : 0.88
                        x: model.px - bsize/2
                        y: model.py - bsize/2

                       Text {
    			anchors.centerIn: parent
    			text: {
        				mainWindow.tick;
        				if (mainWindow.currentBow === "close")
            				return mainWindow.noteName(model.pitch_close);
        				return mainWindow.noteName(model.pitch_open);
    				}
    			font.pixelSize: parent.bsize * 0.28
    			font.bold: true
    			color: "#111111"
			}
                    }
                }
            }

            // ── Leyenda ──────────────────────────────────────────────────────
            Rectangle {
                width:  parent.width
                height: 36
                color:  "#1a1a1a"

                Row {
                    anchors.centerIn: parent
                    spacing: 16

                    Repeater {
                        model: [
                            { col: mainWindow.color_opening, label: "Abriendo" },
                            { col: mainWindow.color_closing, label: "Cerrando" },
                            { col: mainWindow.color_both,    label: "Ambos"    },
                            { col: mainWindow.color_neither, label: "Ninguno"  }
                        ]
                        Row {
                            spacing: 4
                            Rectangle {
                                width: 14; height: 14; radius: 7
                                color: modelData.col
                                border.color: "#666666"
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: 11
                                color: "#CCCCCC"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: buttons_treble
        ListElement { px: 447; py: 115; pitch_open: 58; pitch_close: 58 }
        ListElement { px: 457; py: 144; pitch_open: 63; pitch_close: 63 }
        ListElement { px: 467; py: 178; pitch_open: 77; pitch_close: 77 }
        ListElement { px: 466; py: 212; pitch_open: 75; pitch_close: 76 }
        ListElement { px: 464; py: 240; pitch_open: 78; pitch_close: 80 }
        ListElement { px: 463; py: 279; pitch_open: 81; pitch_close: 83 }
        ListElement { px: 453; py: 314; pitch_open: 85; pitch_close: 88 }
        ListElement { px: 445; py: 352; pitch_open: 79; pitch_close: 75 }
        ListElement { px: 471; py: 105; pitch_open: 57; pitch_close: 57 }
        ListElement { px: 482; py: 134; pitch_open: 65; pitch_close: 65 }
        ListElement { px: 492; py: 165; pitch_open: 70; pitch_close: 64 }
        ListElement { px: 492; py: 196; pitch_open: 68; pitch_close: 69 }
        ListElement { px: 490; py: 231; pitch_open: 71; pitch_close: 73 }
        ListElement { px: 488; py: 266; pitch_open: 74; pitch_close: 76 }
        ListElement { px: 479; py: 302; pitch_open: 80; pitch_close: 81 }
        ListElement { px: 471; py: 336; pitch_open: 83; pitch_close: 85 }
        ListElement { px: 506; py: 124; pitch_open: 59; pitch_close: 59 }
        ListElement { px: 515; py: 154; pitch_open: 64; pitch_close: 66 }
        ListElement { px: 517; py: 184; pitch_open: 73; pitch_close: 78 }
        ListElement { px: 515; py: 221; pitch_open: 66; pitch_close: 67 }
        ListElement { px: 514; py: 252; pitch_open: 69; pitch_close: 71 }
        ListElement { px: 507; py: 287; pitch_open: 72; pitch_close: 74 }
        ListElement { px: 500; py: 323; pitch_open: 76; pitch_close: 79 }
        ListElement { px: 533; py: 138; pitch_open: 60; pitch_close: 62 }
        ListElement { px: 537; py: 169; pitch_open: 62; pitch_close: 61 }
        ListElement { px: 538; py: 201; pitch_open: 67; pitch_close: 68 }
        ListElement { px: 536; py: 239; pitch_open: 82; pitch_close: 70 }
        ListElement { px: 533; py: 274; pitch_open: 84; pitch_close: 72 }
        ListElement { px: 525; py: 312; pitch_open: 86; pitch_close: 86 }
        ListElement { px: 555; py: 149; pitch_open: 61; pitch_close: 60 }
        ListElement { px: 557; py: 184; pitch_open: 93; pitch_close: 91 }
        ListElement { px: 557; py: 220; pitch_open: 90; pitch_close: 82 }
        ListElement { px: 555; py: 259; pitch_open: 88; pitch_close: 84 }
        ListElement { px: 549; py: 297; pitch_open: 87; pitch_close: 87 }
        ListElement { px: 575; py: 166; pitch_open: 95; pitch_close: 93 }
        ListElement { px: 575; py: 203; pitch_open: 92; pitch_close: 92 }
        ListElement { px: 572; py: 242; pitch_open: 91; pitch_close: 90 }
        ListElement { px: 569; py: 279; pitch_open: 89; pitch_close: 89 }
    }

    ListModel {
        id: buttons_bass
        ListElement { px: 209; py: 111; pitch_open: 36; pitch_close: 41 }
        ListElement { px: 199; py: 149; pitch_open: 39; pitch_close: 37 }
        ListElement { px: 191; py: 185; pitch_open: 54; pitch_close: 53 }
        ListElement { px: 190; py: 221; pitch_open: 63; pitch_close: 71 }
        ListElement { px: 192; py: 258; pitch_open: 69; pitch_close: 68 }
        ListElement { px: 198; py: 295; pitch_open: 67; pitch_close: 66 }
        ListElement { px: 206; py: 323; pitch_open: 47; pitch_close: 52 }
        ListElement { px: 215; py: 354; pitch_open: 38; pitch_close: 40 }
        ListElement { px: 181; py: 125; pitch_open: 42; pitch_close: 47 }
        ListElement { px: 170; py: 165; pitch_open: 61; pitch_close: 56 }
        ListElement { px: 164; py: 200; pitch_open: 66; pitch_close: 64 }
        ListElement { px: 164; py: 234; pitch_open: 62; pitch_close: 61 }
        ListElement { px: 164; py: 271; pitch_open: 59; pitch_close: 57 }
        ListElement { px: 170; py: 306; pitch_open: 56; pitch_close: 52 }
        ListElement { px: 177; py: 339; pitch_open: 52; pitch_close: 45 }
        ListElement { px: 155; py: 137; pitch_open: 43; pitch_close: 54 }
        ListElement { px: 142; py: 177; pitch_open: 48; pitch_close: 65 }
        ListElement { px: 141; py: 211; pitch_open: 64; pitch_close: 62 }
        ListElement { px: 139; py: 246; pitch_open: 60; pitch_close: 59 }
        ListElement { px: 141; py: 283; pitch_open: 57; pitch_close: 55 }
        ListElement { px: 146; py: 324; pitch_open: 50; pitch_close: 43 }
        ListElement { px: 138; py: 110; pitch_open: 41; pitch_close: 42 }
        ListElement { px: 127; py: 149; pitch_open: 58; pitch_close: 48 }
        ListElement { px: 117; py: 191; pitch_open: 65; pitch_close: 61 }
        ListElement { px: 116; py: 229; pitch_open: 51; pitch_close: 60 }
        ListElement { px: 117; py: 265; pitch_open: 55; pitch_close: 58 }
        ListElement { px: 120; py: 305; pitch_open: 45; pitch_close: 50 }
        ListElement { px: 115; py: 124; pitch_open: 53; pitch_close: 67 }
        ListElement { px: 102; py: 163; pitch_open: 68; pitch_close: 63 }
        ListElement { px:  97; py: 212; pitch_open: 49; pitch_close: 51 }
        ListElement { px:  95; py: 246; pitch_open: 46; pitch_close: 46 }
        ListElement { px:  99; py: 287; pitch_open: 44; pitch_close: 44 }
        ListElement { px: 125; py: 344; pitch_open: 40; pitch_close: 50 }  // Mi2 abriendo / Re3 cerrando
    }

    onRun: {
        mainWindow.visible = true;
        pollTimer.running = true;
    }

    onScoreStateChanged: {
        mainWindow.updateColors();
    }
}
