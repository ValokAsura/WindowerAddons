--[[

	Many thanks to Ryan Skeldon, the creator of the Grimoire addon, and Ivaar, the creator of the Skillchains addon
	This code borrows elements and concepts from each addon but is heavily modified.

]]

_addon.version = '2.0.0'
_addon.name = 'Magic Assistant'
_addon.author = 'Valok@Asura'
_addon.commands = {'magicassistant', 'maa'}

require('coroutine')
require('tables')
require('strings')
res = require('resources')
--spells = res.spells

packets = require('packets')

--require('pack')
skills = require('skills')
validSCMessageIDs = S{2,110,161,162,185,187,317}

textBox = {}

-- // User-adjustable settings
debug_exampleOnly = false -- Setting this to true will prevent all /maa macros from actually casting spells!!!
debug_user = false
debug_dev = false

ignoreWeather = false
ignoreDay = false

showTimers = false -- Create and delete custom timers using the timers plugin

textBox_enabled = true -- Show moveable, pop-up text box with skillchain information
skillchainsToShow = 1
textBox_showTimer = true
textBox_showSkillchain = true
textBox_showTargetName = true

showSkillchainInChatWindow = false -- Private notification
chatColor = 11

partyAnnounce = false -- Announce the skillchain in party chat when it occurs
partyAnnounceFuckups = false
partyCall = false -- Add a call to the party announcement
callNumber = 20 -- Specify the call number

gearswapInstalled = true
gearswapNotify = false -- gs c MAABurst
-- Sends a command to gearswap that you can use to instruct gearswap to perform a certain action, such as equipping magic burst gear
-- Examples:
-- A Fusion skillchain will send:  MAABurst LightFire
-- A Darkness skillchain will send: MAABurst DarkEarthWaterIce
-- A Scission skil

mobOverrides = false
-- Experimental
-- Can prevent you from bursting Water on a crab if you could burst something better
-- Causes a FORCED spell on an elemental to cast the strongest element it is weakest to

sidegradeBeforeDowngrade = false
-- Experimental
-- Will cast other elemental nukes in the same tier if the skillchain allows it, instead of casting lower tiers of the primary element.

napMode = false -- auto MB when afk. Not implemented yet

maxPostSkillchainBurstTime = 8
--postSkillchainInterruptWindow = 2
-- // End User-adjustable settings

activeSkillchain = {}
target = nil
skillchainTargets = {}

frameTime = 0

main_job = ''
merits = {}
jp_spent = {}

if callNumber < 1 or callNumber > 20 then
	callNumber = 20
end



-- GUI STUFF ///////////////////////
config = require('config')
texts = require('texts')
file = require('files')
require('luau') -- needed?

display = {}
display.pos = {}
display.pos.x = 400
display.pos.y = 500
display.text = {}
display.text.font = 'Courier New'
display.text.size = 15
display.flags = {}
display.flags.bold = true
display.flags.draggable = true
display.bg = {}
display.bg.alpha = 255

elementColor = {}
elementColor.Earth =   '\\cs(153,  76,   0)'
elementColor.Wind =    '\\cs(102, 255, 102)'
elementColor.Water =   '\\cs(  0, 102, 255)'
elementColor.Fire =    '\\cs(255, 102, 102)'
elementColor.Ice =     '\\cs(  0, 255, 255)'
elementColor.Lightning = '\\cs(255,   0, 255)'
elementColor.Light =   '\\cs(255, 255, 255)'
elementColor.Dark =    '\\cs(  0,   0, 180)'

display.textColors = {}
display.textColors.White =   '\\cs(222, 222, 222)'
display.textColors.Gray =    '\\cs(128, 128, 128)'
display.textColors.Black =   '\\cs(  0,   0,   0)'
display.textColors.Green =   '\\cs(  0, 255,   0)'
display.textColors.Yellow =  '\\cs(255, 255,   0)'
display.textColors.Orange =  '\\cs(255, 165,   0)'
display.textColors.Red =     '\\cs(255,   0,   0)'
display.textColors.Light = elementColor.Wind ..'L' .. elementColor.Fire .. 'i' .. elementColor.Lightning .. 'gh' .. elementColor.Light .. 't'
display.textColors.Darkness = elementColor.Earth .. 'Da' .. elementColor.Water .. 'rk' .. elementColor.Ice .. 'ne' .. elementColor.Dark .. 'ss'
display.textColors.Gravitation = elementColor.Earth .. 'Gravi' .. elementColor.Dark .. 'tation'
display.textColors.Fragmentation = elementColor.Wind .. 'Fragmen' .. elementColor.Lightning .. 'tation'
display.textColors.Distortion = elementColor.Water .. 'Disto' .. elementColor.Ice .. 'rtion'
display.textColors.Fusion = elementColor.Fire .. 'Fus' .. elementColor.Light .. 'ion'
display.textColors.Compression = elementColor.Dark .. 'Compression'
display.textColors.Liquefaction = elementColor.Fire .. 'Liquefaction'
display.textColors.Induration = elementColor.Ice .. 'Induration'
display.textColors.Reverberation = elementColor.Water .. 'Reverberation'
display.textColors.Transfixion = elementColor.Light .. 'Transfixion'
display.textColors.Scission = elementColor.Earth .. 'Scission'
display.textColors.Detonation = elementColor.Wind .. 'Detonation'
display.textColors.Impaction = elementColor.Lightning .. 'Impaction'
display.textColors.Radiance = elementColor.Wind ..'Ra' .. elementColor.Fire .. 'di' .. elementColor.Lightning .. 'an' .. elementColor.Light .. 'ce'
display.textColors.Umbra = elementColor.Earth .. 'U' .. elementColor.Water .. 'm' .. elementColor.Ice .. 'br' .. elementColor.Dark .. 'a'

