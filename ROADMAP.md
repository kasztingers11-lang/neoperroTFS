# Implemented efficiency work and remaining proposals

Implemented and tested offline:

- SMART BURSTS with actual local-shot accounting and bounded target scans.
- Fractional reserve priority, optional supply cash reserve and swept retreat checks.
- Permanent background/menu operation with separate physical input ownership.
- MAIN main/backup preferences and return-to-main after inventory resupply.
- Global rapid-fire rate control; per-weapon presets were removed.
- Supply-box ranking by reachable navmesh travel time and threat exposure.
- Manual / Damage first / Headshots first ordering of existing native upgrade categories.

None of these additions establish live damage, survival or a fixed frame rate. See VALIDATION.md for current evidence.

## Remaining game-based proposals

These come from previously inspected native v312 data. Current availability, locks, prices and handlers need fresh verification before implementation.

1. **Native ammo-box upgrade planner.** Expose AmmoSpeed and AmmoRepair through the actual upgrade flow; retain native interaction timing and stock rules.
2. **Resupply perk planning.** Let the player select normal Ammo Logistics / Supply Expert options, showing native tradeoffs instead of silently replacing the loadout.
3. **Native Bottomless Reserve preference.** Surface the Pistol's real reserve-ammo upgrade when owned/unlocked, with its actual price and money-earned tradeoff. It does not remove magazine reloads.
4. **Adaptive retreat distance.** Account for threat closing speed, stamina recovery and reachable space; retain a bounded user-selected radius.
5. **Optional committed-route preview.** Show the actual checked route/destination without restoring removed status paragraphs.
6. **Between-wave repair priorities.** Extend serialized, opt-in spending to verified shop/barricade/armor repair handlers and retain uncertainty stops before Ready.
