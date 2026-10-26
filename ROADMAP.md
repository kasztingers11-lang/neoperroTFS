# Game-based proposals

These are proposals, not implemented features or newly tested purchases. They come from the inspected native v312 game data and handlers; availability still depends on the player's current locks, cash, perks and loadout.

1. **Ammo-box upgrade priorities.** Expose the native AmmoSpeed and AmmoRepair categories alongside weapon upgrades. AmmoSpeed advertises faster normal interactions; AmmoRepair advertises stock recovery at night. Read current levels/prices/locks from the native shop rather than shortening a local timer.
2. **Resupply-aware perk planning.** Show Ammo Logistics (AmmoBoxRefill), which advertises nighttime box regeneration near the shop, and Supply Expert's interaction/ammo-efficiency benefits. Let the player choose these in the normal loadout flow; do not silently change equipped perks.
3. **Native Bottomless Reserve preference.** Surface the Pistol's real UnlimitedAmmo / Bottomless Reserve upgrade when owned and unlocked, including its money-earned tradeoff and actual current price. This is reserve ammunition, not an unlimited magazine or removed reload.
4. **Cost-aware supply planning.** The configurable cash reserve is now implemented for optional weapon upgrades. A future planner could calculate the reserve from actual restock costs and player preferences.
5. **Between-wave maintenance order.** Extend the existing native repair path to prioritize shop/barricade/armor repairs where available, then upgrades/resupply, then Ready. Keep spending opt-in, serialized and stop on uncertain results.

The most useful next step is a native ammo-box upgrade planner. It requires fresh verification of the game's current upgrade handlers. The resupply cash budget is implemented, with default zero to preserve existing spending preferences.

## Proposals after the movement recording

- **Preferred main and backup:** let the player choose weapon order and return to the main weapon after a confirmed refill. Current automatic switching already favors supported loaded backups when the equipped gun is dry.
- **Threat-speed distance:** estimate actual closing speed and choose a sustainable retreat gap instead of using distance alone; account for stamina recovery and avoid increasing the radius beyond reachable space.
- **Reachable resupply fallback:** rank alternate permitted boxes by reachable route, stock and threat exposure, with a player-selected fallback when no safe stocked box exists.
- **Optional route preview:** display only the committed collision-checked route and destination, making blocked exits visible without restoring the removed status paragraphs.

These remain proposals. SMART BURSTS, fractional reserve selection, optional supply cash reserve and swept-path threat checks are now implemented and tested offline. Adaptive retreat distance and an ammo-box upgrade planner are not implemented. Stable steering, checked travel ownership, manual override and stamina-aware sprint remain in place.

## Efficiency proposals after permanent background operation

- **Preferred main/backup and return after refill:** avoid sticking to a weaker backup after the main weapon becomes usable.
- **Exposure-aware resupply:** score stocked, permitted boxes by checked path length and predicted threat exposure, rather than straight-line proximity alone.
- **Native weapon upgrade profiles:** prioritize damage/headshot efficiency or sustainable fire rate within the actual game upgrade system. Do not assume a cosmetic damage/range value changes server damage.
- **Weapon-specific fire-rate presets:** save a tested rate per weapon; choose the lowest rate that reliably meets the intended damage cadence rather than globally maximizing clicks. Accepted server throughput requires live measurement.

These are proposals, not implemented or live-verified features.
