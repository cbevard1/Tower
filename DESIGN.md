# Tower — macOS HDHomeRun TV App Design

## 1. Architecture & Module Boundaries

**Modular Monolith** using Swift Package Manager local packages within a single Xcode workspace.

```
Tower.xcworkspace/
├── TowerApp/                 # App entry point, SwiftUI App, DI container
├── Core/                     # Shared models, protocols, extensions
├── TunerClient/              # HDHomeRun discovery, lineup, stream URLs
├── GuideIngestion/           # XMLTV download, parse, SQLite (GRDB), matching
├── PlaybackEngine/           # VLCKit wrapper, deinterlacing, player state
└── UI/                       # SwiftUI views, view models, navigation
```

### Module Responsibilities

| Module | Public Interface | Dependencies |
|--------|------------------|--------------|
| **Core** | `Channel`, `Tuner`, `GuideEntry`, `GuideProvider`, `TunerStatus` protocols | None (foundation) |
| **TunerClient** | `TunerDiscoverer`, `LineupProvider`, `StreamURLBuilder` | Core, Network (URLSession) |
| **GuideIngestion** | `GuideProvider` (protocol), `XMLTVProvider`, `GuideRepository`, `ChannelMatcher` | Core, GRDB.swift, XMLParsing |
| **PlaybackEngine** | `PlayerController`, `PlaybackSession`, `DeinterlacingMode` | Core, VLCKit (dynamic) |
| **UI** | Views, ViewModels, Navigation | All above (via protocols) |

### Dependency Rule
- UI depends on **protocols** from Core, not concrete implementations
- TunerClient, GuideIngestion, PlaybackEngine implement Core protocols
- TowerApp wires concrete implementations at launch (manual DI, no framework)

### Concurrency Model
- **TunerClient**: `URLSession` async/await, discovery uses NWBrowser (Network framework)
- **GuideIngestion**: Background actor for download/parse; GRDB async writes
- **PlaybackEngine**: `@MainActor` for VLCKit (UI thread), async for prep
- **UI**: SwiftUI `@StateObject`/`@Observable` view models on MainActor

---

## 2. Data Model

### Core Entities (Core module)

```swift
// Core/Models/Tuner.swift
struct Tuner: Identifiable, Hashable, Sendable {
    let id: String           // Device ID from HDHomeRun (e.g., "1234ABCD")
    let ipAddress: String    // e.g., "192.168.1.42"
    let model: String        // "HDHR4-2US", "HDHR5-4K", etc.
    let firmwareVersion: String
    let tunerCount: Int      // 2 for Connect/Duo
    let discoveredAt: Date
    var manualOverride: Bool // true if user entered IP manually
}

// Core/Models/Channel.swift
struct Channel: Identifiable, Hashable, Sendable {
    let id: String           // Composite: "\(tunerID)-\(number)" e.g., "1234ABCD-7.1"
    let tunerID: String
    let number: String       // "7.1", "9.1", "4.1"
    let name: String         // "KABC-DT"
    let callsign: String     // "KABC"
    let affineNumber: Int    // For sorting: 701, 901, 401
    var streamURL: URL {     // Computed: http://<ip>:5004/auto/v<channel>
        URL(string: "http://\(tunerIP):5004/auto/v\(number.replacingOccurrences(of: ".", with: ""))")!
    }
    let modulation: String?  // "8vsb", "qam256"
    let programCount: Int
}

// Core/Models/GuideEntry.swift
struct GuideEntry: Identifiable, Hashable, Sendable {
    let id: String           // UUID
    let channelID: String    // Matches Channel.id
    let startTime: Date
    let endTime: Date
    let title: String
    let description: String?
    let episodeTitle: String?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let isNew: Bool
    let categories: [String] // "Sports", "News", "Movie"
    let rating: String?      // TV-PG, TV-14, etc.
}

// Core/Models/GuideProvider.swift
struct GuideProvider: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let sourceURL: URL       // Single static XMLTV URL
    let lastFetched: Date?
    let lastParsed: Date?
    let entryCount: Int
}
```

### Database Schema (GRDB, GuideIngestion module)