settings = config.load(display)
settings:save()

skillchainsInProgress = 0
displayTextSetup = ''

if textBox_enabled and (textBox_showTimer or textBox_showSkillchain or textBox_showTargetName) then
	for i = 1, skillchainsToShow do
		if i > 1 then displayTextSetup = displayTextSetup .. '\n' end

		if textBox_showTimer then
			displayTextSetup = displayTextSetup .. ' ${SC' .. i .. 'TimeRemaining} '
		end

		if textBox_showSkillchain then
			if textBox_showTimer then
				displayTextSetup = displayTextSetup .. '${SC' .. i .. 'Name} '
			else
				displayTextSetup = displayTextSetup .. ' ${SC' .. i .. 'Name} '
			end
		end

		if textBox_showTargetName then
			if textBox_showSkillchain then
				displayTextSetup = displayTextSetup .. '${SC' .. i .. 'TargetName} '
			else
				if textBox_showTimer then
					displayTextSetup = displayTextSetup .. '${SC' .. i .. 'TargetName} '
				else
					displayTextSetup = displayTextSetup .. ' ${SC' .. i .. 'TargetName} '
				end
			end	
		end
	end
end

textBox = texts.new(displayTextSetup, settings)
if textBox_enabled then textBox:show() end

math.randomseed(os.time())

