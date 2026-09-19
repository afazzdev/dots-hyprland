import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool alwaysShowAllResources: false
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.fill: parent

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "developer_board"
            percentage: ResourceUsage.gpuUsage
            visible: ResourceUsage.gpuAvailable || root.alwaysShowAllResources
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "speed"
            // No % semantic for throughput: fill relative to ~100 Mbit/s for a lively indicator
            percentage: Math.min(1, Math.max(ResourceUsage.netDownSpeed, ResourceUsage.netUpSpeed) / (12.5 * 1024 * 1024))
            visible: Config.options.bar.resources.alwaysShowNetwork || root.alwaysShowAllResources
        }

    }

    Bar.ResourcesPopup {
        hoverTarget: root
    }
}
