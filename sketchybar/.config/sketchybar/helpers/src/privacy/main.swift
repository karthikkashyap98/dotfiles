// sbprivacy: reports whether any process is using the microphone or a camera right now.
//
// Prints one tab-separated line:  <mic 0|1> \t <cam 0|1> \t <app name or ->
//
// Needs no permissions. It reads CoreAudio/CoreMediaIO "is running" flags and never
// opens a device, records, or touches any audio or video data.
// The mic check is per process (kAudioProcessPropertyIsRunningInput, macOS 14.2+).
// That avoids the false positive where headphones playing music look like a live mic.

import AppKit
import CoreAudio
import CoreMediaIO

func audioProp<T: FixedWidthInteger>(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector, _ initial: T) -> T? {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var value = initial
    var size = UInt32(MemoryLayout<T>.size)
    return AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &value) == noErr ? value : nil
}

func audioObjects(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector) -> [AudioObjectID] {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(obj, &addr, 0, nil, &size) == noErr, size > 0 else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &ids) == noErr else { return [] }
    return ids
}

/// The first process with live microphone input, if any.
func micUser() -> pid_t? {
    for proc in audioObjects(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyProcessObjectList) {
        guard audioProp(proc, kAudioProcessPropertyIsRunningInput, UInt32(0)) == 1 else { continue }
        return audioProp(proc, kAudioProcessPropertyPID, pid_t(-1))
    }
    return nil
}

func cameraInUse() -> Bool {
    var addr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
                                         mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                         mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    var size: UInt32 = 0
    let system = CMIOObjectID(kCMIOObjectSystemObject)
    guard CMIOObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == 0, size > 0 else { return false }
    var devices = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
    var used: UInt32 = 0
    guard CMIOObjectGetPropertyData(system, &addr, 0, nil, size, &used, &devices) == 0 else { return false }
    for dev in devices {
        var running: UInt32 = 0
        let rsize = UInt32(MemoryLayout<UInt32>.size)
        var raddr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
                                              mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
                                              mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard))
        var rused: UInt32 = 0
        if CMIOObjectGetPropertyData(dev, &raddr, 0, nil, rsize, &rused, &running) == 0, running != 0 { return true }
    }
    return false
}

/// App name for a pid, reduced to safe characters for the bar label.
func appName(_ pid: pid_t?) -> String {
    guard let pid, let app = NSRunningApplication(processIdentifier: pid) else { return "-" }
    let raw = app.localizedName ?? app.bundleIdentifier ?? "-"
    let safe = raw.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || " .-".unicodeScalars.contains($0) }
    let s = String(String.UnicodeScalarView(safe)).prefix(18)
    return s.isEmpty ? "-" : String(s)
}

let pid = micUser()
let cam = cameraInUse()
print("\(pid == nil ? 0 : 1)\t\(cam ? 1 : 0)\t\(appName(pid))")
