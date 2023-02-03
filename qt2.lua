_addon.name = 'QuickTrade 2'
_addon.author = 'Valok@Asura'
_addon.version = '1.0.0'
_addon.command = 'qt2'

require('tables')
require('coroutine')
packets = require('packets')
res = require('resources')

exampleOnly = false
debug = true
fakeNPC = ''

textSkipTimer = 5
chatColor = 50 -- 8 pink, 21 gray, 28 light red, 50 yellow, 63 light yellow

maxTradeDistance = 5.5

frameTime = 0
player = {}
playerCurrentPosition = {}
playerLastPosition = {}
tradeGroup = {}
npcToTradeTable = {}
itemTable = {}
itemType = ''
itemVerificationComplete = false
currentTradeTargetName = ''
lastTradeTargetName = 'last'
spamEnabled = false
spamReady = false
spamLastItemUsed = ''
lastTradeTargetName = ''
ownedKeyItems = {}
ownedGeasFeteKeyItems = {}
tribulensOrRadialensFound = false

tripleQuestionmarkNotificationTime = 0
tripleQuestionmarkAlert = false

status_TradeExpected = false
status_TradeInProgress = false

function reset()
	status_TradeExpected = false
	status_TradeInProgress = false

	loops = {}
	loops.allowed = false
	loops.requested = false
	loops.current = 0
	loops.numberRequestedByUser = 0
	loops.calculated = 0
	loops.calculationComplete = false
	loops.uniqueTrades = 0
	--loops.initiated = false

	itemType = ''

	pullEnabled = false
	
	spamEnabled = false
	spamLastItemUsed = ''
end

windower.register_event('load', function()
	if windower.ffxi.get_info().logged_in then
		if not itemVerificationComplete then
			verifyAndCreateItemData()
			reset()
		end
	end
end)

windower.register_event('login', function()
	if not itemVerificationComplete then
		verifyAndCreateItemData()
		reset()
	end
end)

windower.register_event('addon command', function(...)
	reset()

	if arg[1] and arg[1]:lower() == 'loop' then
		loops.requested = true

		if arg[2] and tonumber(arg[2]) then
			loops.numberRequestedByUser = tonumber(arg[2])
		elseif arg[2] and arg[2]:lower() ~= 'pull' then
			print(_addon.name .. ": Invalid loop number entered: " .. arg[2])
			print(_addon.name .. ": Valid examples: 'qt2 loop 5' 'qt2 loop 3 pull'")
			return
		end

		if (arg[2] and arg[2]:lower() == 'pull') or (arg[3] and arg[3]:lower() == 'pull') then
			if debug then print("Pulling Enabled") end
			pullEnabled = true
		end
	elseif arg[1] and arg[1]:lower() == 'pull' then
		if debug then print("Pulling Enabled") end
		pullEnabled = true
	elseif arg[1] and arg[1]:lower() == 'xyz' then
		local zone = res.zones[windower.ffxi.get_info().zone].name
		local target = windower.ffxi.get_mob_by_target('t')

		if target and zone then
			print(string.format(_addon.name .. ': Detected coordinates for ' .. target.name .. ': Zone: "%s", X: %s, Y: %s, Z: %s', zone, string.format("%.2f", target.x), string.format("%.2f", target.y), string.format("%.2f", target.z)))
			windower.copy_to_clipboard('{name = "' .. target.name .. '", zone = "' .. zone .. '", x = ' .. string.format("%.2f", target.x) .. ", y = " .. string.format("%.2f", target.y) .. ", z = " .. string.format("%.2f", target.z) .. "},")
		else
			print(_addon.name .. ': Error obtaining target or zone information.')
		end

		return
	elseif arg[1] and arg[1]:lower() == 'ex' then
		exampleOnly = not exampleOnly

		if exampleOnly then
			print(_addon.name .. ": Example mode enabled. " .. _addon.name .. ' will not trade items. It will only show the command to be used in the console.')
		else
			print(_addon.name .. ": Example mode disabled. " .. _addon.name .. " will now trade items.")
		end

		return
	elseif arg[1] and arg[1]:lower() == 'spam' then
		if arg[2] and arg[2] ~= '' then
			table.remove(arg, 1)
			spamEnabled = true
			reset()
			spamItemUse(L(arg):concat(" "))
		else
			spamEnabled = false
			print(_addon.name .. ": Spam disabled.")
		end

		return
	elseif arg[1] and arg[1]:lower() == 'fake' and arg[2] and arg[2]:lower() ~= '' then
		fakeNPC = arg[2]

		if fakeNPC ~= '' then
			print(_addon.name .. ": Now assuming the player is targetting and trading with the NPC " .. fakeNPC .. ". For testing purposes only, trading disabled.")
			exampleOnly = true
		else
			print(_addon.name .. ": No fake NPC currently in use. Trading enabled.")
			exampleOnly = false
		end

		return
	end

	if not status_TradeInProgress then
		doTheThing()
	else
		print(_addon.name .. ": Trade in progress. Please wait until it is complete and try again")
	end
end)

function doTheThing()
	if not itemVerificationComplete then
		verifyAndCreateItemData()
	end

	if not itemVerificationComplete then
		print(_addon.name .. ': Addon disabled due to error in data. Fix data and reload')
		return
	else
		verifyNPCAndGetTrades()

		if itemType ~= '' then
			calculateAndTrade()
		else
			if currentTradeTargetName == '' then
				print(_addon.name .. ': No target selected')
			end
		end
	end
end

function spamItemUse(itemName)
	local _inventory = windower.ffxi.get_items('inventory')
	if not _inventory then
		print(_addon.name .. ": Could not load inventory")
		return
	end
	local itemFound = false
	local itemID = 0

	for i = 1, #_inventory do
		if _inventory[i].id > 0 and res.items[_inventory[i].id].en:lower() == itemName:lower() then
			itemID = _inventory[i].id
			itemFound = true
			break
		end
	end

	if playerMoved() then
        return
    end

	if itemFound then
		if exampleOnly then
			print(_addon.name .. ': Command: input /item "' .. itemName .. '" <me>')
			spamEnabled = false
		else
			windower.send_command('input /item "' .. itemName .. '" <me>')
			spamLastItemUsed = itemName
			spamEnabled = true
		end
	else
		windower.add_to_chat(chatColor, _addon.name .. ': No "' .. itemName .. '" remaining in inventory')
		spamEnabled = false
	end
end

function playerMoved()
	playerCurrentPosition = {[1] = windower.ffxi.get_mob_by_target('me').x, [2] = windower.ffxi.get_mob_by_target('me').y}
	
	if #playerLastPosition ~= 0 and (playerLastPosition[1] ~= playerCurrentPosition[1] or playerLastPosition[2] ~= playerCurrentPosition[2]) then   
        if debug then print(_addon.name .. ': Movement detected. Cancelling.') end
		playerCurrentPosition = {}
		playerLastPosition = {}
		reset()
        return true
    else
        playerLastPosition = playerCurrentPosition
		return false
    end
end

