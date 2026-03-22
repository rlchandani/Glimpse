import GlimpseCore
import SwiftUI

struct CalendarPopoverView: View {
    @Bindable var store: StoreOf<CalendarFeature>
    weak var panel: CalendarPanel?

    @State private var scrollAccumulator: CGFloat = 0
    @State private var scrollMonitor: Any?
    @State private var keyMonitor: Any?
    @State private var aiQueryText: String = ""
    @State private var aiProcessing: Bool = false
    @State private var aiErrorMessage: String?
    @State private var aiFieldActive: Bool = false
    @FocusState private var aiFieldFocused: Bool
    private let scrollThreshold: CGFloat = 5.0
    private let maxScrollContribution: CGFloat = 1.5
    private let caretHeight = CalendarPanel.caretHeight

    var body: some View {
        VStack(spacing: 0) {
            caretView
                .frame(height: caretHeight)

            VStack(spacing: 12) {
                if store.showingPreferences {
                    PreferencesView(
                        store: Store(initialState: PreferencesFeature.State()) {
                            PreferencesFeature()
                        }
                    )
                }
                headerView
                aiQueryField
                calendarSection
                selectedDateInfo
                eventsSection
                footerView
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.lg)
                    .fill(.regularMaterial)
            )
        }
        .frame(width: 300)
        .onAppear {
            store.send(.onAppear)
            setupKeyMonitor()
            setupScrollMonitor()
        }
        .onDisappear {
            removeMonitors()
            store.send(.onDisappear)
        }
    }

    // MARK: - Event Monitors

    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Cmd+G — activate inline AI input
            if event.keyCode == 5 && event.modifierFlags.contains(.command) {
                aiFieldActive = true
                return nil
            }

            switch event.keyCode {
            case 123:
                store.send(.goToPreviousMonth)
                return nil
            case 124:
                store.send(.goToNextMonth)
                return nil
            case 125: // Down arrow
                store.send(.goToNextYear)
                return nil
            case 126: // Up arrow
                store.send(.goToPreviousYear)
                return nil
            case 36, 76: // Enter
                if aiFieldActive {
                    submitAIQuery()
                } else if !store.isShowingCurrentMonth {
                    store.send(.goToToday)
                }
                return nil
            case 53:
                if aiFieldActive {
                    aiFieldActive = false
                    aiQueryText = ""
                    aiErrorMessage = nil
                    panel?.deactivateTextInput()
                    return nil
                }
                if store.showingPreferences {
                    withAnimation(AppDesign.Animation.standard) {
                        _ = store.send(.togglePreferences)
                    }
                } else {
                    store.send(.closePanel)
                    panel?.isPinned = false
                    panel?.orderOut(nil)
                }
                return nil
            default:
                return event
            }
        }
    }

    private func setupScrollMonitor() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            let delta = event.scrollingDeltaY
            let clamped = max(-maxScrollContribution, min(maxScrollContribution, delta))
            scrollAccumulator += clamped

            if scrollAccumulator > scrollThreshold {
                scrollAccumulator = 0
                store.send(.goToPreviousMonth)
            } else if scrollAccumulator < -scrollThreshold {
                scrollAccumulator = 0
                store.send(.goToNextMonth)
            }
            return event
        }
    }

    private func removeMonitors() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
        scrollAccumulator = 0
    }

    // MARK: - Caret

    private var caretView: some View {
        GeometryReader { geometry in
            let caretWidth = AppDesign.Caret.width
            let xOffset = panel?.caretXOffset ?? geometry.size.width / 2

            Path { path in
                let r = AppDesign.Caret.tipRadius
                path.move(to: CGPoint(x: xOffset - caretWidth / 2, y: caretHeight))
                path.addLine(to: CGPoint(x: xOffset - r, y: r))
                path.addQuadCurve(
                    to: CGPoint(x: xOffset + r, y: r),
                    control: CGPoint(x: xOffset, y: -1)
                )
                path.addLine(to: CGPoint(x: xOffset + caretWidth / 2, y: caretHeight))
                path.closeSubpath()
            }
            .fill(.regularMaterial)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(store.monthYearString)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            HStack(spacing: AppDesign.Spacing.sm + 2) {
                Button { store.send(.goToPreviousMonth) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Previous month")

                Button { store.send(.goToToday) } label: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(
                            store.isShowingCurrentMonth
                                ? Color.secondary.opacity(0.3)
                                : Color.accentColor
                        )
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(store.isShowingCurrentMonth)
                .accessibilityLabel("Go to today")

                Button { store.send(.goToNextMonth) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Next month")
            }
        }
    }

    // MARK: - AI Query Field

    @ViewBuilder
    private var aiQueryField: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(
                    aiProcessing ? Color.accentColor :
                    aiFieldActive ? Color.accentColor :
                    Color.secondary.opacity(0.4)
                )

            if aiFieldActive {
                TextField("e.g. next Friday, Christmas...", text: $aiQueryText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .focused($aiFieldFocused)
                    .onSubmit { submitAIQuery() }
                    .onAppear {
                        panel?.activateForTextInput()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            aiFieldFocused = true
                        }
                    }

                if aiProcessing {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Button {
                        aiFieldActive = false
                        aiQueryText = ""
                        aiErrorMessage = nil
                        panel?.deactivateTextInput()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            } else {
                Button {
                    aiFieldActive = true
                } label: {
                    Text("Go to date...  ⌘G")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
        }
        .padding(.horizontal, AppDesign.Spacing.sm)
        .padding(.vertical, AppDesign.Spacing.xs + 2)
        .background(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.sm + 2)
                .fill(Color.secondary.opacity(aiFieldActive ? 0.10 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.sm + 2)
                .strokeBorder(
                    aiFieldActive ? Color.accentColor.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityLabel("Go to date using AI")

        if let error = aiErrorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func submitAIQuery() {
        let query = aiQueryText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty, !aiProcessing else { return }
        aiProcessing = true
        aiErrorMessage = nil

        if #available(macOS 26, *) {
            Task {
                NSLog("[Glimpse] Calling AI for query: %@", query)
                let date = await AIDateHelper.parseNaturalLanguageDate(query)
                await MainActor.run {
                    aiProcessing = false
                    if let date {
                        NSLog("[Glimpse] AI returned date: %@", "\(date)")
                        aiQueryText = ""
                        aiFieldActive = false
                        // Don't call deactivateTextInput here — it would close the panel
                        store.send(.aiDateResult(date))
                    } else {
                        NSLog("[Glimpse] AI returned nil")
                        aiErrorMessage = "Couldn't parse that date. Try: \"next Friday\" or \"Jan 2028\""
                    }
                }
            }
        } else {
            aiProcessing = false
            aiErrorMessage = "Requires macOS 26"
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        let cal = store.calendar
        let days = store.days
        let orderedDays = orderedWeekdaySymbols(startOfWeekday: store.startOfWeekday)
        let gridInfo = store.gridInfo
        let shortNames = Calendar.current.shortWeekdaySymbols

        return VStack(spacing: AppDesign.Spacing.xs) {
            HStack(spacing: 0) {
                Text("Wk")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: AppDesign.Grid.weekNumberWidth)

                ForEach(orderedDays, id: \.index) { day in
                    let isWeekend = day.index == 1 || day.index == 7
                    Text(shortNames[day.index - 1])
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isWeekend ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Calendar.current.weekdaySymbols[day.index - 1])
                }
            }

            if days.count == 42 {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { row in
                            let weekDate = days[row * 7].date
                            Text("\(cal.component(.weekOfYear, from: weekDate))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .frame(
                                    width: AppDesign.Grid.weekNumberWidth,
                                    height: AppDesign.Grid.cellHeight
                                )
                        }
                    }

                    VStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { col in
                                    let day = days[row * 7 + col]
                                    let weekday = orderedDays[col].index
                                    let isWorkday = store.workdays.contains(weekday)
                                    dayCell(day, using: cal, isWorkdayColumn: isWorkday)
                                }
                            }
                        }
                    }
                    .overlay {
                        MonthBorderShape(
                            startCol: gridInfo.startCol,
                            endCol: gridInfo.endCol,
                            endRow: gridInfo.endRow
                        )
                        .stroke(
                            Color.secondary.opacity(AppDesign.Grid.monthBorderOpacity),
                            lineWidth: 1
                        )
                    }
                }
            }
        }
        .padding(AppDesign.Spacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.lg)
                .strokeBorder(
                    Color.secondary.opacity(AppDesign.Grid.borderOpacity),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Calendar grid for \(store.monthYearString)")
    }

    private func orderedWeekdaySymbols(startOfWeekday: Int) -> [(index: Int, symbol: String)] {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return (0..<7).map { offset in
            let weekday = ((startOfWeekday - 1 + offset) % 7) + 1
            return (index: weekday, symbol: symbols[weekday - 1])
        }
    }

    private func dayCell(
        _ day: GlimpseCore.CalendarDay,
        using cal: Calendar,
        isWorkdayColumn: Bool
    ) -> some View {
        let isToday = day.isCurrentMonth && cal.isDateInToday(day.date)
        let dayNumber = cal.component(.day, from: day.date)
        let isSelected = store.selectedDate.map { cal.isDate($0, inSameDayAs: day.date) } ?? false

        return Text("\(dayNumber)")
            .font(.system(.body, design: .rounded))
            .fontWeight(isToday || isSelected ? .bold : .regular)
            .foregroundStyle(foregroundColor(for: day, isToday: isToday, isSelected: isSelected))
            .frame(maxWidth: .infinity)
            .frame(height: AppDesign.Grid.cellHeight)
            .background {
                if isToday {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(
                            width: AppDesign.Grid.todayCircleSize,
                            height: AppDesign.Grid.todayCircleSize
                        )
                } else if isSelected {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .frame(
                            width: AppDesign.Grid.todayCircleSize,
                            height: AppDesign.Grid.todayCircleSize
                        )
                } else if isWorkdayColumn && day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor.opacity(AppDesign.Grid.workdayTintOpacity))
                }
            }
            .foregroundStyle(isToday ? .white : foregroundColor(for: day, isToday: false, isSelected: isSelected))
            .contentShape(Rectangle())
            .onTapGesture {
                store.send(.dateTapped(day.date))
            }
            .accessibilityLabel(dayAccessibilityLabel(day, dayNumber: dayNumber, isToday: isToday))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func dayAccessibilityLabel(
        _ day: GlimpseCore.CalendarDay, dayNumber: Int, isToday: Bool
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        var label = formatter.string(from: day.date)
        if isToday { label += ", today" }
        if !day.isCurrentMonth { label += ", outside current month" }
        return label
    }

    private func foregroundColor(
        for day: GlimpseCore.CalendarDay, isToday: Bool, isSelected: Bool = false
    ) -> Color {
        if isToday { return .white }
        if isSelected { return Color.accentColor }
        if !day.isCurrentMonth { return .secondary.opacity(AppDesign.Grid.dimmedTextOpacity) }
        return .primary
    }

    // MARK: - Selected Date Info

    @ViewBuilder
    private var selectedDateInfo: some View {
        if let info = store.selectedDateInfo {
            HStack(spacing: AppDesign.Spacing.sm) {
                Image(systemName: "calendar.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                Text(info)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .accessibilityLabel("Selected date: \(info)")
        }
    }

    // MARK: - Events Section

    @ViewBuilder
    private var eventsSection: some View {
        if !store.calendarAccessGranted {
            Button {
                store.send(.requestCalendarAccess)
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.subheadline)
                    Text("Show today's events")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Grant calendar access to show events")
        } else if store.todayEvents.isEmpty {
            HStack {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                Text("No events today")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        } else {
            VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                Text("Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(store.todayEvents.prefix(5)) { event in
                    HStack(spacing: AppDesign.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.accentColor)
                            .frame(width: 3, height: 28)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(event.timeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(event.title), \(event.timeString)")
                }

                if store.todayEvents.count > 5 {
                    Text("+\(store.todayEvents.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(AppDesign.Spacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.CornerRadius.md)
                    .strokeBorder(Color.secondary.opacity(AppDesign.Grid.borderOpacity), lineWidth: 1)
            )
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            Divider()
            HStack {
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Quit Glimpse")

                Spacer()

                Button {
                    store.send(.togglePin)
                    panel?.isPinned = store.isPinned
                } label: {
                    Image(systemName: store.isPinned ? "pin.fill" : "pin")
                        .font(.body)
                        .foregroundStyle(store.isPinned ? Color.accentColor : .secondary)
                        .rotationEffect(.degrees(store.isPinned ? 0 : 45))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel(store.isPinned ? "Unpin window" : "Pin window")

                Button(action: openAppleCalendar) {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Open Calendar app")

                Button {
                    withAnimation(AppDesign.Animation.standard) {
                        _ = store.send(.togglePreferences)
                    }
                } label: {
                    Image(systemName: store.showingPreferences ? "gearshape.fill" : "gearshape")
                        .font(.body)
                        .foregroundStyle(
                            store.showingPreferences ? Color.accentColor : .secondary
                        )
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel(
                    store.showingPreferences ? "Close preferences" : "Open preferences"
                )
            }
        }
    }

    private func openAppleCalendar() {
        if let calURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.iCal"
        ) {
            NSWorkspace.shared.openApplication(
                at: calURL,
                configuration: NSWorkspace.OpenConfiguration()
            )
        }
    }
}

