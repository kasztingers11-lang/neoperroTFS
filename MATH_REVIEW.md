# Offline feature audit â€” 2026-10-26

This revision was reviewed locally. It has no new live-game validation. No change can guarantee accepted damage, survival or a particular frame rate.

| Area | Current calculation or protection | Practical limit |
| --- | --- | --- |
| Targeting | Squared range checks, bounded nearest-candidate shortlist, eight visibility rays per throttled search, fair occlusion retries | A blocked crowd can delay acquisition across several scans |
| Firing cadence | Native RPM converted to seconds per shot, elapsed-time scheduling without replaying missed shots | Native gun/server acceptance and rendered frames still limit throughput |
| SMART BURSTS | Actual shot events, conservative single-shot damage samples, `ceil(HP / damage)`, latency-dependent in-flight limit capped at eight | Initial probe can slow engagement; critical hits, falloff and other players can distort estimates |
| Damage feedback | Bounded timeout retries; armor/damage/healing resets; confirmed upgrades clear learned damage; cached estimates expire after 15 seconds when reused for another plan | Health deltas are not server-certified attribution |
| Gun mods | Owned-change restoration, native upgrade reconciliation, charge-type preservation | Native charge weapons still require manual firing |
| Retreat | Local inverse-square threat repulsion, analytic relative-motion closest approach, speed-dependent wall/ground lookahead | Linear velocity prediction is approximate and bounded to two seconds |
| Routes | Swept checks on navmesh segments and current committed corridor; existing stale-result rejection and manual priority | No route may exist when surrounded or map geometry changes |
| Refill | True reserve/capacity ratio, per-threat time-to-contact margin, native duration and proximity | Stock, permissions and native timing still apply; no instant or anywhere refill |
| Purchases | Serialized native transactions and optional cash reserve before weapon upgrades | Native prices, locks, cash and confirmation remain authoritative |
| Ready and priorities | Emergency movement, actionable resupply, shop work and quiet-period readiness retain shared ownership | Other players and native voting permissions can delay a round |
| Camera, controls and effects | Automation continues through menus/background; physical input ownership and bounded visual work remain regression-tested | No new live cursor, hit-placement or camera test this revision |

For relative planar position `r` and relative velocity `v`, closest approach is evaluated at `clamp(-dot(r,v)/dot(v,v), 0, horizon)`. Zero relative velocity is handled separately. The minimum separation is checked along motion rather than assuming that a clear endpoint means a safe crossing.

## Synthetic firing comparison

Two seconds; 60 native shots/second; 40 HP per target; 50 damage per shot; 80 ms delayed health feedback. This tests scheduler behavior in one explicit model, not real weapon damage.

| Simulated FPS | Ordinary shots | Smart shots | Ordinary / smart overkill | Ordinary / smart kills |
| --- | --- | --- | --- | --- |
| 60 | 120 | 24 | 92 / 0 | 23 / 23 |
| 144 | 120 | 24 | 92 / 0 | 23 / 23 |
| 240 | 120 | 24 | 92 / 0 | 23 / 23 |

The full suite runs 145 production behavioral checks plus six packaging/source checks. Trajectory checks compare the analytic minimum against dense samples for 60 deterministic scenes. Compilation and local analysis also pass. None of these establish a real-game performance gain.

## Loadout and supply-route additions

- Weapon selection compares readiness first, then main/backup preference, then loaded/reserve counts. Return-to-main waits for refill ownership and native shop work.
- The global fire rate is clamped to 1–120 requested shots/second. Per-weapon presets were removed. Both gun modifications and cadence consume the same global rate.
- Supply route cost is `sum(segment length / speed * (1 + 20 / max(6, swept gap)))`. A swept gap below six studs rejects the route. Prediction remains bounded/linear and cached; it is not a verified time-dependent safe path. Up to three paths per batch, two-second scheduling, four-second/ten-stud cache limits, rotating failed batches.
- Upgrade plans reorder native categories using names, with no invented category, price or damage value. Existing native transaction checks remain authoritative.

## Committed travel and refill backoff

Route-ranking expiry no longer cancels a committed eligible ammo trip. Waypoint progression handles overshoot. Stalled travel backs off; alternate box approach points rotate by 90 degrees after path failures. Failed native refills wait 8, 16, 32, then at most 60 seconds. Native timing and actual reserve-increase confirmation remain authoritative. FULLBRIGHT is visual-only and does not alter the clock used by shop/round logic.
