<<<<<<< HEAD
--[[
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
]]

_addon.name = 'QuickTrade'
_addon.author = 'Valok@Asura'
_addon.version = '1.5.0'
_addon.command = 'qtr'

require('tables')
require('coroutine')

exampleOnly = false
textSkipTimer = 1
lastNPC = ''

windower.register_event('addon command', function(arg1,  ...)
	-- Table of the tradeable itemIDs that may be found in the player inventory
	local crystalIDs = {
		{id = 4096, name = 'fire crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4097, name = 'ice crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4098, name = 'wind crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4099, name = 'earth crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4100, name = 'lightning crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4101, name = 'water crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4102, name = 'light crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4103, name = 'dark crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4104, name = 'fire cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4105, name = 'ice cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4106, name = 'wind cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4107, name = 'earth cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4108, name = 'lightning cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4109, name = 'water cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4110, name = 'light cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4111, name = 'dark cluster', count = 0, stacks = 0, stacksize = 12},
	}
	
	local sealIDs = {
		{id = 1126, name = "beastmen's seal", count = 0, stacks = 0, stacksize = 99},
		{id = 1127, name = "kindred's seal", count = 0, stacks = 0, stacksize = 99},
		{id = 2955, name = "kindred's crest", count = 0, stacks = 0, stacksize = 99},
		{id = 2956, name = "high kindred's crest", count = 0, stacks = 0, stacksize = 99},
		{id = 2957, name = "sacred kindred's crest", count = 0, stacks = 0, stacksize = 99},
	}
	
	local moatCarpIDs = {
		{id = 4401, name = 'moat carp', count = 0, stacks = 0, stacksize = 12},
	}
	
	local copperVoucherIDs = {
		{id = 8711, name = 'copper voucher', count = 0, stacks = 0, stacksize = 99},
	}

	local remsTaleIDs = {
		{id = 4064, name = "copy of rem's tale, chapter 1", count = 0, stacks = 0, stacksize = 12},
		{id = 4065, name = "copy of rem's tale, chapter 2", count = 0, stacks = 0, stacksize = 12},
		{id = 4066, name = "copy of rem's tale, chapter 3", count = 0, stacks = 0, stacksize = 12},
		{id = 4067, name = "copy of rem's tale, chapter 4", count = 0, stacks = 0, stacksize = 12},
		{id = 4068, name = "copy of rem's tale, chapter 5", count = 0, stacks = 0, stacksize = 12},
		{id = 4069, name = "copy of rem's tale, chapter 6", count = 0, stacks = 0, stacksize = 12},
		{id = 4070, name = "copy of rem's tale, chapter 7", count = 0, stacks = 0, stacksize = 12},
		{id = 4071, name = "copy of rem's tale, chapter 8", count = 0, stacks = 0, stacksize = 12},
		{id = 4072, name = "copy of rem's tale, chapter 9", count = 0, stacks = 0, stacksize = 12},
		{id = 4073, name = "copy of rem's tale, chapter 10", count = 0, stacks = 0, stacksize = 12},
	}

	local mellidoptWingIDs = {
		{id = 9050, name = 'mellidopt wing', count = 0, stacks = 0, stacksize = 12},
	}

	local salvagePlanIDs = {
		{id = 3880, name = 'copy of bloodshed plans', count = 0, stacks = 0, stacksize = 99},
		{id = 3881, name = 'copy of umbrage plans', count = 0, stacks = 0, stacksize = 99},
		{id = 3882, name = 'copy of ritualistic plans' , count = 0, stacks = 0, stacksize = 99},
	}

	local alexandriteIDs = {
		{id = 2488, name = 'alexandrite', count = 0, stacks = 0, stacksize = 99},
	}

	local spGobbieKeyIDs = {
		{id = 8973, name = 'special gobbiedial key', count = 0, stacks = 0, stacksize = 99},
	}

	local zincOreIDs = {
		{id = 642, name = 'zinc ore', count = 0, stacks = 0, stacksize = 12},
	}

	local yagudoNecklaceIDs = {
		{id = 498, name = 'yagudo necklace', count = 0, stacks = 0, stacksize = 12},
	}

	local mandragoraMadIDs = {
		{id = 17344, name = 'cornette', count = 0, stacks = 0, stacksize = 1},
		{id = 4369, name = 'four-leaf mandragora bud', count = 0, stacks = 0, stacksize = 1},
		{id = 1150, name = 'snobby letter', count = 0, stacks = 0, stacksize = 1},
		{id = 1154, name = 'three-leaf mandragora bud', count = 0, stacks = 0, stacksize = 1},
		{id = 934, name = 'pinch of yuhtunga sulfur', count = 0, stacks = 0, stacksize = 1},
	}

	local onlyTheBestIDs = {
		{id = 4366, name = 'la theine cabbage', count = 0, stacks = 0, stacksize = 12},
		{id = 629, name = 'millioncorn', count = 0, stacks = 0, stacksize = 12},
		{id = 919, name = 'boyahda moss', count = 0, stacks = 0, stacksize = 12},
	}

	local soulPlateIDs = {
		{id = 2477, name = 'soul plate', count = 0, stacks = 0, stacksize = 1}, -- Can only trade 10 per Vana'diel day
	}

	local jseCapeIDs = {
		{id = 28617, name = "mauler's mantle", count = 0, stacks = 0, stacksize = 1},
		{id = 28618, name = "anchoret's mantle", count = 0, stacks = 0, stacksize = 1},
		{id = 28619, name = 'mending cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28620, name = 'bane cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28621, name = 'ghostfyre cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28622, name = 'canny cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28623, name = 'weard mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28624, name = 'niht mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28625, name = "pastoralist's mantle", count = 0, stacks = 0, stacksize = 1},
		{id = 28626, name = "rhapsode's cape", count = 0, stacks = 0, stacksize = 1},
		{id = 28627, name = 'lutian cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28628, name = 'takaha mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28629, name = 'yokaze mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28630, name = 'updraft mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28631, name = 'conveyance cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28632, name = 'cornflower cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28633, name = "gunslinger's cape", count = 0, stacks = 0, stacksize = 1},
		{id = 28634, name = 'dispersal mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28635, name = 'toetapper mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28636, name = "bookworm's cape", count = 0, stacks = 0, stacksize = 1},
		{id = 28637, name = 'lifestream cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28638, name = "evasionist's cape", count = 0, stacks = 0, stacksize = 1},
	}

	local ancientBeastcoinIDs = {
		{id = 1875, name = 'ancient beastcoin', count = 0, stacks = 0, stacksize = 99},
	}

	local reisenjimaStones = {
		{id = 9210, name = 'pellucid stone', count = 0, stacks = 0, stacksize = 12},
		{id = 9211, name = 'fern stone', count = 0, stacks = 0, stacksize = 12},
		{id = 9212, name = 'taupe stone', count = 0, stacks = 0, stacksize = 12},
	}

	local befouledWaterIDs = {
		{id = 9008, name = 'befouled water', count = 0, stacks = 0, stacksize = 1},
	}

	local npcTable = {
		{name = 'Shami', idTable = sealIDs, tableType = 'Seals'},
		{name = 'Ephemeral Moogle', idTable = crystalIDs, tableType = 'Crystals'},
		{name = 'Waypoint', idTable = crystalIDs, tableType = 'Crystals'},
		{name = 'Joulet', idTable = moatCarpIDs, tableType = 'Moat Carp'},
		{name = 'Gallijaux', idTable = moatCarpIDs, tableType = 'Moat Carp'},
		{name = 'Isakoth', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Rolandienne', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Fhelm Jobeizat', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Eternal Flame', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Monisette', idTable = remsTaleIDs, tableType = "Rem's Tales"},
		{name = '???', idTable = mellidoptWingIDs, tableType = 'Mellidopt Wings'},
		{name = 'Mrohk Sahjuuli', idTable = salvagePlanIDs, tableType = 'Salvage Plans'},
		{name = 'Paparoon', idTable = alexandriteIDs, tableType = 'Alexandrite'},
		{name = 'Mystrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Habitox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Bountibox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Specilox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Arbitrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Funtrox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Priztrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Sweepstox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Wondrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Rewardox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Winrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Talib', idTable = zincOreIDs, tableType = 'Zinc Ore'},
		{name = 'Nanaa Mihgo', idTable = yagudoNecklaceIDs, tableType = 'Yagudo Necklaces'},
		{name = 'Yoran-Oran', idTable = mandragoraMadIDs, tableType = 'Mandragora Mad Items'},
		{name = 'Melyon', idTable = onlyTheBestIDs, tableType = 'Only the Best Items'},
		{name = 'Sanraku', idTable = soulPlateIDs, tableType = 'Soul Plates'},
		{name = 'A.M.A.N. Reclaimer', idTable = jseCapeIDs, tableType = 'JSE Capes'},
		{name = 'Makel-Pakel', idTable = jseCapeIDs, tableType = 'JSE Capes x3'},
		{name = 'Sagheera', idTable = ancientBeastcoinIDs, tableType = 'Ancient Beastcoins'},
		{name = 'Oseem', idTable = reisenjimaStones, tableType = 'Reisenjima Stones'},
		{name = 'Odyssean Passage', idTable = befouledWaterIDs, tableType = 'Befouled Water'},
	}
	
	local idTable = {}
	local tableType = ''
	local target = windower.ffxi.get_mob_by_target('t')
	
	if not target then
		windower.send_command('input /targetnpc')
		coroutine.sleep(0.4)
		target = windower.ffxi.get_mob_by_target('t')

		if not target then
			print('QuickTrade: No target selected')
			return
		end
	end

	for i = 1, #npcTable do
		if target.name == npcTable[i].name then
			idTable = npcTable[i].idTable
			tableType = npcTable[i].tableType
			break
		end
	end

	

	-- FOR TESTING WITHOUT NPC PRESENT!!!!!!!!!!!!!
	--idTable = table.copy(alexandriteIDs)
	--tableType = 'Alexandrite'
	--exampleOnly = true



	if #idTable == 0 or tableType == '' then
		print('QuickTrade: Invalid target')
		lastNPC = ''
		return
	end

	mogSackTable = table.copy(idTable)
	mogCaseTable = table.copy(idTable)

	-- Scan the mog sack for each item in idTable
	local mogSack = windower.ffxi.get_items('sack')
	if not mogSack then
		print('mogSack read error')
	else
		for i = 1, #mogSackTable do
			for k, v in ipairs(mogSack) do
				if v.id == mogSackTable[i].id then
					mogSackTable[i].count = mogSackTable[i].count + v.count -- Updates the total number of items of each type
					mogSackTable[i].stacks = mogSackTable[i].stacks + 1 -- Updates the total number of stacks of each type
				end
			end
		end
	end

	-- Scan the mog case for each item in idTable
	local mogCase = windower.ffxi.get_items('case')
	if not mogCase then
		print('mogCase read error')
	else
		for i = 1, #mogCaseTable do
			for k, v in ipairs(mogCase) do
				if v.id == mogCaseTable[i].id then
					mogCaseTable[i].count = mogCaseTable[i].count + v.count -- Updates the total number of items of each type
					mogCaseTable[i].stacks = mogCaseTable[i].stacks + 1 -- Updates the total number of stacks of each type
				end
			end
		end
	end

	-- Uses the Itemizer addon to move tradable items from the mog case/sack into the player's inventory
	if arg1 == 'all' and mogCase and mogSack then
		inventory = windower.ffxi.get_items('inventory')
		for i = 1, #idTable do
			for k, v in ipairs(inventory) do
				if v.id == idTable[i].id then
					idTable[i].count = idTable[i].count + v.count -- Updates the total number of items of each type
					idTable[i].stacks = idTable[i].stacks + 1 -- Updates the total number of stacks of each type
				end
			end
		end

		for i = 1, #mogSackTable do
			if mogSackTable[i].count + mogCaseTable[i].count > 0 then
				if exampleOnly then
					print('//get "' .. mogSackTable[i].name ..  '" ' .. idTable[i].count + mogSackTable[i].count + mogCaseTable[i].count)
				else
					windower.add_to_chat(8, 'QuickTrade: Please wait - Using Itemizer to transfer ' .. mogSackTable[i].count + mogCaseTable[i].count .. ' ' .. mogSackTable[i].name .. ' to inventory')
					windower.send_command('input //get "' .. mogSackTable[i].name ..  '" ' .. idTable[i].count + mogSackTable[i].count + mogCaseTable[i].count)
					coroutine.sleep(2.5)
				end
			end
		end

		for i = 1, #idTable do
			idTable[i].count = 0
			idTable[i].stacks = 0
		end
	else
		if target.name ~= lastNPC then
			lastNPC = target.name
			local mogCount = 0

			for i = 1, #mogSackTable do
				mogCount = mogCount + mogSackTable[i].count + mogCaseTable[i].count
			end
			
			if mogCount > 0 then
				windower.add_to_chat(8, 'QuickTrade: ' .. mogCount .. ' of these items are in your mog sack/case. Type "//qtr all" if you wish to move them into your inventory and trade them. Requires Itemizer')
			end
		end
	end

	-- Read the player inventory
	inventory = windower.ffxi.get_items('inventory')

	if not inventory then
		print('QuickTrade: Unable to read inventory')
		return
	end

	-- Scan the inventory for each item in idTable
	for i = 1, #idTable do
		for k, v in ipairs(inventory) do
			if v.id == idTable[i].id then
				idTable[i].count = idTable[i].count + v.count -- Updates the total number of items of each type
				idTable[i].stacks = idTable[i].stacks + 1 -- Updates the total number of stacks of each type
			end
		end
	end
	
	local numTrades = 0 -- Number of times //qtr needs to be run to empty the player inventory
	local availableTradeSlots = 8

	if tableType == 'Crystals' then
		if target.name == 'Ephemeral Moogle' then
			for i = 1, 8 do
				if idTable[i].stacks > 0 or idTable[i + 8].stacks > 0 then
					numTrades = numTrades + math.ceil((idTable[i].stacks + idTable[i + 8].stacks) / 8)
				end
			end
		else
			for i = 1, 8 do
				if idTable[i].stacks > 0 or idTable[i + 8].stacks > 0 then
					numTrades = numTrades + idTable[i].stacks + idTable[i + 8].stacks
				end
			end

			numTrades = math.ceil(numTrades / 8)
		end
	elseif tableType == 'Zinc Ore' or tableType == 'Yagudo Necklaces' then -- 4 at a time
		numTrades = math.floor(idTable[1].count / 4)
	elseif tableType == 'Mandragora Mad Items' or tableType == 'JSE Capes' then -- 1 at a time
		for i = 1, #idTable do
			numTrades = numTrades + idTable[i].count
		end
	elseif tableType == 'JSE Capes x3' then -- 3 of the same kind
		for i = 1, #idTable do
			if idTable[i].count >= 3 then
				numTrades = numTrades + math.min(1, math.floor(idTable[i].count / 3))
			end
		end
	elseif tableType == 'Only the Best Items' then -- Unique for this quest
		numTrades = numTrades + math.floor(idTable[1].count / 5)
		numTrades = numTrades + math.floor(idTable[2].count / 3)
		numTrades = numTrades + idTable[3].count
	elseif tableType == 'Special Gobbiedial Keys' or tableType == 'Soul Plates' then
		numTrades = idTable[1].count
	elseif tableType == 'Reisenjima Stones' then
		numTrades = math.ceil((idTable[1].stacks + idTable[2].stacks + idTable[3].stacks) / 8)
	else
		for i = 1, #idTable do
			if idTable[i].stacks > 0 then
				numTrades = numTrades + math.ceil(idTable[i].stacks / 8)
			end
		end
	end

	if exampleOnly then
		print(numTrades .. ' total trades')
	end

	-- Prepare and send command through TradeNPC if there are trades to be made
	if numTrades > 0 then
		local tradeString = '//tradenpc '
		availableTradeSlots = 8
		
		if tableType == 'Crystals' then
			tradeString = '//tradenpc'

			for i = 1, 8 do
				-- Build the string that will be used as the command
				--availableTradeSlots = 8
				
				if idTable[i].count > 0 then
					tradeString = tradeString .. ' ' .. math.min(availableTradeSlots * idTable[i].stacksize, idTable[i].count) .. ' "' .. idTable[i].name .. '"'
					availableTradeSlots = math.max(0, availableTradeSlots - idTable[i].stacks)
				end
				
				if availableTradeSlots > 0 and idTable[i + 8].count > 0 then
					tradeString = tradeString .. ' ' .. math.min(availableTradeSlots * idTable[i + 8].stacksize, idTable[i + 8].count) .. ' "' .. idTable[i + 8].name .. '"'
					availableTradeSlots = math.max(0, availableTradeSlots - idTable[i].stacks)
				end

				if (target.name == 'Ephemeral Moogle' and (idTable[i].count > 0 or idTable[i + 8].count > 0)) or availableTradeSlots < 1 then
					--print(target.name .. ' - ' .. availableTradeSlots)
					break
				end
			end
		elseif tableType == 'Special Gobbiedial Keys' or tableType == 'Soul Plates' then -- 1 item at a time
			tradeString = '//tradenpc  1 "' .. idTable[1].name .. '"'
		elseif tableType == 'Zinc Ore' or tableType == 'Yagudo Necklaces' then -- 4 items at a time
			if idTable[1].count >= 4 then
				tradeString = '//tradenpc 4 "' .. idTable[1].name .. '"'
			end
		elseif tableType == 'Mandragora Mad Items' or tableType == 'JSE Capes' then
			for i = 1, #idTable do
				tradeString = '//tradenpc '

				if idTable[i].count > 0 then
					tradeString = tradeString .. '1 "' .. idTable[i].name .. '"'
					break
				end
			end
		elseif tableType == 'JSE Capes x3' then
			for i = 1, #idTable do
				tradeString = '//tradenpc '

				if idTable[i].count >= 3 then
					tradeString = tradeString .. '3 "' .. idTable[i].name .. '"'
					break
				end
			end
		elseif tableType == 'Only the Best Items' then
			for i = 1, #idTable do
				tradeString = '//tradenpc '

				if idTable[1].count >= 5 then
					tradeString = tradeString .. '5 "' .. idTable[1].name .. '"'
					break
				end

				if idTable[2].count >= 3 then
					tradeString = tradeString .. '3 "' .. idTable[2].name .. '"'
					break
				end

				if idTable[3].count > 0 then
					tradeString = tradeString .. '1 "' .. idTable[3].name .. '"'
					break
				end
			end
		elseif tableType == 'Reisenjima Stones' then
			tradeString = '//tradenpc'

			for i = 1, #idTable do
				if idTable[i].count > 0 then
					if availableTradeSlots > 0 then
						tradeString = tradeString .. ' ' .. math.min(availableTradeSlots * idTable[i].stacksize, idTable[i].count) .. ' "' .. idTable[i].name .. '"'
						print(i .. ': ' .. tradeString)
						availableTradeSlots = math.max(0, availableTradeSlots - idTable[i].stacks)
					else
						break
					end
				end
			end
		else
			for i = 1, #idTable do
				tradeString = '//tradenpc '
				availableTradeSlots = 8
				
				if idTable[i].count > 0 then
					--availableTradeSlots = math.max(1, availableTradeSlots - idTable[i].stacks)
					tradeString = tradeString .. math.min(availableTradeSlots * idTable[i].stacksize, idTable[i].count) .. ' "' .. idTable[i].name .. '"'
					break
				end
			end
		end

		if tradeString ~= '//tradenpc ' then
			if numTrades - 1 == 0 then
				windower.add_to_chat(8, 'QuickTrade: Trading Complete')
			elseif numTrades - 1 == 1 then
				windower.add_to_chat(8, 'QuickTrade: ' .. (numTrades - 1) .. ' trade remaining')
			else
				windower.add_to_chat(8, 'QuickTrade: ' .. (numTrades - 1) .. ' trades remaining')
			end
			
			if exampleOnly then
				print(tradeString)
			else
				if tableType ~= 'JSE Capes' and tableType ~= 'JSE Capes x3' then
					textSkipTimer = os.time()
				end
				
				windower.send_command('input ' .. tradeString)
			end
		end
	else
		if arg1 == 'all' then
			windower.add_to_chat(8, "QuickTrade - No " .. tableType .. " in inventory, mog case, or mog sack")
		else
			windower.add_to_chat(8, "QuickTrade - No " .. tableType .. " in inventory")
		end
	end
end)
 
windower.register_event('incoming text', function(original, modified, mode)
	-- Allow the addon to skip the conversation text for up to 10 seconds after the trade
	if os.time() - textSkipTimer > 10 then
		return
	end
	
	local target = windower.ffxi.get_mob_by_target('t')
	
	if not target then
		return false
	end
	
	if mode == 150 or mode == 151 then
		modified = modified:gsub(string.char(0x7F, 0x31), '')
	end
	
	return modified
=======
--[[
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
]]

_addon.name = 'QuickTrade'
_addon.author = 'Valok@Asura'
_addon.version = '1.4.0'
_addon.command = 'qtr'

require('tables')
require('coroutine')

exampleOnly = false
textSkipTimer = 1
lastNPC = ''

windower.register_event('addon command', function(arg1, ...)
	-- Table of the tradeable itemIDs that may be found in the player inventory
	local crystalIDs = {
		{id = 4096, name = 'fire crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4097, name = 'ice crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4098, name = 'wind crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4099, name = 'earth crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4100, name = 'lightning crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4101, name = 'water crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4102, name = 'light crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4103, name = 'dark crystal', count = 0, stacks = 0, stacksize = 12},
		{id = 4104, name = 'fire cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4105, name = 'ice cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4106, name = 'wind cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4107, name = 'earth cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4108, name = 'lightning cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4109, name = 'water cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4110, name = 'light cluster', count = 0, stacks = 0, stacksize = 12},
		{id = 4111, name = 'dark cluster', count = 0, stacks = 0, stacksize = 12},
	}
	
	local sealIDs = {
		{id = 1126, name = "beastmen's seal", count = 0, stacks = 0, stacksize = 99},
		{id = 1127, name = "kindred's seal", count = 0, stacks = 0, stacksize = 99},
		{id = 2955, name = "kindred's crest", count = 0, stacks = 0, stacksize = 99},
		{id = 2956, name = "high kindred's crest", count = 0, stacks = 0, stacksize = 99},
		{id = 2957, name = "sacred kindred's crest", count = 0, stacks = 0, stacksize = 99},
	}
	
	local moatCarpIDs = {
		{id = 4401, name = 'moat carp', count = 0, stacks = 0, stacksize = 12},
	}
	
	local copperVoucherIDs = {
		{id = 8711, name = 'copper voucher', count = 0, stacks = 0, stacksize = 99},
	}

	local remsTaleIDs = {
		{id = 4064, name = "copy of rem's tale, chapter 1", count = 0, stacks = 0, stacksize = 12},
		{id = 4065, name = "copy of rem's tale, chapter 2", count = 0, stacks = 0, stacksize = 12},
		{id = 4066, name = "copy of rem's tale, chapter 3", count = 0, stacks = 0, stacksize = 12},
		{id = 4067, name = "copy of rem's tale, chapter 4", count = 0, stacks = 0, stacksize = 12},
		{id = 4068, name = "copy of rem's tale, chapter 5", count = 0, stacks = 0, stacksize = 12},
		{id = 4069, name = "copy of rem's tale, chapter 6", count = 0, stacks = 0, stacksize = 12},
		{id = 4070, name = "copy of rem's tale, chapter 7", count = 0, stacks = 0, stacksize = 12},
		{id = 4071, name = "copy of rem's tale, chapter 8", count = 0, stacks = 0, stacksize = 12},
		{id = 4072, name = "copy of rem's tale, chapter 9", count = 0, stacks = 0, stacksize = 12},
		{id = 4073, name = "copy of rem's tale, chapter 10", count = 0, stacks = 0, stacksize = 12},
	}

	local mellidoptWingIDs = {
		{id = 9050, name = 'mellidopt wing', count = 0, stacks = 0, stacksize = 12},
	}

	local salvagePlanIDs = {
		{id = 3880, name = 'copy of bloodshed plans', count = 0, stacks = 0, stacksize = 99},
		{id = 3881, name = 'copy of umbrage plans', count = 0, stacks = 0, stacksize = 99},
		{id = 3882, name = 'copy of ritualistic plans' , count = 0, stacks = 0, stacksize = 99},
	}

	local alexandriteIDs = {
		{id = 2488, name = 'alexandrite', count = 0, stacks = 0, stacksize = 99},
	}

	local spGobbieKeyIDs = {
		{id = 8973, name = 'special gobbiedial key', count = 0, stacks = 0, stacksize = 99},
	}

	local zincOreIDs = {
		{id = 642, name = 'zinc ore', count = 0, stacks = 0, stacksize = 12},
	}

	local yagudoNecklaceIDs = {
		{id = 498, name = 'yagudo necklace', count = 0, stacks = 0, stacksize = 12},
	}

	local mandragoraMadIDs = {
		{id = 17344, name = 'cornette', count = 0, stacks = 0, stacksize = 1},
		{id = 4369, name = 'four-leaf mandragora bud', count = 0, stacks = 0, stacksize = 1},
		{id = 1150, name = 'snobby letter', count = 0, stacks = 0, stacksize = 1},
		{id = 1154, name = 'three-leaf mandragora bud', count = 0, stacks = 0, stacksize = 1},
		{id = 934, name = 'pinch of yuhtunga sulfur', count = 0, stacks = 0, stacksize = 1},
	}

	local onlyTheBestIDs = {
		{id = 4366, name = 'la theine cabbage', count = 0, stacks = 0, stacksize = 12},
		{id = 629, name = 'millioncorn', count = 0, stacks = 0, stacksize = 12},
		{id = 919, name = 'boyahda moss', count = 0, stacks = 0, stacksize = 12},
	}

	local soulPlateIDs = {
		{id = 2477, name = 'soul plate', count = 0, stacks = 0, stacksize = 1}, -- Can only trade 10 per Vana'diel day
	}

	local jseCapeIDs = {
		{id = 28617, name = "mauler's mantle", count = 0, stacks = 0, stacksize = 1},
		{id = 28618, name = "anchoret's mantle", count = 0, stacks = 0, stacksize = 1},
		{id = 28619, name = 'mending cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28620, name = 'bane cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28621, name = 'ghostfyre cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28622, name = 'canny cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28623, name = 'weard mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28624, name = 'niht mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28625, name = "pastoralist's mantle", count = 0, stacks = 0, stacksize = 1},
		{id = 28626, name = "rhapsode's cape", count = 0, stacks = 0, stacksize = 1},
		{id = 28627, name = 'lutian cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28628, name = 'takaha mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28629, name = 'yokaze mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28630, name = 'updraft mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28631, name = 'conveyance cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28632, name = 'cornflower cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28633, name = "gunslinger's cape", count = 0, stacks = 0, stacksize = 1},
		{id = 28634, name = 'dispersal mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28635, name = 'toetapper mantle', count = 0, stacks = 0, stacksize = 1},
		{id = 28636, name = "bookworm's cape", count = 0, stacks = 0, stacksize = 1},
		{id = 28637, name = 'lifestream cape', count = 0, stacks = 0, stacksize = 1},
		{id = 28638, name = "evasionist's cape", count = 0, stacks = 0, stacksize = 1},
	}

	local npcTable = {
		{name = 'Shami', idTable = sealIDs, tableType = 'Seals'},
		{name = 'Ephemeral Moogle', idTable = crystalIDs, tableType = 'Crystals'},
		{name = 'Waypoint', idTable = crystalIDs, tableType = 'Crystals'},
		{name = 'Joulet', idTable = moatCarpIDs, tableType = 'Moat Carp'},
		{name = 'Gallijaux', idTable = moatCarpIDs, tableType = 'Moat Carp'},
		{name = 'Isakoth', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Rolandienne', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Fhelm Jobeizat', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Eternal Flame', idTable = copperVoucherIDs, tableType = 'Copper Vouchers'},
		{name = 'Monisette', idTable = remsTaleIDs, tableType = "Rem's Tales"},
		{name = '???', idTable = mellidoptWingIDs, tableType = 'Mellidopt Wings'},
		{name = 'Mrohk Sahjuuli', idTable = salvagePlanIDs, tableType = 'Salvage Plans'},
		{name = 'Paparoon', idTable = alexandriteIDs, tableType = 'Alexandrite'},
		{name = 'Mystrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Habitox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Bountibox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Specilox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Arbitrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Funtrox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Priztrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Sweepstox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Wondrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Rewardox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Winrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys'},
		{name = 'Talib', idTable = zincOreIDs, tableType = 'Zinc Ore'},
		{name = 'Nanaa Mihgo', idTable = yagudoNecklaceIDs, tableType = 'Yagudo Necklaces'},
		{name = 'Yoran-Oran', idTable = mandragoraMadIDs, tableType = 'Mandragora Mad Items'},
		{name = 'Melyon', idTable = onlyTheBestIDs, tableType = 'Only the Best Items'},
		{name = 'Sanraku', idTable = soulPlateIDs, tableType = 'Soul Plates'},
		{name = 'A.M.A.N. Reclaimer', idTable = jseCapeIDs, tableType = 'JSE Capes'},
		{name = 'Makel-Pakel', idTable = jseCapeIDs, tableType = 'JSE Capes x3'},
	}
	
	local idTable = {}
	local tableType = ''
	local target = windower.ffxi.get_mob_by_target('t')
	
	if not target then
		windower.send_command('input /targetnpc')
		coroutine.sleep(0.4)
		target = windower.ffxi.get_mob_by_target('t')

		if not target then
			print('QuickTrade: No target selected')
			return
		end
	end

	for i = 1, #npcTable do
		if target.name == npcTable[i].name then
			idTable = npcTable[i].idTable
			tableType = npcTable[i].tableType
			break
		end
	end

	

	-- FOR TESTING WITHOUT NPC PRESENT!!!!!!!!!!!!!
	--idTable = table.copy(alexandriteIDs)
	--tableType = 'Alexandrite'
	--exampleOnly = true



	if #idTable == 0 or tableType == '' then
		print('QuickTrade: Invalid target')
		lastNPC = ''
		return
	end

	mogSackTable = table.copy(idTable)
	mogCaseTable = table.copy(idTable)

	-- Scan the mog sack for each item in idTable
	local mogSack = windower.ffxi.get_items('sack')
	if not mogSack then
		print('mogSack read error')
	else
		for i = 1, #mogSackTable do
			for k, v in ipairs(mogSack) do
				if v.id == mogSackTable[i].id then
					mogSackTable[i].count = mogSackTable[i].count + v.count -- Updates the total number of items of each type
					mogSackTable[i].stacks = mogSackTable[i].stacks + 1 -- Updates the total number of stacks of each type
				end
			end
		end
	end

	-- Scan the mog case for each item in idTable
	local mogCase = windower.ffxi.get_items('case')
	if not mogCase then
		print('mogCase read error')
	else
		for i = 1, #mogCaseTable do
			for k, v in ipairs(mogCase) do
				if v.id == mogCaseTable[i].id then
					mogCaseTable[i].count = mogCaseTable[i].count + v.count -- Updates the total number of items of each type
					mogCaseTable[i].stacks = mogCaseTable[i].stacks + 1 -- Updates the total number of stacks of each type
				end
			end
		end
	end

	-- Uses the Itemizer addon to move tradable items from the mog case/sack into the player's inventory
	if arg1 == 'all' and mogCase and mogSack then
		inventory = windower.ffxi.get_items('inventory')
		for i = 1, #idTable do
			for k, v in ipairs(inventory) do
				if v.id == idTable[i].id then
					idTable[i].count = idTable[i].count + v.count -- Updates the total number of items of each type
					idTable[i].stacks = idTable[i].stacks + 1 -- Updates the total number of stacks of each type
				end
			end
		end

		for i = 1, #mogSackTable do
			if mogSackTable[i].count + mogCaseTable[i].count > 0 then
				if exampleOnly then
					print('//get "'..mogSackTable[i].name.. '" '..idTable[i].count + mogSackTable[i].count + mogCaseTable[i].count)
				else
					windower.add_to_chat(8, 'QuickTrade: Please wait - Using Itemizer to transfer '..mogSackTable[i].count + mogCaseTable[i].count..' '..mogSackTable[i].name..' to inventory')
					windower.send_command('input //get "'..mogSackTable[i].name.. '" '..idTable[i].count + mogSackTable[i].count + mogCaseTable[i].count)
					coroutine.sleep(2.5)
				end
			end
		end

		for i = 1, #idTable do
			idTable[i].count = 0
			idTable[i].stacks = 0
		end
	else
		if target.name ~= lastNPC then
			lastNPC = target.name
			local mogCount = 0

			for i = 1, #mogSackTable do
				mogCount = mogCount + mogSackTable[i].count + mogCaseTable[i].count
			end
			
			if mogCount > 0 then
				windower.add_to_chat(8, 'QuickTrade: '..mogCount..' of these items are in your mog sack/case. Type "//qtr all" if you wish to move them into your inventory and trade them. Requires Itemizer')
			end
		end
	end

	-- Read the player inventory
	inventory = windower.ffxi.get_items('inventory')

	if not inventory then
		print('QuickTrade: Unable to read inventory')
		return
	end

	-- Scan the inventory for each item in idTable
	for i = 1, #idTable do
		for k, v in ipairs(inventory) do
			if v.id == idTable[i].id then
				idTable[i].count = idTable[i].count + v.count -- Updates the total number of items of each type
				idTable[i].stacks = idTable[i].stacks + 1 -- Updates the total number of stacks of each type
			end
		end
	end
	

	
	local numTrades = 0 -- Number of times //qtr needs to be run to empty the player inventory
	local availableTradeSlots = 8

	if tableType == 'Crystals' then
		for i = 1, 8 do
			if idTable[i].stacks > 0 or idTable[i + 8].stacks > 0 then
				numTrades = numTrades + math.ceil((idTable[i].stacks + idTable[i + 8].stacks) / 8)
			end
		end
	elseif tableType == 'Zinc Ore' or tableType == 'Yagudo Necklaces' then -- 4 at a time
		numTrades = math.floor(idTable[1].count / 4)
	elseif tableType == 'Mandragora Mad Items' or tableType == 'JSE Capes' then -- 1 at a time
		for i = 1, #idTable do
			numTrades = numTrades + idTable[i].count
		end
	elseif tableType == 'JSE Capes x3' then -- 3 of the same kind
		for i = 1, #idTable do
			if idTable[i].count >= 3 then
				numTrades = numTrades + math.min(1, math.floor(idTable[i].count / 3))
			end
		end
	elseif tableType == 'Only the Best Items' then -- Unique for this quest
		numTrades = numTrades + math.floor(idTable[1].count / 5)
		numTrades = numTrades + math.floor(idTable[2].count / 3)
		numTrades = numTrades + idTable[3].count
	elseif tableType == 'Special Gobbiedial Keys' or tableType == 'Soul Plates' then
		numTrades = idTable[1].count
	else
		for i = 1, #idTable do
			if idTable[i].stacks > 0 then
				numTrades = numTrades + math.ceil(idTable[i].stacks / 8)
			end
		end
	end

	if exampleOnly then
		print(numTrades..' total trades')
	end

	-- Prepare and send command through TradeNPC if there are trades to be made
	if numTrades > 0 then
		local tradeString = '//tradenpc '
		availableTradeSlots = 8
		
		if tableType == 'Crystals' then
			for i = 1, 8 do
				-- Build the string that will be used as the command
				tradeString = '//tradenpc '
				availableTradeSlots = 8
				
				if idTable[i].count > 0 then
					tradeString = tradeString..math.min(availableTradeSlots * idTable[i].stacksize, idTable[i].count)..' "'..idTable[i].name..'"'
					availableTradeSlots = math.max(0, availableTradeSlots - idTable[i].stacks)
				end
				
				if availableTradeSlots > 0 and idTable[i + 8].count > 0 then
					tradeString = tradeString..' '..math.min(availableTradeSlots * idTable[i + 8].stacksize, idTable[i + 8].count)..' "'..idTable[i + 8].name..'"'
				end

				if idTable[i].count > 0 or idTable[i + 8].count > 0 then
					break
				end
			end
		elseif tableType == 'Special Gobbiedial Keys' or tableType == 'Soul Plates' then -- 1 item at a time
			tradeString = '//tradenpc  1 "'..idTable[1].name..'"'
		elseif tableType == 'Zinc Ore' or tableType == 'Yagudo Necklaces' then -- 4 items at a time
			if idTable[1].count >= 4 then
				tradeString = '//tradenpc 4 "'..idTable[1].name..'"'
			end
		elseif tableType == 'Mandragora Mad Items' or tableType == 'JSE Capes' then
			for i = 1, #idTable do
				tradeString = '//tradenpc '

				if idTable[i].count > 0 then
					tradeString = tradeString..'1 "'..idTable[i].name..'"'
					break
				end
			end
		elseif tableType == 'JSE Capes x3' then
			for i = 1, #idTable do
				tradeString = '//tradenpc '

				if idTable[i].count >= 3 then
					tradeString = tradeString..'3 "'..idTable[i].name..'"'
					break
				end
			end
		elseif tableType == 'Only the Best Items' then
			for i = 1, #idTable do
				tradeString = '//tradenpc '

				if idTable[1].count >= 5 then
					tradeString = tradeString..'5 "'..idTable[1].name..'"'
					break
				end

				if idTable[2].count >= 3 then
					tradeString = tradeString..'3 "'..idTable[2].name..'"'
					break
				end

				if idTable[3].count > 0 then
					tradeString = tradeString..'1 "'..idTable[3].name..'"'
					break
				end
			end
		else
			for i = 1, #idTable do
				tradeString = '//tradenpc '
				availableTradeSlots = 8
				
				if idTable[i].count > 0 then
					availableTradeSlots = math.max(1, availableTradeSlots - idTable[i].stacks)
					tradeString = tradeString..math.min(availableTradeSlots * idTable[i].stacksize, idTable[i].count)..' "'..idTable[i].name..'"'
					break
				end
			end
		end

		if tradeString ~= '//tradenpc ' then
			if numTrades - 1 == 0 then
				windower.add_to_chat(8, 'QuickTrade: Trading Complete')
			elseif numTrades - 1 == 1 then
				windower.add_to_chat(8, 'QuickTrade: '..(numTrades - 1)..' trade remaining')
			else
				windower.add_to_chat(8, 'QuickTrade: '..(numTrades - 1)..' trades remaining')
			end
			
			if exampleOnly then
				print(tradeString)
			else
				if tableType ~= 'JSE Capes' and tableType ~= 'JSE Capes x3' then
					textSkipTimer = os.time()
				end
				
				windower.send_command('input '..tradeString)
			end
		end
	else
		if arg1 == 'all' then
			windower.add_to_chat(8, "QuickTrade - No "..tableType.." in inventory, mog case, or mog sack")
		else
			windower.add_to_chat(8, "QuickTrade - No "..tableType.." in inventory")
		end
	end
end)
 
windower.register_event('incoming text', function(original, modified, mode)
	-- Allow the addon to skip the conversation text for up to 10 seconds after the trade
	if os.time() - textSkipTimer > 10 then
		return
	end
	
	local target = windower.ffxi.get_mob_by_target('t')
	
	if not target then
		return false
	end
	
	if mode == 150 or mode == 151 then
		modified = modified:gsub(string.char(0x7F, 0x31), '')
	end
	
	return modified
>>>>>>> c9035841f1e3eb1461c46cdd123f383fc12b8df4
end)