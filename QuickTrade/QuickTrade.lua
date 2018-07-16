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

_addon.name = 'Quick Trader'
_addon.author = 'Valok@Asura'
_addon.version = '1.0.0'
_addon.command = 'qtr'

exampleOnly = false
textSkipTimer = 1

windower.register_event('addon command', function(...)
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
		{id = 2488, name = 'Alexandrite', count = 0, stacks = 0, stacksize = 99},
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
	}
	
	local idTable = {}
	local tableType = ''
	local stackSize = 12
	local target = windower.ffxi.get_mob_by_target('t')
	
	if not target then
		print('QuickTrader: No target selected')
		return
	end

	for i = 1, #npcTable do
		if target.name == npcTable[i].name then
			idTable = npcTable[i].idTable
			tableType = npcTable[i].tableType
			break
		end
	end

	if #idTable == 0 or tableType == '' then
		print('QuickTrader: Invalid target')
		return
	end

	-- FOR TESTING WITHOUT NPC PRESENT!!!!!!!!!!!!!
	--idTable = alexandriteIDs
	--tableType = 'Alexandrite'
	-- FOR TESTING WITHOUT NPC PRESENT!!!!!!!!!!!!!
	
	-- Read the player inventory
	local inventory = windower.ffxi.get_items(0)
	
	if not inventory then
		print('QuickTrader: Unable to read inventory')
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
	elseif tableType == 'Seals' or tableType == 'Moat Carp' or tableType == 'Copper Vouchers' or tableType == "Rem's Tale"
			or tableType == 'Mellidopt Wings' or tableType == 'Salvage Plans' then
		for i = 1, #idTable do
			if idTable[i].stacks > 0 then
				numTrades = numTrades + math.ceil(idTable[i].stacks / 8)
			end
		end
	end

	-- Prepare and send command through TradeNPC if there are trades to be made
	if numTrades > 0 then
		local tradeString = ''
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
				windower.add_to_chat(8, 'QuickTrader: Trading Complete')
			elseif numTrades - 1 == 1 then
				windower.add_to_chat(8, 'QuickTrader: '..(numTrades - 1)..' trade remaining')
			else
				windower.add_to_chat(8, 'QuickTrader: '..(numTrades - 1)..' trades remaining')
			end
			
			if exampleOnly then
				print(tradeString)
			else
				windower.send_command('input '..tradeString)
				textSkipTimer = os.time()
			end
		end
	else
		windower.add_to_chat(8, "QuickTrader - No "..tableType.." in inventory")
	end
end)
 
windower.register_event('incoming text', function(original, modified, mode)
	-- Allow the addon to skip the conversation text for up to 10 seconds after the trade
	if os.time() - textSkipTimer > 10 then
		return
	end
	
	local target = windower.ffxi.get_mob_by_target('t')
	
	if not target then return
		false
	end
	
	if mode == 150 or mode == 151 then
		modified = modified:gsub(string.char(0x7F, 0x31), '')
	end
	
	return modified
end)