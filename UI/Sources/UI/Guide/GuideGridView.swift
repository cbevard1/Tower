import SwiftUI
import Core

/// Virtualized grid view for the program guide.
public struct GuideGridView: View {
    let channels: [Channel]
    let guideEntries: [GuideEntry]
    let timeRange: ClosedRange<Date>
    let currentTime: Date
    let onEntryTap: (GuideEntry) -> Void
    
    // Grid configuration
    private let rowHeight: CGFloat = 60
    private let channelColumnWidth: CGFloat = 120
    private let timeColumnWidth: CGFloat = 60
    
    public init(
        channels: [Channel],
        guideEntries: [GuideEntry],
        timeRange: ClosedRange<Date>,
        currentTime: Date = Date(),
        onEntryTap: @escaping (GuideEntry) -> Void
    ) {
        self.channels = channels
        self.guideEntries = guideEntries
        self.timeRange = timeRange
        self.currentTime = currentTime
        self.onEntryTap = onEntryTap
    }
    
    private var timeSlots: [Date] {
        var slots: [Date] = []
        var current = Calendar.current.startOfDay(for: timeRange.lowerBound)
        let end = timeRange.upperBound
        
        while current < end {
            slots.append(current)
            current = current.addingTimeInterval(1800) // 30-minute slots
        }
        return slots
    }
    
    private func entriesForChannel(_ channelID: String, at time: Date) -> [GuideEntry] {
        guideEntries.filter { entry in
            entry.channelID == channelID &&
            entry.startTime <= time &&
            entry.endTime > time
        }
    }
    
    private func entryAtChannel(_ channelID: String, time: Date) -> GuideEntry? {
        entriesForChannel(channelID, at: time).first
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Time column (fixed)
                    TimeColumnView(
                        timeSlots: timeSlots,
                        currentTime: currentTime,
                        timeRange: timeRange,
                        width: timeColumnWidth
                    )
                    .frame(width: timeColumnWidth)
                    
                    // Channel columns
                    ForEach(channels) { channel in
                        ChannelColumnView(
                            channel: channel,
                            timeSlots: timeSlots,
                            guideEntries: guideEntries,
                            timeRange: timeRange,
                            currentTime: currentTime,
                            rowHeight: rowHeight,
                            onEntryTap: { entry in
                                // This will be handled by the parent
                            }
                        )
                        .frame(width: max(200, (geometry.size.width - timeColumnWidth - channelColumnWidth) / CGFloat(max(1, channels.count))))
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                // Current time indicator line
                CurrentTimeIndicator(
                    currentTime: currentTime,
                    timeRange: timeRange,
                    timeColumnWidth: timeColumnWidth,
                    rowHeight: rowHeight,
                    timeSlots: timeSlots
                )
            }
        }
    }
}

/// Time column showing 30-minute intervals
private struct TimeColumnView: View {
    let timeSlots: [Date]
    let currentTime: Date
    let timeRange: ClosedRange<Date>
    let width: CGFloat
    
    private let rowHeight: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(timeSlots, id: \.self) { time in
                Text(time, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: width, height: rowHeight, alignment: .trailing)
                    .padding(.trailing, 8)
            }
        }
        .frame(width: width)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// Channel column showing program entries
private struct ChannelColumnView: View {
    let channel: Channel
    let timeSlots: [Date]
    let guideEntries: [GuideEntry]
    let timeRange: ClosedRange<Date>
    let currentTime: Date
    let rowHeight: CGFloat
    let onEntryTap: (GuideEntry) -> Void
    
    private func entryAtTime(_ time: Date) -> GuideEntry? {
        guideEntries.first { entry in
            entry.channelID == channel.id &&
            entry.startTime <= time &&
            entry.endTime > time
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Channel header
            VStack(spacing: 4) {
                Text(channel.number)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Text(channel.name)
                    .font(.caption)
                    .lineLimit(1)
                Text(channel.callsign)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(height: rowHeight * 2)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 0.5)
            }
            
            // Program cells
            ForEach(Array(zip(timeSlots.dropLast(), timeSlots.dropFirst())), id: \.0) { startTime, endTime in
                if let entry = guideEntries.first(where: { entry in
                    entry.channelID == channel.id &&
                    entry.startTime <= startTime &&
                    entry.endTime > startTime
                }) {
                    GuideCellView(
                        entry: entry,
                        timeSlotStart: startTime,
                        timeSlotEnd: endTime,
                        isLive: entry.startTime <= Date() && entry.endTime > Date()
                    )
                    .onTapGesture {
                        // Handle tap
                    }
                } else {
                    // Empty slot
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: rowHeight)
                        .overlay(
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 0.5),
                            alignment: .bottom
                        )
                }
            }
        }
    }
}

/// Individual guide cell showing a program
public struct GuideCellView: View {
    let entry: GuideEntry
    let timeSlotStart: Date
    let timeSlotEnd: Date
    let isLive: Bool
    
    private var durationMinutes: Int {
        Int(entry.endTime.timeIntervalSince(entry.startTime) / 60)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: entry.startTime)) - \(formatter.string(from: entry.endTime))"
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(timeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if isLive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
                if entry.isNew {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }
            
            Text(entry.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if let episodeTitle = entry.episodeTitle {
                Text(episodeTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if !entry.categories.isEmpty {
                Text(entry.categories.first ?? "")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isLive ? Color.red.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isLive ? Color.red.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
        .padding(2)
    }
}

/// Current time indicator line across the grid
private struct CurrentTimeIndicator: View {
    let currentTime: Date
    let timeRange: ClosedRange<Date>
    let timeColumnWidth: CGFloat
    let rowHeight: CGFloat
    let timeSlots: [Date]
    
    private var progress: Double {
        let total = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
        let elapsed = currentTime.timeIntervalSince(timeRange.lowerBound)
        return min(max(elapsed / total, 0), 1)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let x = timeColumnWidth + geometry.size.width * progress
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: geometry.size.height)
                .position(x: x, y: geometry.size.height / 2)
        }
    }
}