```sql
-- GuideIngestion/Database/Schema.sql
CREATE TABLE guide_entries (
    id TEXT PRIMARY KEY,
    channel_id TEXT NOT NULL,
    start_time INTEGER NOT NULL,  -- Unix epoch ms
    end_time INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    episode_title TEXT,
    season_number INTEGER,
    episode_number INTEGER,
    is_new INTEGER NOT NULL DEFAULT 0,
    categories TEXT,              -- JSON array
    rating TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
);

CREATE INDEX idx_guide_channel_time ON guide_entries(channel_id, start_time);
CREATE INDEX idx_guide_time_range ON guide_entries(start_time, end_time);

CREATE TABLE guide_providers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    source_url TEXT NOT NULL,
    last_fetched INTEGER,
    last_parsed INTEGER,
    entry_count INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE channel_matches (
    tuner_channel_id TEXT PRIMARY KEY,  -- Channel.id from tuner
    guide_channel_id TEXT NOT NULL,     -- XMLTV channel id
    match_type TEXT NOT NULL,           -- 'number', 'callsign', 'manual'
    confidence REAL NOT NULL DEFAULT 1.0
);
```

### Channel Matching Logic
1. **Exact number match**: `tunerChannel.number == xmltvChannel.number`
2. **Callsign match**: `tunerChannel.callsign == xmltvChannel.callsign` (case-insensitive)
3. **Fuzzy number**: Major number match (7.1 ↔ 7)
4. **Manual override**: User-editable in Settings

---

## 3. Main Screens & UX

### Navigation Structure
```
TabView (macOS: Sidebar + Detail)
├── Channels          # Grid/list of all channels, play on click
├── Guide             # Time-grid (vertical time, horizontal channels)
├── Now Playing       # Full-screen player (also accessible from anywhere)
└── Settings          # Tuner IP, XMLTV URL, deinterlacing, guide refresh
```

### Screen Details

#### Channels Screen
- **Layout**: LazyVGrid (2-4 columns based on window width) or List
- **Item**: Channel logo (if available), number, name, callsign, live badge
- **Interaction**: Click → play in Now Playing; Right-click → "Set as Favorite", "Remove"
- **Keyboard**: ↑↓←→ navigate, Enter/Space play, Esc stop
- **State**: Loading spinner per tuner, offline badge if tuner unreachable

#### Guide Grid Screen
- **Layout**: Horizontal scroll (channels) × Vertical scroll (time, 30-min rows)
- **Time range**: 6 AM – 2 AM next day (configurable)
- **Current time indicator**: Red line across grid
- **Cell**: Show title, time, new-badge, category color dot
- **Interaction**: Click cell → play if live, or show detail popover
- **Keyboard**: ←→ change channel, ↑↓ change time, Enter play, G toggle grid/list
- **Performance**: Virtualized — only render visible cells + 1 screen buffer

#### Now Playing / Player Overlay
- **Always accessible**: Cmd+1 or menu bar "Window > Now Playing"
- **Fullscreen**: Double-click video or Cmd+F
- **Controls** (auto-hide): Play/pause, timeline, volume, channel up/down, deinterlace toggle, aspect ratio
- **Channel Up/Down**: Cycles through *favorited* channels, or all if none favorited
- **Keyboard**: Space play/pause, ←/→ seek ±10s, ↑/↓ volume, PgUp/PgDn channel up/down, F fullscreen, D deinterlace cycle
- **PiP**: Native macOS PiP button in player (VLCKit supports this)

#### Settings Screen
- **Tuner**: Auto-discovery toggle, Manual IP field (saved), Refresh button
- **Guide**: XMLTV URL field, Refresh now, Auto-refresh interval (6h/12h/24h/Manual), Last updated timestamp
- **Playback**: Deinterlacing mode (Auto/Off/Bob/Yadif/Phosphor), Hardware decoding toggle, Buffer size
- **Advanced**: Log level, Reset database, Export/Import channel favorites

---

## 4. Error Handling

### Tuner Unreachable
- **Discovery fails**: Show "No tuner found" with "Enter IP Manually" button
- **Lineup fetch fails**: Retry 3× with exponential backoff (1s, 2s, 4s), then show error banner with "Retry" and "Manual IP"
- **Stream fails (404/500/timeout)**: Show inline error on channel card, log details, don't crash player
- **Network change**: Listen for `NWPathMonitor` updates, re-discover automatically

### Busy Tuners (2-tuner limit)
- **Strategy**: Auto-stop oldest background stream when new one starts
- **UI**: When opening 3rd stream, briefly show toast "Switched tuner from [channel]" (2s)
- **Edge case**: If user watches Channel A, opens Guide, clicks Channel B → Channel A stops, Channel B plays
- **PiP**: Counts as a tuner. If PiP + fullscreen = 2 tuners used.

### Guide Data Issues
- **XMLTV fetch fails**: Show last successful fetch time, keep cached data, retry next interval
- **Parse fails**: Log error, keep old database, show "Guide data may be stale" banner
- **No match for channel**: Show channel in grid with "No guide data" placeholder, log unmatched channels
- **Stale data (>48h)**: Yellow banner "Guide data is X days old — pull to refresh"

