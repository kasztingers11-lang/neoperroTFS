# Validation — 2026-10-25

## Current mouse, aim, movement and resupply repair

- Removed Infinite Ammo, Instant Reload, Infinite Range, Zombie Piercing and the ineffective optional wall-avoidance checkbox. The failed cached-piercing experiment was stopped and its owned references restored. It is not part of the shipped source.
- Cursor release was verified live as MouseBehavior.Default. The menu now overrides native mouse lock only while visible; targeting no longer requests LockCenter.
- Aim runs at Camera+1, before the native GunScript's Camera+2, with screen-ray compensation for the actual free cursor. Third-person camera/focus restore at Last+1; the game retains visible camera control and clipping. Mocked matrix/ray tests verify off-center head alignment and exact view restoration. No live zombies were available during the immediate alignment probe, so real headshot damage is not newly claimed.
- Navigation combines sampled local steering and body/ground checks with asynchronous navmesh paths, corner detours, route cancellation, stuck replanning and an 8-stud exit margin. No infinite-survival guarantee is made.
- Added Autofarm auto refill for low reserve ammo, permission/stock checks, safe-gap gating, travel to nearby boxes and normal native interactions. It does not claim a 0.01-second refill, an unlimited magazine, a cash restock purchase, or arbitrary-distance access.
- A live normal box refill returned reserve ammo; changing local Time 5 → 0.01 returned no values and replenished nothing. A normal follow-up kept magazine 7 and increased reserve 115 → 116. Native refill is not a magazine reload. Temporary timing and remote wrappers were restored.
- A separate distant normal-timing probe returned zero values about 79 studs away, but that gun was already full. That probe is inconclusive about distance enforcement; it is not used to claim server-wide access or a proven distance rejection.
- The repaired bundle started in Roblox with both controllers alive, no reported automation error, retired controls absent, the new refill control present, and no new console errors. Live startup is not sustained combat validation.
- A stationary native-camera probe aimed at a synthetic point with zero measured screen-ray angle error in first and third person, restored the visible camera exactly and retained MouseBehavior.Default. This checks camera math, not damage against a live zombie.
- Initial map path probes found nearby goals with successful four-waypoint routes while distant candidates returned NoPath. The final offline repair now tries near, middle and distant candidates rather than filling all attempts with distant goals. Ammo travel also excludes the destination box from ground sampling so its roof does not become the floor target. These final route changes were not re-injected after the user requested offline work.
- Current verification: 32 mocked behavioral tests, four packaging tests, successful local Luau compilation and local Luau analysis with zero diagnostics. New coverage includes before-gun render ordering, off-center camera math, third-person restoration, navmesh corner routes, nearby-goal fallback, pending-plan cancellation, hysteresis, mid-segment cliffs, native ammo timing/stock/ownership/refusal, and shooting during ammo travel versus interaction.

## Earlier automation repair checks (historical)

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
| Zombie Piercing | Raising local Pierce to 32 and the later cached-multiplier experiment did not establish working extra damage; the user confirmed failure. The decompiled source contains multi-target loops, but does not prove the original packet layout or server penetration rules. Feature and control removed. |

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
