# Tower Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS app (Swift/SwiftUI, VLCKit) for watching live OTA TV from an HDHomeRun tuner, with channel list, playback, and program guide.

**Architecture:** Modular monolith with SwiftPM local packages (Core, TunerClient, GuideIngestion, PlaybackEngine, UI) wired via protocol-based DI in TowerApp. GRDB for guide database, VLCKit for playback, NWBrowser for discovery.

**Tech Stack:** Swift 6, SwiftUI, SwiftPM, VLCKit 3.6+, GRDB.swift, Network framework, XMLTV parsing (AEXML or XMLCoder).

**Spec:** `/Volumes/Users_Mount/Users/cbevard1/git/Tower/DESIGN.md`

## Global Constraints

- Target: macOS 15 (Tahoe), Intel Mac
- Swift 6 language mode, strict concurrency
- VLCKit dynamic framework (not static)
- 2-tuner HDHomeRun (Connect/Duo), auto-stop oldest on 3rd stream
- Single static XMLTV URL, user-provided
- Deinterlacing enabled by default (Yadif)
- Channel switch target: 1-3 seconds (acceptable)
- App Sandbox: Network Client + Outgoing Connections entitlements

## Review Focus

1. **Tuner discovery race**: App launches before network ready → discovery finds nothing → manual IP fallback must work
2. **VLCKit initialization on non-main thread**: VLCKit requires main thread; verify all player setup is @MainActor
3. **Guide time-zone mismatch**: XMLTV uses UTC, display uses local → all stored times UTC, convert only for display
4. **Tuner busy conflict**: 3rd stream request auto-stops oldest → toast notification must appear before switch completes
5. **XMLTV parse failure mid-refresh**: Partial parse must not corrupt existing guide data → transactional replace

---

## Phase 1: M1 — Minimal Viable Player (Weeks 1-3)

### Task 1.1: Project Setup & Module Scaffolding

**Files:**
- Create: `Package.swift` (workspace root)
- Create: `Core/Package.swift`, `Core/Sources/Core/`
- Create: `TunerClient/Package.swift`, `TunerClient/Sources/TunerClient/`
- Create: `PlaybackEngine/Package.swift`, `PlaybackEngine/Sources/PlaybackEngine/`
- Create: `UI/Package.swift`, `UI/Sources/UI/`
- Create: `TowerApp/Package.swift`, `TowerApp/Sources/TowerApp/`
- Create: `Tower.xcodeproj` (or `.xcworkspace` with local packages)

**Interfaces:**
- Produces: Module structure, import paths, DI container protocol

- [ ] **Step 1: Write Package.swift with local package dependencies**
- [ ] **Step 2: Create each module's Package.swift with proper products/targets**
- [ ] **Step 3: Create TowerApp target with @main App struct**
- [ ] **Step 4: Add VLCKit as binary dependency (Frameworks/VLCKit.xcframework)**
- [ ] **Step 5: Configure entitlements: com.apple.security.network.client, com.apple.security.network.server**
- [ ] **Step 6: Build and verify all modules compile**

```bash
swift build --package-path .
xcodebuild -scheme Tower -destination 'platform=macOS' build
```

### Task 1.2: Core Models & Protocols

**Files:**
- Create: `Core/Sources/Core/Models/Tuner.swift`
- Create: `Core/Sources/Core/Models/Channel.swift`
- Create: `Core/Sources/Core/Models/GuideEntry.swift`
- Create: `Core/Sources/Core/Protocols/TunerDiscoverer.swift`
- Create: `Core/Sources/Core/Protocols/LineupProvider.swift`
- Create: `Core/Sources/Core/Protocols/StreamURLBuilder.swift`
- Create: `Core/Sources/Core/Protocols/PlayerController.swift`
- Create: `Core/Sources/Core/Protocols/GuideProvider.swift`
- Create: `Core/Sources/Core/Protocols/GuideRepository.swift`
- Create: `Core/Sources/Core/Protocols/ChannelMatcher.swift`
- Create: `Core/Sources/Core/DI/Container.swift` (protocol + default impl)

