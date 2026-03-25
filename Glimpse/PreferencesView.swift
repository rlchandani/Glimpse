import AppKit
import Carbon
import GlimpseCore
import SwiftUI

struct PreferencesView: View {
    @Bindable var store: StoreOf<PreferencesFeature>

    private let allWeekdays = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            Text("Preferences")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            menuBarDisplaySection
            startOfWeekPicker
            workdaySelector
            hotkeySection
            launchAtLoginToggle
            checkForUpdatesButton

            Divider()
        }
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Menu Bar Display

    private var menuBarDisplaySection: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Menu bar display:")
                .font(.subheadline)

            HStack(spacing: 12) {
                Toggle("Icon", isOn: $store.displayOptions.showIcon.sending(\.setShowIcon))
                Toggle("Day", isOn: $store.displayOptions.showDayOfWeek.sending(\.setShowDayOfWeek))
                Toggle("Month", isOn: $store.displayOptions.showMonth.sending(\.setShowMonth))
                Toggle("Date", isOn: $store.displayOptions.showDate.sending(\.setShowDate))
                Toggle("Year", isOn: $store.displayOptions.showYear.sending(\.setShowYear))
            }
            .font(.caption)

            let showIcon = store.displayOptions.showIcon
            HStack(spacing: 0) {
                if showIcon {
                    Image(nsImage: DateIconRenderer.render())
                        .padding(.horizontal, AppDesign.StatusItem.padding)
                }
                if showIcon {
                    Divider()
                        .frame(height: AppDesign.Spacing.md)
                }
                Text("Preview")
                    .font(.system(
                        size: AppDesign.StatusItem.fontSize, weight: .medium
                    ))
                    .padding(.horizontal, AppDesign.StatusItem.padding)
            }
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.StatusItem.borderCornerRadius)
                    .strokeBorder(
                        Color.secondary.opacity(AppDesign.StatusItem.borderOpacity),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Start of Week

    private var startOfWeekPicker: some View {
        HStack {
            Text("Week starts on:")
                .font(.subheadline)
            Spacer()
            Picker("Week start day", selection: $store.startOfWeekday.sending(\.setStartOfWeekday)) {
                ForEach(allWeekdays, id: \.self) { weekday in
                    Text(Calendar.current.weekdaySymbols[weekday - 1])
                        .tag(weekday)
                }
            }
            .labelsHidden()
            .frame(width: 120)
            .accessibilityLabel("Week starts on")
        }
    }

    // MARK: - Workday Selection

    private var workdaySelector: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Workdays:")
                .font(.subheadline)

            HStack(spacing: AppDesign.Spacing.sm - 2) {
                ForEach(allWeekdays, id: \.self) { weekday in
                    workdayToggle(weekday)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Workday selection")
    }

    private func workdayToggle(_ weekday: Int) -> some View {
        let isSelected = store.workdays.contains(weekday)
        let symbol = Calendar.current.veryShortWeekdaySymbols[weekday - 1]
        let fullName = Calendar.current.weekdaySymbols[weekday - 1]

        return Button {
            store.send(.toggleWorkday(weekday))
        } label: {
            Text(symbol)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .frame(
                    width: AppDesign.Grid.todayCircleSize,
                    height: AppDesign.Grid.todayCircleSize
                )
                .background(
                    RoundedRectangle(cornerRadius: AppDesign.CornerRadius.sm + 2)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(fullName), \(isSelected ? "workday" : "not a workday")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Hotkey

    @State private var hotkeyEnabled: Bool = {
        UserDefaults.standard.object(forKey: "hotkeyEnabled") != nil
            ? UserDefaults.standard.bool(forKey: "hotkeyEnabled")
            : true
    }()
    @State private var isRecordingHotkey = false
    @State private var hotkeyMonitor: Any?

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack {
                Toggle(isOn: $hotkeyEnabled) {
                    Text("Global shortcut")
                        .font(.subheadline)
                }
                .onChange(of: hotkeyEnabled) { _, enabled in
                    if enabled {
                        let combo = HotkeyCombo.load()
                        GlobalHotkey.register(combo: combo) {
                            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                                appDelegate.calendarStatusItem.statusItemClicked()
                            }
                        }
                    } else {
                        GlobalHotkey.unregister()
                    }
                    UserDefaults.standard.set(enabled, forKey: "hotkeyEnabled")
                }

                Spacer()

                Button {
                    if isRecordingHotkey {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    Text(isRecordingHotkey ? "Press shortcut..." : GlobalHotkey.currentCombo.displayString)
                        .font(.system(.body, design: .monospaced).weight(.medium))
                        .foregroundStyle(isRecordingHotkey ? Color.accentColor : (hotkeyEnabled ? Color.primary : Color.secondary.opacity(0.4)))
                        .padding(.horizontal, AppDesign.Spacing.md)
                        .padding(.vertical, AppDesign.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.sm + 2)
                                .fill(isRecordingHotkey
                                    ? Color.accentColor.opacity(0.1)
                                    : Color.secondary.opacity(hotkeyEnabled ? 0.12 : 0.05)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.sm + 2)
                                .strokeBorder(
                                    isRecordingHotkey ? Color.accentColor : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!hotkeyEnabled)
            }
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecordingHotkey = true
        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !modifiers.isEmpty else { return event }

            var carbonMods: UInt32 = 0
            if modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
            if modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
            if modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
            if modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }

            let combo = HotkeyCombo(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
            combo.save()

            GlobalHotkey.register(combo: combo) {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.calendarStatusItem.statusItemClicked()
                }
            }

            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecordingHotkey = false
        if let monitor = hotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyMonitor = nil
        }
    }

    // MARK: - Check for Updates

    private var checkForUpdatesButton: some View {
        Button {
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                appDelegate.sparkleUpdater.checkForUpdates()
            }
        } label: {
            HStack {
                Text("Check for updates")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Launch at Login

    private var launchAtLoginToggle: some View {
        VStack(alignment: .leading) {
            Toggle(
                "Launch at login",
                isOn: $store.launchAtLogin.sending(\.setLaunchAtLogin)
            )
            .font(.subheadline)

            if let error = store.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

}
