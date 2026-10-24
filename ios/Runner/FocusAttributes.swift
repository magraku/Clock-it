import ActivityKit
import Foundation

/// A running focus timer, shown on the lock screen and in the Dynamic Island.
/// Shared by the app (which starts and ends it) and the FocusTimer widget.
struct FocusAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// When the sand would have started falling (pauses already left out),
    /// and when it runs out.
    var start: Date
    var end: Date
  }

  var goalId: String
  var goal: String
  /// The goal's colour as 0xRRGGBB, for the sand.
  var color: Int
}