**Interfaces:**
- Produces: All Core types and protocol signatures used by other modules

- [ ] **Step 1: Write failing tests for Channel.affineNumber sorting**
- [ ] **Step 2: Implement Tuner, Channel, GuideEntry structs with Sendable**
- [ ] **Step 3: Define all protocols with async/await signatures**
- [ ] **Step 4: Implement DI Container protocol with register/resolve**
- [ ] **Step 5: Run tests, verify compilation**

```bash
swift test --package-path . --filter CoreTests
```

### Task 1.3: HDHomeRun Discovery (SSDP + Manual Fallback)

**Files:**
- Create: `TunerClient/Sources/TunerClient/Discovery/SSDPDiscoverer.swift`
- Create: `TunerClient/Sources/TunerClient/Discovery/ManualTunerStore.swift`
- Create: `TunerClient/Sources/TunerClient/Discovery/TunerDiscovererImpl.swift`
- Create: `TunerClient/Tests/TunerClientTests/DiscoveryTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.TunerDiscoverer`, `Core.Models.Tuner`
- Produces: `TunerDiscovererImpl.discover() async throws -> [Tuner]`

- [ ] **Step 1: Write failing test: discover returns tuner with valid IP**
- [ ] **Step 2: Implement SSDPDiscoverer using NWBrowser (service type "_hdhomerun._tcp")**
- [ ] **Step 3: Parse HDHomeRun SSDP response (device.xml URL → fetch → parse device ID, model, firmware)**
- [ ] **Step 4: Implement ManualTunerStore (UserDefaults key "manualTunerIP")**
- [ ] **Step 4: Implement TunerDiscovererImpl: try SSDP, fallback to manual IP, merge results**
- [ ] **Step 5: Add NWPathMonitor to trigger re-discovery on network change**
- [ ] **Step 6: Run tests, verify discovery works**

```bash
swift test --package-path . --filter TunerClientTests.DiscoveryTests
```

### Task 1.4: Lineup Fetch & Channel Parsing

**Files:**
- Create: `TunerClient/Sources/TunerClient/Lineup/LineupProviderImpl.swift`
- Create: `TunerClient/Sources/TunerClient/Lineup/LineupParser.swift`
- Create: `TunerClient/Sources/TunerClient/StreamURLBuilderImpl.swift`
- Create: `TunerClient/Tests/TunerClientTests/LineupTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.LineupProvider`, `Core.Models.Channel`, `Core.Models.Tuner`
- Produces: `LineupProviderImpl.fetchLineup(for tuner: Tuner) async throws -> [Channel]`

- [ ] **Step 1: Write failing test: parse lineup.json → Channel array with correct affineNumber**
- [ ] **Step 2: Implement LineupParser: decode HDHomeRun lineup.json (GuideNumber, GuideName, URL, etc.)**
- [ ] **Step 3: Compute affineNumber: major * 100 + minor (7.1 → 701, 7.2 → 702)**
- [ ] **Step 4: Implement StreamURLBuilderImpl: build http://<ip>:5004/auto/v<channel>**
- [ ] **Step 5: Implement LineupProviderImpl with retry (3x, exponential backoff)**
- [ ] **Step 6: Run tests**

```bash
swift test --package-path . --filter TunerClientTests.LineupTests
```

### Task 1.5: VLCKit Player Wrapper

**Files:**
- Create: `PlaybackEngine/Sources/PlaybackEngine/Player/VLCPlayerController.swift`
- Create: `PlaybackEngine/Sources/PlaybackEngine/Player/DeinterlacingMode.swift`
- Create: `PlaybackEngine/Sources/PlaybackEngine/Player/PlaybackSession.swift`
- Create: `PlaybackEngine/Sources/PlaybackEngine/Player/PlayerError.swift`
- Create: `PlaybackEngine/Tests/PlaybackEngineTests/PlayerTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.PlayerController`, `Core.Models.Channel`
- Produces: `VLCPlayerController` conforming to `PlayerController`

