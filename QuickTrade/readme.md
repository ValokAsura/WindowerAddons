IMPORTANT
---------

This addon requires the addon "TradeNPC" to be installed and loaded before use.
TradeNPC can be found here: https://github.com/Ivaar/Windower-addons


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
* UNTESTED - Alexandrite: Trade with Paparoon in Nashmau for the quest 'Duties, Tasks, and Deeds.'
* Special Gobbie Keys: Trade with one of the various goblins throughout Vana'diel.


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

If you wish to test this addon before having it perform a trade, you may edit line 33 in the QuickTrade.lua file.

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
add 'lua l QuickTrade' to the bottom of the file Windower\scripts\init.txt.

I would also recommend having the addon TradeNPC load automatically by adding
'lua l TradeNPC' to your init.txt.

If TradeNPC is not loaded when using this addon, the command will be issued but nothing will happen.


Additional Information and Disclaimer
-------------------------------------

QuickTrade only scans your inventory for the items mentioned above then enters a command that will be used by the TradeNPC addon.
No other actions are carried out. This addon will not function if you do not have the TradeNPC addon loaded and working.

I am an amateur programmer and have only recently tried LUA. Please feel free to modify/change/steal any of the code.
If you end up making this addon better, please let me know!


Version History
---------------
v1.1.0
2018.07.20
* Bugfix - Alexandrite should be detected properly
* Added Special Gobbiedial Keys

v1.0.0
2018.07.16
* Initial Release