function verifyAndCreateItemData() -- Determine the ID, Max Stacksize, and trading name of each item
	local startTime = os.clock()
	print(_addon.name .. ': Verifying provided item lists against Windower data...')

	local userSpecifiedItems = 0
	local matchedItems = 0
	local matchFound = false
	local unmatchedItems = {}
	local partialMatches = 0

	local resourceItemsCheckedForItem = 0
	local resourceItemsCheckedTotal = 0

	local foundItemsTable = {} -- Used to prevent scanning res.items for duplicates. Will this save loading time?
	local duplicateFound = false -- Used to prevent scanning res.items for duplicates. Will this save loading time?

	for k, unused in pairs(tradeGroup) do -- Iterate through each "standalone" table in tradeGroup. For example, tradeGroup.Seals is "standalone," but tradeGroups.Seals.NPC is not
		for i = 1, #tradeGroup[k] do -- Iterate through each item in the "standalone" table
			userSpecifiedItems = userSpecifiedItems + 1
			--print('Checking:', dump(tradeGroup[k][i].item))

			duplicateFound = false -- Used to prevent scanning res.items for duplicates. Will this save loading time? This block feels stupid, but it did save .2 seconds on a 235-item scan. Roughly .11s per 100,000 scans
			for o = 1, #foundItemsTable do
				if tradeGroup[k][i].item == foundItemsTable[o].item and not tradeGroup[k][i].partialMatch then
					duplicateFound = true
					matchedItems = matchedItems + 1
					tradeGroup[k][i].id = foundItemsTable[o].id
					tradeGroup[k][i].maxStackSize = foundItemsTable.stack
					tradeGroup[k][i].fullName = foundItemsTable.enl
					break
				end
			end

			if not duplicateFound then
				for key in pairs(res.items) do
					matchFound = false

					if res.items[key] then
						resourceItemsCheckedForItem = resourceItemsCheckedForItem + 1
						if	tradeGroup[k][i].item and (res.items[key].en:lower() == tradeGroup[k][i].item:lower() or res.items[key].enl:lower() == tradeGroup[k][i].item:lower()) then-- Check that the item matches one of the two names in items.lua
							--if debug then print('Match Found', tradeGroup[k][i].item) end
							
							matchedItems = matchedItems + 1
							tradeGroup[k][i].id = res.items[key].id
							tradeGroup[k][i].maxStackSize = res.items[key].stack
							tradeGroup[k][i].fullName = res.items[key].enl
							
							matchFound = true
							break
						elseif tradeGroup[k][i].partialMatch and not tradeGroup[k][i].matched then
							print(_addon.name .. ': Partial Match Found:', tradeGroup[k][i].item)
							tradeGroup[k][i].id = 0
							tradeGroup[k][i].maxStackSize = 0
							tradeGroup[k][i].fullName = ''
							tradeGroup[k][i].matched = false
							matchFound = true
							partialMatches = partialMatches + 1
							break
						end
					end
				end
			end

			if not tradeGroup[k][i].item or not matchFound then
				table.insert(unmatchedItems, dump(tradeGroup[k][i]))
			else
				tradeGroup[k][i].count = 0
				tradeGroup[k][i].groupReady = false
				table.insert(foundItemsTable, #foundItemsTable + 1, {['item'] = tradeGroup[k][i].item, ['id'] = tradeGroup[k][i].id, ['maxStackSize'] = tradeGroup[k][i].maxStackSize, ['fullName'] = tradeGroup[k][i].fullName})
			end

			resourceItemsCheckedTotal = resourceItemsCheckedTotal + resourceItemsCheckedForItem
			--if debug then print(resourceItemsCheckedForItem, resourceItemsCheckedTotal, tradeGroup[k][i].item) end
			resourceItemsCheckedForItem = 0
		end
	end

	if #unmatchedItems > 0 then
		local unmatchedItemsString = ''

		for i = 1, #unmatchedItems - 1 do
			unmatchedItemsString = unmatchedItemsString .. unmatchedItems[i] .. ', '
		end

		unmatchedItemsString = unmatchedItemsString .. unmatchedItems[#unmatchedItems]
		print(_addon.name .. ': ' .. matchedItems .. ' / ' .. userSpecifiedItems .. ' items matched.')
		print(_addon.name .. ': ' .. _addon.name .. ' disabled. No matches for the following items. Edit or remove these entries and reload the addon. : ' .. unmatchedItemsString)
		itemVerificationComplete = false
	else
		print(_addon.name .. ': ' .. matchedItems .. ' / ' .. userSpecifiedItems .. ' matches, ' .. partialMatches .. ' partial ' .. (partialMatches == 1 and 'match' or 'matches') .. ' also accepted. Quicktrade is ready.')
		itemVerificationComplete = true
		if debug then print("resourceItemsChecked Total", resourceItemsCheckedTotal) end
		if debug then print("Time to verify items:", math.round(os.clock() - startTime, 3) .. 's') end
	end
end

function verifyNPCAndGetTrades() -- Check the currently target, or target the nearest NPC, verify they have trades configures, define the itemType, and build the itemTable
	local target = windower.ffxi.get_mob_by_target('t')
	currentTradeTargetName = ''

	if fakeNPC == '' and (not target or not target.is_npc or target.spawn_type ~= 2) then
		if res.zones[windower.ffxi.get_info().zone].name:startswith("Abyssea") and itemType:startswith("Abyssea") then
			targetQuestionMark()
		else
			windower.send_command('input /targetnpc')
		end
		coroutine.sleep(0.5)
		target = windower.ffxi.get_mob_by_target('t')

		if not target then
			windower.add_to_chat(chatColor, _addon.name .. ': No Target Detected')
			return
		end
	elseif fakeNPC ~= '' then
		target = {}
		target.name = fakeNPC
	end

	currentTradeTargetName = target.name

	-- Determine which item table to use to scan inventory
	player = windower.ffxi.get_mob_by_target('me')
	local zone = res.zones[windower.ffxi.get_info().zone].name
	local distanceToCoordinates = 100

	for tradeType, tradeNPCs in pairs(tradeGroup) do
		for i = 1, #tradeGroup[tradeType].NPC do
			if target.name == tradeGroup[tradeType].NPC[i].name then
				if debug then print('Target is either a match, or fakeNPC is set') end

				if tradeGroup[tradeType].NPC[i].zone then
					if debug then print('Zone Specified:', tradeGroup[tradeType].NPC[i].zone, 'Player Zone:', zone) end

					if tradeGroup[tradeType].NPC[i].x and tradeGroup[tradeType].NPC[i].y and tradeGroup[tradeType].NPC[i].z and tradeGroup[tradeType].NPC[i].zone == zone then
						if debug then print("Checking precise NPC coordinates") end
						if fakeNPC ~= '' then
							distanceToCoordinates = 1
						else
							distanceToCoordinates = ((tradeGroup[tradeType].NPC[i].x - player.x)^2 + (tradeGroup[tradeType].NPC[i].y - player.y)^2 + (tradeGroup[tradeType].NPC[i].z - player.z)^2):sqrt()
						end

						if debug then print('distance', math.round(distanceToCoordinates, 2)) end

						if distanceToCoordinates <= 30 then -- maxTradeDistance then -- Possibly need to accept a reasonable distance and set the itemTable and itemType, then later see if it's within trading distance
							--itemTable = table.copy(tradeGroup[tradeType])
							itemType = tradeType
						end
					elseif tradeGroup[tradeType].NPC[i].zone == zone then
						if debug then print("Checking NPC zone") end
						--itemTable = table.copy(tradeGroup[tradeType])
						itemType = tradeType
					end
				else
					--itemTable = table.copy(tradeGroup[tradeType])
					itemType = tradeType
				end
			end

			if itemType ~= '' then break end
		end

		if itemType ~= '' then break end
	end

	if itemType:startswith('GeasFete') then
		getGeasFeteKeyItems()
	end

	if debug then print('verifyNPCAndGetTrades() results:', target.name, 'Trade: ' .. itemType) end

	if itemType == '' then
		windower.add_to_chat(chatColor, _addon.name .. ": " .. target.name .. " is not configured for trade.")
	else
		if fakeNPC == '' and target.distance:sqrt() > maxTradeDistance then -- 5.5 Yalms, according to DistancePlus
			if debug then print(_addon.name .. ': ' .. target.name .. ' is too far away') end
			windower.add_to_chat(chatColor, _addon.name .. ': ' .. target.name .. ' is too far away')
			reset()
			return
		end
	
		if loops.allowed or loops.requested then
			calculateAndTrade()
		end
	end
end

function calculateAndTrade() -- Scan inventory, calculate possible trades, and build the TradeNPC command
	local bags = {'satchel','sack','case','wardrobe','wardrobe2','wardrobe3','wardrobe4','safe','safe2','storage','locker','inventory'}
	local bagItems = {}

	local tempTableInventory = table.copy(tradeGroup[itemType])
	local tempTableMoogleOnly = table.copy(tradeGroup[itemType])
	local tempTableAnywhere = table.copy(tradeGroup[itemType])
	
	local availableItems = 0
	local inaccessibleItems = 0
	local inventoryItems = 0
	local inventorySlotsOpen = windower.ffxi.get_bag_info(0).max - windower.ffxi.get_bag_info(0).count

	-- Variables to check for tags in the item lists.  max, exact, etc.
	local groups = {}
	local groupPreviouslyFound = false
	local keyItemNeeded = true

	for b = 1, #bags do
		bagItems = windower.ffxi.get_items(bags[b])

		if bagItems then
			for itemNumber = 1, #tradeGroup[itemType] do
				if tempTableInventory[itemNumber].group and #groups == 0 then -- Checks tag: group    Only runs if the groups table hasn't been built
					if debug then print('Adding First Group', tempTableInventory[itemNumber].group) end
					table.insert(groups, {['name'] = tempTableInventory[itemNumber].group, ['complete'] = false}) -- Add the first group. Allows the loops below to function

					for x = 1, #tempTableInventory do -- When the first item is found that has a group specified, scan items to determine other groups and place them in the table
						if tempTableInventory[x].group then
							groupPreviouslyFound = false

							for groupNum = 1, #groups do
								if groups[groupNum].name == tempTableInventory[x].group then
									groupPreviouslyFound = true
									break
								end
							end
							
							if not groupPreviouslyFound then
								if debug then print('Adding Group', tempTableInventory[x].group) end
								table.insert(groups, #groups + 1, {['name'] = tempTableInventory[x].group, ['complete'] = false}) -- Complete is check later, and is set to 'true' if all item requirements are met.
							end
						end
					end

					if debug then print("Groups:", #groups) end
				end

				for bagItem = 1, #bagItems do
					if bags[b] == 'inventory' and tempTableInventory[itemNumber].partialMatch and not tradeGroup[itemType][itemNumber].matched and tradeGroup[itemType][itemNumber].id == 0 and bagItems[bagItem].id > 0 and string.find(res.items[bagItems[bagItem].id].enl:lower(), tempTableInventory[itemNumber].item:lower()) then
						print(_addon.name .. ': ' .. tempTableInventory[itemNumber].item, 'is possibly:', res.items[bagItems[bagItem].id].enl:lower())
						
						tradeGroup[itemType][itemNumber].matched = true
						tradeGroup[itemType][itemNumber].itemByUser = tostring(tradeGroup[itemType][itemNumber].item) -- Creates a new field that will be used to reset the item name to what the user provided
						tradeGroup[itemType][itemNumber].item = res.items[bagItems[bagItem].id].en

						tradeGroup[itemType][itemNumber].id = bagItems[bagItem].id
						tradeGroup[itemType][itemNumber].maxStackSize = res.items[bagItems[bagItem].id].stack
						tradeGroup[itemType][itemNumber].fullName = res.items[bagItems[bagItem].id].enl
						tradeGroup[itemType][itemNumber].count = 0
						tradeGroup[itemType][itemNumber].groupReady = false

						verifyNPCAndGetTrades()
						--calculateAndTrade()
						--doTheThing()
						return
					end

					if bagItems[bagItem].id > 0 and bagItems[bagItem].id == tradeGroup[itemType][itemNumber].id then
						if bags[b] == 'inventory' then
							--if debug and not loops.calculationComplete then print("ID Match:", tempTableInventory[itemNumber].item) end
							
							if tempTableInventory[itemNumber].keyItem ~= nil then -- Skip the item if the key item is specified and the player already has it
								keyItemNeeded = true

								for i = 1, #ownedGeasFeteKeyItems do
									if tempTableInventory[itemNumber].keyItem == ownedGeasFeteKeyItems[i].name then
										keyItemNeeded = false
										break
									end
								end

								if not keyItemNeeded then
									if debug then print('Key item ' .. tempTableInventory[itemNumber].keyItem .. ' already in possession. Skipping item') end
									break
								end
							end

							if tempTableInventory[itemNumber].zone and res.zones[windower.ffxi.get_info().zone].name ~= tempTableInventory[itemNumber].zone then
								if debug then print('Excluding :' .. tempTableInventory[itemNumber].item .. '. It is intended for zone: ' .. tempTableInventory[itemNumber].zone) end
								break
							end

							tempTableInventory[itemNumber].count = tempTableInventory[itemNumber].count + bagItems[bagItem].count
							inventoryItems = inventoryItems + bagItems[bagItem].count
							if debug then print(tempTableInventory[itemNumber].item .. " in Inventory:", bagItems[bagItem].count, "Total Inventory Count:", inventoryItems) end
						elseif T({'safe', 'safe2', 'storage', 'locker'}):contains(bags[b]) then
							tempTableMoogleOnly[itemNumber].count = tempTableMoogleOnly[itemNumber].count + bagItems[bagItem].count
							inaccessibleItems = inaccessibleItems + bagItems[bagItem].count
							if debug then print(tempTableMoogleOnly[itemNumber].item .. " in Mog House:", bagItems[bagItem].count, "Total Mog House Count:", inaccessibleItems) end
						else
							tempTableAnywhere[itemNumber].count = tempTableAnywhere[itemNumber].count + bagItems[bagItem].count
							availableItems = availableItems + bagItems[bagItem].count
							if debug then print(tempTableAnywhere[itemNumber].item .. " in Available Storage:", bagItems[bagItem].count, "Total Available Count:", availableItems) end
						end
					end
				end
			end
		else
			print(_addon.name .. ': Unable to Scan: ' .. bags[b])
		end
	end

	local currentItemsAccountedFor = 0
	local currentItemOriginalTotal = 0
	local tradeSlotsAvailable = 8
	local inventoryStacks = 0
	local tradeCommand = 'tradenpc'
	local commandComplete = false
	local groupReady = true
	local keyItemOwned = false
	local totalItemsInTrade = 0
	local pullCount = 0
	local pullCountTotal = 0
	local itemsPulled = false

	for i = 1, #groups do -- Go through any groups and see if one is complete. Will trade only the items specified in the first complete group
		if debug then print('Scanning Group:', groups[i].name) end
		groupReady = true
		keyItemOwned = false

		for o = 1, #tempTableInventory do
			if tempTableInventory[o].group and tempTableInventory[o].group == groups[i].name then
				if debug then print('Checking Group :', tempTableInventory[o].group) end
				
				if not tempTableInventory[o].tradeReady then
					if debug then print('Trade Not Ready:', tempTableInventory[o].item) end
					groupReady = false
					break
				end
			end
		end

		if groupReady then
			for o = 1, #ownedGeasFeteKeyItems do
				if ownedGeasFeteKeyItems[o].name == groups[i].keyItem then
					if debug then print('Key Item: ' .. groups[i].keyItem .. ' already in possession. Ignoring trade.') end
					keyItemOwned = true
				end
			end

			if not keyItemOwned then
				if debug then print('Group: ' .. groups[i].name .. ' is ready to trade') end
				
				for o = 1, #tempTableInventory do
					if tempTableInventory[o].group == groups[i].name then
						tradeCommand = tradeCommand .. ' ' .. tempTableInventory[o].exact .. ' "' .. tempTableInventory[o].item .. '"'
						tradeSlotsAvailable = tradeSlotsAvailable - 1
					end
				end

				commandComplete = true
				break
			end
		else
			-- Here I probably have to zero-out each group's item count. Otherwise they might try to get traded later
			-- I don't think so, since the groups table is local to this function and gets wiped each time
		end
	end

	
	if not commandComplete then
		local maxLoops = 100 -- Just in case something is horribly broken, the addon won't loop indefinitely
		local curLoop = 0 -- Just in case something is horribly broken, the addon won't loop indefinitely
		if (debug or exampleOnly) and (not loops.requested or (loops.requested and loops.calculated == 0)) then
			print('i', 'Inv', 'Any', 'Moogle', 'Name')
			print('--------------------------------------------------')
		end

		while (loops.requested or (not loops.requested and curLoop == 0)) and curLoop ~= maxLoops do
			if loops.requested then
				tradeSlotsAvailable = 8
				commandComplete = false
				uniqueTradeAccountedFor = false
				tradeCommand = 'tradenpc'
			end

			for i = 1, #tempTableInventory do
				if debug then print(i, tempTableInventory[i].count, tempTableAnywhere[i].count, tempTableMoogleOnly[i].count, tempTableInventory[i].item) end
				curLoop = curLoop + 1 -- Just in case something is horribly broken, the addon won't loop indefinitely


				if pullEnabled and tempTableAnywhere[i].count > 0 and (loops.requested and not loops.allowed) then
					if debug then
						print("Merging Inventory and Anywhere tables to calculate loop count:", tempTableAnywhere[i].item, tempTableInventory[i].count, "+", tempTableAnywhere[i].count)
					end
					tempTableInventory[i].count = tempTableInventory[i].count + tempTableAnywhere[i].count
					tempTableAnywhere[i].count = 0
				end

				print(pullEnabled)
				print(tempTableAnywhere[i].count > 0)
				print(((loops.requested and not loops.allowed) or (not loops.requested and not loops.allowed)))

				if pullEnabled and tempTableAnywhere[i].count > 0 and ((loops.requested and not loops.allowed) or (not loops.requested and not loops.allowed)) then
					print("Items need pulling")
					if not exampleOnly and (inventorySlotsOpen > 0 or exampleOnly) then
						pullCount = 0

						while inventorySlotsOpen > 0 and tempTableAnywhere[i].count > 0 do
							pullCount = pullCount + math.min(tempTableAnywhere[i].count, tempTableAnywhere[i].maxStackSize)
							tempTableAnywhere[i].count = tempTableAnywhere[i].count - math.min(tempTableAnywhere[i].count, tempTableAnywhere[i].maxStackSize)
							inventorySlotsOpen = inventorySlotsOpen - 1 --math.ceil(tempTableAnywhere[i].count / tempTableAnywhere[i].maxStackSize)
							--coroutine.sleep(0.1)
						end

						if debug then print('Pulling: ' .. 'get ' .. tempTableAnywhere[i].item .. ' ' .. pullCount .. ' + ' .. tempTableInventory[i].count) end
						if debug then print("Expected Inventory Slots Open:", inventorySlotsOpen) end

						if not exampleOnly then
							windower.send_command('get ' .. tempTableAnywhere[i].item .. ' ' .. (pullCount + tempTableInventory[i].count))
							itemsPulled = true
							tempTableInventory[i].count = tempTableInventory[i].count + pullCount
							availableItems = availableItems - pullCount
							pullCountTotal = pullCountTotal + pullCount
							coroutine.sleep(0.1)
						end
					end
				end

				--print(tradeSlotsAvailable)
				--print(tempTableInventory[i].count)
				
				if tradeSlotsAvailable > 0 and tempTableInventory[i].count > 0 then
					if tempTableInventory[i].exact and tempTableInventory[i].count < tempTableInventory[i].exact then -- Go to next item if there aren't enough to meet the 'exact' requirement
						if debug then print("Not enough for exact trade", tempTableInventory[i].item, tempTableInventory[i].count) end
						break
					end

					currentItemsAccountedFor = 0
					currentItemOriginalTotal = tempTableInventory[i].count

					while tradeSlotsAvailable > 0 and currentItemsAccountedFor < tempTableInventory[i].count do
						if debug then print('maxStackSize', tempTableInventory[i].maxStackSize) end
						currentItemsAccountedFor = currentItemsAccountedFor + math.min(currentItemOriginalTotal, tempTableInventory[i].maxStackSize)
						currentItemOriginalTotal = tempTableInventory[i].count - currentItemsAccountedFor
						tradeSlotsAvailable = tradeSlotsAvailable - 1

						if tempTableInventory[i].max and currentItemsAccountedFor > tempTableInventory[i].max then
							--if debug then print('Maximum specified. Reducing ' .. tempTableInventory[i].count .. ' to ' .. tempTableInventory[i].max) end
							currentItemsAccountedFor = tempTableInventory[i].max
							tempTableInventory[i].tradeReady = true
							break
						elseif tempTableInventory[i].exact and currentItemsAccountedFor > tempTableInventory[i].exact then
							--if debug then print('Exact specified. Reducing ' .. tempTableInventory[i].count .. ' to ' .. tempTableInventory[i].exact) end
							currentItemsAccountedFor = tempTableInventory[i].exact
							tempTableInventory[i].tradeReady = true
							break
						end

						if curLoop == maxLoops then -- Just in case something is horribly broken, the addon won't loop indefinitely
							break
						end
					end

					if curLoop == maxLoops then
						print(maxLoops .. " loops reached. Check for major malfunction")
						break
					end

					if currentItemsAccountedFor > 0 then
						if debug then
							--print(math.ceil(currentItemsAccountedFor / tempTableInventory[i].maxStackSize), currentItemsAccountedFor, tempTableInventory[i].item)
						end

						if loops.requested then
							if debug then print('Reducing Inventory ', tempTableInventory[i].count, 'to', math.max(0, tempTableInventory[i].count - currentItemsAccountedFor)) end
							tempTableInventory[i].count = math.max(0, tempTableInventory[i].count - currentItemsAccountedFor)

							if tempTableInventory[i].unique then
								if tradeCommand ~= 'tradenpc' then loops.calculated = loops.calculated + 1 end
								tradeCommand = tradeCommand .. ' ' .. currentItemsAccountedFor .. ' "' .. tempTableInventory[i].item .. '"'
								loops.uniqueTrades = loops.uniqueTrades + 1
								uniqueTradeAccountedFor = true
								if debug then print('Unique trades:', loops.uniqueTrades) end
								break
							else
								tradeCommand = tradeCommand .. ' ' .. currentItemsAccountedFor .. ' "' .. tempTableInventory[i].item .. '"'
							end
						else
							if not commandComplete then
								if tradeCommand ~= 'tradenpc' and tempTableInventory[i].unique then
									if debug then print('Skipping unique item when a command already contains non-unique items') end
									break
								else
									tradeCommand = tradeCommand .. ' ' .. currentItemsAccountedFor .. ' "' .. tempTableInventory[i].item .. '"'
									totalItemsInTrade = totalItemsInTrade + currentItemsAccountedFor

									if tempTableInventory[i].unique then -- Skip everything else if this trade is unique
										commandComplete = true
									end
								end
							end
						end
					end
				end
			end

			commandComplete = true
			
			if tradeSlotsAvailable == 8 then
				loops.calculationComplete = true
				loops.calculated = loops.calculated + loops.uniqueTrades

				if loops.numberRequestedByUser > 0 then
					loops.calculated = math.min(loops.numberRequestedByUser, loops.calculated)
				end

				if debug and loops.requested then print("final loops.calculated", loops.calculated) end
				break
			elseif loops.requested then
				if not uniqueTradeAccountedFor then loops.calculated = loops.calculated + 1 end

				if debug then print("loops.calculated", loops.calculated) end
				if debug then print('Expected Command:', tradeCommand) end
			end

			coroutine.sleep(0.2)
		end
	end

	if pullEnabled and not itemsPulled and availableItems == 0 and not loops.allowed then
		windower.add_to_chat(chatColor, _addon.name .. ': No items to pull from satchel/sack/case')
	end

	if inventoryItems == 0 and (not loops.requested or (loops.allowed and loops.calculated == 0)) and (not pullEnabled or (pullEnabled and not itemsPulled)) then
		windower.add_to_chat(chatColor, _addon.name .. ': No trades found in inventory for ' .. currentTradeTargetName)
	end

	if lastTradeTargetName ~= currentTradeTargetName and (not loops.requested or loops.allowed) then
		if availableItems > 0 then
			windower.add_to_chat(chatColor, _addon.name .. ': ' .. availableItems .. ((availableItems == 1) and ' item' or ' items') .. ' in your satchel/sack/case can be traded to ' .. currentTradeTargetName ..'. Use "qt2 pull" to pull and trade them')
		end

		if inaccessibleItems > 0 then
			windower.add_to_chat(chatColor, _addon.name .. ': Items in Mog House: ' .. inaccessibleItems)
			--windower.add_to_chat(chatColor, _addon.name .. ': ' .. inaccessibleItems .. ((availableItems == 1) and ' item' or ' items') .. ' in storage.')
		end
	end

	lastTradeTargetName = currentTradeTargetName

	for i = 1, #tradeGroup[itemType] do
		if tradeGroup[itemType][i].matched then
			if debug then print("Resetting " .. tradeGroup[itemType][i].item .. " to user info: " .. tradeGroup[itemType][i].itemByUser) end
			tradeGroup[itemType][i] = {["item"] = tradeGroup[itemType][i].itemByUser, ["partialMatch"] = true, ["matched"] = false}
		end
	end

	if itemsPulled then
		if debug then print('Waiting 1.5 seconds for pulled items') end
		windower.add_to_chat(chatColor, _addon.name .. ': Pulling ' .. pullCountTotal .. ((pullCountTotal == 1) and ' item' or ' items') .. ' from storage')
		coroutine.sleep(1.5)
	end
	--if debug then print(tostring(tradeCommand ~= "tradenpc"), 'and',  '(' .. tostring(not loops.requested), ' or ', tostring(loops.allowed) .. ')') end

	if tradeCommand ~= "tradenpc" and (not loops.requested or loops.allowed) then
		--if debug or exampleOnly then print(_addon.name .. ": " .. inventoryItems .. ((inventoryItems == 1) and " item" or " items") .. " in " .. inventoryStacks .. ((inventoryStacks == 1) and " stack" or " stacks") .. " found in inventory") end
		if debug or exampleOnly then print(tradeCommand) end

		if not exampleOnly and fakeNPC == "" then
			textSkipTimer = os.time()

			if loops.allowed then
				windower.add_to_chat(chatColor, _addon.name .. ": Loop " .. loops.current + 1 .. "/" .. loops.calculated .. ', ' .. totalItemsInTrade .. (totalItemsInTrade == 1 and " item" or " items") .. " --> " .. currentTradeTargetName)
			else
				windower.add_to_chat(chatColor, _addon.name .. ": " .. totalItemsInTrade .. (totalItemsInTrade == 1 and " item" or " items") .. " --> " .. currentTradeTargetName)
			end

			status_TradeExpected = true
			windower.send_command(tradeCommand)
		end
		
		if debug then print("Trade Slots Remaining:", tradeSlotsAvailable) end
	end

	if loops.requested and loops.calculationComplete then
		if debug then print('Loops now allowed') end
		loops.allowed = true
		loops.requested = false
	end
	
	--[[
	if loops.allowed and loops.calculated > 0 then
		if not loops.initiated then
			loops.initiated = true
			if debug then print('Calling verifyNPCAndGetTrades() at the end of calculateAndTrade()') end
			verifyNPCAndGetTrades()
		end
	end--]]
end

function getGeasFeteKeyItems()
	if debug then print("Scanning Geas Fete Key Items") end
    -- This provides a list of all key items in resources that are under the category "Geas Fete"
	ownedGeasFeteKeyItems = {}
	tribulensOrRadialensFound = false

	if getOwnedKeyItems() then
    	for _, keyItem in pairs(res.key_items) do
	        if keyItem.category == 'Geas Fete' then
				for o = 1, #ownedKeyItems do
					if keyItem.id == ownedKeyItems[o] then
						table.insert(ownedGeasFeteKeyItems, {['id'] = keyItem.id, ['name'] = keyItem.en})

						if keyItem.en == 'Radialens' or keyItem.en == 'Tribulens' then
							tribulensOrRadialensFound = true
						end

						break
					end
				end
        	end
		end

		if lastTradeTargetName ~= currentTradeTargetName then
			windower.add_to_chat(chatColor, _addon.name .. ": Don't forget your Tribulens or Radialens!")
		end

		if #ownedGeasFeteKeyItems > 0 then
			return true
		else
			return false
		end
	end
end

function getOwnedKeyItems()
    ownedKeyItems = windower.ffxi.get_key_items()

    if not ownedKeyItems or #ownedKeyItems == 0 then
       print('Error reading key items. Try again in a moment')
       ownedKeyItems = {}
       return false
    end

    return true
end

function getTableSize(t)
    local count = 0

	for _ in pairs(t) do
		count = count + 1
	end

	return count
end

function dump(o)   -- print a table to console  :   print(dump(table))
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

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
end)

windower.register_event('outgoing chunk', function(packetID, original, modified, injected)
	if not injected and packetID == 0x05B then
		local packet = packets.parse('outgoing', original)
		if packet and tostring(packet["Automated Message"]) == 'false' then 
			--if debug then print("Packet Automated Message:", tostring(packet["Automated Message"])) end
		end
	end
end)

windower.register_event('status change', function(new, old)
	if status_TradeExpected and old == 0 and new == 4 then
		if debug then print('Trade Initiated') end
		status_TradeInProgress = true
		status_TradeExpected = false
		
	elseif status_TradeInProgress and old == 4 and new == 0 then
		if debug then print('Trade Complete') end
		status_TradeInProgress = false
		---[[
		
		if loops.allowed then
			--print(loops.current, loops.calculated)
			loops.current = loops.current + 1

			if loops.current < loops.calculated then
				if debug then print('Loop Completed: ' .. loops.current .. '/' .. loops.calculated) end
				verifyNPCAndGetTrades:schedule(0.5)
				--doTheThing:schedule(1.5)
			else
				if debug then print('Total Loops Completed: ' .. loops.current) end
				reset()
			end
		end--]]
	end
end)

windower.register_event('action', function(action) -- Used for spam
	if spamEnabled and action.category == 5 then -- finish item use
		coroutine.sleep(1.5)
		spamItemUse(spamLastItemUsed)
	end
end)


--[[
	Tags and their uses
	-------------------

	------ NPC --------
	name			: ALWAYS REQUIRED, 

	zone, x, y, z	: Always valid.
					: If you use any of these for an NPC, you must use all of these. 'zone' isn't enough by itself. For an item, only use the zone. Target an NPC and use the command "qt2 xyz" to show the zone name and coordinates in the console
					: This is important if there are multiple NPCs/targets with the same name in the same zone with different trades and you want to specify different trades for different parts of the zone
					: Example: Multiple ??? locations in Abyssea require different sets of items.
					: All entries with ??? as the target will require zone, x, y, and z
					: Status: Implemented, minor testing

	------ Item --------			
	item			: ALWAYS REQUIRED, Always valid. You may use the name of the item as it shows in your inventory, or you may use the text from the description.
					: Spelling and punctuation are critical, capitalization is not. If you can't get it to work with your item, see the file Windower\res\items.lua for reference
					: When loading/reloading, QuickTrade will warn you if your item is invalid. Only items in Windower\res\items.lua are supported.
	
	unique			: Invalid if combined with 'group'.
					: If true, it will only trade that specific item without including any others that may go to the same npc
					: Example: Boyahda Moss Quest. If you have Boyahda Moss and Millioncorn on you, it will only trade one type instead of trying to trade both at the same time
					: Status: NOT IMPLEMENTED

	exact			: Always valid, causes 'max' to be ignored
					: Will exchange only this number of items per trade. No more, no less. Not needed if the item is Rare, but using it anyway for consistency
					: Rare items don't need 'exact = 1' since you can only hold one anyway. It won't cause a problem either way
					: Status: Implemented, minor testing

	max				: Always valid, ignored if 'exact' is used
					: Will exchange a maximum of this many items per trade.
					: Status: Implemented, minor testing

	group			: Always valid, requires 'exact' tag
					: If an item has a group name, it will only trade this item with other items that have a matching group name.
					: See the Geas Fete Key Items below for an example. Some of the fights require a single trade containing different items in specific quantities.
					: Status: Implemented, minor testing

	noloop			: Disable looping for a particular item. So far the harvesting trades can't be looped

	partialMatch	: 
					: Don't require the addon to verify the exact item name, but allow a 'possible match.' Useful when there are an excessive number of tradeable items that have the same, unique string in each of them
					: This currently only works nicely when the tradeGroup only contains 1 item. tradeGroups with multiple items that could be partially matched, such as Rem's Tales, would end up being traded only 1 item type at a time
					: Example: Trust Ciphers

	matched			: Required when partial match is used. Always define "matched = false"


	Examples:

	tradeGroup.ElementalCrystals = {
		{item = 'Fire Crystal'},
		{item = 'Ice Crystal', unique = true, exact = 3},
		{item = 'Wind Crystal'},
		{item = 'Earth Crystal', zone = 'Bastok Mines', x = 118.87, y = 4.29, z = 2.02},
	}

	When Ice Crystals are a possible item, it will only trade exactly 3 Ice Crystals, and will ignore all other crystals you may have.
	If you do not have at least 3 Ice Crystals, it will not trade any, and will attempt other valid trades.
	It will also only trade Earth Crystals at the specified coordinates in Bastok Mines. In this example, the coordinates are the location of the Ephemeral Moogle in the Alchemy Guild



tradeGroup.Template = {  -- Status: Untested
	NPC = {
		{name = '', zone = '', x = 0, y = 0, z = 0},
	},

	{item = ''},
}

]]


---[[



tradeGroup.ElementalCrystal = {
	NPC = {
		{name = 'Ephemeral Moogle'},
		{name = 'Waypoint'},
	},
	
	{item = 'Fire Crystal'},
	{item = 'Ice Crystal'},
	{item = 'Wind Crystal'},
	{item = 'Earth Crystal'},
	{item = 'Lightning Crystal'},
	{item = 'Water Crystal'},
	{item = 'Light Crystal'},
	{item = 'Dark Crystal'},
	{item = 'Fire Cluster'},
	{item = 'Ice Cluster'},
	{item = 'Wind Cluster'},
	{item = 'Earth Cluster'},
	{item = 'Lightning Cluster'},
	{item = 'Water Cluster'},
	{item = 'Light Cluster'},
	{item = 'Dark Cluster'},
}

tradeGroup.BeastSeal = {
	NPC = {
		{name = 'Shami'},
	},

	{item = "Beastmen's Seal"},
	{item = "Kindred's Seal"},
	{item = "Kindred's Crest"},
	{item = "High Kindred's Crest"},
	{item = "Sacred Kindred's Crest"},
}


tradeGroup.TheCompetition = {
	NPC = {
		{name = 'Joulet', zone = "Port San d'Oria", x = -17.22, y = -43.8, z = -2},
		{name = 'Gallijaux', zone = "Port San d'Oria", x = -14.7, y = -43.76, z = -2},
	},

	{item = 'Moat Carp'},
}

tradeGroup.CopperVoucher = {
	NPC = {
		{name = 'Isakoth'},
		{name = 'Rolandienne'},
		{name = 'Fhelm Jobeizat'},
		{name = 'Eternal Flame'},
	},

	{item = 'Copper Voucher'},
}

tradeGroup.SilverVoucher = {
	NPC = {
		{name = 'Greyson'},
	},

	{item = 'Silver Voucher'},
}

tradeGroup.RemsTale = {
	NPC = {
		{name = 'Monisette'},
	},

	{item = "Copy of Rem's Tale, Chapter 1"},
	{item = "Copy of Rem's Tale, Chapter 2"},
	{item = "Copy of Rem's Tale, Chapter 3"},
	{item = "Copy of Rem's Tale, Chapter 4"},
	{item = "Copy of Rem's Tale, Chapter 5"},
	{item = "Copy of Rem's Tale, Chapter 6"},
	{item = "Copy of Rem's Tale, Chapter 7"},
	{item = "Copy of Rem's Tale, Chapter 8"},
	{item = "Copy of Rem's Tale, Chapter 9"},
	{item = "Copy of Rem's Tale, Chapter 10"},
}

tradeGroup.GobbieMysteryBox = {
	NPC = {
		{name = 'Mystrix'},
		{name = 'Habitox'},
		{name = 'Bountibox'},
		{name = 'Specilox'},
		{name = 'Arbitrix'},
		{name = 'Funtrox'},
		{name = 'Priztrix'},
		{name = 'Sweepstox'},
		{name = 'Wondrix'},
		{name = 'Rewardox'},
		{name = 'Winrix'},
	},

	[1] = {item = 'Dial Key #Ab', unique = true, exact = 1},
	[2] = {item = 'Dial Key #ANV', unique = true, exact = 1},
	[3] = {item = 'Dial Key #Fo', unique = true, exact = 1},
	[4] = {item = 'Special Gobbiedial Key', unique = true, exact = 1},
}

tradeGroup.ShadyBusiness = {
	NPC = {
		{name = 'Talib'},
	},

	{item = 'Zinc Ore', exact = 4},
}

tradeGroup.MihgosAmigo = {
	NPC = {
		{name = 'Nanaa Mihgo'},
	},

	{item = 'Yagudo Necklace', exact = 4},
}

tradeGroup.MandragoraMad = {
	NPC = {
		{name = 'Yoran-Oran', zone = "Windurst Walls"},
	},

	{item = 'Cornette', unique = true, exact = 1},
	{item = 'Four-leaf Mandragora Bud', unique = true, exact = 1},
	{item = 'Three-Leaf Mandragora Bud', unique = true, exact = 1},
	{item = 'Snobby Letter', unique = true, exact = 1},
	{item = 'Pinch of Yuhtunga Sulfur', unique = true, exact = 1},
}

tradeGroup.OnlyTheBest = {
	NPC = {
		{name = 'Melyon'},
	},

	{item = 'La Theine Cabbage', unique = true, exact = 5},
	{item = 'Millioncorn', unique = true, exact = 3},
	{item = 'Boyahda Moss', unique = true, exact = 1}
}

tradeGroup.AncientBeastcoin = {
	NPC = {
		{name = 'Sagheera'}
	},

	{item = 'Ancient Beastcoin'},
}

tradeGroup.ReisenjimaStones = {
	NPC = {
		{name = 'Oseem'},
	},

	{item = 'Pellucid Stone'},
	{item = 'Fern Stone'},
	{item = 'Taupe Stone'},
}

tradeGroup.VoidwatchNM = {
	NPC = {
		{name = 'Planar Rift'},
	},

	{item = 'Phase Displacer', max = 5},
	{item = 'Cobalt Cell', max = 1},
	{item = 'Rubicund Cell', max = 1}, 
	{item = 'Xanthous Cell', max = 1},
	{item = 'Jade Cell', max = 1},
}

tradeGroup.Voiddust = {
	NPC = {
		{name = 'Voidwatch Officer'},
	},

	{item = 'Pouch of Voiddust'},
}

tradeGroup.EmperorBand = {  -- Status: Untested
	NPC = {
		{name = 'Rabid Wolf, I.M.'},
		{name = 'Crying Wind, I.M.'},
		{name = 'Flying Axe, I.M.'},
		{name = 'Achantere, T.K.'},
		{name = 'Aravoge, T.K.'},
		{name = 'Arpevion, T.K.'},
		{name = 'Harara, W.W.'},
		{name = 'Milma-Hapilma, W.W.'},
		{name = 'Puroiko-Maiko, W.W.'},
		{name = 'Yevgeny, I.M.'},
		{name = 'Sachetan, I.M.'},
		{name = 'Panoquieur, T.K.'},
		{name = 'Glarociquet, T.K.'},
		{name = 'Lexun-Marixun, W.W'},
		{name = 'Chapal-Afal, W.W'},
		{name = 'Morlepiche'},
		{name = 'Emitt'},
		{name = 'Alrauverat'},
		{name = 'Kochahy-Muwachahy'},
	},

	{item = 'Emperor Band'},
}

tradeGroup.JudgmentKey = {  -- Status: Untested
	NPC = {
		{name = 'Brass Door'}, -- NEEDS COORDINATES
	},

	{item = 'Judgment Key'},
}

tradeGroup.BefouledWater = {  -- Status: Untested
	NPC = {
		{name = 'Odyssean Passage'},
	},

	{item = 'Befouled Water', max = 1},
}

tradeGroup.MellidoptWing = {  -- Status: Untested
	NPC = {
		{name = '???', zone = "Yorcia Weald"}, -- NEEDS COORDINATES
	},

	{item = 'Mellidopt Wing'},
}

tradeGroup.SalvagePlan = {  -- Status: Untested. Do these have to be done separately?
	NPC = {
		{name = 'Mrohk Sahjuuli'},
	},

	{item = 'Copy of Bloodshed Plans'},
	{item = 'Copy of Umbrage Plans'},
	{item = 'Copy of Ritualistic Plans'}
}

tradeGroup.Alexandrite = {  -- Status: Untested
	NPC = {
		{name = 'Paparoon'},
	},

	{item = 'Alexandrite'},
}

tradeGroup.SoulPlate = {  -- Status: Untested
	NPC = {
		{name = 'Sanraku'},
	},

	{item = 'Soul Plate', max = 1},
}

tradeGroup.JSECape = {  -- Status: Untested
	NPC = {
		{name = 'A.M.A.N. Reclaimer'},
	},

	{item = "Mauler's Mantle"},
	{item = "Anchoret's Mantle"},
	{item = "Mending Cape"},
	{item = "Bane Cape"},
	{item = "Ghostfyre Cape"},
	{item = "Canny Cape"},
	{item = "Weard Mantle"},
	{item = "Niht Mantle"},
	{item = "Pastoralist's Mantle"},
	{item = "Rhapsode's Cape"},
	{item = "Lutian Cape"},
	{item = "Takaha Mantle"},
	{item = "Yokaze Mantle"},
	{item = "Updraft Mantle"},
	{item = "Conveyance Cape"},
	{item = "Cornflower Cape"},
	{item = "Gunslinger's Cape"},
	{item = "Dispersal Mantle"},
	{item = "Toetapper Mantle"},
	{item = "Bookworm's Cape"},
	{item = "Lifestream Cape"},
	{item = "Evasionist's Cape"},
	{item = "Mecistopins Mantle"},
}

tradeGroup.AbysseaChests = {  -- Status: Testing complete. Opens all chests
	NPC = {
		{name = 'Sturdy Pyxis'},
	},

	{item = 'Forbidden Key', max = 1, unique = true},
}
--]]
tradeGroup.GeasFeteZitah = {   -- Status: Untested
	NPC = {
		{name = 'Affi'},
	},

	-- Tier 5
	[1] = {item = 'Ashweed', exact = 1, group = 'Wrathare', keyItem = "Wrathare's Carrot"},
	[2] = {item = 'Gravewood Log', exact = 1, group = 'Wrathare', keyItem = "Wrathare's Carrot"},
	[3] = {item = 'Duskcrawler', exact = 1, group = 'Wrathare', keyItem = "Wrathare's Carrot"},

	-- Tier 4
	[4] = {item = 'Ashweed', exact = 1, group = 'Tier 4 Alpluachra, Bucca, & Puca', keyItem = "Coven's Dust"},
	[5] = {item = 'Gravewood Log', exact = 1, group = 'Tier 4 Alpluachra, Bucca, & Puca', keyItem = "Coven's Dust"},
	[6] = {item = 'Duskcrawler', exact = 1, group = 'Tier 4 Blazewing', keyItem = "Blazewing's Pincer"},
	[7] = {item = 'Ashweed', exact = 1, group = 'Tier 4 Pazuzu', keyItem = "Pazuzu's Blade Hilt"},
	[8] = {item = 'Duskcrawler', exact = 1, group = 'Tier 4 Pazuzu', keyItem = "Pazuzu's Blade Hilt"},

	-- Tier 3
	[9] = {item = 'Riftborn Boulder', unique = true, exact = 5, keyItem = "Fleetstalker's Claw"},
	[10] = {item = 'Beitetsu', unique = true, exact = 5, keyItem = "Shockmaw's Blubber"},
	[11] = {item = 'Pluton', unique = true, exact = 5, keyItem = "Urmahlullu's Armor"},

	-- Tier 2
	[12] = {item = 'Ethereal Incense', unique = true, exact = 5, keyItem = "Brittlis's Ring"},
	[13] = {item = 'Ethereal Incense', unique = true, exact = 5, keyItem = "Sandy's Lasher"},
	[14] = {item = 'Ethereal Incense', unique = true, exact = 5, keyItem = "Umdhlebi's Flower"},
	[15] = {item = "Ayapec's Shell", unique = true, exact = 5, keyItem = "Ionos's Webbing"},
	[16] = {item = "Ayapec's Shell", unique = true, exact = 5, keyItem = "Kamohoalii's Fin"},
	[17] = {item = "Ayapec's Shell", unique = true, exact = 5, keyItem = "Nosoi's Feather"},
		
	-- Tier 1
	[18] = {item = 'Fish Mithkabob', unique = true, exact = 6},
	--[19] = {item = 'Holy Sword', unique = true, exact = 1},
	--[20] = {item = 'Flame Blade', unique = true, exact = 1},
	--[21] = {item = 'Carapace Gorget', unique = true, exact = 1},
	--[22] = {item = 'Gold Ingot', unique = true, exact = 2},
	--[23] = {item = 'Buffalo Leather', unique = true, exact = 2},
	--[24] = {item = 'Silk Cloth', unique = true, exact = 2},
	--[25] = {item = 'Mahogany Lbr.', unique = true, exact = 3},
	--[26] = {item = 'Darksteel Ingot', unique = true, exact = 2},
}

tradeGroup.GeasFeteRuann = {   -- Status: Untested
	NPC = {
		{name = 'Dremi'},
	},

	-- Tier 4
	[1] = {item = 'Parchment', exact = 1, group = 'Ark Angel EV', keyItem = "Ark Angel EV's Sash"},
	[2] = {item = 'Illuminink', exact = 1, group = 'Ark Angel EV', keyItem = "Ark Angel EV's Sash"},
	[3] = {item = 'Ashen Crayfish', exact = 1, group = 'Ark Angel EV', keyItem = "Ark Angel EV's Sash"},
	[4] = {item = 'Ashweed', exact = 1, group = 'Ark Angel EV', keyItem = "Ark Angel EV's Sash"},

	[5] = {item = 'Parchment', exact = 1, group = 'Ark Angel GK', keyItem = "Ark Angel GK's Bangle"},
	[6] = {item = 'Illuminink', exact = 1, group = 'Ark Angel GK', keyItem = "Ark Angel GK's Bangle"},
	[7] = {item = 'Ashen Crayfish', exact = 1, group = 'Ark Angel GK', keyItem = "Ark Angel GK's Bangle"},
	[8] = {item = 'Gravewood Log', exact = 1, group = 'Ark Angel GK', keyItem = "Ark Angel GK's Bangle"},

	[9] = {item = 'Parchment', exact = 1, group = 'Ark Angel HM', keyItem = "Ark Angel HM's Coat"},
	[10] = {item = 'Illuminink', exact = 1, group = 'Ark Angel HM', keyItem = "Ark Angel HM's Coat"},
	[11] = {item = 'Ashweed', exact = 1, group = 'Ark Angel HM', keyItem = "Ark Angel HM's Coat"},
	[12] = {item = 'Gravewood Log', exact = 1, group = 'Ark Angel HM', keyItem = "Ark Angel HM's Coat"},

	[13] = {item = 'Parchment', exact = 1, group = 'Ark Angel MR', keyItem = "Ark Angel MR's Buckle"},
	[14] = {item = 'Illuminink', exact = 1, group = 'Ark Angel MR', keyItem = "Ark Angel MR's Buckle"},
	[15] = {item = 'Ashen Crayfish', exact = 1, group = 'Ark Angel MR', keyItem = "Ark Angel MR's Buckle"},
	[16] = {item = 'Duskcrawler', exact = 1, group = 'Ark Angel MR', keyItem = "Ark Angel MR's Buckle"},

	[17] = {item = 'Parchment', exact = 1, group = 'Ark Angel TT', keyItem = "Ark Angel TT's Necklace"},
	[18] = {item = 'Illuminink', exact = 1, group = 'Ark Angel TT', keyItem = "Ark Angel TT's Necklace"},
	[19] = {item = 'Duskcrawler', exact = 1, group = 'Ark Angel TT', keyItem = "Ark Angel TT's Necklace"},
	[20] = {item = 'Gravewood Log', exact = 1, group = 'Ark Angel TT', keyItem = "Ark Angel TT's Necklace"},

	-- Tier 3
	[21] = {item = 'Yggdreant Root', unique = true, exact = 1, keyItem = "Duke Vepar's Signet"},
	[22] = {item = 'Waktza Crest', unique = true, exact = 1, keyItem = "Pakecet's Blubber"},
	[23] = {item = 'Cehuetzi Pelt', unique = true, exact = 1, keyItem = "Vir'ava's Stalk"},

	-- Tier 2
	[24] = {item = "Mhuufya's Beak", unique = true, exact = 5, keyItem = "Amymone's Tooth"},
	[25] = {item = "Azrael's Eye", unique = true, exact = 5, keyItem = "Hanbi's Nail"},
	[26] = {item = "Vedrfolnir's Wing", unique = true, exact = 5, keyItem = "Kammavaca's Binding"},
	[27] = {item = "Camahueto's Fur", unique = true, exact = 5, keyItem = "Naphula's Bracelet"},
	[28] = {item = "Vidmapire's Claw", unique = true, exact = 5, keyItem = "Palila's Talon"},
	[29] = {item = "Centurio's Armor", unique = true, exact = 5, keyItem = "Yilan's Scale"},

	-- Tier 1
	[30] = {item = "Bhefhel Marlin", unique = true, exact = 1},
	--[31] = {item = "Pamama Tart", unique = true, exact = 1},
	--[32] = {item = "Turtle Bangles", unique = true, exact = 1},
	--[33] = {item = "Cermet Chunk", unique = true, exact = 2},
	--[34] = {item = "Platinum Ingot", unique = true, exact = 2},
	--[35] = {item = "Catobl. Leather", unique = true, exact = 2},
	--[36] = {item = "Karakul Cloth", unique = true, exact = 2},
	--[37] = {item = "Ebony Lumber", unique = true, exact = 2},
	--[38] = {item = "Steel Ingot", unique = true, exact = 2},
}

tradeGroup.GeasFeteReisenjima = {   -- Status: Untested
	NPC = {
		{name = 'Shiftrix'},
	},

	-- Tier 4
	[1] = {item = 'Ashweed', exact = 3, group = 'Bashmu', keyItem = "Bashmu's Trinket"},
	[2] = {item = 'Void Grass', exact = 3, group = 'Bashmu', keyItem = "Bashmu's Trinket"},
	[3] = {item = 'Vermihumus', exact = 1, group = 'Bashmu', keyItem = "Bashmu's Trinket"},
	[4] = {item = 'Coalition Humus', exact = 1, group = 'Bashmu', keyItem = "Bashmu's Trinket"},

	[5] = {item = 'Voidsnapper', exact = 3, group = 'Erinys', keyItem = "Erinys's Beak"},
	[6] = {item = 'Ashweed', exact = 3, group = 'Erinys', keyItem = "Erinys's Beak"},
	[7] = {item = 'Mistmelt', exact = 1, group = 'Erinys', keyItem = "Erinys's Beak"},
	[8] = {item = 'Tornado', exact = 1, group = 'Erinys', keyItem = "Erinys's Beak"},

	[9] = {item = 'Void Crystal', exact = 3, group = 'Onychophora', keyItem = "Onychophora's Soil"},
	[10] = {item = 'Void Grass', exact = 3, group = 'Onychophora', keyItem = "Onychophora's Soil"},
	[11] = {item = 'Titanite', exact = 10, group = 'Onychophora', keyItem = "Onychophora's Soil"},
	[12] = {item = 'Worm Mulch', exact = 1, group = 'Onychophora', keyItem = "Onychophora's Soil"},

	[13] = {item = 'Voidsnapper', exact = 3, group = 'Schah', keyItem = "Schah's Gambit"},
	[14] = {item = 'Gravewood Log', exact = 3, group = 'Schah', keyItem = "Schah's Gambit"},
	[15] = {item = 'Leisure Table', exact = 1, group = 'Schah', keyItem = "Schah's Gambit"},
	[16] = {item = 'Trump Card Case', exact = 1, group = 'Schah', keyItem = "Schah's Gambit"},

	[17] = {item = 'Void Crystal', exact = 3, group = 'Teles', keyItem = "Teles's Hymn"},
	[18] = {item = 'Voidsnapper', exact = 3, group = 'Teles', keyItem = "Teles's Hymn"},
	[19] = {item = "Siren's Hair", exact = 1, group = 'Teles', keyItem = "Teles's Hymn"},
	[20] = {item = "Maiden's Virelai", exact = 1, group = 'Teles', keyItem = "Teles's Hymn"},

	[21] = {item = 'Void Crystal', exact = 3, group = 'Vinipata', keyItem = "Vinipata's Blade"},
	[22] = {item = 'Duskcrawler', exact = 3, group = 'Vinipata', keyItem = "Vinipata's Blade"},
	[23] = {item = 'Bone Chip', exact = 10, group = 'Vinipata', keyItem = "Vinipata's Blade"},
	[24] = {item = 'Scarletite Ingot', exact = 1, group = 'Vinipata', keyItem = "Vinipata's Blade"},

	[25] = {item = 'Void Grass', exact = 3, group = 'Zerde', keyItem = "Zerde's Cup"},
	[26] = {item = 'Ashen Crayfish', exact = 3, group = 'Zerde', keyItem = "Zerde's Cup"},
	[27] = {item = 'Flan Meat', exact = 10, group = 'Zerde', keyItem = "Zerde's Cup"},
	[28] = {item = 'Black Pudding', exact = 1, group = 'Zerde', keyItem = "Zerde's Cup"},

	-- Tier 3
	[29] = {item = "Sovereign Behemoth's Hide", unique = true, exact = 1, keyItem = "Maju's Claw"},
	[30] = {item = "Tolba's Shell", unique = true, exact = 1, keyItem = "Neak's Treasure"},
	[31] = {item = "Hidhaegg's Scale", unique = true, exact = 1, keyItem = "Yakshi's Scroll"},

	-- Tier 3
	[32] = {item = "Gramk-Droog's grand coffer", unique = true, exact = 1, keyItem = "Bashmu's Trinket"},
	[33] = {item = "Ignor-Mnt's grand coffer", unique = true, exact = 2, keyItem = "Gajasimha's Mane"},
	[34] = {item = "Durs-Vike's grand coffer", unique = true, exact = 2, keyItem = "Ironside's Maul"},
	[35] = {item = "Liij-Vok's grand coffer", unique = true, exact = 2, keyItem = "Old Shuck's Tufs"},
	[36] = {item = "Tryl-Wuj's grand coffer", unique = true, exact = 2, keyItem = "Sarsaok's Hoard"},
	[37] = {item = "Ymmr-Ulvid's grand coffer", unique = true, exact = 2, keyItem = "Strophadia's Pearl"},

	[38] = {item = "Behem. Leather", unique = true, exact = 1},
	[39] = {item = "Bladefish", unique = true, exact = 1},
	--[40] = {item = "Turtle Soup", unique = true, exact = 1},
	--[41] = {item = "Demon's Knife", unique = true, exact = 1},
	--[42] = {item = "Gold Bangles", unique = true, exact = 1},
	--[43] = {item = "Gold Obi", unique = true, exact = 1},
	--[44] = {item = "Ancient Lumber", unique = true, exact = 2},
	--[45] = {item = "Darksteel Buckler", unique = true, exact = 1},
}

tradeGroup.TreasureCoffer = {   -- Status: Tested in Oztroja
	NPC = {
		{name = 'Treasure Coffer'},
	},

	[1] = {item = 'Ozt. Coffer Key', unique = true, zone = 'Castle Oztroja'},
	[2] = {item = 'Davoi Coffer Key', unique = true, zone = 'Monastic Cavern'},
	[3] = {item = 'Bdx. Coffer Key', unique = true, zone = 'Bedeaux'},
	[4] = {item = 'Nest Coffer Key', unique = true, zone = "Crawlers' Nest"},
	[5] = {item = 'Eld. Coffer Key', unique = true, zone = 'The Eldieme Necropolis'},
	[6] = {item = 'Grl. Coffer Key', unique = true, zone = 'Garlaige Citadel'},
	[7] = {item = 'Zvahl Coffer Key', unique = true, zone = 'Castle Zvahl Baileys'},
	[8] = {item = 'Ugl. Coffer Key', unique = true, zone = 'Temple of Uggalepih'},
	[9] = {item = 'Den Coffer Key', unique = true, zone = 'Den of Rancor'},
	[10] = {item = 'Kuftal Coffer Key', unique = true, zone = 'Kuftal Tunnel'},
	[11] = {item = 'Byd. Coffer Key', unique = true, zone = 'The Boyahda Tree'},
	[12] = {item = 'Cld. Coffer Key', unique = true, zone = "Ifrit's Cauldron"},
	[13] = {item = 'Qsd. Coffer Key', unique = true, zone = 'Quicksand Caves'},
	[14] = {item = 'Tor. Coffer Key', unique = true, zone = 'Toraimarai Canal'},
	[15] = {item = "Ru'Aun Coffer Key", unique = true, zone = "Ru'Aun Gardend"},
	[16] = {item = 'Grotto Coffer Key', unique = true, zone = 'Sea Serpent Grotto'},
	[17] = {item = 'Vlg. Coffer Key', unique = true, zone = "Ve'Lugannon Palace"},
	[18] = {item = 'Ntn. Coffer Key', unique = true, zone = 'Newton Movapolos'},
	[19] = {item = "Thief's Tools", unique = true, exact = 1},
	[20] = {item = "Living Key", unique = true, exact = 1},
	[21] = {item = "Skeleton Key", unique = true, exact = 1},
}

tradeGroup.TreasureChest = {   -- Status: Untested
	NPC = {
		{name = 'Treasure Chest'},
	},

	{item = "Gls. Chest Key", unique = true, zone = "Fort Ghelsba"},
	{item = "Plb. Chest Key", unique = true, zone = "Palborough Mines"},
	{item = "Gds. Chest Key", unique = true, zone = "Giddeus"},
	{item = "Rnp. Chest Key", unique = true, zone = "King Ranperre's Tomb"},
	{item = "Dgr. Chest Key", unique = true, zone = "Dangruf Wadi"},
	{item = "Hrt. Chest Key", unique = true, zone = "Outer Horutoto Ruines"},
	{item = "Hrt. Chest Key", unique = true, zone = "Inner Horutoto Ruines"},
	{item = "Ordelle Chest Key", unique = true, zone = "Ordelle's Caves"},
	{item = "Gusgen Chest Key", unique = true, zone = "Gusgen Mines"},
	{item = "Shk. Chest Key", unique = true, zone = "Maze of Shakhrami"},
	{item = "Davoi Chest Key", unique = true, zone = "Davoi"},
	{item = "Bdx. Chest Key", unique = true, zone = "Beadeaux"},
	{item = "Oztroja Chest Key", unique = true, zone = "Castle Oztroja"},
	{item = "Dlk. Chest Key", unique = true, zone = "Middle Delkfutt's Tower"},
	{item = "Dlk. Chest Key", unique = true, zone = "Upper Delkfutt's Tower"},
	{item = "Fei'Yin Chest Key", unique = true, zone = "Fei'Yin"},
	{item = "Zvahl Chest Key", unique = true, zone = "Castle Zvahl Baileys"},
	{item = "Zvahl Chest Key", unique = true, zone = "Castle Zvahl Keep"},
	{item = "Eldieme Chest Key", unique = true, zone = "The Eldieme Necropolis"},
	{item = "Nest Chest Key", unique = true, zone = "Crawler's Nest"},
	{item = "Garlaige Chest Key", unique = true, zone = "Garlaige Citadel"},
	{item = "Grotto Chest Key", unique = true, zone = "Sea Serpent Grotto"},
	{item = "Onzozo Chest Key", unique = true, zone = "Labyrinth of Onzozo"},
	{item = "Scr. Chest Key", unique = true, zone = "Sacrarium"},
	{item = "Oldton Chest Key", unique = true, zone = "Oldton Movapolos"},
	{item = "Pso. Chest Key", unique = true, zone = "Pso'Xja"},
}

tradeGroup.MogHouseMoogle = { -- Status: Tested in Bastok and Whitegate
	NPC = {
		{name = 'Moogle', zone = 'Port Jeuno', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Lower Jeuno', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Upper Jeuno', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = "Ru'lude Gardens", x = 0, y = 1.5, z = 0},

		{name = 'Moogle', zone = 'Bastok Markets', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Bastok Mines', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Port Bastok', x = 0, y = 1.5, z = 0},

		{name = 'Moogle', zone = 'Windurst Woods', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Windurst Waters', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Windurst Walls', x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = 'Port Windurst', x = 0, y = 1.5, z = 0},

		{name = 'Moogle', zone = "South San d'Oria", x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = "North San d'Oria", x = 0, y = 1.5, z = 0},
		{name = 'Moogle', zone = "Port San d'Oria", x = 0, y = 1.5, z = 0},

		{name = "Moogle", zone = "Aht Urhgan Whitegate", x = 0.00, y = 1.50, z = 0.00},
	},

	{item = 'Imp. Brz. Piece', unique = true, exact = 1},
}

tradeGroup.FestiveMoogle = { -- Status: Tested Red in Bastok
	NPC = {
		{name = 'Festive Moogle'},
	},

	{item = 'Mog Pell (Gold)', unique = true, exact = 1},
	{item = 'Mog Pell (Green)', unique = true, exact = 1},
	{item = 'Mog Pell (Marble)', unique = true, exact = 1},
	{item = 'Mog Pell (Ochre)', unique = true, exact = 1},
	{item = 'Mog Pell (Rainbow)', unique = true, exact = 1},
	{item = 'Mog Pell (Red)', unique = true, exact = 1},
	{item = 'Mog Pell (Silver)', unique = true, exact = 1},
}

tradeGroup.TrustCipher = { -- Status: Testing complete
	NPC = {
		{name = 'Wetata'},
		{name = 'Clarion Star'},
		{name = 'Gondebaud'},
	},

	{item = "Cipher: Zeid", unique = true},
	{item = "Cipher: Lion", unique = true},
	{item = "Cipher: Tenzen", unique = true},
	{item = "Cipher: Mihli", unique = true},
	{item = "Cipher: Valaineral", unique = true},
	{item = "Cipher: Joachim", unique = true},
	{item = "Cipher: Naja", unique = true},
	{item = "Cipher: Rainemard", unique = true},
	{item = "Cipher: Lehko", unique = true},
	{item = "Cipher: Ovjang", unique = true},
	{item = "Cipher: Mnejing", unique = true},
	{item = "Cipher: Sakura", unique = true},
	{item = "Cipher: Luzaf", unique = true},
	{item = "Cipher: Najelith", unique = true},
	{item = "Cipher: Aldo", unique = true},
	{item = "Cipher: Moogle", unique = true},
	{item = "Cipher: Fablinix", unique = true},
	{item = "Cipher: Domina", unique = true},
	{item = "Cipher: Elivira", unique = true},
	{item = "Cipher: Noillurie", unique = true},
	{item = "Cipher: Lhu", unique = true},
	{item = "Cipher: F. Coffin", unique = true},
	{item = "Cipher: S. Sibyl", unique = true},
	{item = "Cipher: Mumor", unique = true},
	{item = "Cipher: Uka", unique = true},
	{item = "Cipher: Lilisette", unique = true},
	{item = "Cipher: Cid", unique = true},
	{item = "Cipher: Rahal", unique = true},
	{item = "Cipher: Koru-Moru", unique = true},
	{item = "Cipher: Kuyin", unique = true},
	{item = "Cipher: Karaha", unique = true},
	{item = "Cipher: Babban", unique = true},
	{item = "Cipher: Abenzio", unique = true},
	{item = "Cipher: Rughadjeen", unique = true},
	{item = "Cipher: Kukki", unique = true},
	{item = "Cipher: Margret", unique = true},
	{item = "Cipher: Gilgamesh", unique = true},
	{item = "Cipher: Areuhat", unique = true},
	{item = "Cipher: Lhe", unique = true},
	{item = "Cipher: Mayakov", unique = true},
	{item = "Cipher: Qultada", unique = true},
	{item = "Cipher: Adelheid", unique = true},
	{item = "Cipher: Amchuchu", unique = true},
	{item = "Cipher: Brygid", unique = true},
	{item = "Cipher: Mildaurion", unique = true},
	{item = "Cipher: Semih", unique = true},
	{item = "Cipher: Halver", unique = true},
	{item = "Cipher: Lion II", unique = true},
	{item = "Cipher: Zeid II", unique = true},
	{item = "Cipher: Rongelouts", unique = true},
	{item = "Cipher: Kupofried", unique = true},
	{item = "Cipher: Leonoyne", unique = true},
	{item = "Cipher: Maximilian", unique = true},
	{item = "Cipher: Kayeel", unique = true},
	{item = "Cipher: Robel-Akbel", unique = true},
	{item = "Cipher: Tenzen II", unique = true},
	{item = "Cipher: Prishe II", unique = true},
	{item = "Cipher: Abquhbah", unique = true},
	{item = "Cipher: Nashmeira II", unique = true},
	{item = "Cipher: Lilisette II", unique = true},
	{item = "Cipher: Balamor", unique = true},
	{item = "Cipher: Selh'teus", unique = true},
	{item = "Cipher: Ingrid II", unique = true},
	{item = "Cipher: August", unique = true},
	{item = "Cipher: Rosulatia", unique = true},
	{item = "Cipher: Mumor II", unique = true},
	{item = "Cipher: Ullegore", unique = true},
	{item = "Cipher: Teodor", unique = true},
	{item = "Cipher: Makki", unique = true},
	{item = "Cipher: King", unique = true},
	{item = "Cipher: Morimar", unique = true},
	{item = "Cipher: Darrcuiln", unique = true},
	{item = "Cipher: Arciela II", unique = true},
	{item = "Cipher: Iroha", unique = true},
	{item = "Cipher: Iroha II", unique = true},
	{item = "Cipher: Shantotto II", unique = true},
	{item = "Cipher: Ark HM", unique = true},
	{item = "Cipher: Ark TT", unique = true},
	{item = "Cipher: Ark MR", unique = true},
	{item = "Cipher: Ark EV", unique = true},
	{item = "Cipher: Ark GK", unique = true},
	{item = "Cipher: Monberaux", unique = true},
}

tradeGroup.Einherjar = { -- Status: Untested
	NPC = {
		{name = 'Entry Gate'},
	},

	[1] = {item = 'Glowing Lamp', unique = true},
	[2] = {item = 'Smoldering Lamp', unique = true},
}

tradeGroup.IronGate = {  -- Status: Testing complete
	NPC = {
		{name = "Iron Gate"},
	},

	{item = "Lamian Fang Key"},
}

tradeGroup.FearOfTheDark = {  -- Status: Untested
	NPC = {
		{name = "Secodiand"},
	},

	{item = "Bat Wing", exact = 2},
}

tradeGroup.ThickShells = {  -- Status: Untested
	NPC = {
		{name = "Vounebariont"},
	},

	{item = "Beetle Shell", exact = 5},
}

tradeGroup.TigersTeeth = {  -- Status: Untested
	NPC = {
		{name = "Taumila"},
	},

	{item = "Black Tiger Fang", exact = 3},
}

tradeGroup.PostmanAlwaysKOsTwice = {  -- Status: Untested
	NPC = {
		{name = "Ambrosius"},
	},

	{item = "Damp Envelope", unique = true},
	{item = "Muddy Bar Tab", unique = true},
	{item = "Odd Postcard", unique = true},
	{item = "Torn Epistle", unique = true},
}

tradeGroup.SoulOfTheMatter = {  -- Status: Untested
	NPC = {
		{name = "Cleades"},
	},

	{item = "Gauger Plate", exact = 1},
}

tradeGroup.UnbreakHisHeart = {  -- Status: Untested
	NPC = {
		{name = "Joulet", zone = "Abyssea - La Theine", x = -35.88, y = 176.33, z = 33.75},
	},

	{item = 'Willow Fishing Rod', exact = 1},
}

tradeGroup.ItSetsMyHeartAflutter = {  -- Status: Untested
	NPC = {
		{name = 'Saldinor'},
	},

	{item = 'Twitherym Wing', exact = 2},
}

tradeGroup.AGoodPairOfCrocs = {  -- Status: Untested
	NPC = {
		{name = 'Felmsy'},
	},

	{item = 'Velkk Mask', unique = true, max = 1},
	{item = 'Velkk Necklace', unique = true, max = 1}
}

tradeGroup.AShotInTheDark = {  -- Status: Untested
	NPC = {
		{name = 'Pudith'},
	},

	{item = 'Umbril Ooze', max = 1},
}

tradeGroup.MogGardenTree = {  -- Status: Untested
	NPC = {
		{name = 'Arboreal Grove', zone = "Mog Garden"},
	},

	{item = 'Florid Leaf Mold', unique = true, max = 1},
}

tradeGroup.MogGardenStone = {  -- Status: Testing complete
	NPC = {
		{name = 'Mineral Vein', zone = "Mog Garden"},
	},

	{item = 'Rockoil', unique = true, max = 1},
}

tradeGroup.LoggingPoint = {  -- Status: Testing Complete, cannot loop
	NPC = {
		{name = 'Logging Point'},
	},

	{item = 'Hatchet', unique = true, max = 1},
}

tradeGroup.MiningPoint = {  -- Status: Testing Complete, cannot loop
	NPC = {
		{name = 'Mining Point'},
	},

	{item = 'Pickaxe', unique = true, max = 1},
}

tradeGroup.HarvestingPoint = {  -- Status: Testing Complete, cannot loop
	NPC = {
		{name = 'Harvesting Point'},
	},

	{item = 'Sickle', unique = true, max = 1},
}



-- ABYSSEA - ATTOHWA

tradeGroup.AbysseaAttohwaPallidPercy = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Attohwa", x = 281.06, y = 174.01, z = 20.60},
	},

	{item = 'Blanched Silver'},
}

tradeGroup.AbysseaAttohwaWherwetrice = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Attohwa", x = 198.04, y = 108.71, z = 20.36},
	},

	{item = 'Mngl. Ck. Skin'},
}



