# Validation — 2026-10-25

## Current offline automation repair

- Final source was checked with Real's Luau analyzer without an injected game client: zero errors and warnings.
- Four offline build tests pass: exact original logo bytes/checksum/dimensions, matching embedded UI textures, current source inclusion, and identical output after rebuilding.
- Twenty-two behavioral tests pass using the actual Automation, ShopAdapter and Features factories under Lua 5.4 with explicit mocks. The harness strips only `: any` annotations. Coverage includes inventory ownership/replacement/profile selections/metadata, sticky head selection and death switching, walls/range, native press/release and focus/menu cleanup, manual-input ownership, native reload, charge refusal, camera clipping/restoration, retreat directions/walls/cliffs, waypoint travel/cancellation/path errors, selected/all upgrade modes, serialized confirmation/timeout, native shop locks/prices/cash/selection restoration, unrelated refresh events, and gun-mod suspension/restoration across genuine native baseline changes.
- Inventory choices now come from owned weapons and their actual constrained upgrade values. Changes and respawns invalidate the inventory; active scans refresh once per second. Saved selections can resolve after a weapon becomes available.
- Auto shoot hard-locks the camera to Head, waits one frame for native mouse coordinates, then uses normal mouse input. It changes target when the current zombie dies or becomes invalid, hidden or out of native range. Ammo/reload/range remain native. Charge guns fail closed to manual fire.
- Retreat samples 16 headings with body casts and ground/drop checks; it scores zombie separation and wall clearance, penalizes stuck headings, uses world-space Humanoid movement and optional native Shift input. Shop travel uses native pathfinding/MoveTo and cancels when waves start. No teleport, WalkSpeed or stamina writes are used.
- Third person retains the native camera controller and applies a clipped behind-player view during head lock. Original zoom limits, camera mode and owned mouse behavior are restored on disable/unload.
- Native cash upgrades require round-end/InsideShop, an owned gun, a real unlocked affordable row and a native confirmation observer. One request may be pending; gun mods remain suspended until it resolves. Completion requires acknowledgement before the final-level check. Unconfirmed requests stop and block that weapon for the current script session; no automatic retry/refund is attempted.
- The standalone bundle embeds the unchanged logo and all five UI textures. Image HTTP failures no longer block startup.
- Rapid Fire has a 1–120 shots/second slider, default 60. The adapter converts this to rounds/minute and rejects non-finite rates.
- No Spread refreshes the native cache after applying, restoring or receiving changed native spread values. Integer fields keep a representable nonzero spread interval.
- Dropped/replaced guns restore owned values before their native cached spread is rebuilt. Missing Backpacks no longer skip character-held guns.
- Binding retries are limited to once per second per gun. A failure on one gun is isolated from the remaining inventory.
- Unload performs automation cleanup before gun cleanup, then removes the UI. Owned callback wrappers restore in reverse order. An owned native release ignored while unfocused has one temporary focus listener to finish the release and disconnect itself.
- Profiles validate enums and control types; numeric sliders reject NaN/infinity and clamp valid values. Unsupported controls return to off, including when loaded from an old profile.
- No ammo, clip size, range, reload-time, penetration, perk-folder or firing-packet modifications remain. Those four previously failed controls still cannot activate.
- These are code review, static analysis, packaging and mocked behavioral checks. The new automation has not been executed or visually inspected in Roblox. Real damage, camera alignment, sprint input, shop acceptance and pathfinding on the actual map remain unverified. No live tests, game input or purchases were performed during this offline task.

## Live findings before the offline repair

| Feature | Evidence and current status |
| --- | --- |
| Rapid Fire | User confirmed that it deals damage. The same native fire-rate path is retained, with a slider added. Actual throughput can be lower than the selected rate. |
| No Spread | User confirmed that it deals damage. Native spread fields and cached spread were observed changing and restoring. |
| No Recoil | Gun-scoped camera-kick proxy was identified and installed; its original reference restored when disabled. Camera movement was not separately quantified. |
| Wallbang | Removed at the user's request. |
| Infinite Ammo | Negative clip/ammo values and the later native ignore-ammo branch failed sustained damage in user tests. Both methods were removed. Control is unavailable. |
| Instant Reload | A local reload completed in approximately 0.016 seconds, but the user reported that the altered reload path breaks damage. Removed; control unavailable. |
| Infinite Range | Local range changed, but distant server damage was not established and the user reported damage failure. Removed; control unavailable. |
| Zombie Piercing | Raising local Pierce to 32 did not establish extra damage; the user confirmed failure. Client hitscan sends the first hit per pellet, so extending local rays alone does not establish server penetration. Removed; control unavailable. |

An observation of normal native shots produced positive ReturnServerDamage events totaling 600 damage while the experimental controls were present, but each reported primary shot had at most one zombie target. This was not evidence of successful extra penetration.

The ignore-ammo probe initially showed unchanged local ammunition and some positive damage responses. A longer test failed the user's live check. Weapon replacements/swaps also made the aggregate counters unsuitable for proving sustained behavior of one modified weapon. Those earlier positive counters are not treated as proof that infinite ammo works.

Before the user left the game, the active guns' original perk-folder and network-module references were verified by identity, and native range/reload values were restored. All experimental jobs had stopped. No method claiming to bypass server-owned rules is included in the final build.

The native Pistol Bottomless Reserve upgrade was discovered in the game's own upgrade data: $10,000 in game cash, unlimited reserve, reduced money earned from hits. Both attempted live validations aborted before purchasing because cash was no longer sufficient. The new inventory-based upgrade selector can expose it as an ordinary native cash upgrade when present; it is not claimed as a tested replacement for Infinite Ammo and does not cover all guns or remove reloading.

## Preserved UI checks from earlier builds

- The user confirmed that RightShift hides and reopens the visible black/red Abyss UI.
- Prior live screenshots confirmed the rectangular 500 × 620 layout, two tabs, original logo, conditional upgrade fields and restrained transitions.
- Interrupted visibility/tab transitions settled and their animation connection returned to idle.
- A temporary profile roundtrip preserved the new gun toggles before the final offline profile validation changes.
- Clearing the weapon selector hid dependent drawings through tab changes and hide/show transitions.
- Entering another place cleared the script; automatic teleport persistence is not implemented.
- The final offline changes have not received a fresh in-game screenshot or a full FPS benchmark.
