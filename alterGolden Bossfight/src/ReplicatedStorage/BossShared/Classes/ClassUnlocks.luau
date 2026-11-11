-- Who may pick which class. A class that is not listed here is open to everybody.
--   Kind = "Badge"    -> the player must own the badge (Id)
--   Kind = "GamePass" -> the player must own the game pass (Id). Id = 0 means "not set up yet": nobody can buy or own it.
--   Kind = "Cash"     -> bought in the lobby shop for Price cash; ownership is in the saved player record (CashLedger).
-- Warrior, Mage and Tank are the free starting classes, so they are not listed.
-- Upgrades: owning the badge upgrades the class itself (shown as a different title and stronger numbers).
-- The server checks this when a class is picked (ClassService "Select"); the client only uses it to show padlocks.
return table.freeze({
  Supporter = table.freeze({ Kind = "Cash", Id = 0, ClassId = "Supporter", Price = 100, Hint = "Buy in the shop for 100 cash." }),
  Gambler = table.freeze({ Kind = "Cash", Id = 0, ClassId = "Gambler", Price = 175, Hint = "Buy in the shop for 175 cash." }),
  Duelist = table.freeze({ Kind = "Badge", Id = 2347131894818918, Hint = "Beat True Hardcore to unlock." }),
  Twinblade = table.freeze({ Kind = "Badge", Id = 1170331551749924, Hint = "Beat Hellaven to unlock." }),
  -- Quest = true: also owned once the saved record lists it (bring a Reality Orb to the man at the end of the glitched place)
  Disorderer = table.freeze({ Kind = "GamePass", Id = 2074456085, Price = 25, Quest = true, ClassId = "Disorderer",
    Hint = "25 Robux - or find the Reality Orb in the Golden Encounter and bring it to the man at the end of the glitched place." }),
  -- the final class (concept only for now; not in ClassConfig.Order yet)
  TrueWarrior = table.freeze({ Kind = "Badge", Id = 126477610981225, Hint = "Beat True Hardcore solo to unlock.",
  Upgrade = table.freeze({ Name = "Champion", Id = 2914248639183662, Hint = "Beat Hellaven solo to become the Champion." }) }),
})
