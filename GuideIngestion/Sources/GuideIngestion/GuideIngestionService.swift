import Foundation
import Core

/// Service for scheduled guide refresh operations.
public final class GuideIngestionService: @unchecked Sendable {
    private let coordinator: GuideRefreshCoordinator
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval

    public init(
        coordinator: GuideRefreshCoordinator,
        refreshInterval: TimeInterval = 12 * 60 * 60 // 12 hours default
    ) {
        self.coordinator = coordinator
        self.refreshInterval = refreshInterval
    }

    /// Start periodic guide refresh.
    public func startPeriodicRefresh(tunerChannels: [Channel]) {
        // Cancel existing timer
        refreshTimer?.invalidate()
        
        // Schedule periodic refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    try await self.coordinator.refresh(tunerChannels: tunerChannels)
                } catch {
                    // Log error but don't crash
                    print("Guide refresh failed: \(error)")
                }
            }
        }
        
        // Also trigger immediate refresh
        Task {
            do {
                try await self.coordinator.refresh(tunerChannels: tunerChannels)
            } catch {
                print("Initial guide refresh failed: \(error)")
            }
        }
    }

    /// Stop periodic refresh.
    public func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Trigger immediate refresh.
    public func refreshNow(tunerChannels: [Channel]) async throws {
        try await coordinator.refresh(tunerChannels: tunerChannels)
    }
}