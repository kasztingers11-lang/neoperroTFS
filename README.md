# neoperroTFS

The original [Abyss Drawing layout](https://github.com/Eazvy/UILibs/blob/main/Librarys/Abyss/Example), with clean text, black surfaces and a static dark-red glow beneath section titles and the selected tab. Subtle motion preserves the rectangular layout; there is no color cycling.

The Main tab includes gun mods, native-input head-lock farming, distance-based retreat, inventory-driven cash upgrades and third person. These offline implementations have passed mocked behavioral checks and Luau analysis; the new automation still needs an in-game check. All automation starts off. The original rectangular UI structure and exact logo are preserved.

## Main tab

- **GUN MODS:** Rapid Fire with a 1–120 shots/second slider (default 60), No Spread and No Recoil. Wallbang was removed. Infinite Ammo, Instant Reload, Infinite Range and Zombie Piercing remain marked unavailable and cannot activate.
- **AUTOFARM:** hard camera lock on a live zombie's Head, normal mouse firing, automatic target change after death, native weapon range and visible targets only. Empty clips use the native reload function; an unequipped gun is equipped through Humanoid. Charge weapons require manual fire. Retreat uses a 5–100 stud radius, body clearance and ground checks, alternative headings around walls, stuck detection and optional native Shift sprint. Optional distance text and a dark-red ground circle show the radius.
- **AUTO UPGRADE:** scans Backpack, Character and owned Backgear, including new/replaced guns and respawns. Select an owned gun, then one of its actual upgrade categories. Selected-only mode stops at that category's maximum; All upgrades tries the priority first and then the remaining categories. Achievement locks and mutually exclusive choices can prevent a complete maximum. No fake Pistol or generic Damage/Range choices remain.
- **THIRD PERSON:** normal third-person zoom, 4–24 studs, with a clipped camera behind the player while head locking. Disabling or unloading restores the previous camera mode and zoom limits.

Hide the UI with RightShift and focus Roblox to let firing, retreat and purchases run. Showing the menu, focusing a text box, losing focus, dying or unloading releases owned fire/movement input. Manual mouse/Shift holds are not taken over. If unloaded while unfocused, a single temporary focus listener finishes a pending native release and disconnects itself.

Auto buy currently means **upgrades for guns you own**, using the native shop's game-cash buttons. It waits for the round to end and for InsideShop; optional travel follows normal pathfinding waypoints to the shop, cancels when a wave starts and retries blocked paths. Close the native shop menu before automatic buying. This does not buy weapons, passes or premium currency items, or open the shop remotely.

Only one purchase can be pending. The adapter reads native prices/locks and invokes the native Lua button handler; it does not synthesize money, levels or weapon stats. Gun mods are temporarily restored during that transaction so native upgrade math sees native values. A matching server refresh plus an increased level is required before continuing or notifying completion. A six-second timeout stops automation without another buy or an invented refund. That weapon remains blocked for this script session after an unconfirmed purchase; check the native shop manually. Loading profiles restores dynamic selections only when the corresponding owned gun/category exists.

## Gun adapter

`src/Features.luau` binds owned guns, including guns added after loading or respawning. No Spread changes hip-fire/ADS spread and its growth, then refreshes the gun's cached spread. No Recoil bypasses the gun's camera-kick call through a scoped proxy. Rapid Fire converts the selected shots/second to the gun's rounds/minute field. Actual throughput depends on frame rate, weapon behavior and server acceptance.

The failed ammo, reload, range and piercing methods have been removed. Their controls immediately return to off and explain that no working method has been verified; loading an old profile cannot activate them. Native ammo, reload time, range, penetration, perk flags and firing packets remain untouched. A working server-compatible replacement for those abilities has not been established. See `VALIDATION.md` for the evidence and limits.

Switching mods off, dropping a weapon or unloading restores owned changes and scoped closure references. If the game updates a value while a mod is active, that update becomes the restoration baseline. Native cached spread is refreshed after restoration. Newly initialized/replaced gun scripts can bind on a later update; retries are limited to once per second per gun. One gun failing to bind does not stop other guns from updating. The gun heartbeat disconnects when gun mods and auto shoot are off.

## Run and controls

Run `loader.luau` in Real, or execute `dist/neoperroTFS.luau`.

- **RightShift** hides and reopens the UI by default.
- In **settings → interface**, click **show / hide UI**, then press your new key. Escape cancels capture. The capture key does not also toggle the menu.
- Use **reset UI bind to RightShift** to restore the default.
- **show keybind list** controls the floating panel, initially hidden. The panel has separate, padded rows and resizes when active bindings change. It hides with the menu.
- Drag the menu header or keybind panel header to move them.
- **save profile / load profile** preserve controls, the UI shortcut, and control keys with their Hold/Toggle/Always modes.
- **unload UI** removes the UI and disconnects its event handlers.

The watermark has been removed. Text input receives keyboard focus without toggling the menu.

## Logo

[View the exact original PNG](assets/logo.png) · [Download](https://raw.githubusercontent.com/kasztingers11-lang/neoperroTFS/main/assets/logo.png)

![Original neoperro logo](assets/logo.png)

The supplied image is unchanged: 1254 × 1254, 220,436 bytes. SHA-256: `1e4d00f434d682b47f9f5f53e07890435f5f018610417e384c5f24db808e23c1`. The standalone bundle embeds those exact bytes, so opening it does not depend on downloading the image. The image's black margins are retained. The build rejects a different logo checksum.

## Source and performance

`src/Library.luau` contains the adapted Abyss renderer; `src/App.luau` declares the menu; `src/Features.luau` owns gun changes; `src/Automation.luau` owns inventory, input, camera and movement; `src/ShopAdapter.luau` wraps the native cash-upgrade UI. The shop closure layout is guarded against the previously inspected v312 shape and stops on unsupported layouts. Run `node build.mjs` to regenerate `dist/neoperroTFS.luau` and the small generated UI textures. No npm dependencies are required.

Run `node --test tests/build.test.mjs` for four packaging checks. With Python and `lupa` installed, run `python tests/run_behavior.py` for 22 behavioral checks of the actual factories using explicit Roblox/input/shop mocks. `--deps PATH` can reuse an existing Python dependency directory. The harness removes only `: any` annotations; it does not replace production logic. Mocks do not prove real server damage, purchase acceptance, camera appearance or map navigation.

Automation uses one throttled heartbeat, event-driven inventory invalidation with a one-second active rescan, and one render binding only while farming or distance visuals need it. Camera aiming runs after the native camera. Escape planning runs at 10 Hz, drawing at 20 Hz, and circle objects are allocated once and reused. Purchases are serialized and rate-limited. All owned listeners, drawings, callback wrappers and camera state are cleaned up on unload, apart from the one-shot pending-input release described above.

The UI retains four shared engine event connections. A single extra render connection exists only while transitions are active and disconnects when idle. There are no animated accent broadcasts, custom cursor loops or clock loops. The glow remains a static texture. These are structural reductions, not a measured FPS claim.

Motion is restrained: 120–160 ms visibility fades, 100 ms hover highlights, a 120 ms tab underline slide with a 140 ms content fade, keybind-row fades and smooth panel contraction, plus 75 ms drag smoothing. Transitions reverse from their current values when interrupted. No bounce, scaling or layout rearrangement is used.

Profiles are stored in `neoperroTFS/Configs/default.json`. Invalid enum names and mismatched control values are ignored, and numeric sliders reject NaN/infinity and clamp valid numbers to their limits. Drawing support is required; HTTP is required only to fetch the loader's remote bundle, and filesystem APIs are needed for profiles. This is not a Roblox Studio LocalScript. See `VALIDATION.md` for tested behavior and limits.

The library and demo derive from the Abyss example in Eazvy/UILibs; original authors retain attribution.
