import SwiftUI

struct PreferencesView: View {
    @Bindable var preferences: CalendarPreferences

    private let allWeekdays = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)

            menuBarDisplaySection
            startOfWeekPicker
            workdaySelector
            launchAtLoginToggle

            Divider()
        }
    }

    // MARK: - Menu Bar Display

    private var menuBarDisplaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu bar display:")
                .font(.subheadline)

            HStack(spacing: 12) {
                Toggle("Icon", isOn: $preferences.showIcon)
                Toggle("Day", isOn: $preferences.showDayOfWeek)
                Toggle("Month", isOn: $preferences.showMonth)
                Toggle("Date", isOn: $preferences.showDate)
                Toggle("Year", isOn: $preferences.showYear)
            }
            .font(.caption)

            // Live preview
            let preview = preferences.menuBarDateString()
            let showIcon = preferences.showIcon || preview.isEmpty
            HStack(spacing: 0) {
                if showIcon {
                    Image(nsImage: DateIconRenderer.render())
                        .padding(.horizontal, 6)
                }
                if showIcon && !preview.isEmpty {
                    Divider()
                        .frame(height: 16)
                }
                if !preview.isEmpty {
                    Text(preview)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 6)
                }
            }
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Start of Week

    private var startOfWeekPicker: some View {
        HStack {
            Text("Week starts on:")
                .font(.subheadline)
            Spacer()
            Picker("", selection: $preferences.startOfWeekday) {
                ForEach(allWeekdays, id: \.self) { weekday in
                    Text(preferences.weekdayName(for: weekday))
                        .tag(weekday)
                }
            }
            .labelsHidden()
            .frame(width: 120)
        }
    }

    // MARK: - Workday Selection

    private var workdaySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workdays:")
                .font(.subheadline)

            HStack(spacing: 6) {
                ForEach(allWeekdays, id: \.self) { weekday in
                    workdayToggle(weekday)
                }
            }
        }
    }

    private func workdayToggle(_ weekday: Int) -> some View {
        let isSelected = preferences.isWorkday(weekday)
        let symbol = Calendar.current.veryShortWeekdaySymbols[weekday - 1]

        return Button {
            preferences.toggleWorkday(weekday)
        } label: {
            Text(symbol)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Launch at Login

    private var launchAtLoginToggle: some View {
        Toggle("Launch at login", isOn: $preferences.launchAtLogin)
            .font(.subheadline)
    }
}