### Playback Errors
- **VLCKit init fails**: Fallback to Software decoding, show alert "Hardware decode unavailable"
- **Stream stalls**: Show buffering spinner, retry same URL once, then show error
- **Deinterlace crash**: Catch, disable deinterlacing, log, continue playback

---

## 5. Milestone Plan

### M1: Minimal Viable Player (2-3 weeks)
- [ ] Xcode project + SwiftPM modules setup
- [ ] HDHomeRun SSDP discovery + manual IP fallback
- [ ] Fetch `lineup.json` → parse Channel array
- [ ] Channels screen: grid/list, click to play
- [ ] PlaybackEngine: VLCKit init, open stream URL, deinterlacing=Auto
- [ ] Now Playing: fullscreen, basic controls, keyboard nav
- [ ] Auto-stop oldest stream on 3rd play attempt
- [ ] Error banners for tuner unreachable, stream failed

### M2: Guide Grid (3-4 weeks)
- [ ] XMLTVProvider: download, parse (XMLParser or AEXML), GRDB schema + migrations
- [ ] ChannelMatcher: number → callsign → fuzzy → manual
- [ ] GuideRepository: async CRUD, time-range queries
- [ ] Guide screen: virtualized grid, current-time line, 6AM–2AM range
- [ ] Click guide cell → play if live, detail popover if future
- [ ] Settings: XMLTV URL, refresh interval, manual refresh button
- [ ] Background refresh (BGTaskScheduler or timer when app active)

### M3: Polish & Hardening (2-3 weeks)
- [ ] Channel favorites, reorder, hide/unhide
- [ ] PiP support, remember window size/position
- [ ] Deinterlacing mode picker (Yadif/Bob/Phosphor), persist choice
- [ ] Guide: channel logos (from XMLTV or local), category colors
- [ ] Keyboard shortcuts customization
- [ ] Accessibility: VoiceOver labels, focus rings, high contrast
- [ ] Unit tests: ChannelMatcher, GuideRepository, TunerClient
- [ ] Integration test: Discovery → Lineup → Play → Guide match
- [ ] Code signing, notarization, Sparkle updates (optional)

---

## 6. Risks & Open Questions

| Risk | Impact | Mitigation |
|------|--------|------------|
| **VLCKit/libVLC on macOS 15 (Tahoe)** | High — may not build or have regressions | Test early with VLCKit 3.6+ nightly; fallback to MPVKit if needed |
| **XMLTV source reliability** | Medium — free sources change/break | Design for multiple URLs; graceful degradation to cached data |
| **XMLTV licensing** | Legal — some sources forbid redistribution | User provides URL; app only parses local cache; no bundling |
| **Channel switching speed** | UX — 1-3s target may need pre-buffering | M1: measure baseline; M3: pre-load next favorited channel |
| **Deinterlacing quality** | UX — interlaced OTA looks bad without it | Test Yadif vs Bob vs Phosphor on real content; default Yadif |
| **2-tuner conflict UX** | UX — auto-stop may surprise users | Toast notification; option to disable in Settings |
| **Guide time-zone handling** | Correctness — XMLTV uses UTC, user local | Store all times UTC; convert for display using `TimeZone.current` |
| **VLCKit SwiftUI integration** | Technical — VLCKit is AppKit/NSView based | Use `NSViewRepresentable`; test fullscreen/PIP transitions |

### Open Questions to Resolve
1. **VLCKit version**: Use `VLCKit` (official, Objective-C) or `MobileVLCKit` (Swift-friendly, iOS-focused)? → Test both on macOS 15.
2. **XMLTV parser**: `AEXML` (lightweight) vs `XMLCoder` (Codable) vs `SWXMLHash`? → Benchmark parse time for 2-week guide (~50k entries).
3. **Channel logos**: XMLTV may include `<icon src="..."/>`. Download/cache? Or skip for M1-M2?
4. **Background guide refresh**: `BGAppRefreshTask` requires entitlements. Use launch-at-login helper or just refresh on app foreground?
5. **Sandboxing**: App Sandbox + Network Client + Outgoing Connections needed for tuner + XMLTV URL. Test early.

---

## 7. Next Steps

1. **Approve this design** → I'll write the spec to `docs/superpowers/specs/YYYY-MM-DD-tower-design.md`
2. **Spec self-review** (I'll do inline)
3. **You review spec** → approve or request changes
4. **Invoke `writing-plans` skill** for detailed implementation plan