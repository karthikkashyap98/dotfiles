// sbdisplays: lists the connected screens and says which one has a camera notch.
//
// Prints one tab-separated line per screen:  <CGDirectDisplayID> \t <builtin 0|1> \t <notch 0|1>
//
// The first column is the same number SketchyBar reports as "DirectDisplayID" in
// `sketchybar --query displays`, so the caller can map it to SketchyBar's arrangement-id.
// Notch = NSScreen.safeAreaInsets.top > 0 (macOS 12+). Needs no permissions: it only reads
// public screen geometry and never captures or touches screen contents.

import AppKit
import CoreGraphics

for screen in NSScreen.screens {
    guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
        continue
    }
    let id = CGDirectDisplayID(num.uint32Value)
    let builtin = CGDisplayIsBuiltin(id) != 0
    let notch = screen.safeAreaInsets.top > 0
    print("\(id)\t\(builtin ? 1 : 0)\t\(notch ? 1 : 0)")
}
