# neoperroTFS

The original [Abyss Drawing layout](https://github.com/Eazvy/UILibs/blob/main/Librarys/Abyss/Example), with clean text, black surfaces and a static dark-red glow beneath section titles and the selected tab. Subtle motion preserves the rectangular layout; there is no color cycling.

The current implementation focuses on **gun mods only**. The other Main sections remain design previews and do not run farming, shop purchases or camera automation. The old main/rage demo controls and rage tab have been removed.

## Main tab

- **GUN MODS:** Rapid Fire with a 1–120 shots/second slider (default 60), No Spread and No Recoil. Wallbang was removed. Infinite Ammo, Instant Reload, Infinite Range and Zombie Piercing remain marked unavailable and cannot activate.
- **AUTOFARM:** auto shoot zombies, distance checker, a 5–100 stud distance slider, distance text/circle toggles, wall avoidance and Shift sprint preferences.
- **AUTO UPGRADE:** enabled, weapon, priority upgrade, selected-only/all-upgrades mode, shop fallback and completion alerts. Clearing the weapon choice hides the dependent priority/mode fields; selecting a weapon restores them. The mode hint explains whether to stop after one upgrade or max the weapon.
- **THIRD PERSON:** enabled and a 4–24 stud camera distance slider.

Pistol and the upgrade categories in AUTO UPGRADE are preview choices. Those controls save menu state only.

## Gun adapter

`src/Features.luau` binds owned guns, including guns added after loading or respawning. No Spread changes hip-fire/ADS spread and its growth, then refreshes the gun's cached spread. No Recoil bypasses the gun's camera-kick call through a scoped proxy. Rapid Fire converts the selected shots/second to the gun's rounds/minute field. Actual throughput depends on frame rate, weapon behavior and server acceptance.

The failed ammo, reload, range and piercing methods have been removed. Their controls immediately return to off and explain that no working method has been verified; loading an old profile cannot activate them. Native ammo, reload time, range, penetration, perk flags and firing packets remain untouched. A working server-compatible replacement for those abilities has not been established. See `VALIDATION.md` for the evidence and limits.

Switching mods off, dropping a weapon or unloading restores owned changes and scoped closure references. If the game updates a value while a mod is active, that update becomes the restoration baseline. Native cached spread is refreshed after restoration. Newly initialized/replaced gun scripts can bind on a later update; retries are limited to once per second per gun. One gun failing to bind does not stop other guns from updating. With every gun mod off, the feature heartbeat disconnects. There are no autofire, camera-aim, movement or purchase loops in this build.

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

The supplied image is unchanged: 1254 × 1254, 220,436 bytes. SHA-256: `1e4d00f434d682b47f9f5f53e07890435f5f018610417e384c5f24db808e23c1`. The standalone bundle embeds those exact bytes, so opening it does not depend on downloading the image. The image's black margins are retained. The build rejects a different logo checksum.

## Source and performance

`src/Library.luau` contains the adapted Abyss renderer; `src/App.luau` declares the menu; `src/Features.luau` owns gun changes and cleanup. Run `node build.mjs` to regenerate `dist/neoperroTFS.luau` and the small generated UI textures. No npm dependencies are required.

Run `node --test tests/build.test.mjs` for offline packaging, exact-image and deterministic-build checks. These do not simulate Roblox or prove server damage.

The UI retains four shared engine event connections. A single extra render connection exists only while transitions are active and disconnects when idle. There are no animated accent broadcasts, custom cursor loops or clock loops. The glow remains a static texture. These are structural reductions, not a measured FPS claim.

Motion is restrained: 120–160 ms visibility fades, 100 ms hover highlights, a 120 ms tab underline slide with a 140 ms content fade, keybind-row fades and smooth panel contraction, plus 75 ms drag smoothing. Transitions reverse from their current values when interrupted. No bounce, scaling or layout rearrangement is used.

Profiles are stored in `neoperroTFS/Configs/default.json`. Invalid enum names and mismatched control values are ignored, and numeric sliders reject NaN/infinity and clamp valid numbers to their limits. Drawing support is required; HTTP is required only to fetch the loader's remote bundle, and filesystem APIs are needed for profiles. This is not a Roblox Studio LocalScript. See `VALIDATION.md` for tested behavior and limits.

The library and demo derive from the Abyss example in Eazvy/UILibs; original authors retain attribution.
