pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
/**
 * Shared right-click context menu for a workspace.
 * Used by the ii bar (Workspaces) and the ii overview grid.
 * Styling follows SysTrayMenu (Appearance tokens); the anchor block is
 * provided by the instantiator, same as SysTrayMenu in SysTrayItem.
 */
PopupWindow {
    id: root
    required property int wsId
    property bool showSpecialToggle: false

    signal menuOpened(qsWindow: var) // Correct type is QsWindow, but QML does not like that
    signal menuClosed()

    color: "transparent"
    property real outerPadding: Appearance.sizes.elevationMargin

    readonly property var wsClients: HyprlandData.hyprlandClientsForWorkspace(root.wsId)
    readonly property int windowCount: wsClients.length
    readonly property bool isActive: HyprlandData.activeWorkspace?.id === root.wsId
    readonly property var focusedToplevel: ToplevelManager.activeToplevel
    readonly property string focusedAddress: focusedToplevel?.HyprlandToplevel?.address ?? ""
    readonly property var focusedClient: HyprlandData.clientForToplevel(root.focusedToplevel)
    readonly property bool canMoveFocused: root.focusedAddress.length > 0 && root.focusedClient?.workspace?.id !== root.wsId

    property bool closeArmed: false

    function open() {
        root.closeArmed = false;
        root.visible = true;
        GlobalFocusGrab.addDismissable(root);
        root.menuOpened(root);
    }

    function close() {
        GlobalFocusGrab.removeDismissable(root);
        root.closeArmed = false;
        root.visible = false;
        root.menuClosed();
    }

    Component.onDestruction: GlobalFocusGrab.removeDismissable(root)

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.close();
        }
    }

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.closeArmed = false
    }

    implicitWidth: menuBackground.implicitWidth + root.outerPadding * 2
    implicitHeight: menuBackground.implicitHeight + root.outerPadding * 2

    StyledRectangularShadow {
        target: menuBackground
    }

    Rectangle {
        id: menuBackground
        readonly property real padding: 4
        anchors {
            fill: parent
            margins: root.outerPadding
        }

        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.windowRounding
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        implicitWidth: menuColumn.implicitWidth + menuBackground.padding * 2
        implicitHeight: menuColumn.implicitHeight + menuBackground.padding * 2

        ColumnLayout {
            id: menuColumn
            anchors {
                fill: parent
                margins: menuBackground.padding
            }
            spacing: 0

            MenuRow {
                iconName: root.isActive ? "check" : "arrow_forward"
                label: root.isActive ? Translation.tr("Current desktop") : Translation.tr("Switch to Desktop %1").arg(root.wsId)
                enabled: !root.isActive
                releaseAction: () => {
                    GlobalStates.overviewOpen = false;
                    Hyprland.dispatch(`hl.dsp.focus({workspace = ${root.wsId}})`);
                    root.close();
                }
            }

            MenuRow {
                iconName: "move_to_inbox"
                label: Translation.tr("Move focused window here")
                enabled: root.canMoveFocused
                releaseAction: () => {
                    Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${root.wsId}, follow = false, window = "address:${root.focusedAddress}" })`);
                    root.close();
                }
            }

            MenuRow {
                iconName: "open_in_new"
                label: Translation.tr("Move focused here and follow")
                enabled: root.canMoveFocused
                releaseAction: () => {
                    Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${root.wsId}, follow = true, window = "address:${root.focusedAddress}" })`);
                    root.close();
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Appearance.colors.colSubtext
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            MenuRow {
                iconName: "close"
                label: !root.closeArmed ? (root.windowCount === 1 ? Translation.tr("Close 1 window") : Translation.tr("Close %1 windows").arg(root.windowCount)) : Translation.tr("Click again to confirm")
                enabled: root.windowCount > 0
                releaseAction: () => {
                    if (!root.closeArmed) {
                        root.closeArmed = true;
                        disarmTimer.restart();
                        return;
                    }
                    disarmTimer.stop();
                    for (const client of root.wsClients) {
                        Hyprland.dispatch(`hl.dsp.window.close({window = "address:${client.address}"})`);
                    }
                    root.close();
                }
            }

            MenuRow {
                visible: root.showSpecialToggle
                iconName: "star"
                label: Translation.tr("Toggle special workspace")
                releaseAction: () => {
                    Hyprland.dispatch(`hl.dsp.workspace.toggle_special("special")`);
                    root.close();
                }
            }
        }
    }

    component MenuRow: RippleButton {
        id: row
        property string iconName: ""
        property string label: ""
        buttonRadius: menuBackground.radius - menuBackground.padding
        horizontalPadding: 12
        implicitHeight: 36
        Layout.fillWidth: true

        contentItem: RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                leftMargin: row.horizontalPadding
                rightMargin: row.horizontalPadding
            }
            spacing: 8

            MaterialSymbol {
                iconSize: 20
                text: row.iconName
            }

            StyledText {
                Layout.fillWidth: true
                text: row.label
                font.pixelSize: Appearance.font.pixelSize.smallie
            }
        }
    }
}
