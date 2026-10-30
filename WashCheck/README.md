# Wash Check

Wash Check is an iOS app that tells you whether a laundry load is safe to wash together. You keep a small library of the clothes you wash most often. Tap the ones going in and they fly into the drum of an animated washing machine. The app scores the load for colour bleeding and fabric clashes, shows the result on a gauge, explains every concern in plain language, and suggests how to split a bad load. Everything runs on the device. There are no accounts, no network calls and no analytics.

## Requirements

- Xcode 16 or newer. The project uses the folder-synchronised project format, which older versions of Xcode cannot open.
- iOS 17.0 or newer.
- Swift 5 language mode.
- No third-party dependencies.

## Getting started

1. Open `WashCheck.xcodeproj`.
2. Select the `WashCheck` scheme and an iOS 17 simulator.
3. Press ⌘R to run the app, or ⌘U to run the unit tests.

From the command line:

```sh
xcodebuild test -project WashCheck.xcodeproj -scheme WashCheck -destination 'platform=iOS Simulator,name=iPhone 16'
```

The bundle identifier is `com.example.washcheck`. The simulator needs no signing. A signing team is needed only to run on a physical device; set one under Signing & Capabilities for the `WashCheck` target.

## Project layout

```
WashCheck/
  WashCheck.xcodeproj/          Xcode project. Folder-synchronised; the source of truth.
  project.yml                   Optional XcodeGen spec (see the last section).
  README.md
  .gitignore                    Xcode user data and build products.
  WashCheck/                    App target. Every file in this folder compiles into the app.
    WashCheckApp.swift          Entry point: creates the ModelContainer, seeds starters, shows RootView.
    Models/
      ColourGroup.swift         Six colour families and their default bleed risk.
      BleedRisk.swift           Low, Medium, High, plus the "new item" bump.
      FabricWeight.swift        Delicate, Light, Medium, Heavy.
      ItemFlags.swift           Lint shedder, hardware, wool, athletic, hand-wash only.
      ItemIcon.swift            Emoji or SF Symbol glyph, stored as one string.
      LoadItem.swift            Value snapshot that the scoring engine consumes.
      ClothingItem.swift        SwiftData model, seeding and reset.
      StarterItems.swift        The twelve items a fresh install starts with.
    Scoring/
      ScoringWeights.swift      Every tunable number in one struct.
      Concern.swift             One flagged problem: kind, severity, points, message.
      ConcernLevel.swift        Safe, Mild caution, Caution, Don't wash together.
      LoadAssessment.swift      Score, level, concerns, headline and suggested split.
      LoadAssessor.swift        The rules. assessLoad(_:weights:) lives here.
      LoadSplitter.swift        Greedy split into concern-free groups.
    ViewModels/
      LoadViewModel.swift       Memoised assessment, card flights, drum speed and tint.
      AppSettings.swift         UserDefaults keys and their defaults.
    Views/
      RootView.swift            Tab bar: Load, Items, Settings.
      Load/
        LoadScreen.swift        Home screen. Owns the reported frames and the flights.
        FlightOverlayView.swift A card flying along an arc between grid and porthole.
        ItemGridView.swift      The "Your items" grid and the "Add item" card.
        ItemCardView.swift      One tappable card; reports its frame.
        WhyListView.swift       Concern list and the split recommendation.
      Machine/
        WashingMachineView.swift  Machine body, control strip, indicator lights, porthole.
        DrumView.swift            Rotating drum with fins and item chips.
      Gauge/
        ConcernGaugeView.swift  Thermometer gauge with threshold ticks.
        GaugePalette.swift      Green to red colours for fractions and levels.
      Items/
        ItemsLibraryView.swift  Searchable, reorderable list of every item.
        ItemEditorSheet.swift   Add or edit an item.
        IconPickerView.swift    Emoji and symbol grid.
      Settings/
        SettingsView.swift        Haptics, numeric scores, reset, about.
        HowScoringWorksView.swift Rules and bands, read from ScoringWeights.
      Shared/
        FramePreferences.swift  Frame reporting for the flight animation.
        Haptics.swift           Feedback generators that honour the Haptics setting.
        ColourSupport.swift     Swatches, hex colours, item tint.
        ItemIconView.swift      Renders an ItemIcon.
    Resources/
      Assets.xcassets           App icon and accent colour.
    Preview Content/
      Preview Assets.xcassets   Assets used only by Xcode previews.
  Tests/                        WashCheckTests target.
    TestSupport.swift
    ModelTests.swift
    LoadAssessorTests.swift
    LoadSplitterTests.swift
    ConcernLevelTests.swift
    ClothingItemStoreTests.swift
```