windower.register_event('addon command', function(...)
	for i = 1, #arg do
		arg[i] = string.lower(arg[i])
	end

	activeSkillchain = nil

	if #arg == 0 then

	elseif arg[1] == 'help' then

	elseif arg[1] == 'dev' then
		local rand = math.random(0, 14)

		if rand <= 12 then
			rand = 288 + rand
		else
			if rand == 13 then
				rand = 767
			else
				rand = 768
			end
		end

		--print('Random SC: ' .. skillchains[rand].english)

		skillchainTargets[windower.ffxi.get_mob_by_target('t').id] = {index = windower.ffxi.get_mob_by_target('t').index, name = windower.ffxi.get_mob_by_target('t').name, skillchain = 288, startTime = os.clock()}
		windower.send_command('maa mb spell 4')
		return
	elseif arg[1] == 'ex' then
		if textBox_enabled then skillchainTargets[12345] = {index = 130, name = 'TestName', skillchain = 289, startTime = os.clock()} end
	elseif #arg == 2 or (#arg == 3 and arg[1] ~= 'mb' and arg[1] ~= 'force') then
		if #arg == 2 then
			arg[3] = 't'
		end

		if not T(validMacroTargets):contains(arg[3]) then
			print('MAA: Invalid Target. Valid options: me, t, bt, ht, ft, st, stpc, stpt, stal, stnpc, lastst, r, pet, scan, p#, a#')
		elseif not T({1, 2, 3, 4, 5, 6}):contains(tonumber(arg[2])) then
			print('MAA: Invalid Tier. Valid options: 1, 2, 3, 4, 5, 6')
		else
			downgradeSpell(arg[1], tonumber(arg[2]), arg[3], false)
		end
	elseif (arg[1] == 'mb' or arg[1] == 'force') and #arg == 3 or #arg == 4 then
		if not T({'spell', 'helix', 'ga', 'ja', 'ra', 'nin'}):contains(arg[2]) then
			print('MAA: Invalid Spelltype. Valid options: spell, helix, ga, ja, ra, nin')
		elseif not T({1, 2, 3, 4, 5, 6}):contains(tonumber(arg[3])) then
			print('MAA: Invalid Tier. Valid options: 1, 2, 3, 4, 5, 6')
		else
			if #arg == 3 then
				arg[4] = 't'
			end

			if not T(validMBMacroTargets):contains(arg[4]) then
				print('MAA: Invalid Target. Valid options: t, bt, ht, scan')
			else
				if arg[1] == 'force' then
					if not activeSkillchain then
						activeSkillchain = anyNuke
					end

					MBOrBestOffer(arg[2], tonumber(arg[3]), true, arg[4])
				else
					target = windower.ffxi.get_mob_by_target(arg[4])

					if target and skillchainTargets[target.id] then
						activeSkillchain = skillchains[skillchainTargets[target.id].skillchain]
						MBOrBestOffer(arg[2], tonumber(arg[3]), false, arg[4])
					else
						print('MAA: No Skillchain detected on taret. MB Aborted')
					end
				end
			end
		end
	else
		local badCommand = 'maa '

		for i = 1, #arg do
			badCommand = badCommand .. arg[i] .. ' '
		end

		print('MAA: Invalid Command: ' .. badCommand)
	end

	local receivedCommand = 'maa '

	for i = 1, #arg do
		receivedCommand = receivedCommand .. arg[i] .. ' '
	end

	--if debug_dev then print('MAA: Final Command Received: Args: ' .. #arg .. ' Cmd: ' .. receivedCommand) end
end)

function updateDisplay()
	local skillchainCount = 1
	local timerColor = {}
	local tempArray = {}
	local tempArrayCount = 0

	for k, v in pairs(skillchainTargets) do
		tempArrayCount = tempArrayCount + 1
		table.insert(tempArray, skillchainTargets[k].startTime)
	end

	table.sort(tempArray)

	local i, o = 1, #tempArray

	while i < o do
		tempArray[i], tempArray[o] = tempArray[o], tempArray[i]

		i = i + 1
		o = o - 1
	end

	for i = #tempArray, 1, -1 do
		for k, v in pairs(skillchainTargets) do
			if skillchainTargets[k].startTime == tempArray[i] then
				timerColor = {red = 0, blue = 0, green = 0}

				timeElapsed = os.clock() - skillchainTargets[k].startTime

				if maxPostSkillchainBurstTime - timeElapsed > .75 * maxPostSkillchainBurstTime then -- Green to Yellow  0, 255, 0 - 255, 255, 0
					timerColor.red = 255 - round(255 * (1 - (4 - ((maxPostSkillchainBurstTime - timeElapsed) / (maxPostSkillchainBurstTime / 4)))), 0)
					timerColor.green = 255
					timerColor.blue = 0
				elseif maxPostSkillchainBurstTime - timeElapsed > .5 * maxPostSkillchainBurstTime then -- Yellow to Orange  255, 255, 0 - 255, 165, 0
					timerColor.red = 255
					timerColor.green = 165 + round(90 * (1 - (3 - ((maxPostSkillchainBurstTime - timeElapsed) / (maxPostSkillchainBurstTime / 4)))), 0)
					timerColor.blue = 0
				elseif maxPostSkillchainBurstTime - timeElapsed > .25 * maxPostSkillchainBurstTime then -- Orange to Red  255, 165, 0 - 255, 0, 0
					timerColor.red = 255
					timerColor.green = round(165 * (1 - (2 - ((maxPostSkillchainBurstTime - timeElapsed) / (maxPostSkillchainBurstTime / 4)))), 0)
					timerColor.blue = 0
				elseif maxPostSkillchainBurstTime - timeElapsed > 0 * maxPostSkillchainBurstTime then -- Red to Black  255, 0 0, - 0, 0, 0
					timerColor.red = round(255 * (1 - (1 - ((maxPostSkillchainBurstTime - timeElapsed) / (maxPostSkillchainBurstTime / 4)))), 0)
					timerColor.green = 0
					timerColor.blue = 0
				end

				timerColor = '\\cs('.. timerColor.red .. ', ' .. timerColor.green .. ', ' .. timerColor.blue .. ')'

				if textBox_showTimer then textBox['SC' .. skillchainCount .. 'TimeRemaining'] = timerColor .. string.format("%2.1f", maxPostSkillchainBurstTime - (os.clock() - skillchainTargets[k].startTime)) end
				if textBox_showSkillchain then textBox['SC' .. skillchainCount .. 'Name'] = display.textColors[skillchains[skillchainTargets[k].skillchain].english] end
				if textBox_showTargetName then textBox['SC' .. skillchainCount .. 'TargetName'] = display.textColors.Gray ..  skillchainTargets[k].name end
				textBox:show()

				skillchainCount = skillchainCount + 1
				if skillchainCount > skillchainsToShow then break end
			end
		end
	end
end

function downgradeSpell(spell_original, maxTier, targ, isMagicBurst, spell_selectedType)
	if debug_user then print('downgradeSpell: ' .. spell_original) end
	local tiers = spellTiers

	if not isValidSpell(spell_original) then
		if T(ninjutsu):contains(string.lower(spell_original)) then
			tiers = ninjutsuTiers
		else
			print('MAA: Invalid Spell: ' .. spell_original)
			return
		end
	end

	maxTier = math.min(maxTier, #tiers)
	local spellToCast = find_spell_by_name(spell_original .. tiers[maxTier])

	while not spellToCast and maxTier > 0 do
		maxTier = maxTier - 1
		if debug_dev then print('Checking if Valid: ' .. spell_original .. tiers[maxTier]) end
		spellToCast = find_spell_by_name(spell_original .. tiers[maxTier])
	end

	if not spellToCast then
		print('MAA: Invalid Spell: ' .. spell_original)
		return
	else
		if debug_user then print('First Valid Spell: ' .. spellToCast.english) end
	end

	local player = windower.ffxi.get_player()
	local player_spells = windower.ffxi.get_spells()
	local recasts = windower.ffxi.get_spell_recasts()
	local tierTable = {}
	local spellBase = string.lower(string.mgsub(spell_original, "%s.+", ""))
	local spellSuccess = false

	main_job = string.lower(windower.ffxi.get_player().main_job)
	merits = windower.ffxi.get_player().merits
	jp_spent = windower.ffxi.get_player().job_points[main_job].jp_spent

	--[[
	if spellToCast.type == 'Ninjutsu' then
		if spellToCast.english:endswith("San") then
			tierTable = {': San', ': Ni', ': Ichi'}
		elseif spellToCast.english:endswith("Ni") then
			tierTable = {': Ni', ': Ichi'}
		else
			tierTable = {': Ichi'}
		end
	else
		if spellToCast.english:endswith(" VI") then
			tierTable = {" VI", " V", " IV", " III", " II", ""}
		elseif spellToCast.english:endswith(" V") then
			tierTable = {" V", " IV", " III", " II", ""}
		elseif spellToCast.english:endswith(" IV") then
			tierTable = {" IV", " III", " II", ""}
		elseif spellToCast.english:endswith(" III") then
			tierTable = {" III", " II", ""}
		elseif spellToCast.english:endswith(" II") then
			tierTable = {" II", ""}
		else
			tierTable = {""}
		end
	end
]]

	if spellToCast.type == 'Ninjutsu' then
		if spellToCast.english:endswith("San") then
			tierTable = {': Ichi', ': Ni', ': San'}
		elseif spellToCast.english:endswith("Ni") then
			tierTable = {': Ichi', ': Ni'}
		else
			tierTable = {': Ichi'}
		end
	else
		if spellToCast.english:endswith(" VI") then
			tierTable = {"", " II", " III", " IV", " V", " VI"}
		elseif spellToCast.english:endswith(" V") then
			tierTable = {"", " II", " III", " IV", " V"}
		elseif spellToCast.english:endswith(" IV") then
			tierTable = {"", " II", " III", " IV"}
		elseif spellToCast.english:endswith(" III") then
			tierTable = {"", " II", " III"}
		elseif spellToCast.english:endswith(" II") then
			tierTable = {"", " II"}
		else
			tierTable = {""}
		end
	end

	if isMagicBurst and sidegradeBeforeDowngrade and activeSkillchain and activeSkillchain.english ~= 'AnyElement' then
		for i = #tierTable, 1, -1 do
			if debug_dev then print('Tier Search: ' .. i) end
			for o = 1, #spell_priorities do
				if debug_dev then print('Priority Search: ' .. spell_priorities[o]) end
				if T(activeSkillchain.elements):contains(spell_priorities[o]) and elements[spell_priorities[o]][spell_selectedType] then
					if debug_dev then print('Spell Priority Found: Attempting ' .. spell_priorities[o] .. tierTable[i]) end
					spellToCast = find_spell_by_name(elements[spell_priorities[o]][spell_selectedType] .. tierTable[i])

--[[
					if spellIsCastable(spellToCast) then
						if debug_exampleOnly then
							print('MAA: Command: /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
						else
							windower.send_command('input /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
						end
		
						spellSuccess = true
						break
					end
]]
end
					
					if spellToCast then
						if debug_dev then print(spellToCast.english .. ' is valid. Checking castability') end
						if recasts[spellToCast.recast_id] == 0 and -- Spell is off cooldown
								spellToCast.mp_cost <= player.vitals.mp and -- player has enough MP
								((spellToCast.levels[player.main_job_id] and spellToCast.levels[player.main_job_id] <= player.main_job_level) or -- main job is high enough to cast it
								(spellToCast.levels[player.sub_job_id] and spellToCast.levels[player.sub_job_id] <= player.sub_job_level) or -- sub job is high enough to cast it
								spellUnlocked(spellToCast.english)) and -- player has unlocked it through job or merit points
								player_spells[spellToCast.id] then -- the player has learned the spell. IGNORES JOB!
									
							if debug_exampleOnly then
								print('MAA: Command: /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
							else
								windower.send_command('input /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
							end
		
							spellSuccess = true
							break
						end

						if debug_dev then print(spellToCast.english .. ' is unavailable') end
					end
					
			end
		
			if spellSuccess then break end
		end
	else
		for i = #tierTable, 1, -1 do
			spellToCast = find_spell_by_name(spellBase .. tierTable[i])
--[[
			if spellIsCastable(spellToCast) then
				if debug_exampleOnly then
					print('MAA: Command: /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
				else
					windower.send_command('input /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
				end

				spellSuccess = true
				break
			end
]]



			
			if spellToCast then
				if recasts[spellToCast.recast_id] == 0 and -- Spell is off cooldown
						spellToCast.mp_cost <= player.vitals.mp and -- player has enough MP
						((spellToCast.levels[player.main_job_id] and spellToCast.levels[player.main_job_id] <= player.main_job_level) or -- main job is high enough to cast it
						(spellToCast.levels[player.sub_job_id] and spellToCast.levels[player.sub_job_id] <= player.sub_job_level) or -- sub job is high enough to cast it
						spellUnlocked(spellToCast.english)) and -- player has unlocked it through job or merit points
						player_spells[spellToCast.id] then -- the player has learned the spell. IGNORES JOB!
							
					if debug_exampleOnly then
						print('MAA: Command: /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
					else
						windower.send_command('input /ma "' .. spellToCast.english .. '" <' .. targ .. '>')
					end

					spellSuccess = true
					break
				end
			end
			
		end
	end

	if not spellSuccess and debug_user then
		if recasts[spellToCast.recast_id] ~= 0 then
			windower.add_to_chat(4, 'MAA: All ' .. spellBase .. ' spells on cooldown.')
		elseif spellToCast.mp_cost > player.vitals.mp then
			windower.add_to_chat(4, 'MAA: Not enough MP to cast ' .. spellBase .. '.')
		elseif not spellToCast.levels[player.main_job_id] and not spellToCast.levels[player.sub_job_id] then
			windower.add_to_chat(4, 'MAA: ' .. player.main_job .. '/' .. player.sub_job .. ' cannot cast ' .. spellBase .. '.')
		elseif spellToCast.levels[player.main_job_id] and spellToCast.levels[player.main_job_id] > player.main_job_level then
			windower.add_to_chat(4, 'MAA: Job not high enough to cast ' .. spellBase .. '.')
		elseif not spellToCast.levels[player.sub_job_id] or spellToCast.levels[player.sub_job_id] > player.sub_job_level then
			windower.add_to_chat(4, 'MAA: Subjob not high enough to cast ' .. spellBase .. '.')
		elseif not player_spells[spellToCast.id] then
			windower.add_to_chat(4, 'You have not learned, or your job cannot cast, ' .. spellBase)
		elseif not spellUnlocked(spellToCast.english) then
			windower.add_to_chat(4, 'MAA: Not merited or not enough job points to unlock ' .. spellBase .. '.')
		else
			windower.add_to_chat(4, 'MAA: ' .. spellBase .. ' failed for an unknown reason.')
		end
	end
end

function buildSidegradeTable(weather_element, day_element, skillchain_element, spell_selectedTier)
	local spellList = {}

	for i = 1, #spell_priorities do
		if T(activeSkillchain.elements):contains(spell_priorities[i]) then
			spellList[spell_priorities[i]] = spell_priorities[i]
			print('Adding ' .. spell_priorities[i])
		end
	end
end

function spellUnlocked(spellName)
	if jobPointUnlocks[main_job] and jobPointUnlocks[main_job][spellName] and jobPointUnlocks[main_job][spellName] <= jp_spent then
		return true
	else
		for k, v in pairs(merits) do
			if meritUnlocks[main_job] and meritUnlocks[main_job][k] then
				if v ~= 0 then
					return true
				end
			end
		end
	end

	return false
end

function spellIsCastable(spell)
	if spell then
		if recasts[spell.recast_id] == 0 and -- Spell is off cooldown
			spell.mp_cost <= player.vitals.mp and -- player has enough MP
			((spell.levels[player.main_job_id] and spell.levels[player.main_job_id] <= player.main_job_level) or -- main job is high enough to cast it
			(spell.levels[player.sub_job_id] and spell.levels[player.sub_job_id] <= player.sub_job_level) or -- sub job is high enough to cast it
			spellUnlocked(spell.english)) and -- player has unlocked it through job or merit points
			player_spells[spell.id] then -- the player has learned the spell. IGNORES JOB!

			return true
		end
	end

	return false
end

function MBOrBestOffer(spell_selectedType, spell_selectedTier, forced, targ)
	local weather_element = nil
	local day_element = nil
	local priority_element = nil
	local skillchain_element = nil
	local spellToCast = nil
	local player = windower.ffxi.get_player()
	local buff_name = ''
	local tiers = spellTiers

	if spell_selectedType == 'nin' then
		tiers = ninjutsuTiers
	end

	spell_selectedTier = math.min(spell_selectedTier, #tiers)

	-- Get weather. SCH Weather buff takes priority
	if #player.buffs > 0 then
		for i = 1, #player.buffs do
			buff_name = res.buffs[player.buffs[i]].name

			for o = 1, #storms do
				if buff_name == storms[o].name then
					weather_element = storms[o].weather
					if debug_user then print('SCH Weather Buff Found: ' .. weather_element) end
					break
				end
			end

			if weather_element then
				break
			end
		end
	end
	
	if not weather_element then
		weather_element = res.elements[res.weather[windower.ffxi.get_info().weather].element].en
		if debug_user then print('Weather Found: ' .. weather_element) end
	end

	-- Get day element
	local day_element = res.elements[res.days[windower.ffxi.get_info().day].element].en

	if not day_element then
		if debug_dev then print('day_element is nil') end
	else

		if debug_user then print('Day Found: ' .. day_element) end
	end

	-- Determine which benefits the spell most; Weather, day, or priority
	if (not ignoreWeather or forced) and weather_element and T(activeSkillchain.elements):contains(weather_element) then
		skillchain_element = weather_element
		if debug_user then print('Bursting weather element: ' .. skillchain_element) end
	elseif (not ignoreDay or forced) and day_element ~= nil and elements[day_element][spell_selectedType] and T(activeSkillchain.elements):contains(day_element) then
		skillchain_element = day_element
		if debug_user then print('Bursting day element: ' .. skillchain_element) end
	else -- If weather or day provide no benefit, just go by priority
		for i = 1, #spell_priorities do
			if T(activeSkillchain.elements):contains(spell_priorities[i]) then
				skillchain_element = spell_priorities[i]
				if debug_user then print('Bursting priority element: ' .. skillchain_element) end
				break
			end
		end
	end

	if not skillchain_element then
		print('MAA: No skillchain_element found for ' .. activeSkillchain.english)
		return
	end

	sidegradeTable = {}
	sidegradeTable[6] = {}
	sidegradeTable[5] = {}
	sidegradeTable[4] = {}
	sidegradeTable[3] = {}
	sidegradeTable[2] = {}
	sidegradeTable[1] = {}

	if sidegradeBeforeDowngrade then
		for i = 1, #spell_priorities do
			for o = spell_selectedTier, 1, -1 do
				if T(activeSkillchain.elements):contains(spell_priorities[i]) then
					sidegradeTable[o][string.lower(spell_priorities[i])] = true
				end
			end
		end
	end

	skillchain_element = mobOverrides(skillchain_element, forced)
	
	if elements[skillchain_element][spell_selectedType] then
		spellToCast = elements[skillchain_element][spell_selectedType] .. tiers[spell_selectedTier]
	end
	
	if spellToCast then
		if debug_user then print('MAA: Spell Suggestion: ' .. spellToCast) end

		if gearswapInstalled and gearswapNotify and activeSkillchain.english ~= 'AnyElement' then
			local tempElements = ''

			for i = 1, #activeSkillchain.elements do
				tempElements = tempElements .. activeSkillchain.elements[i]
			end

			windower.send_command('gs c MAABurst ' .. tempElements)
		end

		if activeSkillchain.english ~= 'AnyElement' then
			downgradeSpell(elements[skillchain_element][spell_selectedType], spell_selectedTier, targ, true, spell_selectedType)
		else
			downgradeSpell(elements[skillchain_element][spell_selectedType], spell_selectedTier, targ, false, spell_selectedType)
		end
	else
		print('MAA: No valid or useful spell for ' .. skillchain_element)
	end
end

function mobOverrides(skillchain_element, forced, target)
	if not mobOverrides or not target then return skillchain_element end

	if debug_dev then print('Target: ' .. target.name) end

	if target.name:contains(' Crab') and skillchain_element == 'Water' and (activeSkillchain.skillchain.english == 'Distortion' or activeSkillchain.skillchain.english == 'Darkness' or forced) then
		if debug_dev then print('Water detected on crab: Changing to Ice') end
		return 'Ice'
	elseif target.name:contains(' Elemental') then
		if forced then
			if debug_dev then print(skillchain_element .. ' forced on ' .. skillchain_element .. ' Elemental. Changing to weakness') end
			
			if target.name == 'Air Elemental' then
				target.name = 'Wind Elemental'
			end

			return spell_strengths[string.sub(target.name, 1, string.find(target.name, ' ') - 1)].weakness
		else

		end
	end

	return skillchain_element
end

windower.register_event('incoming chunk', function(id, orig)
	if id == 0x28 then
		local packet = windower.packets.parse_action(orig)

		if not T({3, 4, 11, 13, 14, 20}):contains(packet.category) then -- Valid categories, according to Skillchains addon: 3, 4, 11, 13, 14, 20
			return
		elseif #packet.targets ~= 1 then
			return
		end

		if T({110, 161, 162, 187, 317}):contains(packet.targets[1].actions[1].message) then -- 2 seems to be just a normal spell cast?
			if debug_dev then print('MAA: Unknown msg = ' .. packet.targets[1].actions[1].message) end
		end

		if validSCMessageIDs[packet.targets[1].actions[1].message] then  -- 185 is WS hit, not sure what the others are. This should be something that can either open or close a skillchain
			local packet_skillchainID = packet.targets[1].actions[1].add_effect_message
			local packet_target = windower.ffxi.get_mob_by_id(packet.targets[1].id)

			local ability = skills[packet.category] and skills[packet.category][packet.param]



			

			if ability then
				ability = ability.en
			else
				ability = 'Unknown'
				--if debug_dev then print('Unknown ability: ' .. packet.category .. ' : ' .. packet.param) end
				return -- SINCE SKILLS DOES NOT HAVE ALL SKILLS, THIS IS NOT 100% SUCCESSFUL. EXAMPLE: GILGAMESH'S UNKNOWN WEAPONSKILL
			end

			if packet_skillchainID ~= 0 then -- If an ability hit that closes a skillchain, add_effect_message will contain the skillchain ID
				if skillchainTargets[packet_target.id] then -- Check the table to see if there is already an active on the target. Replace it if so, add it if not
					--if debug_dev then print('Active skillchain on target. Updating skillchainTargets') end
					if showTimers then windower.send_command('timers d "' .. skillchains[skillchainTargets[packet_target.id].skillchain].english .. ': ' .. skillchainTargets[packet_target.id].name .. '"') end
					--skillchainTargets[packet_target.id] = {name = packet_target.name, skillchain = packet_skillchainID, startTime = os.clock()}
					skillchainTargets[packet_target.id].skillchain = packet_skillchainID
					skillchainTargets[packet_target.id].startTime = os.clock()
				else
					--if debug_dev then print('Adding skillchain to skillchainTargets') end
					skillchainTargets[packet_target.id] = {index = packet_target.index, name = packet_target.name, skillchain = packet_skillchainID, startTime = os.clock()}
				end

				if partyAnnounce then
					if partyCall then
						windower.send_command('input /party Skillchain: ' .. skillchains[skillchainTargets[packet_target.id].skillchain].english .. '!  <call' .. callNumber .. '>')
					else
						windower.send_command('input /party Skillchain: ' .. skillchains[skillchainTargets[packet_target.id].skillchain].english .. '!')
					end
				elseif showSkillchainInChatWindow then
					windower.add_to_chat(chatColor, 'MAA Skillchain: ' .. skillchains[skillchainTargets[packet_target.id].skillchain].english)
				elseif debug_user then
					print('MAA: Skillchain on ' .. packet_target.id)
				end

				if showTimers then windower.send_command('timers c "' .. skillchains[skillchainTargets[packet_target.id].skillchain].english .. ': ' .. skillchainTargets[packet_target.id].name .. '" ' .. maxPostSkillchainBurstTime .. ' down') end
			elseif packet_skillchainID == 0 and skillchainTargets[packet_target.id] then -- If an ability hits that does not close a skillchain. This includes skillchain openers and weaponskills that mess up the magic burst
				
				-- Normal spells are ending skillchains.  Skills[4] contains normal spells. Commented them out for testing



				if os.clock() - skillchainTargets[packet_target.id].startTime < 2 then -- Check if the SC was interrupted withing X seconds after the SC.
					local actor = windower.ffxi.get_mob_by_id(packet.actor_id)
						if actor then
						if partyAnnounceFuckups then
							if partyCall then
								windower.send_command('input /party ' .. actor.name .. ' fucked the MB by using ' .. ability .. ' <call5>')
							else
								windower.send_command('input /party ' .. actor.name .. ' fucked the MB by using ' .. ability)
							end
						elseif showSkillchainInChatWindow then
							windower.add_to_chat(8, actor.name .. ' fucked the MB by using ' .. ability)
						elseif debug_user then
							print('MAA: Magic burst fucked by ' .. actor.name .. ' with ' .. ability)
						end
					end
				end

				print(ability)
				
				if showTimers then windower.send_command('timers d "' .. skillchains[skillchainTargets[packet_target.id].skillchain].english .. ': ' .. skillchainTargets[packet_target.id].name .. '"') end
				if debug_dev then print('Removing skillchain from ' .. skillchainTargets[packet_target.id].name) end
				skillchainTargets[packet_target.id] = nil
			end
		end
	end
end)

windower.register_event('prerender',function()
	local clock = os.clock()

	if os.clock() - frameTime >= 0.1 then
		frameTime = clock
		local skillchainsActive = 0

		for k, v in pairs(skillchainTargets) do
			skillchainsActive = skillchainsActive + 1

			if os.clock() - skillchainTargets[k].startTime >= maxPostSkillchainBurstTime then
				if debug_dev then print('Skillchain on ' .. skillchainTargets[k].name .. ' ID: ' .. k .. ' has expired.') end
				skillchainTargets[k] = nil
			end
		end
		
		if textBox_enabled then
			for i = skillchainsActive + 1, skillchainsToShow do
				if textBox_showTimer then textBox['SC' .. i .. 'TimeRemaining'] = '' end
				if textBox_showSkillchain then textBox['SC' .. i .. 'Name'] = '' end
				if textBox_showTargetName then textBox['SC' .. i .. 'TargetName'] = '' end
			end

			if skillchainsActive > 0 then
				updateDisplay()
			else
				textBox:hide()
			end
		end
	end
end)

function isValidSpell(spellName)
	for i = 1, #res.spells do
		if res.spells[i] then
			if string.lower(spellName) == string.lower(res.spells[i].en) and res.spells[i].type ~= 'Trust' and res.spells[i].type ~= 'SummonerPact' then
				return true
			end
		end
	end

	return false
end

function spellReadyToUse(spellname)
	local cooldowns = windower.ffxi.get_spell_recasts()
	
	if cooldowns[find_spell_recast_id_by_name(spellname)] == 0 then
		return true
	end

	return false
end

function find_spell_recast_id_by_name(spellname)
    for spell in res.spells:it() do
        if spell['english']:lower() == spellname:lower() then
            return spell['recast_id']
        end
	end
	
    return nil
end

function find_spell_by_name(spellname)
	for spell in res.spells:it() do
		if spell['english']:lower() == spellname:lower() then
            return spell
        end
	end
	
    return nil
end

function round(num, numDecimalPlaces)
	if numDecimalPlaces and numDecimalPlaces > 0 then
	  local mult = 10 ^ numDecimalPlaces

	  return math.floor(num * mult + 0.5) / mult
	end

	return math.floor(num + 0.5)
end

function dump(o)   -- print a table to console  :   print(dump(table))
	if type(o) == 'table' then
		local s = '{ '

		for k, v in pairs(o) do
			if type(k) ~= 'number' then k = '"' .. k .. '"' end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

windower.register_event('incoming text', function(original, modified, mode)
	if string.find(original, 'Kefkaesque starts casting Warp II on Valok.') then
		modified = 'Kefkaesque starts casting BANANASHITFUCK on Valok. Oh dear.'
		return modified
	elseif string.find(original, 'Kefkaesque starts casting Warp on Kefkaesque.') then
		modified = 'Kefkaesque starts Warping away. Goodbye, Kefka!'
		return modified
	end
end)

jobPointUnlocks = {
	blm = {
		['Stone VI'] = 100,
		['Water VI'] = 100,
		['Aero VI'] = 100,
		['Fire VI'] = 100,
		['Blizzard VI'] = 100,
		['Thunder VI'] = 100,
		['Aspir III'] = 550,
		['Death'] = 1200,
	},

	rdm = {
		['Stone V'] = 100,
		['Water V'] = 100,
		['Aero V'] = 100,
		['Fire V'] = 100,
		['Blizzard V'] = 100,
		['Thunder V'] = 100,
		['Addle II'] = 550,
		['Distract III'] = 550,
		['Frazzle III'] = 550,
		['Refresh III'] = 1200,
		['Temper II'] = 1200,
	},

	drk = {
		['Drain III'] = 550,
	},

	nin = {
		['Utsusemi: San'] = 100,
	},

	sch = {
		['Geohelix II'] = 1200,
		['Hydrohelix II'] = 1200,
		['Anemohelix II'] = 1200,
		['Pyrohelix II'] = 1200,
		['Cryohelix II'] = 1200,
		['Ionohelix II'] = 1200,
		['Noctohelix II'] = 1200,
		['Luminohelix II'] = 1200,
	},

	geo = {
		['Stone V'] = 100,
		['Water V'] = 100,
		['Aero V'] = 100,
		['Fire V'] = 100,
		['Blizzard V'] = 100,
		['Thunder V'] = 100,
		['Aspir III'] = 550,
		['Stonera III'] = 1200,
		['Watera III'] = 1200,
		['Aera III'] = 1200,
		['Fira III'] = 1200,
		['Blizzara III'] = 1200,
		['Thundara III'] = 1200,
	},
}

meritUnlocks = {
	blm = {
		['quake_ii'] = {name = 'Quake II'},
		['burst_ii'] = {name = 'Burst II'},
		['freeze_ii'] = {name = 'Freeze II'},
		['flare_ii'] = {name = 'Flare II'},
		['tornado_ii'] = {name = 'Tornado II'},
		['flood_ii'] = {name = 'Flood II'},
	},

	rdm = {
		['slow_ii'] = {name = 'Slow II'},
		['phalanx_ii'] = {name = 'Phalanx II'},
		['dia_iii'] = {name = 'Dia III'},
		['paralyze_ii'] = {name = 'Paralyze II'},
		['bio_iii'] = {name = 'Bio III'},
		['blind_ii'] = {name = 'Blind II'},
	},

	nin = {
		['hyoton_san']  = {name = 'Hyoton: San'},
		['huton_san'] = {name = 'Huton: San'},
		['katon_san'] = {name = 'Katon: San'},
		['doton_san'] = {name = 'Doton: San'},
		['raiton_san'] = {name = 'Raiton: San'},
		['suiton_san'] = {name = 'Suiton: San'},
	}
}

spellTiers = {
	[1] = '',
	[2] = ' II',
	[3] = ' III',
	[4] = ' IV',
	[5] = ' V',
	[6] = ' VI',
}

ninjutsuTiers = {
	[1] = ': Ichi',
	[2] = ': Ni',
	[3] = ': San',
}

ninjutsu = {
	'tonko',
	'utsusemi',
	'katon',
	'suiton',
	'doton',
	'hyoton',
	'huton',
	'raiton',
	'kurayami',
	'hojo',
	'monomi',
	'dokumori',
	'jubaku',
	'aisha',
	'yurin',
	'myoshu',
	'migawari',
	'gekko',
	'yain',
	'kakka',
}

skillchains = { -- Radiance and Umbra untested
	[288] = {english = 'Light', elements = {'Lightning', 'Fire', 'Wind', 'Light'}},
	[289] = {english = 'Darkness', elements = {'Ice', 'Water', 'Earth', 'Dark'}},
	[290] = {english = 'Gravitation', elements = {'Earth', 'Dark'}},
	[291] = {english = 'Fragmentation', elements = {'Lightning', 'Wind'}},
	[292] = {english = 'Distortion', elements = {'Ice', 'Water'}},
	[293] = {english = 'Fusion', elements = {'Fire', 'Light'}},
	[294] = {english = 'Compression', elements = {'Dark'}},
	[295] = {english = 'Liquefaction', elements = {'Fire'}},
	[296] = {english = 'Induration', elements = {'Ice'}},
	[297] = {english = 'Reverberation', elements = {'Water'}},
	[298] = {english = 'Transfixion', elements = {'Light'}},
	[299] = {english = 'Scission', elements = {'Earth'}},
	[300] = {english = 'Detonation', elements = {'Wind'}},
	[301] = {english = 'Impaction', elements = {'Lightning'}},
	[767] = {english = 'Radiance', elements = {'Lightning', 'Fire', 'Wind', 'Light'}},
	[768] = {english = 'Umbra', elements = {'Ice', 'Water', 'Earth', 'Dark'}},
}

anyNuke = {
	english = 'AnyElement', elements = {'Lightning', 'Ice', 'Fire', 'Wind', 'Water', 'Earth'}
}

spell_priorities = {
	'Lightning',
	'Ice',
	'Fire',
	'Wind',
	'Water',
	'Earth',
	'Dark',
	'Light',
}

spell_strengths = {
	['Fire'] = {weakness = 'Water'},
	['Ice'] = {weakness = 'Fire'},
	['Wind'] = {weakness = 'Ice'},
	['Earth'] = {weakness = 'Wind'},
	['Lightning'] = {weakness = 'Earth'},
	['Water'] = {weakness = 'Lightning'},
	['Dark'] = {weakness = 'Lightning'},
	['Light'] = {weakness = 'Ice'},
}

storms = { 
	{name = 'Firestorm', weather = 'Fire'}, 
	{name = 'Hailstorm', weather = 'Ice'}, 
	{name = 'Windstorm', weather = 'Wind'}, 
	{name = 'Sandstorm', weather = 'Earth'}, 
	{name = 'Thunderstorm', weather = 'Lightning'}, 
	{name = 'Rainstorm', weather = 'Water'}, 
	{name = 'Aurorastorm', weather = 'Light'}, 
	{name = 'Voidstorm', weather = 'Dark'},
}

elements = {
	['Lightning'] = {spell = 'Thunder', helix = 'Ionohelix', ga = 'Thundaga', ja = 'Thundaja', ra = 'Thundara', nin = 'Raiton'},
	['Ice'] = {spell = 'Blizzard', helix = 'Cryohelix', ga = 'Blizzaga', ja = 'Blizzaja', ra = 'Blizzara', nin = 'Hyoton'},
	['Fire'] = {spell = 'Fire', helix = 'Pyrohelix', ga = 'Firaga', ja = 'Firaja', ra = 'Fira', nin = 'Katon'},
	['Wind'] = {spell = 'Aero', helix = 'Anemohelix', ga = 'Aeroga', ja = 'Aeroja', ra = 'Aera', nin = 'Huton'},
	['Water'] = {spell = 'Water', helix = 'Hydrohelix', ga = 'Waterga', ja = 'Waterja', ra = 'Watera', nin = 'Suiton'},
	['Earth'] = {spell = 'Stone', helix = 'Geohelix', ga = 'Stonega', ja = 'Stoneja', ra = 'Stonera', nin = 'Doton'},
	['Dark'] = {spell = nil, helix = 'Noctohelix', ga = nil, ja = nil, ra = nil, nin = nil},
	['Light'] = {spell = nil, helix = 'Luminohelix', ga = nil, ja = nil, ra = nil, nin = nil},
}

validMBMacroTargets = {
	't', 'bt', 'ht', 'scan'
}

validMacroTargets = {
	'me', 't', 'bt', 'ht', 'ft', 'st', 'stpc', 'stpt', 'stal', 'stnpc', 'lastst', 'r', 'pet', 'scan',
	'p0', 'p1', 'p2', 'p3', 'p4', 'p5',
	'a10', 'a11', 'a12', 'a13', 'a14', 'a15',
	'a20', 'a21', 'a22', 'a23', 'a24', 'a25',
}

--[[
		--print('----- Packet Dump Start ------')
		--print(dump(packet))
		--print('Category: ' .. packet.category)
		--print('Actor ID: ' .. packet.actor_id)
		--print('Param: ' .. packet.param)
		--print('Ability: ' .. ability.en)
		--print('Target ID: ' .. packet.targets[1].id) -- if there is only 1 target
		--print('Message: ' .. packet.targets[1].actions[1].message) -- if there is only 1 target
		--print('------Packet Dump End ------')
]]