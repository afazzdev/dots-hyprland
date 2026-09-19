import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "developer_board"
            percentage: ResourceUsage.gpuUsage
            shown: (ResourceUsage.gpuAvailable || root.alwaysShowAllResources) &&
                (Config.options.bar.resources.alwaysShowGpu ||
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }

        RowLayout {
            visible: Config.options.bar.resources.alwaysShowNetwork || root.alwaysShowAllResources
            spacing: 2
            Layout.leftMargin: 6
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                fill: 1
                text: "speed"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
            }
            StyledText {
                Layout.alignment: Qt.AlignVCenter
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: `↓ ${ResourceUsage.formatSpeed(ResourceUsage.netDownSpeed)} ↑ ${ResourceUsage.formatSpeed(ResourceUsage.netUpSpeed)}`
            }
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