## How it works

The Load tab is the home screen (`LoadScreen`). It queries every `ClothingItem` sorted by `sortOrder`. The items whose `isInDrum` flag is set are the current load.

1. You tap a card in the "Your items" grid.
2. `LoadScreen.toggle` asks `LoadViewModel.startFlight` for a `CardFlight`. The flight records the card's frame and the porthole's frame.
3. `FlightOverlayView` animates the card along an arc into the porthole. When the animation completes, `LoadViewModel.finishFlight` sets `isInDrum` on the SwiftData object. The change is persisted, so the last load survives a relaunch.
4. `LoadViewModel.assessment(for:)` calls `assessLoad` on the drum contents and memoises the result.
5. The `LoadAssessment` drives everything else: the thermometer gauge, the level label and headline, the "Why?" list of concerns, the split suggestion, the machine's indicator lights, the drum speed and the pink tint on the porthole glass.

Tapping a chip inside the porthole flies the item back out. "Empty the drum" clears the whole load.

Where things live:

- Geometry: `Views/Shared/FramePreferences.swift`. `reportFrame(_:)` reports a view's frame in the named coordinate space `FrameSpace.name`, which `LoadScreen` declares on its root `ZStack`. `ItemCardView` reports `.card(uuid)` and the porthole glass in `WashingMachineView` reports `.porthole`.
- Flight animation: `Views/Load/FlightOverlayView.swift`. `FlightPathModifier` is `Animatable` on `progress`. It moves the glyph along a quadratic Bézier curve and scales it on the way.
- Drum rotation: `Views/Machine/DrumView.swift`. A `TimelineView` drives the angle. The angle is anchored to a date so a speed change never makes it jump. The drum pauses when empty.
- Gauge: `Views/Gauge/ConcernGaugeView.swift` and `GaugePalette.swift`. Fill height and colour animate with a spring on the score.
- Haptics: `Views/Shared/Haptics.swift`. Views call it directly: a light impact when a card lands, a selection tick when one leaves, and a success notification when the drum is emptied or the library is reset. The view model never fires haptics. The wrapper honours the Haptics toggle in Settings.
- Persistence: `Models/ClothingItem.swift`. One SwiftData model. `WashCheckApp` creates the container and seeds the twelve starter items on first launch.

## Scoring rules

`assessLoad` checks every unordered pair of items, then every single item, then the whole load. Each rule that fires produces a `Concern` with a severity and a number of points. Points are added up to give the score. The tables below match `LoadAssessor.swift` and `ScoringWeights.swift`.

### Colour bleeding

Bleed rules look at the source item's effective bleed risk and the receiving item's colour group. They apply only to items from different colour groups.

| Rule | Points | Severity |
| --- | --- | --- |
| High bleed-risk item with any Whites or Lights item | 40 | High |
| High bleed-risk item with a Brights item from another group | 20 | Medium |
| Medium bleed-risk item with a Whites item | 20 | Medium |
| Medium bleed-risk item with a Lights item | 10 | Low |
| Reds/Pinks source with anything other than Darks (extra) | 15 | Low when it stands alone; otherwise the severity of the rule it joins |
| Each new or never washed item in the pair (extra) | 10 | Same as the concern it adds to |

### Fabric thickness and delicacy

| Rule | Points | Severity |
| --- | --- | --- |
| Heavy item with a Delicate item | 35 | High |
| Heavy item with a Light item | 15 | Medium |
| Medium item with a Delicate item | 15 | Medium |
| Lint shedder with a Darks item or any Delicate item | 15 | Medium |
| Item with zips or hooks with a Delicate item | 20 | High |
| Wool or cashmere with anything Heavy | 15 | Medium |
| Athletic/synthetic with a Heavy lint shedder | 10 | Low |

### Single item and whole load

| Rule | Points | Severity |
| --- | --- | --- |
| Hand-wash only item in a load with two or more other items | 25 | High |
| Load spans Delicate through Heavy | 10 | Low |