- [ ] **Step 1: Write failing test: open URL → player state becomes .playing**
- [ ] **Step 2: Add VLCKit.xcframework to PlaybackEngine target (link, embed)**
- [ ] **Step 3: Implement VLCPlayerController @MainActor with VLCMediaPlayer**
- [ ] **Step 4: Implement open(url: URL, deinterlacing: DeinterlacingMode) async throws**
- [ ] **Step 5: Implement play(), pause(), stop(), seek(to: TimeInterval)**
- [ ] **Step 6: Implement channelUp/Down (requires TunerClient for next channel URL)**
- [ ] **Step 7: Implement deinterlacing: map DeinterlacingMode → VLCMediaPlayer.videoDeinterlacingMode**
- [ ] **Step 8: Add Publishers for state (playing, buffering, error, time, duration)**
- [ ] **Step 9: Run tests (may need integration test with real stream)**

```bash
swift test --package-path . --filter PlaybackEngineTests.PlayerTests
```

### Task 1.6: Tuner Management & Auto-Stop Logic

**Files:**
- Create: `PlaybackEngine/Sources/PlaybackEngine/Tuner/TunerManager.swift`
- Create: `PlaybackEngine/Sources/PlaybackEngine/Tuner/StreamSession.swift`
- Create: `PlaybackEngine/Tests/PlaybackEngineTests/TunerManagerTests.swift`

**Interfaces:**
- Consumes: `PlaybackEngine.PlayerController`, `Core.Models.Tuner`, `Core.Models.Channel`
- Produces: `TunerManager.requestStream(for channel: Channel) async throws -> StreamSession`

- [ ] **Step 1: Write failing test: 3rd stream request stops oldest session**
- [ ] **Step 2: Implement StreamSession (channel, playerController, startedAt, isBackground)**
- [ ] **Step 3: Implement TunerManager with maxConcurrentStreams = 2**
- [ ] **Step 4: On new request when at limit: stop oldest background session, show toast via callback**
- [ ] **Step 5: Track foreground vs background (PiP = background, fullscreen = foreground)**
- [ ] **Step 6: Run tests**

```bash
swift test --package-path . --filter PlaybackEngineTests.TunerManagerTests
```

### Task 1.7: Channels Screen (UI)

**Files:**
- Create: `UI/Sources/UI/Channels/ChannelsView.swift`
- Create: `UI/Sources/UI/Channels/ChannelsViewModel.swift`
- Create: `UI/Sources/UI/Channels/ChannelCardView.swift`
- Create: `UI/Sources/UI/Channels/ChannelGridView.swift`
- Create: `UI/Tests/UITests/ChannelsViewModelTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.TunerDiscoverer`, `Core.Protocols.LineupProvider`, `Core.Protocols.PlayerController`, `Core.Models.Channel`, `Core.Models.Tuner`
- Produces: `ChannelsView`, `ChannelsViewModel`

- [ ] **Step 1: Write failing test: ViewModel loads channels on appear**
- [ ] **Step 2: Implement ChannelsViewModel @Observable with tuner discovery + lineup fetch**
- [ ] **Step 3: State: .loading, .loaded([Channel]), .error(Error), .tunerOffline(Tuner)**
- [ ] **Step 4: Implement ChannelCardView: number, name, callsign, live badge, offline badge**
- [ ] **Step 5: Implement ChannelGridView (LazyVGrid, adaptive columns)**
- [ ] **Step 6: Implement ChannelsView with toolbar: refresh, settings, tuner status**
- [ ] **Step 7: Keyboard navigation: ↑↓←→ focus, Enter/Space play, Esc stop**
- [ ] **Step 8: Click channel → call PlayerController.open() via DI**
- [ ] **Step 9: Run tests, preview in Xcode**

```bash
swift test --package-path . --filter UITests.ChannelsViewModelTests
```

