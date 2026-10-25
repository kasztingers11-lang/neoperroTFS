# neoperroTFS

The original [Abyss Drawing layout](https://github.com/Eazvy/UILibs/blob/main/Librarys/Abyss/Example), with clean text, black surfaces and a static dark-red glow beneath section titles and the selected tab. Subtle motion preserves the rectangular layout; there is no color cycling.

The Main tab includes gun mods, native-input head targeting, pathfinding retreat, nearby ammo resupply, ammo-box cash restocking, inventory-driven upgrades and a third-person view with free camera control. The current build loaded in Roblox with the new controls present, a free menu cursor, all automation off and the unfocused state correctly detected. Sustained combat and survival still need live validation. The original rectangular UI structure and exact logo are preserved.

## Main tab

- **GUN MODS:** Rapid Fire with a 1–120 shots/second slider (default 60), No Spread and No Recoil. Wallbang, Infinite Ammo, Instant Reload, Infinite Range and Zombie Piercing have been removed, including their controls. Old profiles cannot recreate removed controls.
- **AUTOFARM:** auto shoot targets a live zombie's Head before the native gun update, compensating for the cursor's actual screen position. It uses normal mouse firing, native range and line-of-sight checks. Death/spawn acquisition can refresh at 30 ms intervals. Empty clips use native reload; charge weapons require manual fire. Auto retreat combines local body/ground checks with scored navmesh routes, corner detours, stuck replanning and optional native Shift sprint. The 5–100 stud radius has an 8-stud exit margin to reduce oscillation. Wall avoidance is always active; the ineffective optional wall toggle is removed. Optional distance text and a dark-red circle show the radius.
- **AUTO UPGRADE:** scans Backpack, Character and owned Backgear, including new/replaced guns and respawns. Select an owned gun, then one of its actual upgrade categories. Selected-only mode stops at that category's maximum; All upgrades tries the priority first and then the remaining categories. Achievement locks and mutually exclusive choices can prevent a complete maximum. No fake Pistol or generic Damage/Range choices remain.
- **THIRD PERSON:** native third-person zoom, 4–24 studs, with free camera control. The targeting frame applies before the native gun update, then restores the visible camera and focus before drawing the frame. Native camera clipping remains in control. Aim does not force MouseBehavior.LockCenter. Disabling/unloading restores the previous camera mode and zoom limits.

Hide the UI with RightShift and focus Roblox to let firing, retreat and purchases run. Showing the menu, focusing a text box, losing focus, dying or unloading releases owned fire/movement input. Manual mouse/Shift holds are not taken over. If unloaded while unfocused, a single temporary focus listener finishes a pending native release and disconnects itself.

The visible menu releases the cursor after the native camera update, including when the game normally uses a first-person mouse lock. Hold the right mouse button outside the main menu/keybind panel to rotate the native camera; release it to return to the free UI cursor. Closing/unloading removes that menu-only render binding and restores the prior behavior. A latched focus-loss event supplements the executor focus check: tabbing out stops owned movement/firing and new purchases, restores gun mods and camera overrides, and cancels queued refill starts. Already-sent native transactions may finish. Focus return reapplies enabled gun preferences.

**Auto refill ammo** is an Autofarm option for low reserve ammunition (20% of native base capacity). It selects a stocked, permitted ammo box and can walk to it. Retreat takes priority when zombies approach; an interaction waits for a safe gap, normal equipped-gun state and the box's native timer. Firing pauses during the actual refill and can continue while walking to the box. Native replies supply ammo; the adapter never invents counts. It does not buy box stock or remove magazine reloads. No method guarantees endless survival on a finite map.

The 0.01-second box-timer attempt returned no ammunition in a live comparison. Automatic refill keeps normal timing. An explicit **test 0.01s refill** button now hides the menu and makes one native attempt at a nearby stocked box with the equipped gun. It restores the original timer on return/error/unload and reports the actual before/after reserve counts and elapsed time. The label is an experiment, not a promise that the server grants ammo instantly; the native wait can also round above 0.01 seconds. Both routes require a nearby box within the native 8-stud radius. Refill from arbitrary positions has not been established.

**Auto restock ammo box** is a separate Autofarm option. Its **restock below (%)** slider defaults to 20% (5–50%). Between rounds during daytime, it travels to the shop if necessary, checks native cash pricing and invokes the game's `ShopPurchase:RepairStructure("AmmoBox")` handler for the main map box. It respects the first-night restriction, available cash and native shop-menu state, and shares a transaction lock with weapon upgrades/refills. Restocking the box does not refill a magazine. The handler changes stock/cash optimistically and has no dedicated acknowledgement; the status says submitted rather than confirmed. At most one restock is attempted per round, including after an error, to avoid repeated uncertain spending. Native pricing may buy only what current cash affords.

Auto buy currently means **upgrades for guns you own**, using the native shop's game-cash buttons. It waits for the round to end and for InsideShop; optional travel follows normal pathfinding waypoints to the shop, cancels when a wave starts and retries blocked paths. Close the native shop menu before automatic buying. This does not buy weapons, passes or premium currency items, or open the shop remotely.

Only one purchase can be pending. The adapter reads native prices/locks and invokes the native Lua button handler; it does not synthesize money, levels or weapon stats. Gun mods are temporarily restored during that transaction so native upgrade math sees native values. A matching server refresh plus an increased level is required before continuing or notifying completion. A six-second timeout stops automation without another buy or an invented refund. That weapon remains blocked for this script session after an unconfirmed purchase; check the native shop manually. Loading profiles restores dynamic selections only when the corresponding owned gun/category exists.

## Gun adapter

`src/Features.luau` binds owned guns, including guns added after loading or respawning. No Spread changes hip-fire/ADS spread and its growth, then refreshes the gun's cached spread. No Recoil bypasses the gun's camera-kick call through a scoped proxy. Rapid Fire converts the selected shots/second to the gun's rounds/minute field. Actual throughput depends on frame rate, weapon behavior and server acceptance.

The failed ammo, reload, range and piercing methods and controls have been removed. Native magazine/ammo data is updated only by the game's normal firing/reload/refill transactions; range, penetration, perk flags and firing packets are not modified by these adapters. A server-compatible unlimited-ammo or instant-reload replacement has not been established. See `VALIDATION.md` for evidence and limits.

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

`src/Library.luau` contains the adapted Abyss renderer; `src/App.luau` declares the menu; `src/Features.luau` owns gun changes; `src/Automation.luau` coordinates inventory, input, camera and movement; `src/Navigation.luau` plans retreat; `src/AmmoAdapter.luau` wraps native ammo-box interactions; `src/ShopAdapter.luau` wraps native cash upgrades. Native closure layouts are guarded against the inspected v312 shapes. Run `node build.mjs` to regenerate `dist/neoperroTFS.luau` and generated UI textures. No npm dependencies are required.

Run `node --test tests/build.test.mjs` for four packaging checks. With Python and `lupa` installed, run `python tests/run_behavior.py` for 43 behavioral checks of the actual factories with Roblox/input/shop mocks and camera transform math. `--deps PATH` can reuse an existing Python dependency directory. The harness removes only `: any` annotations; it does not replace production logic. The final bundle also passed local Luau compilation and local analysis with no diagnostics. Mocks do not prove real server damage, purchase acceptance, camera appearance or survival.

Automation uses one throttled heartbeat and two render bindings only while farming or distance visuals need them: aim at Camera+1, before the gun's Camera+2, and view restoration/movement at Last+1. Existing targets receive a fresh head position and visibility check every render; full acquisition searches are capped at 30 Hz when no target exists and test nearest candidates first. Single-shot input uses measured frame intervals and elapsed-time deadlines, with no replay burst after a hitch; full-auto guns retain a held native input. Native pathfinding runs asynchronously with up to three candidate routes per 0.8-second planning interval; local checks run at 10 Hz, inventory at 1 Hz and gun reconciliation at 4 Hz. The circle projects once per vertex every rendered frame, with cached geometry, point records and Drawing objects; distance text updates at 10 Hz. Timing is tested at simulated 60/144/240 FPS, not a claim that the client sustains 240 FPS. Purchases and resupply are serialized. Owned listeners, drawings, callback wrappers and camera state are cleaned up on unload, apart from the one-shot pending-input release described above.

The UI retains four shared engine event connections, a transient animation connection while transitions run, and the cursor-release binding while the menu is visible. There are no accent broadcasts, custom cursor loops or clock loops. The glow remains static. These are structural reductions, not a measured FPS claim.

Motion is restrained: 120–160 ms visibility fades, 100 ms hover highlights, a 120 ms tab underline slide with a 140 ms content fade, keybind-row fades and smooth panel contraction, plus 75 ms drag smoothing. Transitions reverse from their current values when interrupted. No bounce, scaling or layout rearrangement is used.

Profiles are stored in `neoperroTFS/Configs/default.json`. Invalid enum names and mismatched control values are ignored, and numeric sliders reject NaN/infinity and clamp valid numbers to their limits. Drawing support is required; HTTP is required only to fetch the loader's remote bundle, and filesystem APIs are needed for profiles. This is not a Roblox Studio LocalScript. See `VALIDATION.md` for tested behavior and limits.

The library and demo derive from the Abyss example in Eazvy/UILibs; original authors retain attribution.
