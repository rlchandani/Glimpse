import AppKit
import Sparkle

@MainActor
final class SparkleUpdater {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        AppLogger.general.info("Sparkle updater initialized")
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
