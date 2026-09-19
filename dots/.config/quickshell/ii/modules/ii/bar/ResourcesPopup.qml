import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }
    // Helper function to format bytes to GB (for GPU VRAM)
    function formatBytes(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            }
        }

        Column {
            visible: ResourceUsage.swapTotal > 0
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.cpuFreqMHz > 0
                    icon: "speed"
                    label: Translation.tr("Freq:")
                    value: `${(ResourceUsage.cpuFreqMHz / 1000).toFixed(1)} / ${ResourceUsage.maxAvailableCpuString}`
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.cpuTemp >= 0
                    icon: "thermometer"
                    label: Translation.tr("Temp:")
                    value: `${Math.round(ResourceUsage.cpuTemp)}°C`
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.cpuThreadCount > 0
                    icon: "widgets"
                    label: Translation.tr("Cores:")
                    value: ResourceUsage.cpuCoreCount > 0 ? `${ResourceUsage.cpuCoreCount}C / ${ResourceUsage.cpuThreadCount}T` : `${ResourceUsage.cpuThreadCount}T`
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.loadAvgString !== "--"
                    icon: "show_chart"
                    label: Translation.tr("Load avg:")
                    value: ResourceUsage.loadAvgString
                }
            }
        }

        Column {
            visible: ResourceUsage.gpuAvailable
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "GPU"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.gpuUsage * 100)}%`
                }
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("VRAM Used:")
                    value: root.formatBytes(ResourceUsage.gpuMemUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("VRAM Free:")
                    value: root.formatBytes(ResourceUsage.gpuMemTotal - ResourceUsage.gpuMemUsed)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("VRAM Total:")
                    value: root.formatBytes(ResourceUsage.gpuMemTotal)
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.gpuTemp >= 0
                    icon: "thermometer"
                    label: Translation.tr("Temp:")
                    value: `${Math.round(ResourceUsage.gpuTemp)}°C`
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "network_check"
                label: "Network"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "downloading"
                    label: Translation.tr("Down:")
                    value: ResourceUsage.formatSpeed(ResourceUsage.netDownSpeed)
                }
                StyledPopupValueRow {
                    icon: "upload"
                    label: Translation.tr("Up:")
                    value: ResourceUsage.formatSpeed(ResourceUsage.netUpSpeed)
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.netInterface !== ""
                    icon: "lan"
                    label: Translation.tr("Iface:")
                    value: ResourceUsage.netInterface
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.netDownTotal > 0
                    icon: "clock_loader_60"
                    label: Translation.tr("Total down:")
                    value: ResourceUsage.formatBytesTotal(ResourceUsage.netDownTotal)
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.netUpTotal > 0
                    icon: "check_circle"
                    label: Translation.tr("Total up:")
                    value: ResourceUsage.formatBytesTotal(ResourceUsage.netUpTotal)
                }
            }
        }
    }
}
