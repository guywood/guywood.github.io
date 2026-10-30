import SwiftUI

/// The "Why?" card: every concern the assessor raised, worst first, plus a suggested split.
///
/// Only the first three concerns are shown until the user taps "Show all"; `showAll` is owned by
/// the Load screen so the choice survives re-assessment.
struct WhyListView: View {
    let assessment: LoadAssessment
    let showNumericScore: Bool
    @Binding var showAll: Bool

    /// How many concerns are visible while the list is collapsed.
    private static let collapsedCount = 3

    private var visibleConcerns: [Concern] {
        if showAll {
            return assessment.concerns
        }
        return Array(assessment.concerns.prefix(WhyListView.collapsedCount))
    }

    private var hasMore: Bool {
        return assessment.concerns.count > WhyListView.collapsedCount
    }

    private var toggleTitle: String {
        return showAll ? "Show less" : "Show all \(assessment.concerns.count)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why?")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(visibleConcerns) { concern in
                ConcernRow(concern: concern, showNumericScore: showNumericScore)
            }

            if hasMore {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAll.toggle()
                    }
                } label: {
                    Text(toggleTitle)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderless)
            }

            if assessment.suggestedSplit.count >= 2 {
                Divider()
                SplitRecommendationView(groups: assessment.suggestedSplit)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

/// One concern: severity dot, message, detail and (optionally) the points it adds.
private struct ConcernRow: View {
    let concern: Concern
    let showNumericScore: Bool

    private var severityLabel: String {
        return "\(concern.severity.displayName) severity"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(concern.severity.color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
                .accessibilityLabel(severityLabel)
            VStack(alignment: .leading, spacing: 2) {
                Text(concern.message)
                    .font(.subheadline)
                Text(concern.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if showNumericScore {
                Text("+\(concern.points)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Split into": the groups a problem load could be washed as instead, one row per group.
struct SplitRecommendationView: View {
    let groups: [[LoadItem]]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Split into")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(groups.enumerated()), id: \.offset) { pair in
                SplitGroupRow(
                    title: SplitRecommendationView.loadName(for: pair.offset),
                    items: pair.element
                )
            }
        }
    }

    /// "Load A", "Load B", … falling back to numbers after Z.
    static func loadName(for index: Int) -> String {
        let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        if index >= 0 && index < letters.count {
            return "Load \(letters[index])"
        }
        return "Load \(index + 1)"
    }
}

/// One suggested group: its title and a horizontally scrolling row of item-name chips.
private struct SplitGroupRow: View {
    let title: String
    let items: [LoadItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(items) { item in
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color(.tertiarySystemGroupedBackground)))
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WhyListView(
        assessment: assessLoad([
            LoadItem(name: "Red hoodie", colourGroup: .reds, fabricWeight: .heavy),
            LoadItem(name: "White t-shirts", colourGroup: .whites, fabricWeight: .light, quantity: 3),
            LoadItem(name: "Lace underwear", colourGroup: .lights, fabricWeight: .delicate),
        ]),
        showNumericScore: true,
        showAll: .constant(false)
    )
    .padding()
}