### Task 1.8: Now Playing / Player View

**Files:**
- Create: `UI/Sources/UI/Player/PlayerView.swift`
- Create: `UI/Sources/UI/Player/PlayerViewModel.swift`
- Create: `UI/Sources/UI/Player/PlayerControlsView.swift`
- Create: `UI/Sources/UI/Player/VideoViewRepresentable.swift` (NSViewRepresentable for VLCKit)
- Create: `UI/Tests/UITests/PlayerViewModelTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.PlayerController`, `Core.Models.Channel`
- Produces: `PlayerView`, `PlayerViewModel`

- [ ] **Step 1: Write failing test: PlayerViewModel reflects player state changes**
- [ ] **Step 2: Implement VideoViewRepresentable wrapping VLCMediaPlayer's drawable (NSView)**
- [ ] **Step 3: Implement PlayerViewModel: binds to PlayerController publishers**
- [ ] **Step 4: Implement PlayerControlsView: play/pause, timeline, volume, channel up/down, deinterlace cycle, fullscreen, PiP**
- [ ] **Step 5: Implement PlayerView: fullscreen support, auto-hide controls, keyboard shortcuts**
- [ ] **Step 6: Keyboard: Space=play/pause, ←/→=seek ±10s, ↑/↓=volume, PgUp/PgDn=channel up/down, F=fullscreen, D=deinterlace**
- [ ] **Step 7: Integrate with TunerManager for channel up/down (favorited channels only)**
- [ ] **Step 8: Run tests, test with real stream**

```bash
swift test --package-path . --filter UITests.PlayerViewModelTests
```

### Task 1.9: Settings Screen (Tuner & Playback)

**Files:**
- Create: `UI/Sources/UI/Settings/SettingsView.swift`
- Create: `UI/Sources/UI/Settings/SettingsViewModel.swift`
- Create: `UI/Sources/UI/Settings/TunerSettingsView.swift`
- Create: `UI/Sources/UI/Settings/PlaybackSettingsView.swift`

**Interfaces:**
- Consumes: `Core.Protocols.TunerDiscoverer`, `TunerClient.ManualTunerStore`, `PlaybackEngine.DeinterlacingMode`
- Produces: `SettingsView`, `SettingsViewModel`

- [ ] **Step 1: Write failing test: manual IP saved and used on next launch**
- [ ] **Step 2: Implement SettingsViewModel with @AppStorage for manual IP, deinterlacing mode, hardware decode**
- [ ] **Step 3: Implement TunerSettingsView: auto-discovery toggle, manual IP field, "Test Connection" button**
- [ ] **Step 4: Implement PlaybackSettingsView: deinterlacing picker, hardware decode toggle, buffer size**
- [ ] **Step 5: Wire SettingsView into main navigation (TabView or Sidebar)**
- [ ] **Step 6: Run tests**

```bash
swift test --package-path . --filter UITests.SettingsViewModelTests
```

### Task 1.10: App Wiring & Integration

**Files:**
- Modify: `TowerApp/Sources/TowerApp/TowerApp.swift`
- Create: `TowerApp/Sources/TowerApp/DIContainer.swift` (concrete impl)
- Create: `TowerApp/Sources/TowerApp/AppState.swift` (shared observable)

**Interfaces:**
- Consumes: All module protocols and implementations
- Produces: Working app with DI container wiring

- [ ] **Step 1: Implement DIContainer with concrete registrations**
- [ ] **Step 2: TowerApp.swift: @main struct, create DIContainer, inject into environment**
- [ ] **Step 3: Set up main window with TabView: Channels, Now Playing, Settings**
- [ ] **Step 4: Handle app lifecycle: resume discovery on foreground, save state on background**
- [ ] **Step 5: Add menu bar: File > Open Manual IP, Window > Now Playing (Cmd+1), View > Deinterlacing**
- [ ] **Step 6: Build, run, test end-to-end: discover → lineup → play → channel up/down → settings persist**

