# Game-based proposals

These are proposals, not implemented features or newly tested purchases. They come from the inspected native v312 game data and handlers; availability still depends on the player's current locks, cash, perks and loadout.

1. **Ammo-box upgrade priorities.** Expose the native AmmoSpeed and AmmoRepair categories alongside weapon upgrades. AmmoSpeed advertises faster normal interactions; AmmoRepair advertises stock recovery at night. Read current levels/prices/locks from the native shop rather than shortening a local timer.
2. **Resupply-aware perk planning.** Show Ammo Logistics (AmmoBoxRefill), which advertises nighttime box regeneration near the shop, and Supply Expert's interaction/ammo-efficiency benefits. Let the player choose these in the normal loadout flow; do not silently change equipped perks.
3. **Native Bottomless Reserve preference.** Surface the Pistol's real UnlimitedAmmo / Bottomless Reserve upgrade when owned and unlocked, including its money-earned tradeoff and actual current price. This is reserve ammunition, not an unlimited magazine or removed reload.
4. **Cash reserve for essentials.** Reserve a configurable amount for box restock before optional weapon upgrades. Price the plan from actual native costs and explain which purchase is waiting for cash.
5. **Between-wave maintenance order.** Extend the existing native repair path to prioritize shop/barricade/armor repairs where available, then upgrades/resupply, then Ready. Keep spending opt-in, serialized and stop on uncertain results.

The most useful next step is a native ammo-box upgrade planner plus a resupply cash budget. Both build on real game systems that can be checked rather than reviving failed instant-refill or piercing methods.
