# neoperroTFS

The original [Abyss Drawing interface](https://github.com/Eazvy/UILibs/blob/main/Librarys/Abyss/Example), cleaned up with readable UI-font text, red accents, optional slow color cycling and small transitions. Its compact horizontal tabs, framed two-column sections, sliders, dropdowns and color pickers retain the Abyss layout.

This is a **UI-only demo**. The original main/rage example controls change menu state only; gameplay features have no implementation.

## Logo

[View the original PNG](assets/logo.png) · [Download the exact image](https://raw.githubusercontent.com/kasztingers11-lang/neoperroTFS/main/assets/logo.png)

![Original neoperro logo](assets/logo.png)

The PNG is the supplied 1254 × 1254 image, unchanged: 220,436 bytes. SHA-256: `1e4d00f434d682b47f9f5f53e07890435f5f018610417e384c5f24db808e23c1`.

The UI downloads that PNG directly from this repository and uses the same bytes for the loader, header icon and watermark. The full image contains substantial black space, so its eyes appear small when displayed as an icon. It is not cropped or recolored.

## Run

Run `loader.luau` in Real, or run `dist/neoperroTFS.luau` directly. RightShift hides/shows the menu; drag the header to move it. The settings tab provides the accent picker, Static / Red pulse / Spectrum modes, animation toggle, profile save/load and unload button.

Profiles store toggle, slider, dropdown and color-picker values in `neoperroTFS/Configs/default.json`. Keybindings are not saved in this version. Filesystem APIs are needed for profiles; Drawing and HTTP support are needed for the UI. This is not a Roblox Studio LocalScript.

## Source

- `src/Library.luau`: the adapted Abyss library and original widget layout.
- `src/App.luau`: original demo tabs plus appearance settings.
- `build.mjs`: dependency-free Node build; run `node build.mjs`.
- `dist/neoperroTFS.luau`: generated runnable bundle.
- `assets/logo.png`: exact user-supplied logo.

The build supplies small gradient, hue and saturation textures because the upstream texture links no longer resolve. It removes unused anime decorations, obsolete settings presets, dead sample code and the synthetic caps-lock keypress. It fixes profile storage, control registration, duplicate fallback flags, color-picker updates, popup closing, tab refresh and teardown. Running the bundle again removes the previous instance. Real live reload also registers cleanup through `STATE.onCleanup`.

The library and demo derive from Eazvy/UILibs's Abyss example; attribution remains with the original authors. See `VALIDATION.md` for checks performed.
