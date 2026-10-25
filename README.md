# neoperroTFS

The original [Abyss Drawing layout](https://github.com/Eazvy/UILibs/blob/main/Librarys/Abyss/Example), with clean text, black surfaces and a static dark-red glow beneath section titles and the selected tab. Subtle motion preserves the rectangular layout; there is no color cycling.

This is the **Main tab design preview**. Controls save menu state; gameplay behavior and feasibility checks come after design approval. The old main/rage demo controls and rage tab have been removed.

## Main tab

- **GUN MODS:** independent checkboxes for wallbang, rapid fire, infinite ammo, instant reload and infinite range.
- **AUTOFARM:** auto shoot zombies, distance checker, a 5–100 stud distance slider, distance text/circle toggles, wall avoidance and Shift sprint preferences.
- **AUTO UPGRADE:** enabled, weapon, priority upgrade, selected-only/all-upgrades mode, shop fallback and completion alerts. Clearing the weapon choice hides the dependent priority/mode fields; selecting a weapon restores them. The mode hint explains whether to stop after one upgrade or max the weapon.
- **THIRD PERSON:** enabled and a 4–24 stud camera distance slider.

Pistol and the upgrade categories are preview choices. Inventory discovery, actual shop upgrades, completion notifications, shooting, movement and camera behavior have not been wired or tested. The planned range behavior shares the infinite-range setting with auto shoot. Shop access methods and gun-mod compatibility remain unverified.

## Run and controls

Run `loader.luau` in Real, or execute `dist/neoperroTFS.luau`.

- **RightShift** hides and reopens the UI by default.
- In **settings → interface**, click **show / hide UI**, then press your new key. Escape cancels capture. The capture key does not also toggle the menu.
- Use **reset UI bind to RightShift** to restore the default.
- **show keybind list** controls the floating panel, initially hidden because this preview has no feature keybinds. The panel has separate, padded rows and resizes when active bindings change. It hides with the menu.
- Drag the menu header or keybind panel header to move them.
- **save profile / load profile** preserve controls, the UI shortcut, and control keys with their Hold/Toggle/Always modes.
- **unload UI** removes the UI and disconnects its event handlers.

The watermark has been removed. Text input receives keyboard focus without toggling the menu.

## Logo

[View the exact original PNG](assets/logo.png) · [Download](https://raw.githubusercontent.com/kasztingers11-lang/neoperroTFS/main/assets/logo.png)

![Original neoperro logo](assets/logo.png)

The supplied image is unchanged: 1254 × 1254, 220,436 bytes. SHA-256: `1e4d00f434d682b47f9f5f53e07890435f5f018610417e384c5f24db808e23c1`. The UI downloads it directly from this repository. The image's black margins are retained.

## Source and performance

`src/Library.luau` contains the adapted Abyss renderer; `src/App.luau` declares the menu. Run `node build.mjs` to regenerate `dist/neoperroTFS.luau` and the small generated UI textures. No npm dependencies are required.

The UI retains four shared engine event connections. A single extra render connection exists only while transitions are active and disconnects when idle. There are no animated accent broadcasts, custom cursor loops or clock loops. The glow remains a static texture. These are structural reductions, not a measured FPS claim.

Motion is restrained: 120–160 ms visibility fades, 100 ms hover highlights, a 120 ms tab underline slide with a 140 ms content fade, keybind-row fades and smooth panel contraction, plus 75 ms drag smoothing. Transitions reverse from their current values when interrupted. No bounce, scaling or layout rearrangement is used.

Profiles are stored in `neoperroTFS/Configs/default.json`. Drawing and HTTP support are required; filesystem APIs are needed for profiles. This is not a Roblox Studio LocalScript. See `VALIDATION.md` for tested behavior and limits.

The library and demo derive from the Abyss example in Eazvy/UILibs; original authors retain attribution.
