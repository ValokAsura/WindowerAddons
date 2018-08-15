IMPORTANT
---------

This addon requires the addon "TradeNPC" to be installed and loaded before use.
TradeNPC can be found here: https://github.com/Ivaar/Windower-addons

The addon Itemizer is required if you would like to use the command '//qtr all' to also trade items that are in your Mog Sack or Mog Case.
Itemizer can be downloaded from the Windower launcher or found here: http://docs.windower.net/addons/itemizer/


What does this addon do?
------------------------

Example Video: https://youtu.be/TVFWjjP_Dh0

QuickTrade searches your inventory for items that are tradeable or storable with certain NPCs, then sends a command to be used by TradeNPC.
This allows you to automatically trade multiple stacks of items repeatedly with a command instead of using the much slower trade menu.
QuickTrade will inform you of how many times you need to enter //qtr in order to complete all available trades.
For up to 10 seconds after the trade is complete, it will skip any conversations with the NPC.

Valid trades are as follow:

* Elemental Crystals and Clusters: Trade with Ephemeral Moogles for storage or with Waypoints to accumulate Kinetic Units.
* Seals and Crests: Trade with Shami in Port Jeuno to store your various seals and crests.
* Moat Carp: Trade with Joulet or Gallijaux in Port San d'Oria for the Lu Shang's Rod quest.
* Copper Vouchers: Trade with Isakoth, Rolandienne, Fhelm Jobeizat, or Eternal Flame to store your vouchers.
* Rem's Tale Chapters: Trade with Monisette in Port Jeuno to store your chapters.
* UNTESTED - Mellidopt Wings: Trade with the ??? in Yorcia Weald
* UNTESTED - Salvage Plans: Trade with Mrohk Sahjuuli in Aht Urhgan Whitegate to store your plans.
* Alexandrite: Trade with Paparoon in Nashmau for the quest 'Duties, Tasks, and Deeds.'
* Special Gobbie Keys: Trade with one of the various goblins throughout Vana'diel.
* Zinc Ore: Trade with Talib in Port Bastok for the repeatable quest 'Shady Business.'
* Yagudo Necklaces: Trade with Nanaa Mihgo in Windurst Woods for the repeeatable quest 'Mihgo's Amigo.'
* Cornettes: Trade with Yoran-Oran in Windurst Walls for the repeatable quest 'Manragora-Mad.'
	* The other 4 items that Yoran-Oran accepts are also supported.
* La Theine Cabbage, Millioncorn, Boyahda Moss: Trade with Melyon in Selbina for the repeatable quest 'Only the Best.'
* UNTESTED - Soul Plates: Trade with Sanraku in Aht Urhgan Whitegate in exchange for Zeni.
	* Currently set to trade only 1 at a time. This can be changed if needed.
* JSE Capes: Trade with an A.M.A.N. Reclaimer to trade a single cape, or trade with Makel-Pakel in the Celennia Memorial Library to trade 3 of the same cape.
	* Currently set to NOT skip dialogue when trading JSE capes. Make sure your inventory does not have any capes that you want to keep.



Example
-------

You have 3 stacks of Fire Crystals, 1 stack of Ice Crystals, and 2 Fire Clusters in your inventory that you would like to store.
Travel to and target one of the Ephemeral Moogles or Waypoints you would like to trade to.
In the chat window, enter '//qtr' without the quotes and press enter, or enter 'qtr' in the console.
The addon will cause TradeNPC to instantly trade all 3 stacks of Fire Crystals and the 2 Fire Clusters with one command.
After waiting a few seconds, target the moogle or Waypoint again and re-enter the command.
The addon will then cause TradeNPC to instantly trade the stack of Ice Crystals.
If you run the command again, you will be informed that you have no more items to trade.

The behavior is similiar when trading other valid items with valid NPCs.

You will need to enter the command once for each crystal element or item type you possess in your inventory.
This seems to be a game limitation since most NPCs accept only one type of item at a time.

If you have the Itemizer addon and would like to also trade any valid items that you may have in your Mog Case or Mog Sack,
enter the command '//qtr all'. This will allow QuickTrade to search your other valid storage areas and use Itemizer to move the items
into your inventory automatically.

If you wish to test this addon before having it perform a trade, you may edit line 36 in the QuickTrade.lua file.

Change
	exampleOnly = false
to
	exampleOnly = true
	
This will cause the addon to print the command to be issued in the windower console.
When you are ready to allow the addon to trade for you, change the 'true' back to 'false'.


Installation
------------

Browse to your Windower\addons folder and create a new folder inside called "QuickTrade"
Place QuickTrade.lua in this new folder.
Load the addon by accessing the console from within FFXI and typing 'lua l QuickTrade'

If you want this addon to be loaded automatically every time you launch the game,
add 'lua l QuickTrade' to the bottom of the file "Windower\scripts\init.txt"

I would also recommend having the addons TradeNPC and Itemizer load automatically by adding
'lua l TradeNPC' and 'lua l itemizer' to your init.txt.

If TradeNPC is not loaded when using this addon, the trade command will be issued but nothing will happen.



Version History
---------------
v1.4.0
2018.08.11
* Added functionality '//qtr all' to use the Itemizer addon to include items in your Mog Case and Mog Sack
* QuickTrade will target the nearest NPC automatically if you run the command without a target

v1.3.0
2018.07.21
* Added JSE Capes: 1x to the A.M.A.N. Reclaimers, 3x to Makel-Pakel

v1.2.0
2018.07.20
* Added Zinc Ore, Yagudo Necklaces, Mandragora-Mad items, Only the Best items, and Soul Plates

v1.1.0
2018.07.20
* Bugfix - Alexandrite should be detected properly
* Added Special Gobbiedial Keys

v1.0.0
2018.07.16
* Initial Release