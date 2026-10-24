import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FocusTimerBundle: WidgetBundle {
  var body: some Widget {
    FocusTimerLiveActivity()
  }
}

private let navy = Color(red: 0x2B / 255, green: 0x3B / 255, blue: 0x5B / 255)
private let cream = Color(red: 0xF1 / 255, green: 0xE8 / 255, blue: 0xD0 / 255)
private let yellow = Color(red: 1, green: 0xF8 / 255, blue: 0xA5 / 255)

private extension Color {
  init(rgb: Int) {
    self.init(red: Double(rgb >> 16 & 0xFF) / 255, green: Double(rgb >> 8 & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
  }
}

struct FocusTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusAttributes.self) { context in
      LockScreenView(context: context)
        .activityBackgroundTint(yellow.opacity(0.92))
        .activitySystemActionForegroundColor(navy)
    } dynamicIsland: { context in
      let sand = Color(rgb: context.attributes.color)
      let range = context.state.start...context.state.end
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          SandGlass(range: range, sand: sand, ink: cream).frame(width: 34, height: 50).padding(.leading, 6)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.goal.uppercased())
            .font(.system(size: 15, weight: .semibold))
            .lineLimit(1)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(timerInterval: range, countsDown: true)
            .font(.system(size: 28, weight: .bold).monospacedDigit())
            .foregroundStyle(sand)
            .frame(width: 92)
        }
      } compactLeading: {
        SandGlass(range: range, sand: sand, ink: cream).frame(width: 14, height: 20)
      } compactTrailing: {
        Text(timerInterval: range, countsDown: true)
          .monospacedDigit()
          .foregroundStyle(sand)
          .frame(width: 44)
      } minimal: {
        SandGlass(range: range, sand: sand, ink: cream).frame(width: 14, height: 20)
      }
    }
  }
}

private struct LockScreenView: View {
  let context: ActivityViewContext<FocusAttributes>

  var body: some View {
    let range = context.state.start...context.state.end
    HStack(spacing: 18) {
      SandGlass(range: range, sand: Color(rgb: context.attributes.color))
        .frame(width: 58, height: 84)
      VStack(alignment: .leading, spacing: 2) {
        Text(context.attributes.goal.uppercased())
          .font(.system(size: 17, weight: .semibold))
          .lineLimit(1)
        Text(timerInterval: range, countsDown: true)
          .font(.system(size: 44, weight: .bold).monospacedDigit())
        Text(Locale.current.language.languageCode?.identifier == "es" ? "Tiempo restante" : "Focus time left")
          .font(.system(size: 13))
          .opacity(0.75)
      }
      Spacer(minLength: 0)
    }
    .foregroundStyle(navy)
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
  }
}

/// The hourglass. Widgets can't run their own animations, but iOS keeps a
/// timer-driven progress bar moving on its own, so each bulb is one such
/// bar turned upright and cut to the glass's shape: the top one empties
/// while the bottom one fills.
private struct SandGlass: View {
  let range: ClosedRange<Date>
  let sand: Color
  /// The frame: navy on the lock screen, cream on the black Dynamic Island.
  var ink = navy

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width, h = geo.size.height
      let bulb = h * 0.42
      ZStack {
        VStack(spacing: h * 0.16) {
          bar(countsDown: true, width: w, height: bulb).mask(Bulb(top: true))
          bar(countsDown: false, width: w, height: bulb).mask(Bulb(top: false))
        }
        GlassOutline()
          .stroke(ink, style: StrokeStyle(lineWidth: max(1.2, w * 0.05), lineJoin: .round))
        VStack {
          Capsule().fill(ink).frame(height: max(2, h * 0.05))
          Spacer()
          Capsule().fill(ink).frame(height: max(2, h * 0.05))
        }
      }
    }
  }

  private func bar(countsDown: Bool, width: CGFloat, height: CGFloat) -> some View {
    ProgressView(timerInterval: range, countsDown: countsDown) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    }
    .progressViewStyle(.linear)
    .tint(sand)
    .labelsHidden()
    .frame(width: height)
    .scaleEffect(x: 1, y: width, anchor: .center)
    .rotationEffect(.degrees(-90))
    .frame(width: width, height: height)
    .clipped()
  }
}

/// One bulb, in its own frame: widest at the outer end, pinched at the neck.
private struct Bulb: Shape {
  let top: Bool

  func path(in r: CGRect) -> Path {
    var p = Path()
    let neck = r.width * 0.06
    p.move(to: CGPoint(x: r.minX + r.width * 0.08, y: r.minY))
    p.addLine(to: CGPoint(x: r.maxX - r.width * 0.08, y: r.minY))
    p.addCurve(
      to: CGPoint(x: r.midX + neck, y: r.maxY),
      control1: CGPoint(x: r.maxX - r.width * 0.08, y: r.minY + r.height * 0.55),
      control2: CGPoint(x: r.midX + neck, y: r.maxY - r.height * 0.3)
    )
    p.addLine(to: CGPoint(x: r.midX - neck, y: r.maxY))
    p.addCurve(
      to: CGPoint(x: r.minX + r.width * 0.08, y: r.minY),
      control1: CGPoint(x: r.midX - neck, y: r.maxY - r.height * 0.3),
      control2: CGPoint(x: r.minX + r.width * 0.08, y: r.minY + r.height * 0.55)
    )
    p.closeSubpath()
    if top { return p }
    return p.applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: r.minY + r.maxY))
  }
}

/// Both bulbs joined at the neck, for the outline.
private struct GlassOutline: Shape {
  func path(in r: CGRect) -> Path {
    let bulb = r.height * 0.42, gap = r.height * 0.16
    var p = Path()
    p.addPath(Bulb(top: true).path(in: CGRect(x: r.minX, y: r.minY, width: r.width, height: bulb)))
    p.addPath(Bulb(top: false).path(in: CGRect(x: r.minX, y: r.minY + bulb + gap, width: r.width, height: bulb)))
    // The neck between them.
    let neck = r.width * 0.06
    p.move(to: CGPoint(x: r.midX - neck, y: r.minY + bulb))
    p.addLine(to: CGPoint(x: r.midX - neck, y: r.minY + bulb + gap))
    p.move(to: CGPoint(x: r.midX + neck, y: r.minY + bulb))
    p.addLine(to: CGPoint(x: r.midX + neck, y: r.minY + bulb + gap))
    return p
  }
}
