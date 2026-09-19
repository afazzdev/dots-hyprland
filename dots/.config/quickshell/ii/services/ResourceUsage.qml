pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU, GPU, and network speed.
 * GPU is read from amdgpu sysfs (gpu_busy_percent, VRAM info, hwmon temp);
 * unavailable GPUs simply report 0 / hidden widget.
 * Network speed is derived from /proc/net/dev on the default-route interface.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats
    // CPU details (resolved live; -1 / 0 = unknown)
    property real cpuFreqMHz: 0 // average across cores
    property real cpuTemp: -1 // Celsius, -1 = unknown
    property int cpuCoreCount: 0
    property int cpuThreadCount: 0
    property string loadAvgString: "--"
    // GPU (amdgpu sysfs; 0-1 fractions, bytes for VRAM, Celsius for temp)
    property real gpuUsage: 0
    property real gpuMemUsed: 0
    property real gpuMemTotal: 1
    property real gpuMemUsedPercentage: gpuMemTotal > 0 ? (gpuMemUsed / gpuMemTotal) : 0
    property real gpuTemp: -1 // -1 = unknown
    property bool gpuAvailable: false
    // Network speed (default-route interface; bytes/sec, totals in bytes)
    property string netInterface: ""
    property real netDownSpeed: 0
    property real netUpSpeed: 0
    property real netDownTotal: 0
    property real netUpTotal: 0
    property real prevNetRx: -1
    property real prevNetTx: -1
    property real prevNetTime: -1

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"
    property string maxAvailableGpuMemString: bytesToGbString(ResourceUsage.gpuMemTotal)

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []
    property list<real> gpuUsageHistory: []
    property list<real> gpuMemHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }
    function bytesToGbString(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }
    function formatSpeed(bytesPerSec) {
        if (!(bytesPerSec > 0)) return "0 B/s";
        if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B/s";
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
    }
    function formatBytesTotal(bytes) {
        if (!(bytes > 0)) return "0 B";
        if (bytes < 1024) return Math.round(bytes) + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB";
        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateGpuUsageHistory() {
        gpuUsageHistory = [...gpuUsageHistory, gpuUsage]
        if (gpuUsageHistory.length > historyLength) {
            gpuUsageHistory.shift()
        }
        gpuMemHistory = [...gpuMemHistory, gpuMemUsedPercentage]
        if (gpuMemHistory.length > historyLength) {
            gpuMemHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
        updateGpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()
            fileLoadavg.reload()
            fileCpuinfo.reload()
            if (root.cpuTempPath.length > 0) fileCpuTemp.reload()
            fileGpuBusy.reload()
            fileGpuVramUsed.reload()
            fileGpuVramTotal.reload()
            fileGpuTemp.reload()
            fileNetDev.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // Parse CPU frequency (average across cores)
            const cpuMHzMatches = fileCpuinfo.text().match(/cpu MHz\s*:\s*([\d.]+)/g)
            if (cpuMHzMatches && cpuMHzMatches.length > 0) {
                let freqSum = 0
                for (let i = 0; i < cpuMHzMatches.length; i++) {
                    freqSum += parseFloat(cpuMHzMatches[i].split(":")[1])
                }
                cpuFreqMHz = freqSum / cpuMHzMatches.length
            }

            // Parse load average (1, 5, 15 min)
            const loadParts = fileLoadavg.text().trim().split(/\s+/)
            if (loadParts.length >= 3) {
                loadAvgString = `${loadParts[0]} ${loadParts[1]} ${loadParts[2]}`
            }

            // Parse CPU temperature (millidegree -> Celsius, -1 = unknown)
            const cpuTempRaw = Number(fileCpuTemp.text().trim())
            if (root.cpuTempPath.length > 0 && !isNaN(cpuTempRaw) && fileCpuTemp.text().trim().length > 0) {
                cpuTemp = cpuTempRaw / 1000
            } else {
                cpuTemp = -1
            }

            // Parse GPU usage (amdgpu sysfs; empty text = unavailable)
            const gpuBusy = Number(fileGpuBusy.text().trim())
            if (!isNaN(gpuBusy) && fileGpuBusy.text().trim().length > 0) {
                gpuUsage = Math.max(0, Math.min(1, gpuBusy / 100))
                gpuAvailable = true
            } else {
                gpuUsage = 0
            }
            const vramUsed = Number(fileGpuVramUsed.text().trim())
            const vramTotal = Number(fileGpuVramTotal.text().trim())
            if (!isNaN(vramUsed) && !isNaN(vramTotal) && vramTotal > 0) {
                gpuMemUsed = vramUsed
                gpuMemTotal = vramTotal
                gpuAvailable = true
            }
            const gpuTempRaw = Number(fileGpuTemp.text().trim())
            if (!isNaN(gpuTempRaw) && fileGpuTemp.text().trim().length > 0) {
                gpuTemp = gpuTempRaw / 1000 // millidegree -> Celsius
            } else {
                gpuTemp = -1
            }

            // Parse network speed from /proc/net/dev (default-route iface, fallback: first non-lo)
            const netLines = fileNetDev.text().split("\n")
            let netRx = -1, netTx = -1
            let fallbackRx = -1, fallbackTx = -1
            for (let i = 0; i < netLines.length; i++) {
                const colonIdx = netLines[i].indexOf(":")
                if (colonIdx < 0) continue
                const iface = netLines[i].slice(0, colonIdx).trim()
                if (iface === "" || iface === "Inter" || iface === "face" || iface === "lo") continue
                const fields = netLines[i].slice(colonIdx + 1).trim().split(/\s+/)
                if (fields.length < 9) continue
                const r = Number(fields[0]), t = Number(fields[8])
                if (isNaN(r) || isNaN(t)) continue
                if (root.netInterface.length > 0 && iface === root.netInterface) {
                    netRx = r
                    netTx = t
                    break
                }
                if (fallbackRx < 0) {
                    fallbackRx = r
                    fallbackTx = t
                }
            }
            if (netRx < 0 && fallbackRx >= 0) {
                netRx = fallbackRx
                netTx = fallbackTx
            }
            const nowMs = Date.now()
            if (netRx >= 0 && netTx >= 0) {
                netDownTotal = netRx
                netUpTotal = netTx
                if (prevNetRx >= 0 && prevNetTime > 0) {
                    const dtSec = (nowMs - prevNetTime) / 1000
                    if (dtSec > 0.2) {
                        netDownSpeed = Math.max(0, (netRx - prevNetRx) / dtSec)
                        netUpSpeed = Math.max(0, (netTx - prevNetTx) / dtSec)
                    }
                }
                prevNetRx = netRx
                prevNetTx = netTx
                prevNetTime = nowMs
            }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

    // Resolve the amdgpu hwmon temp path once (hwmon numbering can shift).
    // Defaults to hwmon1 (correct on this machine) until resolved.
    property string gpuTempPath: "/sys/class/hwmon/hwmon1/temp1_input"

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileLoadavg; path: "/proc/loadavg" }
    FileView { id: fileCpuinfo; path: "/proc/cpuinfo" }
    FileView { id: fileCpuTemp; path: root.cpuTempPath }
    FileView { id: fileGpuBusy; path: "/sys/class/drm/card0/device/gpu_busy_percent" }
    FileView { id: fileGpuVramUsed; path: "/sys/class/drm/card0/device/mem_info_vram_used" }
    FileView { id: fileGpuVramTotal; path: "/sys/class/drm/card0/device/mem_info_vram_total" }
    FileView { id: fileGpuTemp; path: root.gpuTempPath }
    FileView { id: fileNetDev; path: "/proc/net/dev" }

    // Resolve the default-route interface once (e.g. enp6s0); fallback is first non-lo iface.
    Process {
        id: findNetInterfaceProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c", "awk '$2==\"00000000\" {print $1; exit}' /proc/net/route 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            id: netInterfaceCollector
            onStreamFinished: {
                const p = netInterfaceCollector.text.trim()
                if (p.length > 0) {
                    root.netInterface = p
                }
            }
        }
    }

    Process {
        id: findGpuTempPathProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*; do [ \"$(cat $d/name 2>/dev/null)\" = amdgpu ] && echo \"$d/temp1_input\" && break; done"]
        running: true
        stdout: StdioCollector {
            id: gpuTempPathCollector
            onStreamFinished: {
                const p = gpuTempPathCollector.text.trim()
                if (p.length > 0) {
                    root.gpuTempPath = p
                    fileGpuTemp.reload()
                }
            }
        }
    }

    // Resolve the CPU hwmon temp path once (hwmon numbering can shift).
    // Supports k10temp (AMD), coretemp (Intel), zenpower, k8temp.
    property string cpuTempPath: ""
    Process {
        id: findCpuTempPathProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*; do n=$(cat $d/name 2>/dev/null); case $n in k10temp|coretemp|zenpower|k8temp) echo \"$d/temp1_input\"; break;; esac; done"]
        running: true
        stdout: StdioCollector {
            id: cpuTempPathCollector
            onStreamFinished: {
                const p = cpuTempPathCollector.text.trim()
                if (p.length > 0) {
                    root.cpuTempPath = p
                    fileCpuTemp.reload()
                }
            }
        }
    }

    Process {
        id: findCpuInfoProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "echo \"threads=$(nproc)\"; echo \"cores=$(lscpu -p=core 2>/dev/null | grep -v '^#' | sort -u | wc -l)\"; lscpu | grep 'CPU max MHz' | awk '{print \"maxMHz=\"$4}'"]
        running: true
        stdout: StdioCollector {
            id: cpuInfoCollector
            onStreamFinished: {
                const text = cpuInfoCollector.text
                const threads = parseInt(text.match(/threads=(\d+)/)?.[1] ?? "0")
                if (threads > 0) root.cpuThreadCount = threads
                const cores = parseInt(text.match(/cores=(\d+)/)?.[1] ?? "0")
                if (cores > 0) root.cpuCoreCount = cores
                const maxMHz = parseFloat(text.match(/maxMHz=([\d.]+)/)?.[1] ?? "NaN")
                if (!isNaN(maxMHz)) root.maxAvailableCpuString = (maxMHz / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
