import SwiftUI

struct PreferencesView: View {
    @Bindable var preferences: CalendarPreferences

    private let allWeekdays = Array(1...7)

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            Text("Preferences")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            menuBarDisplaySection
            startOfWeekPicker
            workdaySelector
            launchAtLoginToggle

            Divider()
        }
    }

    // MARK: - Menu Bar Display

    private var menuBarDisplaySection: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
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

            let preview = preferences.menuBarDateString()
            let showIcon = preferences.showIcon || preview.isEmpty
            HStack(spacing: 0) {
                if showIcon {
                    Image(nsImage: DateIconRenderer.render())
                        .padding(.horizontal, AppDesign.StatusItem.padding)
                }
                if showIcon && !preview.isEmpty {
                    Divider()
                        .frame(height: AppDesign.Spacing.md)
                }
                if !preview.isEmpty {
                    Text(preview)
                        .font(.system(
                            size: AppDesign.StatusItem.fontSize, weight: .medium
                        ))
                        .padding(.horizontal, AppDesign.StatusItem.padding)
                }
            }
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.StatusItem.borderCornerRadius)
                    .strokeBorder(
                        Color.secondary.opacity(AppDesign.StatusItem.borderOpacity),
                        lineWidth: 1
                    )
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Preview: \(showIcon ? "icon" : "") \(preview)")
        }
    }

    // MARK: - Start of Week

    private var startOfWeekPicker: some View {
        HStack {
            Text("Week starts on:")
                .font(.subheadline)
            Spacer()
            Picker("Week start day", selection: $preferences.startOfWeekday) {
                ForEach(allWeekdays, id: \.self) { weekday in
                    Text(preferences.weekdayName(for: weekday))
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
        let isSelected = preferences.isWorkday(weekday)
        let symbol = Calendar.current.veryShortWeekdaySymbols[weekday - 1]
        let fullName = Calendar.current.weekdaySymbols[weekday - 1]

        return Button {
            preferences.toggleWorkday(weekday)
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

    // MARK: - Launch at Login

    private var launchAtLoginToggle: some View {
        Toggle("Launch at login", isOn: $preferences.launchAtLogin)
            .font(.subheadline)
    }
}
