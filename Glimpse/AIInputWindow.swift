import AppKit
import SwiftUI

@MainActor
final class AIInputWindow {
    private var window: NSWindow?
    var onDateParsed: ((Date) -> Void)?

    func show() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let inputView = AIInputView { [weak self] date in
            self?.window?.close()
            self?.window = nil
            self?.onDateParsed?(date)
        }

        let hostingView = NSHostingView(rootView: inputView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 350, height: 80)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 80),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.contentView = hostingView
        win.title = "Go to Date"
        win.level = .floating
        win.center()
        win.isReleasedWhenClosed = false
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }
}

struct AIInputView: View {
    @State private var query = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    let onResult: (Date) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(isProcessing ? Color.accentColor : .secondary)
                TextField("e.g. next Friday, Christmas, Jan 2028", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { submit() }
                    .disabled(isProcessing)
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Button("Go") { submit() }
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            if let error = errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .padding()
    }

    private func submit() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !isProcessing else { return }
        isProcessing = true
        errorMessage = nil

        if #available(macOS 26, *) {
            Task {
                let date = await AIDateHelper.parseNaturalLanguageDate(q)
                await MainActor.run {
                    isProcessing = false
                    if let date {
                        onResult(date)
                    } else {
                        errorMessage = "Couldn't understand that date"
                    }
                }
            }
        } else {
            isProcessing = false
            errorMessage = "Requires macOS 26"
        }
    }
}
