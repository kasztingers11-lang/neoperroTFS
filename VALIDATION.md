# Validation — 2026-10-25

- Final bundled Luau: zero checker errors and warnings (with the live-reload STATE prelude).
- Loaded in Real and inspected screenshots of main/settings, the hidden UI, and a two-entry keybind panel.
- Zero watermark drawings; four persistent shared engine connections after reload. The new animation render connection runs only during transitions.
- Menu handler tests: hide/reopen, capture a different key without hiding immediately, cancel with Escape, save/load the menu shortcut.
- Native RightShift input successfully hid the menu. Further native-key tests were blocked when Roblox lost focus; those are not counted as passes.
- Keybind panel: two active entries fit inside its background; changing modes reduced the row count from two to one to zero.
- Profile round-trip restored a control key and Always mode, then test defaults were restored and the temporary profile deleted.
- Previous controls remain UI-only. No gameplay features were implemented or tested.

This does not claim exhaustive physical mouse/keyboard testing of every inherited widget, a measured FPS improvement, or compatibility with every executor.

## Subtle motion checks

- Updated bundle passed Real's checker with zero errors and warnings.
- Rapid hide/show reversal restored every non-hitbox drawing's original opacity.
- Rapid tab switches settled and released the animation render connection.
- Group dragging moved by the requested offset and returned without drift.
- Hover color interpolation was sampled mid-transition, reversed, and settled at its original color.
- Two keybind rows appeared, then retired; the panel settled back to its compact height.
- The render connection was nil after each transition sequence. The runtime console showed no warnings/errors.
- Final screenshots did not capture the Drawing overlay despite visible drawing state; final visual confirmation remains limited. Tests above inspect live drawing properties and handler behavior, not exhaustive physical-input coverage.
