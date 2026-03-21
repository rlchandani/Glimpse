import AppKit
import Carbon

struct HotkeyCombo: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    static let `default` = HotkeyCombo(keyCode: 8, modifiers: UInt32(cmdKey | shiftKey))

    func save() {
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "hotkeyModifiers")
    }

    static func load() -> HotkeyCombo {
        if UserDefaults.standard.object(forKey: "hotkeyKeyCode") != nil {
            let code = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
            let mods = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
            return HotkeyCombo(keyCode: UInt32(code), modifiers: UInt32(mods))
        }
        return .default
    }

    private func keyName(for code: UInt32) -> String {
        let mapping: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
        ]
        return mapping[code] ?? "Key\(code)"
    }
}

@MainActor
final class GlobalHotkey {
    private var eventHotKey: EventHotKeyRef?
    private var handler: (() -> Void)?

    private static var instance: GlobalHotkey?
    private static var eventHandlerInstalled = false
    static var isRegistered: Bool { instance != nil }
    static var currentCombo: HotkeyCombo = .load()

    static func register(combo: HotkeyCombo, handler: @escaping () -> Void) {
        unregister()

        let hotkey = GlobalHotkey()
        hotkey.handler = handler
        instance = hotkey
        currentCombo = combo

        var hotkeyID = EventHotKeyID(signature: 0x474C4D50, id: 1)
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr {
            hotkey.eventHotKey = hotkeyRef
            combo.save()
            AppLogger.general.info("Global hotkey registered: \(combo.displayString)")
        } else {
            AppLogger.general.error("Failed to register global hotkey: \(status)")
        }

        if !eventHandlerInstalled {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, _, _ -> OSStatus in
                    Task { @MainActor in
                        GlobalHotkey.instance?.handler?()
                    }
                    return noErr
                },
                1,
                &eventType,
                nil,
                nil
            )
            eventHandlerInstalled = true
        }
    }

    static func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        register(combo: HotkeyCombo(keyCode: keyCode, modifiers: modifiers), handler: handler)
    }

    static func unregister() {
        if let ref = instance?.eventHotKey {
            UnregisterEventHotKey(ref)
        }
        instance = nil
    }
}
