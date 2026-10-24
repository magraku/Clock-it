import ActivityKit
import Flutter
import Foundation

/// `clockit/live`: starts and ends the focus timer's Live Activity.
enum LiveTimer {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "clockit/live", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else { return result(nil) }
      let args = call.arguments as? [String: Any] ?? [:]
      let id = args["id"] as? String ?? ""
      switch call.method {
      case "show":
        show(
          id: id,
          goal: args["goal"] as? String ?? "",
          color: args["color"] as? Int ?? 0x8DC740,
          start: Date(timeIntervalSince1970: (args["start"] as? Double ?? 0) / 1000),
          end: Date(timeIntervalSince1970: (args["end"] as? Double ?? 0) / 1000)
        )
        result(nil)
      case "end":
        end(id: id)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16.2, *)
  private static func show(id: String, goal: String, color: Int, start: Date, end: Date) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let state = FocusAttributes.ContentState(start: start, end: end)
    // The sand runs out on its own. After that it shows the empty glass
    // until the app ends it (next time it opens) or it's swiped away.
    let content = ActivityContent(state: state, staleDate: end)
    Self.end(id: id) // a goal never shows two
    _ = try? Activity.request(
      attributes: FocusAttributes(goalId: id, goal: goal, color: color),
      content: content
    )
  }

  @available(iOS 16.2, *)
  private static func end(id: String) {
    // Found through iOS, so this also ends ones from an earlier launch.
    for activity in Activity<FocusAttributes>.activities where activity.attributes.goalId == id {
      Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
  }
}
