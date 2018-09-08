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
_addon.version = '1.7.0'
_addon.command = 'qtr'

require('tables')
require('coroutine')

exampleOnly = false
textSkipTimer = 1
lastNPC = ''

loopWait = 0
loopCount = 1
loopModeSet = false
loopable = false
loopMax = 0
loopCurrent = 0
lastLoopNPC = ''

windower.register_event('addon command', function(...)
	loopCount = 1
	loopModeSet = false
	loopable = false
	loopMax = 0
	loopCurrent = 0
	loopText = ''
	lastLoopNPC = ''

	if #arg > 0 and arg[1] == 'loop'then
		loopModeSet = true
		--print('loop request detected')

		if #arg > 1 and arg[2] then
			if not tonumber(arg[2]) then
				print('Invalid Loop Count Entry: ' .. arg[2])
				return
			end

			loopMax = tonumber(arg[2])
			--print('Max Loops: ' .. loopMax)
		end
	end


	if loopMax == 0 then
		loopMax = 100000
	end

	while loopCount > 0 and loopCurrent < loopMax do
		loopCurrent = loopCurrent + 1
		quicktrade(arg)
		--print('loopCount: ' .. loopCount)
		--loopCount = loopCount - 1

		if loopCount > 0 then
			--print(loopCount .. ' loops remaining')
			coroutine.sleep(loopWait)
		end
	end
	--print('Complete')
end)

