# Validation — 2026-10-25

## Main tab design preview

- Final bundled source passed Real's Luau checker with zero errors and warnings.
- Live-reloaded the preview and inspected screenshots: all four sections fit the original 500 × 620 window without clipping.
- Confirmed two tabs remain (main/settings) and old aimlock, silent-aim, flight, speed, recoil and trigger controls are absent.
- Clearing the weapon selector hid all 12 drawings belonging to priority/mode fields. Those fields stayed hidden through tab changes and an animated hide/show cycle, and returned after selecting Pistol.
- Changing upgrade mode updated its explanatory text; defaults were restored afterward.
- No console errors or warnings after loading the preview. The animation connection returned to idle after interactions.
- These are UI checks. Gun modifications, farming, shop automation, inventory choices and third-person gameplay behavior have not been implemented or tested.

## Prior renderer checks

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