### Levels and cap

The score is capped at 100 (`maximumScore`). The capped score maps to a level using the thresholds in `ScoringWeights`.

| Score | Level |
| --- | --- |
| 0–19 | Safe |
| 20–44 | Mild caution |
| 45–69 | Caution |
| 70–100 | Don't wash together |

Concerns are listed worst first: by severity, then points, then message.

## Interpretation notes

These are the decisions the code makes where the rules could be read more than one way.

- Items in the same colour group never bleed onto each other, whatever their risk.
- The Reds/Pinks extra is applied once per pair, when the red item is the source. It stands alone as a low-severity concern when no other bleed rule fired. Reds with Darks is exempt.
- "New or never washed" bumps the item's bleed risk one level (saturating at High) and adds 10 points per new item in the pair. The receiving item counts too, so a pair with two new items adds 20.
- Two lint shedders together raise no lint concern.
- The wool rule and the athletic rule each count once per pair, even when both items qualify.
- Hand-wash only fires when there are two or more other items in the load. One companion is allowed.
- The whole-load span is added once, however many items sit at each extreme.
- Quantity never changes the score. It is shown on chips and cards only.
- A weight set to 0 disables its rule. Concerns with zero points are dropped.
- The split is greedy. The most-conflicted items are placed first. Each item joins the first group it can enter without creating any concern, and a new group is opened when none will take it. Groups are shown in the original item order. A split is only suggested when the load has a concern and at least two items.

## Tuning the weights

`ScoringWeights` is the single place every number lives. Edit the values in `Scoring/ScoringWeights.swift` to retune the app: the engine, the gauge ticks and the "How scoring works" screen all read `ScoringWeights.default`, so they cannot drift apart. `assessLoad(_:weights:)` and `LoadViewModel.weights` also accept a custom instance, which is how the tests exercise alternative weights; the explainer screen always shows the defaults.

```swift
var weights = ScoringWeights.default
weights.highBleedWithWhitesOrLights = 50
weights.redsExtra = 0 // switches the rule off
let result = assessLoad(items, weights: weights)
print(result.score, result.level.displayName)
```

## Accessibility

- VoiceOver: every card, drum chip and the gauge has a label. Cards announce their bleed risk, fabric weight and whether they are in the drum. The gauge reports the level and the score out of the maximum. Concern rows read as one element.
- Reduce Motion: cards crossfade into the drum instead of flying, chips fade instead of scaling, and the drum stays still.
- Dynamic Type: text uses system text styles throughout. Long labels wrap or scale down rather than clip.
- Dark mode: only system colours and materials are used.
- Haptics can be switched off in Settings. Scores can be shown as numbers for people who prefer them to the gauge alone.

## Tests

All tests live in `Tests/` and run in the `WashCheckTests` target with ⌘U.

- `TestSupport.swift`: shared `TestItems` builders, `concerns(withPrefix:)` on `LoadAssessment`, and `assertValidSplit` which checks that every group is concern-free and that the groups partition the input.
- `ModelTests.swift`: default bleed risk per colour group, `LoadItem` defaults, the quantity floor, the bleed-risk bump, fabric weight ordering, flag names, icon storage round trips and the starter items.
- `LoadAssessorTests.swift`: the required scenarios (empty load, single item, red hoodie with whites, towels with silk, all darks, hand-wash only), every bleed and fabric rule, the cap, ordering, pair symmetry, custom weights, stable concern identifiers and quantity.
- `LoadSplitterTests.swift`: no split for fine or tiny loads, whites kept together and away from red, hand-wash isolation, the full starter library, order within groups, custom weights and determinism.
- `ConcernLevelTests.swift`: thresholds, lower bounds, ordering, custom thresholds and display names.
- `ClothingItemStoreTests.swift`: SwiftData round trips against an in-memory store: seeding once only, reset, and the typed accessors.

## Regenerating the project (optional)

The checked-in `WashCheck.xcodeproj` is the source of truth. You do not need XcodeGen to build or run the app.

`project.yml` exists only so the project can be rebuilt from scratch if it is ever damaged. Running `xcodegen generate` in the `WashCheck/` folder overwrites the checked-in project with one generated from the spec.
