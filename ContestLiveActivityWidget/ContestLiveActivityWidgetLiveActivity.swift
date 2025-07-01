import ActivityKit
import WidgetKit
import SwiftUI

struct ContestLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ContestCountdownAttributes.self) { context in
            // Lock Screen / Banner UI
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(spacing: 12) {
                    Text(context.attributes.contestName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    // Timer
                    Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    // Progress bar
                    ProgressView(
                        value: min(
                            max(
                                Date().timeIntervalSince(context.state.startDate) /
                                max(context.state.endDate.timeIntervalSince(context.state.startDate), 1),
                                0
                            ),
                            1
                        )
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(height: 8)
                }
                .padding()
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.contestName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                            .font(.title2.monospacedDigit())
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Optionally add more info here
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: min(
                            max(
                                Date().timeIntervalSince(context.state.startDate) /
                                max(context.state.endDate.timeIntervalSince(context.state.startDate), 1),
                                0
                            ),
                            1
                        )
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(height: 8)
                }
            } compactLeading: {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            } compactTrailing: {
                let remaining = max(context.state.endDate.timeIntervalSinceNow, 0)
                let minutes = Int(remaining) / 60
                let seconds = Int(remaining) % 60
                Text(String(format: "%d:%02d", minutes, seconds))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}

// MARK: - Preview
struct ContestLiveActivityWidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = ContestCountdownAttributes(contestName: "Codeforces Round 1034 (Div. 3)")
    static let contentState = ContestCountdownAttributes.ContentState(
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 2 + 15 * 60) // 2h 15m
    )
    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Lock Screen")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Dynamic Island Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Dynamic Island Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Dynamic Island Minimal")
    }
}