-- ABYSSEA - GRAUBERG

tradeGroup.AbysseaGraubergFleshflayerKillakriq = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Grauberg", x = 397.00, y = -436.00, z = 40.00},
	},

	{item = 'Goblin Rope'},
}

tradeGroup.AbysseaGraubergBomblixFlamefinger = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Grauberg", x = 556.00, y = -318.00, z = 24.00},
	},

	{item = 'Goblin Oil'},
	{item = 'Goblin Gunpowder'}
}



-- ABYSSEA - ALTEPA

tradeGroup.AbysseaAltepaChickcharney = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Altepa", x = 36.00, y = -240.00, z = 0.00},
	},

	{item = 'H.Q. Cktrice. Skin'},
}



-- ABYSSEA - MISAREAUX

tradeGroup.AbysseaMisareauxNehebkau = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Misareaux", x = 321.22, y = -354.06, z = 23.97},
	},

	{item = 'Hd. Raptor Skin'},
}

tradeGroup.AbysseaCepKamuy = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Misareaux", x = -161.13, y = 638.61, z = -15.55},
	},

	{item = 'Orbn. Cheekmeat'},
}



-- ABYSSEA - VUNKERL

tradeGroup.AbysseaVunkerlSeps = {  -- Status: Confirmed
	NPC = {
		{name = "???", zone = "Abyssea - Vunkerl", x = -239.75, y = -717.55, z = -39.98},
	},

	{item = 'Opaque Wing'},
}



