import Foundation
import Core
import TunerClient
import PlaybackEngine
import UI

/// Concrete DI container wiring all modules together.
///
/// This is the composition root of the Tower application.
/// It registers concrete implementations for all Core protocols.
@preconcurrency
public final class AppContainer: DIContainer, ObservableObject, @unchecked Sendable {
    private let lockQueue = DispatchQueue(label: "tower.app-container")
    private var factories: [String: @Sendable (DIContainer) -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var asyncFactories: [String: @Sendable (DIContainer) async -> Any] = [:]

    public init() {
        registerAll()
    }

    public nonisolated func register<T>(
        _ type: T.Type,
        factory: @escaping @Sendable (DIContainer) -> T
    ) {
        let key = String(describing: T.self)
        lockQueue.sync(execute: {
            factories[key] = { container in factory(container) }
        })
    }

    public nonisolated func registerAsync<T>(
        _ type: T.Type,
        factory: @escaping @Sendable (DIContainer) async -> T
    ) {
        let key = String(describing: T.self)
        lockQueue.sync(execute: {
            asyncFactories[key] = { container in await factory(container) }
        })
    }

    public nonisolated func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: T.self)

        // Check singleton cache first
        if let cached = lockQueue.sync(execute: { singletons[key] }) {
            return cached as? T
        }

        // Check sync factories first
        if let factory = lockQueue.sync(execute: { factories[key] }) {
            let instance = factory(self)
            lockQueue.sync(execute: { singletons[key] = instance })
            return instance as? T
        }

        return nil
    }

    public func resolveAsync<T>(_ type: T.Type) async -> T? {
        let key = String(describing: T.self)

        // Check singleton cache first
        if let cached = lockQueue.sync(execute: { singletons[key] }) {
            return cached as? T
        }

        // Check sync factories first
        if let factory = lockQueue.sync(execute: { factories[key] }) {
            let instance = factory(self)
            lockQueue.sync(execute: { singletons[key] = instance })
            return instance as? T
        }

        // Check async factories
        if let factory = lockQueue.sync(execute: { asyncFactories[key] }) {
            let instance = await factory(self)
            lockQueue.sync(execute: { singletons[key] = instance })
            return instance as? T
        }

        return nil
    }

    private func registerAll() {
        // Core services
        register(TunerDiscoverer.self) { _ in
            TunerDiscovererImpl(manualStore: ManualTunerStore())
        }

        register(LineupProvider.self) { _ in
            LineupProviderImpl()
        }

        register(StreamURLBuilder.self) { _ in
            StreamURLBuilderImpl()
        }

        registerAsync(PlayerController.self) { _ in
            await Task { @MainActor in VLCPlayerController() }.value
        }

        register(GuideProvider.self) { _ in
            MockGuideProvider()
        }

        register(GuideRepository.self) { _ in
            MockGuideRepository()
        }

        register(ChannelMatcher.self) { _ in
            MockChannelMatcher()
        }

        // View Models - created lazily on first resolve (async)
        registerAsync(ChannelsViewModel.self) { container in
            await Task { @MainActor in
                ChannelsViewModel(
                    discoverer: try! container.resolveOrFail(TunerDiscoverer.self),
                    lineupProvider: try! container.resolveOrFail(LineupProvider.self),
                    playerController: try! container.resolveOrFail(PlayerController.self)
                )
            }.value
        }

        registerAsync(PlayerViewModel.self) { container in
            await Task { @MainActor in
                PlayerViewModel(playerController: try! container.resolveOrFail(PlayerController.self))
            }.value
        }

        registerAsync(SettingsViewModel.self) { container in
            await Task { @MainActor in
                SettingsViewModel(manualTunerStore: ManualTunerStore())
            }.value
        }

        // TunerManager - @MainActor so use async registration
        registerAsync(TunerManager.self) { _ in
            await Task { @MainActor in TunerManager(maxConcurrentStreams: 2) }.value
        }
    }
}

/// Mock implementations for services not yet implemented
private final class MockGuideProvider: GuideProvider, @unchecked Sendable {
    func fetch() async throws -> [GuideEntry] { [] }
}

private final class MockGuideRepository: GuideRepository, @unchecked Sendable {
    func save(_ entries: [GuideEntry]) async throws {}
    func entries(for channelID: String, from start: Date, to end: Date) async throws -> [GuideEntry] { [] }
    func entries(from start: Date, to end: Date) async throws -> [GuideEntry] { [] }
}

private final class MockChannelMatcher: ChannelMatcher, @unchecked Sendable {
    func match(tunerChannels: [Channel], guideChannels: [GuideEntry]) async throws -> [ChannelMatch] { [] }
}