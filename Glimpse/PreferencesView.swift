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
            launchAtLoginToggle

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
