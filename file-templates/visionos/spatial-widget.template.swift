//
//  [WIDGET_NAME].swift
//  [PROJECT_NAME]
//
//  Created by [AUTHOR] on [DATE].
//
//  [DESCRIPTION]
//

import SwiftUI
import WidgetKit
import RealityKit
import RealityKitContent

/// [WIDGET_DESCRIPTION]
///
/// This spatial widget provides:
/// - [FEATURE_1]
/// - [FEATURE_2]
/// - [FEATURE_3]
///
/// Usage:
/// Add to your WidgetBundle:
/// ```swift
/// @main
/// struct MyWidgets: WidgetBundle {
///     var body: some Widget {
///         [WIDGET_NAME]()
///     }
/// }
/// ```
struct [WIDGET_NAME]: Widget {

    // MARK: - Widget Configuration

    let kind: String = "[WIDGET_KIND]"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            [WIDGET_NAME]EntryView(entry: entry)
                .containerBackground(for: .widget) {
                    // Widget background
                    Color.clear
                }
        }
        .configurationDisplayName("[DISPLAY_NAME]")
        .description("[WIDGET_DESCRIPTION_SHORT]")
        .supportedFamilies([.systemMedium, .systemLarge])
        // VisionOS 2.6 specific modifiers
        .preferredColorScheme(.automatic)
        .contentMarginsDisabled()
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {

    // MARK: - Timeline Entry

    struct SimpleEntry: TimelineEntry {
        let date: Date
        let data: WidgetData
        let configuration: WidgetConfiguration
    }

    // MARK: - Widget Data Model

    struct WidgetData {
        let title: String
        let subtitle: String?
        let primaryValue: String
        let secondaryValue: String?
        let status: WidgetStatus
        let lastUpdate: Date
        let spatialElements: [SpatialElement]

        enum WidgetStatus: String, CaseIterable {
            case active = "active"
            case inactive = "inactive"
            case loading = "loading"
            case error = "error"

            var color: Color {
                switch self {
                case .active: return .green
                case .inactive: return .secondary
                case .loading: return .blue
                case .error: return .red
                }
            }

            var icon: String {
                switch self {
                case .active: return "checkmark.circle.fill"
                case .inactive: return "pause.circle.fill"
                case .loading: return "arrow.triangle.2.circlepath.circle.fill"
                case .error: return "exclamationmark.circle.fill"
                }
            }
        }

        struct SpatialElement {
            let id: UUID = UUID()
            let type: ElementType
            let position: SIMD3<Float>
            let scale: Float
            let rotation: simd_quatf
            let material: MaterialType

            enum ElementType {
                case sphere
                case cube
                case cylinder
                case custom(String)
            }

            enum MaterialType {
                case color(Color)
                case material(String)
                case metallic
                case glass
            }
        }
    }

    /// Widget configuration options
    struct WidgetConfiguration {
        let showSpatialElements: Bool
        let animationEnabled: Bool
        let updateInterval: TimeInterval
        let maxElements: Int

        static let `default` = WidgetConfiguration(
            showSpatialElements: true,
            animationEnabled: true,
            updateInterval: 60.0, // 1 minute
            maxElements: 5
        )
    }

    // MARK: - Timeline Provider Methods

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            data: sampleData(),
            configuration: .default
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            data: sampleData(),
            configuration: .default
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            do {
                let data = try await fetchWidgetData()
                let entry = SimpleEntry(
                    date: Date(),
                    data: data,
                    configuration: .default
                )

                // Create timeline with updates every hour
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
                completion(timeline)

            } catch {
                // Fallback to sample data on error
                let entry = SimpleEntry(
                    date: Date(),
                    data: sampleData(),
                    configuration: .default
                )
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))) // Retry in 30 minutes
                completion(timeline)
            }
        }
    }

    // MARK: - Data Fetching

    /// Fetch live widget data
    private func fetchWidgetData() async throws -> WidgetData {
        // TODO: Implement your data fetching logic here
        // This should connect to your app's data source

        // Simulate network request
        try await Task.sleep(for: .milliseconds(100))

        return WidgetData(
            title: "[DYNAMIC_TITLE]",
            subtitle: "[DYNAMIC_SUBTITLE]",
            primaryValue: "\(Int.random(in: 1...100))",
            secondaryValue: "\(Int.random(in: 1...50))",
            status: .active,
            lastUpdate: Date(),
            spatialElements: generateSpatialElements()
        )
    }

    /// Generate sample data for preview/placeholder
    private func sampleData() -> WidgetData {
        return WidgetData(
            title: "[SAMPLE_TITLE]",
            subtitle: "[SAMPLE_SUBTITLE]",
            primaryValue: "42",
            secondaryValue: "24",
            status: .active,
            lastUpdate: Date(),
            spatialElements: generateSpatialElements()
        )
    }

    /// Generate spatial elements for 3D visualization
    private func generateSpatialElements() -> [WidgetData.SpatialElement] {
        return [
            WidgetData.SpatialElement(
                type: .sphere,
                position: SIMD3(0, 0, 0),
                scale: 0.5,
                rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                material: .color(.blue)
            ),
            WidgetData.SpatialElement(
                type: .cube,
                position: SIMD3(0.3, 0, 0),
                scale: 0.3,
                rotation: simd_quatf(angle: .pi / 4, axis: [0, 1, 0]),
                material: .metallic
            ),
            WidgetData.SpatialElement(
                type: .cylinder,
                position: SIMD3(-0.3, 0, 0),
                scale: 0.4,
                rotation: simd_quatf(angle: 0, axis: [1, 0, 0]),
                material: .glass
            )
        ]
    }
}

