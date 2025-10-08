**A new update** has arrived!
***
**Note**: I apologise for the long delay between updates. The addon has not been abandoned.
I'm working towards the next version and plan to deliver it later this year.

Thank you for using Delve Companion. Stay tuned!
***
**Version [0.9.2]**:
- Add support for the 11.2.5 game update.<br><br>
**Version [0.9.1]**:
- **QoL**: Add tracking of Weekly Caches which contain [Coffer Key Shards](https://www.wowhead.com/item=245653/coffer-key-shard). Their tooltips will display amount of shards that can be obtained that week.
- **Localization**: Add `Spanish` translation (thanks to `Romanv` for contribution).
- Fixed displaying of story variants which are not part of the corresponding achievements as `Not Completed`.<br><br>
**Version [0.9]**:
- **QoL**: Track the active Story Variant for each Delve (thanks Blizzard for providing this information eventually).
    - It's displayed in a tooltip hovering over a Delve button (both in **Delves Tab** and **Delves UI**).
    - The tooltip also highlights whether this variant has been completed in the corresponding achievement or not.
- **Delves Tab**:  If the active Story Variant hasn't been completed yet, there is an orange exclamation mark on the corresponding Delve button.
- Updated consumables and Caches for Season 3. Note:
    - In Season 3, only Caches for Weekly Quests and Ka'Resh activities contain [Restored Coffer Keys](https://www.wowhead.com/currency=3028/restored-coffer-key).
    - Caches for activities of old zones (e.g. Theater Troupe) contain [Coffer Key Shards](https://www.wowhead.com/item=245653/coffer-key-shard) instead (the same limit, 4 per week). The AddOn doesn't track such Caches at the moment.
- Removed the `Overcharged` modifier due to it being inactive in Season 3.
- **MapPinEnhanced support**: Introduce support of `MapPinEnhanced` waypoints (by default: disabled). It can be turned on in the AddOn Settings.
    - At the moment, `MapPinEnhanced` API doesn't provide an option to remove created pins from other addons. Please use `MapPinEnhanced` directly to remove the created pins.
***
[Full versions history](https://github.com/FunDeliveryGames/wow-delve-companion/blob/main/CHANGELOG.md)<br>
[Report an issue](https://github.com/FunDeliveryGames/wow-delve-companion/issues)