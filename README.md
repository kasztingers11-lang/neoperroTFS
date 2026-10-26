# neoperroTFS

The original [Abyss layout](https://github.com/Eazvy/UILibs/blob/main/Librarys/Abyss/Example), with a readable system font, black surfaces, dark-red glow and restrained fades. Feature/tab labels use capitals. Requested status/explanation lines and SHOW DISTANCE are removed; SHOW DISTANCE CIRCLE remains. The rectangular 500 × 620 structure and exact original logo remain. There is no color cycling.

## Run

Execute `loader.luau` in Real, or execute `dist/neoperroTFS.luau` directly. RightShift shows/hides the menu. Settings includes menu-key capture, profile save/load and unload. This requires executor Drawing support; it is not a Roblox Studio LocalScript. Only the loader requires HTTP. Profiles require filesystem APIs.

## Main

- **SMART BURSTS:** optional shot budgeting, enabled by default when AUTO SHOOT runs. Counts native local shot events, learns conservative damage from nonlethal single-shot health changes, and estimates remaining shots with `ceil(health / observed damage)`. Limits in-flight shots using native fire rate and observed feedback delay, capped at eight. Unknown damage starts with one probe; missing feedback times out and retries. Without the shot listener it falls back to normal firing. This reduces redundant shots; it does not increase damage or guarantee one-hit kills. Other players, armor, critical hits and range can affect estimates.
- **KEEP CASH FOR SUPPLIES:** optional 0–5000 cash reserve (default 0). Weapon upgrades must leave this amount available; native ammo-box restock remains governed by its own cash checks.
- **Gun mods:** Rapid Fire, No Spread and No Recoil. Fire rate is 1–120 requested shots/second, default 60; actual throughput depends on weapon, frames and server acceptance. Failed ammo/reload/range/piercing modifications and Wallbang are removed.
- **Autofarm:** head targeting before the native gun update, native range/line-of-sight/reload, automatic backup switching when the current gun is completely dry (loaded supported guns first, then reserve-only backups), stable wall/ground-aware retreat and asynchronous navmesh detours. Clear escape headings do not request paths; committed routes persist, passed waypoints are skipped and stale results are discarded. Body/ground checks run before retreat or resupply/shop movement. Manual movement takes priority and native stamina recovery uses sprint hysteresis without changing stamina values. Charge weapons require manual firing. Third person restores the freely controlled visible camera after the targeting phase. There is no survival guarantee.
- **Auto refill ammo:** configurable reserve trigger (5–80%, default 30%) and optional between-wave top-up. The controller selects a stocked permitted nearby box, travels normally, waits for a safe gap, and performs the native timed interaction. Available resupply takes priority over optional shop travel. When every gun is empty, the approach uses a smaller emergency retreat radius; the actual refill gap estimates native interaction time and zombie movement speed. Immediate close danger still takes priority. Failed boxes back off eight seconds. Ammo remains supplied by native responses; magazines still reload normally.
- **Auto restock ammo box:** between rounds during daytime, optionally travels to the shop and uses its native game-cash repair handler when main-box stock is below the selected threshold. Cash, shop/first-night restrictions and shared transaction locks apply. One attempt per round; optimistic native changes are labelled submitted, not confirmed.
- **Auto upgrade:** discovers owned weapons and real upgrade categories. Select a weapon, priority and selected-only/all-upgrades mode. Native price, locks, cash and confirmation govern purchases. An uncertain purchase blocks further attempts for that weapon this session. The user confirmed upgrades work after the selection repair.
- **Control:** Start farming enables shooting, retreat and refill, scans inventory and hides the menu. It does not enable spending or auto start. Stop automation disables farming, restock, upgrades and auto start, and releases owned inputs.
- **Auto start round:** opt in separately. Uses the native Vote permission directly; an unavailable refill box does not leave Ready waiting forever, and cancellation before submitting a vote does not consume its attempt. Waits for intermission, enabled affordable upgrade/restock work, resupply, travel and pending transactions, then a 1.5-second quiet period. Calls the game's native Ready handler once per round and never toggles an already-ready vote off. Unaffordable/locked upgrades may carry to the next round. Uncertain transactions block ready; other players can still delay the round.

The **0.01-second refill experiment failed**: reserve did not increase. Its test button and timer changes are removed. Normal auto refill retains native timing and proximity. Instant or anywhere refill is not supported. Shop upgrades and ammo refill use different native operations; an accepted purchase does not establish that the refill wait can be skipped.

## Focus and camera

With **run while unfocused** off (default), losing focus stops owned automation, restores gun mods/camera overrides and cancels queued refill starts. Already-sent transactions can finish. Enabled preferences resume on focus return.

The hit marker has no avatar/screen-center fallback when a recent contact is unknown. Chams reject the local character.

The opt-in background mode uses the native GunScript firing latch instead of OS mouse/keyboard commands. This path is **experimental: background damage was not verified live**. Background movement does not send Shift, so sprint requires foreground focus. Roblox may throttle rendering while unfocused/minimized. The user chose to finish without another live firing check.

An open neoperro menu, native Roblox ESC menu, text editing or key capture pauses farming. RightShift and setting clicks/key capture remain available inside the native ESC menu, including when CoreGui focuses its search textbox. The cursor stays free there. The menu releases the cursor; hold right mouse outside the UI to rotate the native camera. Manual mouse/Shift input is not deliberately taken over. Unload removes owned changes and listeners; a pending OS release can retain one temporary focus listener until release is possible.

## Visuals

The visuals tab has three independent effects, enabled by default:

- **Bullet tracers:** red glow with a white core, using native local shot rays; adjustable lifetime.
- **Hit chams:** short client-only red/white flashes on zombie shot contact. Native visual rays omit zombie references, so a bounded local ray reconstruction resolves contact while respecting intervening geometry. Occluded highlights, not through-wall overlays. Local contact is not separate server confirmation of target damage.
- **Hit indicator:** fading marker and damage number projected at the recent zombie shot contact from native server hit/damage notifications. Positive ReturnServerDamage also triggers the marker because ordinary hits do not necessarily emit RemoteHitmarker; adjustable flash duration.

Effects stay visible when the menu is hidden. Tracers are pooled (maximum 96 segments), chams capped at 16, and all effects clean up on unload. Round stats, its controls, counters and HUD have been removed.

## Feature binds

Right-click a feature checkbox row or its key box for **Hold / Toggle / Set key… / None**. Right-click opens/closes this popup without changing the feature. Left-click a mode or Set key, then press the desired key; Escape cancels and Backspace/Delete clears. **None** explicitly clears the binding while preserving the checkbox state. Only intentional mouse input during capture assigns a mouse button.

Unassigned keys never match mouse `Unknown` key codes. Feature shortcuts run only while the menu is hidden and Roblox is focused. Hold releases on focus loss. Profiles preserve keys/modes; Hold profiles load released. Menu-key capture is separate and cannot accidentally assign the menu shortcut to a feature. The optional keybind list shows active assigned binds and moves independently.

## Source and checks

`src/Library.luau` renders the UI; `Features` manages gun changes; `Automation` coordinates gameplay; `Navigation`, `AmmoAdapter` and `ShopAdapter` wrap native movement, refill and shop interactions; `Visuals` owns shot effects. Native closure layouts are guarded against the inspected game v312. Native firing packets are not rewritten.

Run `node build.mjs` to regenerate the standalone bundle and UI textures (no npm dependencies). Run `node --test tests/build.test.mjs` for four packaging checks. With Python and lupa, `python tests/run_behavior.py` runs 108 behavioral checks. `--deps PATH` can reuse an existing dependency directory. Factories and isolated UI input methods execute from production source with explicit mocks; only `: any` annotations are stripped from factory source. These checks do not prove live combat, server purchases or survival.

Target acquisition uses squared distances and at most eight visibility rays per throttled search, with fair revisits to blocked candidates. Retreat checks closest approach along movement segments, not just endpoint distance, and nearby threats dominate separation steering. Refill selection ranks reserve fractions using real capacities; its safety gap considers each zombie's speed and distance separately. Charge weapons retain their native firing type under RAPID FIRE. See [MATH_REVIEW.md](MATH_REVIEW.md) for the offline audit and simulation limits.

The final bundle passed local Luau compilation and local analysis with no diagnostics. Aim follows every rendered frame. Movement decisions run at up to 20 Hz, live-head raycasts reuse native ignore-list parameters for 0.25 seconds, inventory stays throttled and transactions are serialized. Empty guns reload/switch without needless camera locking. Overlay deadlines cap at 144 Hz without catch-up bursts; shot-contact scans cap at four rays per event and 30 events/second. Inactive tracer handles receive no per-frame property writes. Cadence is tested at simulated 60/144/240 FPS; this is not a measured 240 FPS performance claim. UI input uses five shared engine signals and a temporary animation connection while transitions run. See [VALIDATION.md](VALIDATION.md) for evidence and [ROADMAP.md](ROADMAP.md) for game-based proposals.

## Logo

[Exact original PNG](assets/logo.png) · [Download](https://raw.githubusercontent.com/kasztingers11-lang/neoperroTFS/main/assets/logo.png)

![Original neoperro logo](assets/logo.png)

Unchanged: 1254 × 1254, 220,436 bytes, SHA-256 `1e4d00f434d682b47f9f5f53e07890435f5f018610417e384c5f24db808e23c1`. The standalone bundle embeds those exact bytes, including the original black margins. The build rejects a different checksum.

The library derives from Eazvy/UILibs' Abyss example; original authors retain attribution.

## FlowAuth upload

Upload `dist/neoperroTFS.luau` as the full unobfuscated script. It includes all source modules and exact image assets; `loader.luau` is only the GitHub downloader. No obfuscation was applied.