// MARK: - Widget Entry View

struct [WIDGET_NAME]EntryView: View {

    // MARK: - Properties

    var entry: Provider.SimpleEntry

    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    /// Animation state for spatial elements
    @State private var animationPhase: Double = 0

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            spatialWidgetContent(geometry: geometry)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Content Views

    /// Main spatial widget content
    @ViewBuilder
    private func spatialWidgetContent(geometry: GeometryProxy) -> some View {
        ZStack {
            // Background with spatial depth
            backgroundLayer

            // Main content based on widget family
            switch family {
            case .systemMedium:
                mediumWidgetLayout(geometry: geometry)
            case .systemLarge:
                largeWidgetLayout(geometry: geometry)
            default:
                compactWidgetLayout(geometry: geometry)
            }

            // Floating spatial elements overlay
            if entry.configuration.showSpatialElements {
                spatialElementsOverlay(geometry: geometry)
            }
        }
    }

    /// Background layer with spatial materials
    @ViewBuilder
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.quaternary, lineWidth: 0.5)
            }
    }

    /// Medium widget layout
    @ViewBuilder
    private func mediumWidgetLayout(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            Spacer()
            contentRow
            Spacer()
            statusRow
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Large widget layout
    @ViewBuilder
    private func largeWidgetLayout(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    contentRow
                    statusRow
                    lastUpdateRow
                }

                Spacer()

                // 3D visualization area
                spatialVisualization
                    .frame(width: geometry.size.width * 0.4)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Compact widget layout
    @ViewBuilder
    private func compactWidgetLayout(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.data.title)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)

            HStack {
                Text(entry.data.primaryValue)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                statusIcon
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Header row with title and subtitle
    @ViewBuilder
    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.data.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if let subtitle = entry.data.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Content row with primary values
    @ViewBuilder
    private var contentRow: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.data.primaryValue)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Primary")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let secondaryValue = entry.data.secondaryValue {
                VStack(alignment: .leading, spacing: 2) {
                    Text(secondaryValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Secondary")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    /// Status row with current state
    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 8) {
            statusIcon

            Text(entry.data.status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(entry.data.status.color)

            Spacer()
        }
    }

    /// Last update information
    @ViewBuilder
    private var lastUpdateRow: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text("Updated \(entry.data.lastUpdate, style: .relative) ago")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    /// Status icon
    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: entry.data.status.icon)
            .font(.caption)
            .foregroundStyle(entry.data.status.color)
            .symbolEffect(.pulse, options: .repeating, value: entry.data.status == .loading)
    }

    /// 3D spatial visualization
    @ViewBuilder
    private var spatialVisualization: some View {
        ZStack {
            // Background for 3D area
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
                .stroke(.quaternary, lineWidth: 1)

            // Simulated 3D elements using SwiftUI transforms
            ForEach(Array(entry.data.spatialElements.enumerated()), id: \.offset) { index, element in
                spatialElementView(element: element, index: index)
            }
        }
    }

    /// Individual spatial element view
    @ViewBuilder
    private func spatialElementView(element: Provider.WidgetData.SpatialElement, index: Int) -> some View {
        let animatedOffset = sin(animationPhase + Double(index) * 0.5) * 10
        let animatedRotation = animationPhase * 45 + Double(index) * 30

        Circle()
            .fill(materialForElement(element.material))
            .frame(width: 20 * CGFloat(element.scale), height: 20 * CGFloat(element.scale))
            .offset(
                x: CGFloat(element.position.x * 50) + animatedOffset,
                y: CGFloat(element.position.y * 50)
            )
            .rotationEffect(.degrees(animatedRotation))
            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }

    /// Floating spatial elements overlay
    @ViewBuilder
    private func spatialElementsOverlay(geometry: GeometryProxy) -> some View {
        ForEach(Array(entry.data.spatialElements.enumerated()), id: \.offset) { index, element in
            floatingElement(element: element, index: index, in: geometry)
        }
    }

    /// Floating element with animation
    @ViewBuilder
    private func floatingElement(element: Provider.WidgetData.SpatialElement, index: Int, in geometry: GeometryProxy) -> some View {
        let floatOffset = sin(animationPhase * 0.7 + Double(index)) * 3
        let position = CGPoint(
            x: geometry.size.width * (0.2 + Double(index) * 0.15),
            y: geometry.size.height * 0.3
        )

        Circle()
            .fill(materialForElement(element.material).opacity(0.6))
            .frame(width: 6, height: 6)
            .position(x: position.x, y: position.y + floatOffset)
            .blur(radius: 0.5)
    }

    // MARK: - Helper Methods

    /// Convert material type to SwiftUI material
    private func materialForElement(_ material: Provider.WidgetData.MaterialType) -> AnyShapeStyle {
        switch material {
        case .color(let color):
            return AnyShapeStyle(color)
        case .material(let name):
            // Return appropriate material based on name
            return AnyShapeStyle(.regularMaterial)
        case .metallic:
            return AnyShapeStyle(.linearGradient(
                colors: [.gray, .white, .gray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .glass:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    /// Start widget animations
    private func startAnimations() {
        guard entry.configuration.animationEnabled else { return }

        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

// MARK: - Widget Bundle Integration

/// Extension to help integrate with WidgetBundle
extension [WIDGET_NAME] {
    /// Static widget configuration for easy bundle integration
    static func configure() -> some WidgetConfiguration {
        StaticConfiguration(kind: "[WIDGET_KIND]", provider: Provider()) { entry in
            [WIDGET_NAME]EntryView(entry: entry)
        }
        .configurationDisplayName("[DISPLAY_NAME]")
        .description("[WIDGET_DESCRIPTION_SHORT]")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Medium Widget", as: .systemMedium) {
    [WIDGET_NAME]()
} timeline: {
    Provider.SimpleEntry(
        date: .now,
        data: Provider().sampleData(),
        configuration: .default
    )
    Provider.SimpleEntry(
        date: .now.addingTimeInterval(300),
        data: Provider.WidgetData(
            title: "[SAMPLE_TITLE]",
            subtitle: "[SAMPLE_SUBTITLE]",
            primaryValue: "85",
            secondaryValue: "12",
            status: .loading,
            lastUpdate: .now.addingTimeInterval(-120),
            spatialElements: []
        ),
        configuration: .default
    )
}

#Preview("Large Widget", as: .systemLarge) {
    [WIDGET_NAME]()
} timeline: {
    Provider.SimpleEntry(
        date: .now,
        data: Provider().sampleData(),
        configuration: .default
    )
}

// MARK: - App Intent Support (Optional)

/// App Intent for widget configuration (iOS 17+)
@available(iOS 17.0, *)
struct Configure[WIDGET_NAME]Intent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "[WIDGET_INTENT_TITLE]"
    static var description = IntentDescription("[WIDGET_INTENT_DESCRIPTION]")

    @Parameter(title: "Show Spatial Elements")
    var showSpatialElements: Bool

    @Parameter(title: "Enable Animations")
    var enableAnimations: Bool

    @Parameter(title: "Update Frequency", default: .medium)
    var updateFrequency: UpdateFrequency

    enum UpdateFrequency: String, AppEnum, CaseDisplayRepresentable {
        case low = "low"
        case medium = "medium"
        case high = "high"

        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Update Frequency")

        static var caseDisplayRepresentations: [UpdateFrequency: DisplayRepresentation] = [
            .low: "Low (30 minutes)",
            .medium: "Medium (15 minutes)",
            .high: "High (5 minutes)"
        ]

        var timeInterval: TimeInterval {
            switch self {
            case .low: return 1800 // 30 minutes
            case .medium: return 900 // 15 minutes
            case .high: return 300 // 5 minutes
            }
        }
    }

    init() {
        showSpatialElements = true
        enableAnimations = true
        updateFrequency = .medium
    }
}

// MARK: - Template Placeholders
//
// Replace these placeholders when using this template:
//
// [WIDGET_NAME] - Name of your widget struct
// [PROJECT_NAME] - Name of your project
// [AUTHOR] - Author name
// [DATE] - Creation date
// [DESCRIPTION] - Brief description of the widget
// [WIDGET_DESCRIPTION] - Detailed description of what the widget shows
// [WIDGET_DESCRIPTION_SHORT] - Short description for widget configuration
// [FEATURE_1] - First main feature
// [FEATURE_2] - Second main feature
// [FEATURE_3] - Third main feature
// [WIDGET_KIND] - Unique identifier for the widget
// [DISPLAY_NAME] - Display name shown in widget gallery
// [SAMPLE_TITLE] - Sample title text
// [SAMPLE_SUBTITLE] - Sample subtitle text
// [DYNAMIC_TITLE] - Dynamic title for live data
// [DYNAMIC_SUBTITLE] - Dynamic subtitle for live data
// [WIDGET_INTENT_TITLE] - Title for widget configuration intent
// [WIDGET_INTENT_DESCRIPTION] - Description for widget configuration intent
//
// Example replacements:
// [WIDGET_NAME] -> ActivitySpatialWidget
// [WIDGET_KIND] -> "com.myapp.activity-spatial-widget"
// [DISPLAY_NAME] -> "Activity Monitor"
// [SAMPLE_TITLE] -> "Current Activity"
// [SAMPLE_SUBTITLE] -> "Real-time monitoring"