```bash
xcodebuild -scheme Tower -destination 'platform=macOS' build
# Manual test on device
```

---

## Phase 2: M2 — Guide Grid (Weeks 4-7)

### Task 2.1: GRDB Database Schema & Migrations

**Files:**
- Create: `GuideIngestion/Sources/GuideIngestion/Database/DatabaseManager.swift`
- Create: `GuideIngestion/Sources/GuideIngestion/Database/Migrations.swift`
- Create: `GuideIngestion/Sources/GuideIngestion/Database/GuideRepositoryImpl.swift`
- Create: `GuideIngestion/Tests/GuideIngestionTests/DatabaseTests.swift`

**Interfaces:**
- Consumes: `Core.Models.GuideEntry`, `Core.Models.GuideProvider`, `Core.Protocols.GuideRepository`
- Produces: `DatabaseManager`, `GuideRepositoryImpl`

- [ ] **Step 1: Write failing test: insert + query guide entries by channel/time range**
- [ ] **Step 2: Implement DatabaseManager with GRDB DatabaseQueue (async)**
- [ ] **Step 3: Implement Migrations: create tables, indexes, channel_matches**
- [ ] **Step 4: Implement GuideRepositoryImpl: saveEntries, entriesForChannel(in:), entriesInRange(_:)**
- [ ] **Step 5: Add transactional replace: delete old + insert new in single transaction**
- [ ] **Step 6: Run tests**

```bash
swift test --package-path . --filter GuideIngestionTests.DatabaseTests
```

### Task 2.2: XMLTV Download & Parse

**Files:**
- Create: `GuideIngestion/Sources/GuideIngestion/XMLTV/XMLTVProvider.swift`
- Create: `GuideIngestion/Sources/GuideIngestion/XMLTV/XMLTVParser.swift`
- Create: `GuideIngestion/Sources/GuideIngestion/XMLTV/XMLTVModels.swift` (Codable structs)
- Create: `GuideIngestion/Tests/GuideIngestionTests/XMLTVTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.GuideProvider`, `Core.Models.GuideEntry`, `GuideIngestion.DatabaseManager`
- Produces: `XMLTVProvider.fetchAndParse() async throws -> [GuideEntry]`

- [ ] **Step 1: Write failing test: parse sample XMLTV → GuideEntry array**
- [ ] **Step 2: Define XMLTVModels matching XMLTV DTD (tv, channel, programme elements)**
- [ ] **Step 3: Implement XMLTVParser using XMLParser (streaming, low memory)**
- [ ] **Step 4: Convert XMLTVProgramme → GuideEntry (UTC times, categories array, rating)**
- [ ] **Step 5: Implement XMLTVProvider: download (URLSession), parse, return entries**
- [ ] **Step 6: Handle gzip-compressed XMLTV (Content-Encoding: gzip)**
- [ ] **Step 7: Run tests with sample XMLTV file**

```bash
swift test --package-path . --filter GuideIngestionTests.XMLTVTests
```

### Task 2.3: Channel Matching (Tuner ↔ Guide)

**Files:**
- Create: `GuideIngestion/Sources/GuideIngestion/Matching/ChannelMatcherImpl.swift`
- Create: `GuideIngestion/Sources/GuideIngestion/Matching/MatchStrategy.swift`
- Create: `GuideIngestion/Tests/GuideIngestionTests/ChannelMatcherTests.swift`

**Interfaces:**
- Consumes: `Core.Models.Channel`, `GuideIngestion.DatabaseManager`, `Core.Protocols.ChannelMatcher`
- Produces: `ChannelMatcherImpl.match(tunerChannels: [Channel], guideChannels: [XMLTVChannel]) -> [ChannelMatch]`

