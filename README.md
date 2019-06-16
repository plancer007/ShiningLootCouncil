# ShiningLootCouncil

Original addon made by Zernin (wotlk) and backported to TBC by CrapSoda.

Originally called MasterLootManager I decided to give the addon sort of an overhaul to make it a loot council addon and make it as similar as I can to retail's RCLootCouncil addon

Link to original addon: https://legacy-wow.com/tbc-addons/master-loot-manager/

The GearScore addon for tbc interferes with this addon's ability to scan for player's specs and item lvl so I recommend not using GearScore at the same time if you want correct player specs and item levels.

# TODO

-Figure out a way to know for sure that you're getting the player's correct spec. Atm it's sometimes getting Protection for warriors instead of fury because it switches your inspection target when you hover over another player <.<. Maybe detect that the player is hovering over another player in which case we delete any info we're getting and continue onto the next player.

-Instead of returning '0' or 'not found' when values about players arent found, query other players for the information and then use that info

-Figure out a good way to send info between players so that all data/tables are up to date and using correct values.

-When a player logs in, have them query for information from others about talents/ilvl and items if you're in the middle of looting a boss

-When a tier item is linked link its real item lvl value instead of the token's ilvl, and also link which classes can use the token when announcing to roll for the item.
