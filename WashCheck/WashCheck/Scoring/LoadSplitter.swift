import Foundation

/// Greedily partitions a load into the fewest groups it can find where every group is concern-free.
///
/// Items with the most conflicts are placed first (the usual greedy-colouring heuristic),
/// and each item joins the first existing group it can enter without creating a concern.
/// Group membership is checked with the full assessor, so single-item and whole-load rules
/// (hand-wash only, mixed weight span) are honoured as well as pair rules.
struct LoadSplitter: Sendable {
    let assessor: LoadAssessor

    init(assessor: LoadAssessor = LoadAssessor()) {
        self.assessor = assessor
    }

    /// Returns two or more groups, or an empty array when no split is needed.
    func split(_ items: [LoadItem]) -> [[LoadItem]] {
        guard items.count >= 2 else { return [] }
        guard !assessor.assess(items, includeSplit: false).concerns.isEmpty else { return [] }

        let ordered = orderedByConflicts(items)
        var groups: [[LoadItem]] = []

        for item in ordered {
            var placed = false
            for index in groups.indices {
                let candidate = groups[index] + [item]
                if assessor.assess(candidate, includeSplit: false).concerns.isEmpty {
                    groups[index].append(item)
                    placed = true
                    break
                }
            }
            if !placed {
                groups.append([item])
            }
        }

        // Present each group in the caller's original order so the chips read naturally.
        let originalIndex = Dictionary(items.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
        let restored = groups.map { group in
            group.sorted { (originalIndex[$0.id] ?? 0) < (originalIndex[$1.id] ?? 0) }
        }
        return restored.count >= 2 ? restored : []
    }

    /// Items sorted by how many pair concerns they take part in, most first. Stable for ties.
    private func orderedByConflicts(_ items: [LoadItem]) -> [LoadItem] {
        var conflictCount: [UUID: Int] = [:]
        for i in items.indices {
            for j in items.indices where j > i {
                let concerns = assessor.pairConcerns(items[i], items[j])
                if !concerns.isEmpty {
                    conflictCount[items[i].id, default: 0] += concerns.count
                    conflictCount[items[j].id, default: 0] += concerns.count
                }
            }
        }
        let indexed = items.enumerated().map { ($0.offset, $0.element) }
        return indexed.sorted { lhs, rhs in
            let l = conflictCount[lhs.1.id] ?? 0
            let r = conflictCount[rhs.1.id] ?? 0
            if l != r { return l > r }
            return lhs.0 < rhs.0
        }.map { $0.1 }
    }
}
