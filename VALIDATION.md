# Validation — 2026-10-25

- Final bundled Luau: zero checker errors and warnings (with the live-reload STATE prelude).
- Loaded in Real and inspected screenshots of main/settings, the hidden UI, and a two-entry keybind panel.
- Zero watermark drawings; no per-frame UI callbacks; four tracked engine connections after reload.
- Menu handler tests: hide/reopen, capture a different key without hiding immediately, cancel with Escape, save/load the menu shortcut.
- Native RightShift input successfully hid the menu. Further native-key tests were blocked when Roblox lost focus; those are not counted as passes.
- Keybind panel: two active entries fit inside its background; changing modes reduced the row count from two to one to zero.
- Profile round-trip restored a control key and Always mode, then test defaults were restored and the temporary profile deleted.
- Previous controls remain UI-only. No gameplay features were implemented or tested.

This does not claim exhaustive physical mouse/keyboard testing of every inherited widget, a measured FPS improvement, or compatibility with every executor.
