import SwiftUI

enum MainTab: Int, CaseIterable {
    case rating, submissions, home, contests, practice
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var tabBarOffset: CGFloat = 0 // <-- For draggable debug
    @State private var lastTabBarOffset: CGFloat = 0 // <-- For sticky drag

    // Tab data: (tab, outline icon)
    private let tabs: [(tab: MainTab, icon: String)] = [
        (.rating, "chart.line.uptrend.xyaxis"),
        (.submissions, "doc.text"),
        (.home, "house"),
        (.contests, "trophy"),
        (.practice, "target")
    ]

    var body: some View {
        let theme = colorThemeManager.current
        GeometryReader { geo in
            let tabCount = tabs.count
            let horizontalMargin: CGFloat = 6 // minimal margin to screen edge
            let barHeight: CGFloat = 72 // slightly taller for a more anchored look
            let tabWidth = (geo.size.width - horizontalMargin * 2) / CGFloat(tabCount)
            // let safeAreaBottom = geo.safeAreaInsets.bottom
            // let screenHeight = geo.size.height
            // let tabBarBottomPosition = screenHeight - barHeight - safeAreaBottom

            // --- Draggable handle and debug code (commented out for future use) ---
            /*
            VStack(spacing: 0) {
                // Grab handle
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 48, height: 8)
                    .padding(.bottom, 8)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                tabBarOffset = lastTabBarOffset + value.translation.height
                            }
                            .onEnded { _ in
                                lastTabBarOffset = tabBarOffset
                                print("TabBar y-offset: \(tabBarOffset)")
                            }
                    )
                    .accessibilityLabel("Drag to move TabBar")

                // The actual TabBar
                ZStack {
                    // Flat/glassy background with custom corners
                    AsymmetricRoundedRectangle(
                        topLeft: 6, topRight: 6, bottomLeft: 36, bottomRight: 36
                    )
                    .fill(theme.tabBar.opacity(0.85))
                    .background(
                        BlurView(style: .systemUltraThinMaterialDark)
                            .clipShape(AsymmetricRoundedRectangle(
                                topLeft: 6, topRight: 6, bottomLeft: 36, bottomRight: 36
                            ))
                    )
                    .overlay(
                        AsymmetricRoundedRectangle(
                            topLeft: 6, topRight: 6, bottomLeft: 36, bottomRight: 36
                        )
                        .stroke(theme.accent.opacity(0.10), lineWidth: 1.2)
                    )
                    .shadow(color: theme.accent.opacity(0.08), radius: 6, y: 1)
                    .frame(height: barHeight)
                    .padding(.horizontal, horizontalMargin)
                    .animation(.easeInOut, value: theme)

                    HStack(spacing: 0) {
                        ForEach(Array(tabs.enumerated()), id: \.offset) { idx, item in
                            tabButton(item.tab, icon: item.icon, theme: theme, width: tabWidth)
                        }
                    }
                    .padding(.horizontal, 0)
                    .frame(height: barHeight)
                }
            }
            .offset(y: tabBarOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                print("=== TabBar Debug Info ===")
                print("Screen height: \(screenHeight)")
                print("Safe area bottom: \(safeAreaBottom)")
                print("Tab bar height: \(barHeight)")
                print("Tab bar bottom position: \(tabBarBottomPosition)")
                print("Distance from absolute bottom: \(safeAreaBottom)")
                print("Recommended padding for 5pt gap: \(safeAreaBottom + 5)")
                print("Recommended padding for 10pt gap: \(safeAreaBottom + 10)")
                print("Recommended padding for 15pt gap: \(safeAreaBottom + 15)")
                print("=========================")
            }
            */
            // --- End commented debug/drag code ---

            // --- Final floating TabBar ---
            ZStack {
                // Flat/glassy background with custom corners
                AsymmetricRoundedRectangle(
                    topLeft: 6, topRight: 6, bottomLeft: 36, bottomRight: 36
                )
                .fill(theme.tabBar.opacity(0.85))
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .clipShape(AsymmetricRoundedRectangle(
                            topLeft: 6, topRight: 6, bottomLeft: 36, bottomRight: 36
                        ))
                )
                .overlay(
                    AsymmetricRoundedRectangle(
                        topLeft: 6, topRight: 6, bottomLeft: 36, bottomRight: 36
                    )
                    .stroke(theme.accent.opacity(0.10), lineWidth: 1.2)
                )
                .shadow(color: theme.accent.opacity(0.08), radius: 6, y: 1)
                .frame(height: barHeight)
                .padding(.horizontal, horizontalMargin)
                .animation(.easeInOut, value: theme)

                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { idx, item in
                        tabButton(item.tab, icon: item.icon, theme: theme, width: tabWidth)
                    }
                }
                .padding(.horizontal, 0)
                .frame(height: barHeight)
            }
            .padding(.bottom, geo.safeAreaInsets.bottom + 9) // <--- Use your found offset here
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            // --- End final floating TabBar ---
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .animation(.easeInOut, value: selectedTab)
    }

    @ViewBuilder
    func tabButton(_ tab: MainTab, icon: String, theme: ColorTheme, width: CGFloat) -> some View {
        let isActive = selectedTab == tab
        Button(action: { withAnimation(.easeInOut(duration: 0.18)) { selectedTab = tab } }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(isActive ? theme.accent : theme.text.opacity(0.5))
                .frame(width: width, height: 64)
        }
    }
}

// Glassmorphism BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 18.0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct AsymmetricRoundedRectangle: Shape {
    var topLeft: CGFloat
    var topRight: CGFloat
    var bottomLeft: CGFloat
    var bottomRight: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let width = rect.size.width
        let height = rect.size.height

        // Start at top left
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        // Top right corner
        path.addArc(withCenter: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight), radius: topRight, startAngle: -CGFloat.pi/2, endAngle: 0, clockwise: true)
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        // Bottom right corner
        path.addArc(withCenter: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight), radius: bottomRight, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        // Bottom left corner
        path.addArc(withCenter: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft), radius: bottomLeft, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi, clockwise: true)
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        // Top left corner
        path.addArc(withCenter: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft), radius: topLeft, startAngle: CGFloat.pi, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
        path.close()
        return Path(path.cgPath)
    }
}