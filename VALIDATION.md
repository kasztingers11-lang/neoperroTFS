# Validation — 2026-10-25

## Current offline repair

- Final source was checked with Real's Luau analyzer without an injected game client: zero errors and warnings.
- Four offline build tests pass: exact original logo bytes/checksum/dimensions, matching embedded UI textures, current source inclusion, and identical output after rebuilding.
- The standalone bundle embeds the unchanged logo and all five UI textures. Image HTTP failures no longer block startup.
- Rapid Fire has a 1–120 shots/second slider, default 60. The adapter converts this to rounds/minute and rejects non-finite rates.
- No Spread refreshes the native cache after applying, restoring or receiving changed native spread values. Integer fields keep a representable nonzero spread interval.
- Dropped/replaced guns restore owned values before their native cached spread is rebuilt. Missing Backpacks no longer skip character-held guns.
- Binding retries are limited to once per second per gun. A failure on one gun is isolated from the remaining inventory.
- Unload performs feature cleanup before UI removal, with protection so feature cleanup errors cannot prevent removal of the UI.
- Profiles validate enums and control types; numeric sliders reject NaN/infinity and clamp valid values. Unsupported controls return to off, including when loaded from an old profile.
- No ammo, clip size, range, reload-time, penetration, perk-folder or firing-packet modifications remain. No purchase, auto-shoot, farming, aim or camera automation is shipped.
- These are code review, static-analysis and packaging checks. The final offline refactor has not been executed or visually inspected in Roblox.

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

The native Pistol Bottomless Reserve upgrade was discovered in the game's own upgrade data: $10,000 in game cash, unlimited reserve, reduced money earned from hits. Both attempted validations aborted before purchasing because cash was no longer sufficient. It is not implemented or claimed as a tested replacement, and does not cover all guns or remove reloading.

## Preserved UI checks from earlier builds

- The user confirmed that RightShift hides and reopens the visible black/red Abyss UI.
- Prior live screenshots confirmed the rectangular 500 × 620 layout, two tabs, original logo, conditional upgrade fields and restrained transitions.
- Interrupted visibility/tab transitions settled and their animation connection returned to idle.
- A temporary profile roundtrip preserved the new gun toggles before the final offline profile validation changes.
- Clearing the weapon selector hid dependent drawings through tab changes and hide/show transitions.
- Entering another place cleared the script; automatic teleport persistence is not implemented.
- The final offline changes have not received a fresh in-game screenshot or a full FPS benchmark.