function quicktrade(arg)
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
		{id = 74994, name = 'mecistopins Mantle', count = 0, stacks = 0, stacksize = 1},
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

	local geasFeteZitahIDs = {
		{id = 4061, name = 'riftborn boulder', count = 0, stacks = 0, stacksize = 99, minimum = 5},
		{id = 4060, name = 'beitetsu', count = 0, stacks = 0, stacksize = 99, minimum = 5},
		{id = 4059, name = 'pluton', count = 0, stacks = 0, stacksize = 99, minimum = 5},
		{id = 9060, name = 'ethereal incense', count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 9057, name = "ayapec's shell", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 4398, name = 'fish mithkabob', count = 0, stacks = 0, stacksize = 12, minimum = 6}, -- 1k from curio moogle
		{id = 16581, name = 'holy sword', count = 0, stacks = 0, stacksize = 1, minimum = 1}, -- 20k or 430 sparks
		{id = 16564, name = 'flame blade', count = 0, stacks = 0, stacksize = 1, minimum = 1}, -- 10k or 775 sparks
		{id = 745, name = 'gold ingot', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 10k
		{id = 829, name = 'silk cloth', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 10k
		{id = 717, name = 'mahogany lumber', count = 0, stacks = 0, stacksize = 12, minimum = 3}, -- 10k
		{id = 654, name = 'darksteel ingot', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 15k
		{id = 1629, name = 'buffalo leather', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 20k
		{id = 13091, name = 'carapace gorget', count = 0, stacks = 0, stacksize = 1, minimum = 1}, -- 60k
	}

	local geasFeteRuaunIDs = {
		{id = 4015, name = 'yggdreant root', count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 4013, name = 'waktza crest', count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 8754, name = 'cehuetzi pelt', count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 9097, name = "mhuufya's beak", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 9103, name = "vidmapire's claw", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 9104, name = "centurio's armor", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 9051, name = "camahueto's fur", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 9031, name = "vedrfolnir's wing", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 9059, name = "azrael's eye", count = 0, stacks = 0, stacksize = 12, minimum = 5},
		{id = 4479, name = 'bhefhel marlin', count = 0, stacks = 0, stacksize = 12, minimum = 1}, -- 4k id 5806?
		{id = 4563, name = 'pamama tart', count = 0, stacks = 0, stacksize = 12, minimum = 1}, -- 10k
		{id = 746, name = 'platinum ingot', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 13k
		{id = 652, name = 'steel ingot', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 15k
		{id = 719, name = 'ebony lumber', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 15k
		{id = 2124, name = 'catoblepas leather', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 15k
		{id = 931, name = 'cermet chunk', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 20k
		{id = 2288, name = 'karakul cloth', count = 0, stacks = 0, stacksize = 12, minimum = 2}, -- 30k
		{id = 13981, name = 'turtle bangles', count = 0, stacks = 0, stacksize = 1, minimum = 1}, -- 30k
	}

	local geasFeteReisenjimaIDs = {
		{id = 9151, name = "sovereign behemoth's hide", count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 9150, name = "tolba's shell", count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 9149, name = "hidhaegg's scale", count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 6296, name = "gramk-droog's grand coffer", count = 0, stacks = 0, stacksize = 99, minimum = 1},
		{id = 6288, name = "ignor-mnt's grand coffer", count = 0, stacks = 0, stacksize = 99, minimum = 2},
		{id = 6290, name = "durs-vike's grand coffer", count = 0, stacks = 0, stacksize = 99, minimum = 2},
		{id = 6294, name = "liij-vok's grand coffer", count = 0, stacks = 0, stacksize = 99, minimum = 2},
		{id = 6292, name = "tryl-wuj's grand coffer", count = 0, stacks = 0, stacksize = 99, minimum = 2},
		{id = 6286, name = "ymmr-ulvid's grand coffer", count = 0, stacks = 0, stacksize = 99, minimum = 2},
		{id = 4471, name = 'bladefish', count = 0, stacks = 0, stacksize = 1, minimum = 1},
		{id = 12302, name = 'darksteel buckler', count = 0, stacks = 0, stacksize = 1, minimum = 1},
		{id = 862, name = 'behemoth leather', count = 0, stacks = 0, stacksize = 12, minimum = 1},
		{id = 720, name = 'ancient lumber', count = 0, stacks = 0, stacksize = 12, minimum = 2},
		{id = 13206, name = 'gold obi', count = 0, stacks = 0, stacksize = 1, minimum = 1},
		{id = 13983, name = 'gold bangles', count = 0, stacks = 0, stacksize = 1, minimum = 1},
		{id = 17601, name = "demon's knife", count = 0, stacks = 0, stacksize = 1, minimum = 1},
		{id = 16502, name = 'venom knife', count = 0, stacks = 0, stacksize = 1, minimum = 1},
		{id = 4418, name = 'turtle soup', count = 0, stacks = 0, stacksize = 1, minimum = 1},
	}

	local npcTable = {
		{name = 'Shami', idTable = sealIDs, tableType = 'Seals', loopable = true, loopWait = 3},
		{name = 'Ephemeral Moogle', idTable = crystalIDs, tableType = 'Crystals', loopable = true, loopWait = 9},
		{name = 'Waypoint', idTable = crystalIDs, tableType = 'Crystals', loopable = true, loopWait = 3},
		{name = 'Joulet', idTable = moatCarpIDs, tableType = 'Moat Carp', loopable = true, loopWait = 4},
		{name = 'Gallijaux', idTable = moatCarpIDs, tableType = 'Moat Carp', loopable = true, loopWait = 4},
		{name = 'Isakoth', idTable = copperVoucherIDs, tableType = 'Copper Vouchers', loopable = true, loopWait = 3},
		{name = 'Rolandienne', idTable = copperVoucherIDs, tableType = 'Copper Vouchers', loopable = true, loopWait = 3},
		{name = 'Fhelm Jobeizat', idTable = copperVoucherIDs, tableType = 'Copper Vouchers', loopable = true, loopWait = 3},
		{name = 'Eternal Flame', idTable = copperVoucherIDs, tableType = 'Copper Vouchers', loopable = true, loopWait = 3},
		{name = 'Monisette', idTable = remsTaleIDs, tableType = "Rem's Tales", loopable = true, loopWait = 3},
		{name = '???', idTable = mellidoptWingIDs, tableType = 'Mellidopt Wings', loopable = true, loopWait = 5},
		{name = 'Mrohk Sahjuuli', idTable = salvagePlanIDs, tableType = 'Salvage Plans', loopable = true, loopWait = 5},
		{name = 'Paparoon', idTable = alexandriteIDs, tableType = 'Alexandrite', loopable = true, loopWait = 5},
		{name = 'Mystrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Habitox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Bountibox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Specilox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Arbitrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Funtrox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Priztrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Sweepstox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Wondrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Rewardox', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Winrix', idTable = spGobbieKeyIDs, tableType = 'Special Gobbiedial Keys', loopable = true, loopWait = 14},
		{name = 'Talib', idTable = zincOreIDs, tableType = 'Zinc Ore', loopable = true, loopWait = 3},
		{name = 'Nanaa Mihgo', idTable = yagudoNecklaceIDs, tableType = 'Yagudo Necklaces', loopable = true, loopWait = 10},
		{name = 'Yoran-Oran', idTable = mandragoraMadIDs, tableType = 'Mandragora Mad Items', loopable = true, loopWait = 8},
		{name = 'Melyon', idTable = onlyTheBestIDs, tableType = 'Only the Best Items', loopable = true, loopWait = 10},
		{name = 'Sanraku', idTable = soulPlateIDs, tableType = 'Soul Plates', loopable = true, loopWait = 10},
		{name = 'A.M.A.N. Reclaimer', idTable = jseCapeIDs, tableType = 'JSE Capes', loopable = true, loopWait = 6},
		{name = 'Makel-Pakel', idTable = jseCapeIDs, tableType = 'JSE Capes x3', loopable = false, loopWait = 0},
		{name = 'Sagheera', idTable = ancientBeastcoinIDs, tableType = 'Ancient Beastcoins', loopable = true, loopWait = 3},
		{name = 'Oseem', idTable = reisenjimaStones, tableType = 'Reisenjima Stones', loopable = true, loopWait = 5},
		{name = 'Odyssean Passage', idTable = befouledWaterIDs, tableType = 'Befouled Water', loopable = false, loopWait = 10},
		{name = 'Affi', idTable = geasFeteZitahIDs, tableType = "Geas Fete Zi'Tah Items", loopable = false, loopWait = 0},
		{name = 'Dremi', idTable = geasFeteRuaunIDs, tableType = "Geas Fete Ru'Aun Items", loopable = false, loopWait = 0},
		{name = 'Shiftrix', idTable = geasFeteReisenjimaIDs, tableType = "Geas Fete Reisenjima Items", loopable = false, loopWait = 0},
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
			loopCount = 0
			return
		end
	end

	for i = 1, #npcTable do
		if target.name == npcTable[i].name then
			idTable = npcTable[i].idTable
			tableType = npcTable[i].tableType
			loopable = npcTable[i].loopable
			loopWait = npcTable[i].loopWait
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
		lastLoopNPC = ''
		loopCount = 0
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
	if arg == 'all' and mogCase and mogSack then
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
					windower.add_to_chat(4, 'QuickTrade: Please wait - Using Itemizer to transfer ' .. mogSackTable[i].count + mogCaseTable[i].count .. ' ' .. mogSackTable[i].name .. ' to inventory')
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

			if loopModeSet then
				if lastLoopNPC == '' then
					lastLoopNPC = target.name
				else
					print('New NPC detected after trade loop started. Aborting to prevent accidental trades.')
					loopCount = 0
					return
				end
			end

			local mogCount = 0

			for i = 1, #mogSackTable do
				mogCount = mogCount + mogSackTable[i].count + mogCaseTable[i].count
			end
			
			if mogCount > 0 then
				windower.add_to_chat(4, 'QuickTrade: ' .. mogCount .. ' of these items are in your mog sack/case. Type "//qtr all" if you wish to move them into your inventory and trade them. Requires Itemizer')
			end
		end
	end

	-- Read the player inventory
	inventory = windower.ffxi.get_items('inventory')

	if not inventory then
		print('QuickTrade: Unable to read inventory')
		loopCount = 0
		return
	end

	if tableType == 'Special Gobbiedial Keys' and inventory.count == inventory.max then
		windower.add_to_chat(4, 'QuickTrade: Inventory full. Cancelling Special Gobbiedial Key Trades.')
		loopCount = 0
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
	elseif tableType == 'Mandragora Mad Items' or tableType == 'JSE Capes' or tableType == 'Special Gobbiedial Keys' or tableType == 'Soul Plates' then -- 1 at a time
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
	--elseif tableType == 'Special Gobbiedial Keys' or tableType == 'Soul Plates' then
	--	numTrades = idTable[1].count
	elseif tableType == 'Reisenjima Stones' then -- Can trade all types at once
		numTrades = math.ceil((idTable[1].stacks + idTable[2].stacks + idTable[3].stacks) / 8)
	elseif tableType == "Geas Fete Zi'Tah Items" or tableType == "Geas Fete Ru'Aun Items" or tableType == "Geas Fete Reisenjima Items" then
		for i = 1, #idTable do
			if idTable[i].count >= idTable[i].minimum then
				print(idTable[i].count .. ' ' .. idTable[i].name)
				numTrades = numTrades + math.floor(idTable[i].count / idTable[i].minimum)
			end
		end
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
		local tradeList = ''
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
						availableTradeSlots = math.max(0, availableTradeSlots - idTable[i].stacks)
					else
						break
					end
				end
			end
		elseif tableType == "Geas Fete Zi'Tah Items" or tableType == "Geas Fete Ru'Aun Items" or tableType == "Geas Fete Reisenjima Items" then
			for i = 1, #idTable do
				if idTable[i].count >= idTable[i].minimum then
					tradeString = '//tradenpc ' .. idTable[i].minimum .. ' "' .. idTable[i].name .. '"'
					tradeList = idTable[i].minimum .. ' ' .. idTable[i].name
					break
				end
			end
		else
			for i = 1, #idTable do
				loopable = true -- May not work for everything

				tradeString = '//tradenpc '
				availableTradeSlots = 8
				
				if idTable[i].count > 0 then
					tradeString = tradeString .. math.min(availableTradeSlots * idTable[i].stacksize, idTable[i].count) .. ' "' .. idTable[i].name .. '"'
					break
				end
			end
		end

		if tradeString ~= '//tradenpc ' then
			if loopModeSet and loopable then
				loopCount = numTrades

				if loopMax ~= 100000 then
					numTrades = loopMax - loopCurrent + 1
					loopText = ' Loop: ' .. loopCurrent .. '/' .. loopMax
				else
					loopMax = numTrades
					loopText = ' Loop: ' .. loopCurrent .. '/' .. numTrades
				end
			else
				loopCount = 0
				loopText = ''
			end

			if numTrades - 1 == 0 then
				windower.add_to_chat(4, 'QuickTrade: Trading Complete.' .. loopText)
			elseif numTrades - 1 == 1 then
				windower.add_to_chat(4, 'QuickTrade: ' .. (numTrades - 1) .. ' trade remaining.' .. loopText)
			else
				windower.add_to_chat(4, 'QuickTrade: ' .. (numTrades - 1) .. ' trades remaining.' .. loopText)
			end
			
			if exampleOnly then
				print(tradeString)
			else
				if tableType ~= 'JSE Capes' and tableType ~= 'JSE Capes x3' and not string.find(tableType, 'Geas Fete') then
					textSkipTimer = os.time()
				end
				
				windower.send_command('input ' .. tradeString)
			end

			if string.find(tableType, 'Geas Fete') then
				windower.add_to_chat(4, 'QuickTrade: Trading '.. tradeList)
				windower.add_to_chat(4, "QuickTrade: Don't forget your Tribulens or Radialens!")
			end

			if loopModeSet then
				loopCount = loopCount - 1
			end
		end
	else
		if arg == 'all' then
			windower.add_to_chat(4, "QuickTrade - No " .. tableType .. " in inventory, mog case, or mog sack")
		else
			windower.add_to_chat(4, "QuickTrade - No " .. tableType .. " in inventory")
		end

		loopCount = 0
		loopModeSet = false
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