import SwiftUI

struct CalendarPopoverView: View {
    weak var panel: CalendarPanel?

    @State private var displayedMonth = Date()
    @State private var showingPreferences = false
    @State private var isPinned = false
    @State private var scrollAccumulator: CGFloat = 0
    @State private var scrollMonitor: Any?
    @State private var keyMonitor: Any?
    private let preferences = CalendarPreferences.shared
    private let scrollThreshold: CGFloat = 5.0
    private let maxScrollContribution: CGFloat = 1.5
    private let caretHeight = CalendarPanel.caretHeight

    init(panel: CalendarPanel? = nil) {
        self.panel = panel
    }

    var body: some View {
        VStack(spacing: 0) {
            caretView
                .frame(height: caretHeight)

            VStack(spacing: 12) {
                if showingPreferences {
                    PreferencesView(preferences: preferences)
                }
                headerView
                calendarSection
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
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                switch event.keyCode {
                case 123:
                    goToPreviousMonth()
                    return nil
                case 124:
                    goToNextMonth()
                    return nil
                case 36, 76:
                    if !isShowingCurrentMonth {
                        goToToday()
                    }
                    return nil
                case 53:
                    if showingPreferences {
                        withAnimation(AppDesign.Animation.standard) {
                            showingPreferences = false
                        }
                    } else {
                        panel?.isPinned = false
                        panel?.orderOut(nil)
                    }
                    return nil
                default:
                    return event
                }
            }

            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                let delta = event.scrollingDeltaY
                let clamped = max(-maxScrollContribution, min(maxScrollContribution, delta))
                scrollAccumulator += clamped

                if scrollAccumulator > scrollThreshold {
                    scrollAccumulator = 0
                    goToPreviousMonth()
                } else if scrollAccumulator < -scrollThreshold {
                    scrollAccumulator = 0
                    goToNextMonth()
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
            if let monitor = scrollMonitor {
                NSEvent.removeMonitor(monitor)
                scrollMonitor = nil
            }
            scrollAccumulator = 0
            showingPreferences = false
            displayedMonth = Date()
        }
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
            Text(monthYearString)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            HStack(spacing: AppDesign.Spacing.sm + 2) {
                Button(action: goToPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Previous month")

                Button(action: goToToday) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(
                            isShowingCurrentMonth
                                ? Color.secondary.opacity(0.3)
                                : Color.accentColor
                        )
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(isShowingCurrentMonth)
                .accessibilityLabel("Go to today")

                Button(action: goToNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Next month")
            }
        }
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        let cal = preferences.calendar
        let days = calendarDays(using: cal)
        let orderedDays = preferences.orderedWeekdaySymbols()
        let gridInfo = monthGridInfo(days: days)
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
                            .accessibilityLabel("Week \(cal.component(.weekOfYear, from: weekDate))")
                    }
                }

                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { col in
                                let day = days[row * 7 + col]
                                let weekday = orderedDays[col].index
                                let isWorkday = preferences.isWorkday(weekday)
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
        .padding(AppDesign.Spacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.lg)
                .strokeBorder(
                    Color.secondary.opacity(AppDesign.Grid.borderOpacity),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Calendar grid for \(monthYearString)")
    }

    private func monthGridInfo(days: [CalendarDay]) -> (startCol: Int, endCol: Int, endRow: Int) {
        CalendarGridHelper.monthGridInfo(days: days)
    }

    private func dayCell(
        _ day: CalendarDay,
        using cal: Calendar,
        isWorkdayColumn: Bool
    ) -> some View {
        let isToday = day.isCurrentMonth && cal.isDateInToday(day.date)
        let dayNumber = cal.component(.day, from: day.date)

        return Text("\(dayNumber)")
            .font(.system(.body, design: .rounded))
            .fontWeight(isToday ? .bold : .regular)
            .foregroundStyle(foregroundColor(for: day, isToday: isToday))
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
                } else if isWorkdayColumn && day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor.opacity(AppDesign.Grid.workdayTintOpacity))
                }
            }
            .foregroundStyle(isToday ? .white : foregroundColor(for: day, isToday: false))
            .accessibilityLabel(dayAccessibilityLabel(day, dayNumber: dayNumber, isToday: isToday))
    }

    private func dayAccessibilityLabel(
        _ day: CalendarDay, dayNumber: Int, isToday: Bool
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        var label = formatter.string(from: day.date)
        if isToday { label += ", today" }
        if !day.isCurrentMonth { label += ", outside current month" }
        return label
    }

    private func foregroundColor(for day: CalendarDay, isToday: Bool) -> Color {
        if isToday { return .white }
        if !day.isCurrentMonth { return .secondary.opacity(AppDesign.Grid.dimmedTextOpacity) }
        return .primary
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: AppDesign.Spacing.sm) {
            Divider()
            HStack {
                Spacer()

                Button {
                    isPinned.toggle()
                    panel?.isPinned = isPinned
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.body)
                        .foregroundStyle(isPinned ? Color.accentColor : .secondary)
                        .rotationEffect(.degrees(isPinned ? 0 : 45))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel(isPinned ? "Unpin window" : "Pin window")

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
                        showingPreferences.toggle()
                    }
                } label: {
                    Image(systemName: showingPreferences ? "gearshape.fill" : "gearshape")
                        .font(.body)
                        .foregroundStyle(showingPreferences ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel(showingPreferences ? "Close preferences" : "Open preferences")
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

    // MARK: - Navigation

    private func goToPreviousMonth() {
        displayedMonth = preferences.calendar.date(
            byAdding: .month, value: -1, to: displayedMonth
        ) ?? displayedMonth
    }

    private func goToNextMonth() {
        displayedMonth = preferences.calendar.date(
            byAdding: .month, value: 1, to: displayedMonth
        ) ?? displayedMonth
    }

    private func goToToday() {
        displayedMonth = Date()
    }

    private var isShowingCurrentMonth: Bool {
        preferences.calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Data

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func calendarDays(using cal: Calendar) -> [CalendarDay] {
        CalendarGridHelper.calendarDays(for: displayedMonth, using: cal)
    }
}

// MARK: - Month Border Shape

struct MonthBorderShape: Shape {
    let startCol: Int
    let endCol: Int
    let endRow: Int
    let cornerRadius: CGFloat = AppDesign.CornerRadius.md

    func path(in rect: CGRect) -> Path {
        let cw = rect.width / 7
        let ch = rect.height / 6
        let r = cornerRadius

        var vertices: [CGPoint] = []
        let hasTopStep = startCol > 0
        let hasBottomStep = endCol < 6

        if hasTopStep {
            vertices.append(CGPoint(x: CGFloat(startCol) * cw, y: 0))
        } else {
            vertices.append(CGPoint(x: 0, y: 0))
        }

        vertices.append(CGPoint(x: rect.width, y: 0))

        if hasBottomStep {
            vertices.append(CGPoint(x: rect.width, y: CGFloat(endRow) * ch))
            vertices.append(CGPoint(x: CGFloat(endCol + 1) * cw, y: CGFloat(endRow) * ch))
            vertices.append(CGPoint(x: CGFloat(endCol + 1) * cw, y: CGFloat(endRow + 1) * ch))
        } else {
            vertices.append(CGPoint(x: rect.width, y: CGFloat(endRow + 1) * ch))
        }

        if hasTopStep {
            vertices.append(CGPoint(x: 0, y: CGFloat(endRow + 1) * ch))
            vertices.append(CGPoint(x: 0, y: ch))
            vertices.append(CGPoint(x: CGFloat(startCol) * cw, y: ch))
        } else {
            vertices.append(CGPoint(x: 0, y: CGFloat(endRow + 1) * ch))
        }

        var path = Path()
        let count = vertices.count
        let start = midpoint(vertices[count - 1], vertices[0])
        path.move(to: start)

        for i in 0..<count {
            let current = vertices[i]
            let next = vertices[(i + 1) % count]
            path.addArc(tangent1End: current, tangent2End: next, radius: r)
        }

        path.closeSubpath()
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

struct CalendarDay {
    let date: Date
    let isCurrentMonth: Bool
}
