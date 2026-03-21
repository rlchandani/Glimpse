import AppKit
import Carbon

@MainActor
final class GlobalHotkey {
    private var eventHotKey: EventHotKeyRef?
    private var handler: (() -> Void)?

    private static var instance: GlobalHotkey?

    static func register(
        keyCode: UInt32,
        modifiers: UInt32,
        handler: @escaping () -> Void
    ) {
        let hotkey = GlobalHotkey()
        hotkey.handler = handler
        instance = hotkey

        var hotkeyID = EventHotKeyID(signature: 0x474C4D50, id: 1) // "GLMP"
        var hotkeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status == noErr {
            hotkey.eventHotKey = hotkeyRef
            AppLogger.general.info("Global hotkey registered")
        } else {
            AppLogger.general.error("Failed to register global hotkey: \(status)")
        }

        // Install Carbon event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
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
    }

    static func unregister() {
        if let ref = instance?.eventHotKey {
            UnregisterEventHotKey(ref)
        }
        instance = nil
    }
}