- [ ] **Step 1: Write failing test: exact number match → confidence 1.0**
- [ ] **Step 2: Write failing test: callsign match (case-insensitive) → confidence 0.9**
- [ ] **Step 3: Write failing test: major number only match → confidence 0.7**
- [ ] **Step 4: Implement MatchStrategy protocol with match() → (guideChannelID, confidence)**
- [ ] **Step 5: Implement strategies: ExactNumber, Callsign, MajorNumber, ManualOverride**
- [ ] **Step 6: Implement ChannelMatcherImpl: run strategies in order, pick highest confidence**
- [ ] **Step 7: Persist matches to channel_matches table**
- [ ] **Step 8: Run tests**

```bash
swift test --package-path . --filter GuideIngestionTests.ChannelMatcherTests
```

### Task 2.4: Guide Refresh Orchestration

**Files:**
- Create: `GuideIngestion/Sources/GuideIngestion/GuideRefreshCoordinator.swift`
- Create: `GuideIngestion/Sources/GuideIngestion/GuideIngestionService.swift`
- Create: `GuideIngestion/Tests/GuideIngestionTests/GuideRefreshTests.swift`

**Interfaces:**
- Consumes: `GuideIngestion.XMLTVProvider`, `GuideIngestion.GuideRepositoryImpl`, `GuideIngestion.ChannelMatcherImpl`, `Core.Models.GuideProvider`
- Produces: `GuideRefreshCoordinator.refresh() async throws`

- [ ] **Step 1: Write failing test: refresh downloads, parses, matches, stores atomically**
- [ ] **Step 2: Implement GuideRefreshCoordinator: coordinate provider → parser → matcher → repository**
- [ ] **Step 3: Implement GuideIngestionService: scheduled refresh (timer + BGAppRefreshTask)**
- [ ] **Step 4: On refresh: fetch XMLTV, parse to temp entries, match channels, transactional replace in DB**
- [ ] **Step 5: Update GuideProvider.lastFetched, lastParsed, entryCount**
- [ ] **Step 6: Emit notification on completion (success/failure) for UI**
- [ ] **Step 7: Run tests**

```bash
swift test --package-path . --filter GuideIngestionTests.GuideRefreshTests
```

### Task 2.5: Guide Grid Screen (UI)

**Files:**
- Create: `UI/Sources/UI/Guide/GuideView.swift`
- Create: `UI/Sources/UI/Guide/GuideViewModel.swift`
- Create: `UI/Sources/UI/Guide/GuideGridView.swift`
- Create: `UI/Sources/UI/Guide/GuideCellView.swift`
- Create: `UI/Sources/UI/Guide/GuideTimeHeaderView.swift`
- Create: `UI/Sources/UI/Guide/GuideChannelHeaderView.swift`
- Create: `UI/Tests/UITests/GuideViewModelTests.swift`

**Interfaces:**
- Consumes: `Core.Protocols.GuideRepository`, `Core.Models.Channel`, `Core.Models.GuideEntry`, `GuideIngestion.ChannelMatcherImpl`
- Produces: `GuideView`, `GuideViewModel`

- [ ] **Step 1: Write failing test: ViewModel loads guide entries for visible time range**
- [ ] **Step 2: Implement GuideViewModel: timeRange (DateInterval), channels [Channel], entries [GuideEntry]**
- [ ] **Step 3: Virtualized grid: only render visible rows + 1 buffer (use ScrollViewReader + GeometryReader)**
- [ ] **Step 4: Time axis: 30-min rows, 6 AM – 2 AM next day, current time red line**
- [ ] **Step 5: Channel axis: horizontal scroll, fixed channel header column**
- [ ] **Step 6: GuideCellView: title, time range, new badge, category color, live indicator**
- [ ] **Step 7: Click cell → if live: play; if future: show detail popover (title, desc, episode info)**
- [ ] **Step 8: Keyboard: ←→ change channel, ↑↓ change time, Enter play, G toggle grid/list**
- [ ] **Step 9: Run tests, preview with mock data**

```bash
swift test --package-path . --filter UITests.GuideViewModelTests
```

### Task 2.6: Guide Settings & Manual Match Override

