import SwiftUI

// MARK: - Design Tokens

struct DesignTokens {
    // Colors
    static let bgColor = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let cardBg = Color.white.opacity(0.03)
    static let cardBorder = Color.white.opacity(0.06)
    static let cardBorderHover = Color.white.opacity(0.12)
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.2)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.45, blue: 0.2), Color(red: 0.9, green: 0.3, blue: 0.1)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textTertiary = Color.white.opacity(0.35)

    // Animation
    static let cardHoverAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let buttonHoverAnimation = Animation.easeInOut(duration: 0.15)

    // Scale effects
    static let cardHoverScale: CGFloat = 1.005
    static let tileHoverScale: CGFloat = 1.02
    static let buttonHoverScale: CGFloat = 1.03
    static let pressScale: CGFloat = 0.97
}

// MARK: - Visual Effect Blur (NSVisualEffectView wrapper)

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Hover Card Modifier

struct HoverCardModifier: ViewModifier {
    let isHovered: Bool
    var scale: CGFloat = DesignTokens.cardHoverScale

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(DesignTokens.cardHoverAnimation, value: isHovered)
    }
}

extension View {
    func hoverCard(isHovered: Bool, scale: CGFloat = DesignTokens.cardHoverScale) -> some View {
        modifier(HoverCardModifier(isHovered: isHovered, scale: scale))
    }
}

// MARK: - Hover Button Modifier

struct HoverButtonModifier: ViewModifier {
    let isHovered: Bool
    var scale: CGFloat = DesignTokens.buttonHoverScale

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(DesignTokens.buttonHoverAnimation, value: isHovered)
    }
}

extension View {
    func hoverButton(isHovered: Bool, scale: CGFloat = DesignTokens.buttonHoverScale) -> some View {
        modifier(HoverButtonModifier(isHovered: isHovered, scale: scale))
    }
}

// MARK: - Press Effect Modifier

struct PressEffectModifier: ViewModifier {
    let isPressed: Bool
    var scale: CGFloat = DesignTokens.pressScale

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(DesignTokens.buttonHoverAnimation, value: isPressed)
    }
}

extension View {
    func pressEffect(isPressed: Bool, scale: CGFloat = DesignTokens.pressScale) -> some View {
        modifier(PressEffectModifier(isPressed: isPressed, scale: scale))
    }
}

// MARK: - Interactive Card Background

struct InteractiveCardBackground: View {
    let isHovered: Bool
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignTokens.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isHovered ? DesignTokens.cardBorderHover : DesignTokens.cardBorder,
                        lineWidth: 1
                    )
            )
            .animation(DesignTokens.cardHoverAnimation, value: isHovered)
    }
}
