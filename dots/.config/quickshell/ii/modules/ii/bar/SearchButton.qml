import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

RippleButton {
    id: root

    property real buttonPadding: 5
    implicitWidth: searchIcon.implicitWidth + buttonPadding * 2
    implicitHeight: searchIcon.implicitHeight + buttonPadding * 2
    buttonRadius: Appearance.rounding.full
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.overviewOpen

    onPressed: {
        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    }

    MaterialSymbol {
        id: searchIcon
        anchors.centerIn: parent
        text: "search"
        iconSize: 20
        color: Appearance.colors.colOnLayer0
    }
}