--[[

	tradeGroup. = {  -- Status: Untested
		NPC = {
			{name = ''},
		},

		{item = ''},
	}



	To Add
	-------
	Abyssea.... dear god...
	Storage Slips - Create method of saving already-attempted items, otherwise it'll trade the same thing over and over if the item is already stored



]]





function targetQuestionMark()
	local mobs = windower.ffxi.get_mob_array()
    local closest

    for _, mob in pairs(mobs) do
        if mob.valid_target and mob.name  == '???' then
			if debug and mob.name == '???' then print("??? Distance", mob.distance:sqrt()) end

			if mob.distance:sqrt() < 15 then
				if not closest or mob.distance < closest.distance then
					closest = mob
				end
			end
        end
    end

    if not closest then
        return
    end

	--if true then return end
    local player = windower.ffxi.get_player()

	if player then
		packets.inject(packets.new('incoming', 0x058, {
			['Player'] = player.id,
			['Target'] = closest.id,
			['Player Index'] = player.index,
		}))
	end
end

function tripleQuestionmarkSpawnNotification(id, data)
	if not tripleQuestionmarkAlert or os.clock() - tripleQuestionmarkNotificationTime < 20 or not res.zones[windower.ffxi.get_info().zone].name:startswith("Abyssea") then return end

    if id == 0xe then
        local p = packets.parse('incoming', data)
        local npc = windower.ffxi.get_mob_by_id(p['NPC'])

        if npc and npc.name == '???' then
			local _player = windower.ffxi.get_mob_by_target('me')
			local distanceToSpawn = 1000

			for tradeType, tradeNPCs in pairs(tradeGroup) do
				for i = 1, #tradeGroup[tradeType].NPC do
					if tradeGroup[tradeType].NPC[i].name == '???' then
						if tradeGroup[tradeType].NPC[i].zone and tradeGroup[tradeType].NPC[i].zone == res.zones[windower.ffxi.get_info().zone].name then
							if 	tradeGroup[tradeType].NPC[i].x and tradeGroup[tradeType].NPC[i].y and tradeGroup[tradeType].NPC[i].z and
								(string.format("%.2f", tradeGroup[tradeType].NPC[i].x) == string.format("%.2f", npc.x) and string.format("%.2f", tradeGroup[tradeType].NPC[i].y) == string.format("%.2f", npc.y) and string.format("%.2f", tradeGroup[tradeType].NPC[i].z) == string.format("%.2f", npc.z)) then
								distanceToSpawn = ((tradeGroup[tradeType].NPC[i].x - _player.x)^2 + (tradeGroup[tradeType].NPC[i].y - _player.y)^2 + (tradeGroup[tradeType].NPC[i].z - _player.z)^2):sqrt()
								
								if distanceToSpawn <= 40 then
									windower.play_sound('D:/Windower/addons/audio/Digital watch beep.wav')
									tripleQuestionmarkNotificationTime = os.clock()
								end
							end
						end
					end
				end
			end
        end
    end
end

windower.register_event('incoming chunk', tripleQuestionmarkSpawnNotification)





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