**Files:**
- Create: `UI/Sources/UI/Settings/GuideSettingsView.swift`
- Create: `UI/Sources/UI/Settings/ChannelMatchEditorView.swift`
- Modify: `UI/Sources/UI/Settings/SettingsViewModel.swift`

**Interfaces:**
- Consumes: `Core.Protocols.GuideProvider`, `GuideIngestion.ChannelMatcherImpl`, `GuideIngestion.GuideRefreshCoordinator`
- Produces: Guide settings UI

- [ ] **Step 1: Write failing test: manual match override persists and affects guide**
- [ ] **Step 2: Add to SettingsViewModel: XMLTV URL, auto-refresh interval, manual refresh trigger**
- [ ] **Step 3: Implement GuideSettingsView: URL field, refresh interval picker, "Refresh Now" button, last updated label**
- [ ] **Step 4: Implement ChannelMatchEditorView: list unmatched/low-confidence channels, allow manual guide channel selection**
- [ ] **Step 5: Wire into SettingsView tab**
- [ ] **Step 6: Run tests**

```bash
swift test --package-path . --filter UITests.GuideSettingsTests
```

---

## Phase 3: M3 — Polish & Hardening (Weeks 8-10)

### Task 3.1: Channel Favorites & Management

**Files:**
- Create: `Core/Sources/Core/Models/ChannelPreferences.swift`
- Create: `UI/Sources/UI/Channels/ChannelEditorView.swift`
- Modify: `UI/Sources/UI/Channels/ChannelsViewModel.swift`
- Modify: `PlaybackEngine/Sources/PlaybackEngine/Tuner/TunerManager.swift` (favorites for channel up/down)

**Interfaces:**
- Consumes: `Core.Models.Channel`, `Core.Models.ChannelPreferences`
- Produces: Favorite/reorder/hide logic

- [ ] **Step 1: Write failing test: favorite channels used for channel up/down**
- [ ] **Step 2: Add ChannelPreferences (favorite: Bool, hidden: Bool, sortOrder: Int)**
- [ ] **Step 3: Persist to UserDefaults (or GRDB if complex)**
- [ ] **Step 4: Implement ChannelEditorView: drag reorder, favorite toggle, hide toggle**
- [ ] **Step 5: Filter ChannelsView by hidden, sort by sortOrder then affineNumber**
- [ ] **Step 6: TunerManager.channelUp/Down cycles through favorites only (or all if none)**
- [ ] **Step 7: Run tests**

### Task 3.2: Deinterlacing Quality & Persistence

**Files:**
- Modify: `PlaybackEngine/Sources/PlaybackEngine/Player/DeinterlacingMode.swift`
- Modify: `PlaybackEngine/Sources/PlaybackEngine/Player/VLCPlayerController.swift`
- Modify: `UI/Sources/UI/Settings/PlaybackSettingsView.swift`

**Interfaces:**
- Consumes: `PlaybackEngine.DeinterlacingMode`, `VLCPlayerController`
- Produces: Per-channel or global deinterlacing preference

- [ ] **Step 1: Test each deinterlacing mode (Off, Bob, Yadif, Yadif2x, Phosphor) with real interlaced content**
- [ ] **Step 2: Default to Yadif (best quality/performance balance)**
- [ ] **Step 3: Persist user choice per-channel (some channels progressive, some interlaced)**
- [ ] **Step 4: Apply mode on stream open, allow runtime toggle (D key)**
- [ ] **Step 5: Run manual QA**

### Task 3.3: Channel Logos & Guide Visual Polish

**Files:**
- Create: `GuideIngestion/Sources/GuideIngestion/Logos/LogoCache.swift`
- Create: `UI/Sources/UI/Guide/GuideChannelHeaderView.swift` (add logo)
- Create: `UI/Sources/UI/Channels/ChannelCardView.swift` (add logo)

**Interfaces:**
- Consumes: XMLTV `<icon src="..."/>`, Channel.callsign
- Produces: Cached logo images

