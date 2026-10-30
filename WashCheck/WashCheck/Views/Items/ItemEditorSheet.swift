import SwiftData
import SwiftUI

/// Adds a new clothing item or edits an existing one. Pass `nil` to add.
///
/// Every field is edited on a local `@State` copy and written back (or inserted) on Save,
/// so Cancel never leaves a half-edited model behind.
struct ItemEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ClothingItem.sortOrder) private var allItems: [ClothingItem]

    /// The item being edited, or `nil` when adding a new one.
    private let item: ClothingItem?

    @State private var name: String
    @State private var icon: ItemIcon
    @State private var colourGroup: ColourGroup
    @State private var bleedRisk: BleedRisk
    @State private var isNew: Bool
    @State private var fabricWeight: FabricWeight
    @State private var flags: ItemFlags
    @State private var quantity: Int
    /// The colour shown in the picker. Only persisted when `usesCustomTint` is true.
    @State private var tint: Color
    @State private var usesCustomTint: Bool

    init(editing item: ClothingItem?) {
        self.item = item
        let group: ColourGroup = item?.colourGroup ?? ColourGroup.whites
        var customTint: Color? = nil
        if let hex = item?.tintHex {
            customTint = Color(hex: hex)
        }
        _name = State(initialValue: item?.name ?? "")
        _icon = State(initialValue: item?.icon ?? ItemIcon.defaultIcon)
        _colourGroup = State(initialValue: group)
        _bleedRisk = State(initialValue: item?.bleedRisk ?? group.defaultBleedRisk)
        _isNew = State(initialValue: item?.isNew ?? false)
        _fabricWeight = State(initialValue: item?.fabricWeight ?? FabricWeight.light)
        _flags = State(initialValue: item?.flags ?? ItemFlags())
        _quantity = State(initialValue: item?.quantity ?? 1)
        _tint = State(initialValue: customTint ?? group.swatch)
        _usesCustomTint = State(initialValue: customTint != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                colourSection
                bleedSection
                fabricSection
                flagsSection
                quantitySection
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        Haptics.notify(.success)
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    // MARK: - Derived values

    private var title: String {
        return item == nil ? "Add item" : "Edit item"
    }

    private var trimmedName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What VoiceOver reads for the current icon.
    private var iconDescription: String {
        switch icon {
        case .emoji(let value):
            return value
        case .symbol(let symbolName):
            return symbolName.replacingOccurrences(of: ".", with: " ")
        }
    }

    private var swatchColumns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

    private var tintFooter: String {
        if usesCustomTint {
            return "The card and drum chip use your custom tint."
        }
        return "The card and drum chip use the colour group's swatch."
    }

    /// Binding for the colour picker. Any change switches the item to a custom tint.
    private var tintBinding: Binding<Color> {
        return Binding<Color>(
            get: { tint },
            set: { newValue in
                tint = newValue
                usesCustomTint = true
            }
        )
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Name") {
            TextField("Name", text: $name)
            NavigationLink {
                IconPickerView(selection: $icon)
            } label: {
                HStack {
                    Text("Icon")
                    Spacer()
                    ItemIconView(icon: icon, size: 22)
                }
            }
            .accessibilityValue(iconDescription)
        }
    }

    private var colourSection: some View {
        Section {
            LazyVGrid(columns: swatchColumns, spacing: 10) {
                ForEach(ColourGroup.allCases) { group in
                    colourSwatchButton(for: group)
                }
            }
            .padding(.vertical, 4)
            ColorPicker("Card tint", selection: tintBinding, supportsOpacity: false)
            if usesCustomTint {
                Button("Use group colour") {
                    tint = colourGroup.swatch
                    usesCustomTint = false
                }
            }
        } header: {
            Text("Colour")
        } footer: {
            Text(tintFooter)
        }
    }

    private var bleedSection: some View {
        Section {
            Picker("Bleed risk", selection: $bleedRisk) {
                ForEach(BleedRisk.allCases) { risk in
                    Text(risk.displayName).tag(risk)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Toggle("New or never washed", isOn: $isNew)
        } header: {
            Text("Bleed risk")
        } footer: {
            Text("Bumps the risk up one level and adds extra points to any bleed concern.")
        }
    }

    private var fabricSection: some View {
        Section {
            Picker("Fabric weight", selection: $fabricWeight) {
                ForEach(FabricWeight.allCases) { weight in
                    Text(weight.displayName).tag(weight)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } header: {
            Text("Fabric weight")
        } footer: {
            Text(fabricWeight.examples)
        }
    }

    private var flagsSection: some View {
        Section("Flags") {
            ForEach(ItemFlags.allFlags, id: \.rawValue) { flag in
                Toggle(isOn: flagBinding(for: flag)) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(flag.displayName)
                            Text(flag.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: flag.symbolName)
                    }
                }
            }
        }
    }

    private var quantitySection: some View {
        Section {
            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...20)
        } footer: {
            Text("Shown on the drum chip. Quantity does not change the score.")
        }
    }

    // MARK: - Pieces

    /// One tappable swatch circle with the group's short name beneath it.
    private func colourSwatchButton(for group: ColourGroup) -> some View {
        let isSelected: Bool = (group == colourGroup)
        return Button {
            selectColourGroup(group)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                        .frame(width: 40, height: 40)
                        .opacity(isSelected ? 1 : 0)
                    Circle()
                        .fill(group.swatch)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                        }
                }
                Text(group.shortName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(group.displayName)
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    /// A Bool binding that inserts or removes one flag from the set.
    private func flagBinding(for flag: ItemFlags) -> Binding<Bool> {
        return Binding<Bool>(
            get: { flags.contains(flag) },
            set: { isOn in
                var updated: ItemFlags = flags
                if isOn {
                    updated.insert(flag)
                } else {
                    updated.remove(flag)
                }
                flags = updated
            }
        )
    }

    // MARK: - Actions

    /// Switches colour group, resets the bleed risk to the group default, and follows the group
    /// swatch unless the user has chosen a custom tint.
    private func selectColourGroup(_ group: ColourGroup) {
        guard group != colourGroup else { return }
        colourGroup = group
        bleedRisk = group.defaultBleedRisk
        if !usesCustomTint {
            tint = group.swatch
        }
    }

    /// Writes the edited fields back to the existing item, or inserts a new one at the end of the list.
    private func save() {
        let trimmed: String = trimmedName
        guard !trimmed.isEmpty else { return }
        let storedTintHex: String? = usesCustomTint ? tint.hexString : nil

        if let existing = item {
            existing.name = trimmed
            existing.icon = icon
            existing.colourGroup = colourGroup
            existing.bleedRisk = bleedRisk
            existing.isNew = isNew
            existing.fabricWeight = fabricWeight
            existing.flags = flags
            existing.quantity = quantity
            existing.tintHex = storedTintHex
        } else {
            let highestSortOrder: Int = allItems.map { $0.sortOrder }.max() ?? -1
            let newItem = ClothingItem(
                name: trimmed,
                icon: icon,
                colourGroup: colourGroup,
                bleedRisk: bleedRisk,
                isNew: isNew,
                fabricWeight: fabricWeight,
                flags: flags,
                quantity: quantity,
                tintHex: storedTintHex,
                sortOrder: highestSortOrder + 1
            )
            modelContext.insert(newItem)
        }
        try? modelContext.save()
        dismiss()
    }
}
