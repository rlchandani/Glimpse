import AppKit
import Combine
import Sparkle
import SwiftUI

// MARK: - Update Status

enum UpdateStatus: Equatable {
    case idle
    case checking
    case latest
    case error(String)
    case available(version: String)
    case downloading
    case extracting
    case readyToInstall
}

// MARK: - Sparkle Updater (shared)

@Observable
@MainActor
final class SparkleUpdater {
    static let shared = SparkleUpdater()

    let userDriver = InlineUpdateDriver()
    var updater: SPUUpdater!
    var canCheckForUpdates = false
    private var cancellable: AnyCancellable?

    var availableVersion: String? {
        if case .available(let version) = userDriver.status { return version }
        return nil
    }

    private init() {
        updater = SPUUpdater(
            hostBundle: Bundle.main,
            applicationBundle: Bundle.main,
            userDriver: userDriver,
            delegate: nil
        )
        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
        do {
            try updater.start()
            AppLogger.general.info("Sparkle updater started")
        } catch {
            AppLogger.general.error("Sparkle updater failed: \(error.localizedDescription)")
        }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}

// MARK: - Inline User Driver

@Observable
@MainActor
final class InlineUpdateDriver: NSObject, SPUUserDriver {
    var status: UpdateStatus = .idle
    var pendingReply: ((SPUUserUpdateChoice) -> Void)?
    var pendingInstallReply: ((SPUUserUpdateChoice) -> Void)?
    private var dismissTask: Task<Void, Never>?

    private func autoDismiss(after seconds: Double = 5) {
        let expectedStatus = status
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled, status == expectedStatus {
                status = .idle
            }
        }
    }

    // MARK: - SPUUserDriver

    func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
        reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
    }

    func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        dismissTask?.cancel()
        status = .checking
    }

    func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping @Sendable (SPUUserUpdateChoice) -> Void) {
        let version = appcastItem.displayVersionString ?? appcastItem.versionString
        status = .available(version: version)
        pendingReply = reply
    }

    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {}
    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {}

    func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        status = .latest
        acknowledgement()
        autoDismiss()
    }

    func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        status = .error("Could not check for updates")
        acknowledgement()
    }

    func showDownloadInitiated(cancellation: @escaping () -> Void) {
        status = .downloading
    }

    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {}
    func showDownloadDidReceiveData(ofLength length: UInt64) {}

    func showDownloadDidStartExtractingUpdate() {
        status = .extracting
    }

    func showExtractionReceivedProgress(_ progress: Double) {}

    func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        status = .readyToInstall
        pendingInstallReply = reply
    }

    func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) {
        status = .extracting
    }

    func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        acknowledgement()
        status = .idle
    }

    func dismissUpdateInstallation() {
        pendingReply = nil
        pendingInstallReply = nil
    }
}