- [ ] **Step 1: Write failing test: download and cache logo from URL**
- [ ] **Step 2: Extract icon URLs from XMLTV during parse**
- [ ] **Step 3: Implement LogoCache (async download, disk cache, placeholder)**
- [ ] **Step 4: Display logos in Guide channel header and Channel card**
- [ ] **Step 5: Category color coding in guide cells**

### Task 3.4: Accessibility & Keyboard Shortcuts Customization

**Files:**
- Modify: `UI/Sources/UI/Channels/ChannelsView.swift`
- Modify: `UI/Sources/UI/Guide/GuideView.swift`
- Modify: `UI/Sources/UI/Player/PlayerView.swift`
- Create: `UI/Sources/UI/Settings/KeyboardShortcutsView.swift`

**Interfaces:**
- Consumes: SwiftUI accessibility APIs
- Produces: VoiceOver support, customizable shortcuts

- [ ] **Step 1: Add accessibility labels, hints, traits to all interactive elements**
- [ ] **Step 2: Verify focus rings visible, tab order logical**
- [ ] **Step 3: Implement KeyboardShortcutsView: list all shortcuts, allow remap (UserDefaults)**
- [ ] **Step 4: Apply custom shortcuts in PlayerView, GuideView, ChannelsView**
- [ ] **Step 5: Test with VoiceOver enabled**

### Task 3.5: Unit & Integration Tests

**Files:**
- Create: `Core/Tests/CoreTests/ChannelMatcherTests.swift` (integration)
- Create: `TunerClient/Tests/TunerClientTests/IntegrationTests.swift`
- Create: `PlaybackEngine/Tests/PlaybackEngineTests/IntegrationTests.swift`
- Create: `UI/Tests/UITests/IntegrationTests.swift`

**Interfaces:**
- Consumes: All modules
- Produces: Test coverage for critical paths

- [ ] **Step 1: ChannelMatcher: test all strategies with real tuner + XMLTV samples**
- [ ] **Step 2: TunerClient: test discovery → lineup → stream URL with real HDHomeRun (or mock server)**
- [ ] **Step 3: PlaybackEngine: test open → play → seek → channel up → deinterlace toggle**
- [ ] **Step 4: UI: test ViewModel state transitions (loading → loaded → error → retry)**
- [ ] **Step 5: Run full test suite, target >80% coverage on Core/TunerClient/GuideIngestion/PlaybackEngine**

```bash
swift test --package-path . --codecov
```

### Task 3.6: Code Signing, Notarization & Distribution Prep

**Files:**
- Modify: `TowerApp/Sources/TowerApp/TowerApp.entitlements`
- Create: `Scripts/notarize.sh`
- Create: `Scripts/build-release.sh`

**Interfaces:**
- Consumes: Xcode project, Developer ID certificates
- Produces: Notarized .app, optional Sparkle appcast

- [ ] **Step 1: Configure automatic code signing (Development team)**
- [ ] **Step 2: Verify entitlements: network client, outgoing connections, microphone (if VLC needs)**
- [ ] **Step 3: Test hardened runtime: `codesign --verify --deep --strict`**
- [ ] **Step 4: Create notarization script (xcrun notarytool submit --wait)**
- [ ] **Step 5: Create build-release.sh: archive, sign, notarize, staple, create DMG**
- [ ] **Step 6: (Optional) Add Sparkle framework for auto-updates**

---

## Execution Order Summary

| Phase | Tasks | Est. Duration |
|-------|-------|---------------|
| M1 | 1.1 - 1.10 | 2-3 weeks |
| M2 | 2.1 - 2.6 | 3-4 weeks |
| M3 | 3.1 - 3.6 | 2-3 weeks |

**Total: ~7-10 weeks**

---

## Next Steps

1. **Review this plan** — confirm it captures the design intent
2. **Choose execution method** — Subagent-driven (recommended for thoroughness) or Native (faster)
3. **Begin Task 1.1** — Project setup and module scaffolding