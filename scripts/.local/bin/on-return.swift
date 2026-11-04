// on-return <command…>: runs the command each time Bassim comes back to this Mac, when its screen
// unlocks or it wakes, once a minute at most.
import AppKit

let command = Array(CommandLine.arguments.dropFirst())
var last = Date.distantPast

func returned(_: Notification) {
  guard Date().timeIntervalSince(last) > 60 else { return }
  last = Date()
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = command
  try? process.run()
}

DistributedNotificationCenter.default().addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main, using: returned)
NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: returned)
RunLoop.main.run()
