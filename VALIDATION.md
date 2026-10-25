# Validation — 2026-10-25

- Animated bundle loaded successfully through Real in the lobby and after entering a match.
- Screenshots confirmed the UI visible, hidden, and visible again after animated show/hide.
- User confirmed the UI is visible and physical RightShift hides and reopens it.
- Repeated interrupted hide/show transitions settled with WindowVisible=true and no active animation connection.
- Tab switching completed without a runtime error; animation connection returned to idle.
- No console errors or warnings during the lobby checks.
- Earlier property checks covered hover interpolation, drag drift, and keybind panel growth/contraction. These are not exhaustive physical interaction tests.
- Entering a different place cleared the script state; reloading restored the UI. Automatic persistence across teleports is not implemented.
- The earlier missing-overlay report did not reproduce after reconnecting; its original cause is not proven.
- Controls remain UI-only. No gameplay features were implemented or tested; no FPS improvement is claimed.
