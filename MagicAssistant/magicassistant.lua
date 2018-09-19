--[[

	Many thanks to Ryan Skeldon, the creator of the addon Grimoire.
	This code borrows elements from his addon but is heavily modified.

	Need to find a way to stop the magic burst timers if someone fucks it up by using a weaponskill after the skillchain
	Incoming Text event from a party/alliance member that HITS with a weaponskill? Will this be fast enough?
	Should be able to get the player's name as well

]]

_addon.version = '1.0.0'
_addon.name = 'Magic Assistant'
_addon.author = 'Valok@Asura'
_addon.commands = {'magicassistant', 'maa'}

require('tables')
require('strings')
res = require('resources')
spells = res.spells


-- // User-adjustable settings
local debug = false
local showSkillchainInChatWindow = true -- Private notification
local targetmode = 'bt' -- t or bt. BT can be a little unreliable if your party is fighting multiple red-named mobs
-- Maybe I can get the mob ID of the mob found in the incoming chunk and compare it to the target ID when the MB command is run
-- Can possibly abort the MB if the IDs don't match

local partyAnnounce = false -- Announce the skillchain in party chat when it occurs
local partyCall = false -- Add a call to the party announcement
local callNumber = 20 -- Specify the call number

-- Sends a command to gearswap that you can use to instruct gearswap to perform a certain action, such as equipping magic burst gear
-- Examples:
-- A Fusion skillchain will send:  MAABurst LightFire
-- A Darkness skillchain will send: MAABurst DarkEarthWaterIce
-- A Scission skil
local gearswapNotify = false -- gs c MAABurst

-- Experimental
-- Can prevent you from bursting Water on a crab if you could burst something better
-- Causes a FORCED spell on an elemental to cast the strongest element it is weakest to
local manualOverrides = false

local napMode = false -- auto MB when afk. Not implemented yet

local chatColor = 20
-- // End User-adjustable settings



local activeSkillchain = nil
local activeSkillchainStartTime = 0
local main_job = ''
local merits = {}
local jp_spent = {}

if callNumber < 1 or callNumber > 20 then
	callNumber = 20
end

tierUnlocks = {
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
		['quake_ii'] = {name = 'Quake II', unlocked = false},
		['burst_ii'] = {name = 'Burst II', unlocked = false},
		['freeze_ii'] = {name = 'Freeze II', unlocked = false},
		['flare_ii'] = {name = 'Flare II', unlocked = false},
		['tornado_ii'] = {name = 'Tornado II', unlocked = false},
		['flood_ii'] = {name = 'Flood II', unlocked = false},
	},

	rdm = {
		['slow_ii'] = {name = 'Slow II', unlocked = false},
		['phalanx_ii'] = {name = 'Phalanx II', unlocked = false},
		['dia_iii'] = {name = 'Dia III', unlocked = false},
		['paralyze_ii'] = {name = 'Paralyze II', unlocked = false},
		['bio_iii'] = {name = 'Bio III', unlocked = false},
		['blind_ii'] = {name = 'Blind II', unlocked = false},
	},

	nin = {
		['hyoton_san']  = {name = 'Hyoton: San', unlocked = false},
		['huton_san'] = {name = 'Huton: San', unlocked = false},
		['katon_san'] = {name = 'Katon: San', unlocked = false},
		['doton_san'] = {name = 'Doton: San', unlocked = false},
		['raiton_san'] = {name = 'Raiton: San', unlocked = false},
		['suiton_san'] = {name = 'Suiton: San', unlocked = false},
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

local skillchains = { -- What about Radiance and Umbra?
	[288] = {english = 'Light', elements = {'Light', 'Fire', 'Thunder', 'Wind'}},
	[289] = {english = 'Darkness', elements = {'Dark', 'Earth', 'Water', 'Ice'}},
	[290] = {english = 'Gravitation', elements = {'Dark', 'Earth'}},
	[291] = {english = 'Fragmentation', elements = {'Thunder', 'Wind'}},
	[292] = {english = 'Distortion', elements = {'Water', 'Ice'}},
	[293] = {english = 'Fusion', elements = {'Light', 'Fire'}},
	[294] = {english = 'Compression', elements = {'Dark'}},
	[295] = {english = 'Liquefaction', elements = {'Fire'}},
	[296] = {english = 'Induration', elements = {'Ice'}},
	[297] = {english = 'Reverberation', elements = {'Water'}},
	[298] = {english = 'Transfixion', elements = {'Light'}},
	[299] = {english = 'Scission', elements = {'Earth'}},
	[300] = {english = 'Detonation', elements = {'Wind'}},
	[301] = {english = 'Impaction', elements = {'Thunder'}},
}

local anyNuke = {english = 'AnyElement', elements = {'Fire', 'Thunder', 'Wind', 'Earth', 'Water', 'Ice'}}

local spell_priorities = {
	'Thunder',
	'Ice',
	'Fire',
	'Wind',
	'Water',
	'Earth',
	'Dark',
	'Light',
}

local spell_strengths = {
	['Fire'] = {weakness = 'Water'},
	['Ice'] = {weakness = 'Fire'},
	['Wind'] = {weakness = 'Ice'},
	['Earth'] = {weakness = 'Wind'},
	['Thunder'] = {weakness = 'Earth'},
	['Water'] = {weakness = 'Thunder'},
	['Dark'] = {weakness = 'Thunder'},
	['Light'] = {weakness = 'Ice'},
}

local storms = { 
	{name = 'Firestorm', weather = 'Fire'}, 
	{name = 'Hailstorm', weather = 'Ice'}, 
	{name = 'Windstorm', weather = 'Wind'}, 
	{name = 'Sandstorm', weather = 'Earth'}, 
	{name = 'Thunderstorm', weather = 'Thunder'}, 
	{name = 'Rainstorm', weather = 'Water'}, 
	{name = 'Aurorastorm', weather = 'Light'}, 
	{name = 'Voidstorm', weather = 'Dark'},
}

local elements = {
	['Thunder'] = {spell = 'Thunder', helix = 'Ionohelix', ga = 'Thundaga', ja = 'Thundaja', ra = 'Thundara', nin = 'Raiton'},
	['Ice'] = {spell = 'Blizzard', helix = 'Cryohelix', ga = 'Blizzaga', ja = 'Blizzaja', ra = 'Blizzara', nin = 'Hyoton'},
	['Fire'] = {spell = 'Fire', helix = 'Pyrohelix', ga = 'Firaga', ja = 'Firaja', ra = 'Fira', nin = 'Katon'},
	['Wind'] = {spell = 'Aero', helix = 'Anemohelix', ga = 'Aeroga', ja = 'Aeroja', ra = 'Aera', nin = 'Huton'},
	['Water'] = {spell = 'Water', helix = 'Hydrohelix', ga = 'Waterga', ja = 'Waterja', ra = 'Watera', nin = 'Suiton'},
	['Earth'] = {spell = 'Stone', helix = 'Geohelix', ga = 'Stonega', ja = 'Stoneja', ra = 'Stonera', nin = 'Doton'},
	['Dark'] = {spell = nil, helix = 'Noctohelix', ga = nil, ja = nil, ra = nil, nin = nil},
	['Light'] = {spell = nil, helix = 'Luminohelix', ga = nil, ja = nil, ra = nil, nin = nil},
}

windower.register_event('addon command', function(...)
	if #arg == 0 then -- random testing
		main_job = string.lower(windower.ffxi.get_player().main_job)
		merits = windower.ffxi.get_player().merits
		jp_spent = windower.ffxi.get_player().job_points[main_job].jp_spent

		meritTest()
	elseif #arg == 2 then
		if string.lower(arg[2]) ~= 'best' and not T({1, 2, 3, 4, 5, 6}):contains(tonumber(arg[2])) then
			print('MAA: Invalid Tier. Valid examples are: 1, 2, 3, 4, 5, 6, or Best')
			return
		elseif string.lower(arg[2]) == 'best' then
			downgradeSpell(arg[1], '6')
		else
			downgradeSpell(arg[1], arg[2])
		end
	elseif #arg == 3 then
		if string.lower(arg[1]) == 'mb' then
			-- FOR TESTING
			--activeSkillchainStartTime = os.clock() - 2
			--activeSkillchain = anyNuke


			if (os.clock() - activeSkillchainStartTime > 8 or not activeSkillchain) and not forced then
				print('MAA: No Skillchain detected. MB Aborted')
				return
			elseif not T({'spell', 'helix', 'ga', 'ja', 'ra', 'nin'}):contains(arg[2]) then
				print('MAA Invalid MB Spell. Valid options: spell, helix, ga, ja, ra, nin')
				return
			elseif string.lower(arg[3]) ~= 'best' and not T({6, 5, 4, 3, 2, 1}):contains(tonumber(arg[3])) then
				print('MAA Invalid MB Tier. Valid options: 1, 2, 3, 4, 5, 6, Best')
				return
			else
				-- DO THE MAGIC BURST THING
				print('MB: ' .. arg[2] .. ' ' .. arg[3])

				if string.lower(arg[3]) ~= 'best' then
					arg[3] = tonumber(arg[3])
				end

				MBOrBestOffer(arg[2], arg[3], false)
			end
		elseif string.lower(arg[1]) == 'force' then
			if not T({'spell', 'helix', 'ga', 'ja', 'ra'}):contains(arg[2]) then
				print('MAA Invalid MB Spell. Valid options: spell, helix, ga, ja, ra, nin')
				return
			elseif string.lower(arg[3]) ~= 'best' and not T({6, 5, 4, 3, 2, 1}):contains(tonumber(arg[3])) then
				print('MAA Invalid Force Tier. Valid options: 1, 2, 3, 4, 5, 6, Best')
				return
			else
				-- DO THE FORCE THING
				print('Force: ' .. arg[2] .. ' ' .. arg[3])
				MBOrBestOffer(arg[2], arg[3], true)
			end
		end
	else
		local badCommand = 'maa '

		for i = 1, #arg do
			badCommand = badCommand .. arg[i] .. ' '
		end

		print('MAA: Invalid Command: ' .. badCommand)
	end
end)

function downgradeSpell(spell_original, maxTier)
	print('downgradeSpell: ' .. spell_original)
	local tiers = spellTiers

	if not isValidSpell(spell_original) then
		if T(ninjutsu):contains(string.lower(spell_original)) then
			tiers = ninjutsuTiers
		else
			print('Invalid Spell: ' .. spell_original)
			return
		end
	end

	maxTier = math.min(tonumber(maxTier), #tiers)
	local spellToCast = find_spell_by_name(spell_original .. tiers[maxTier])

	while not spellToCast and maxTier > 0 do
		maxTier = maxTier - 1
		print('Checking if Valid: ' .. spell_original .. tiers[maxTier])
		spellToCast = find_spell_by_name(spell_original .. tiers[maxTier])
	end

	if not spellToCast then
		print('Invalid Spell: ' .. spell_original)
		return
	else
		print('First Valid Spell: ' .. spellToCast.english)
	end

	local player = windower.ffxi.get_player()
	local player_spells = windower.ffxi.get_spells()
	local recasts = windower.ffxi.get_spell_recasts()
	local tierTable = {}
	local spellBase = string.mgsub(spell_original, "%s.+", "")
	local spellSuccess = false

	main_job = string.lower(windower.ffxi.get_player().main_job)
	merits = windower.ffxi.get_player().merits
	jp_spent = windower.ffxi.get_player().job_points[main_job].jp_spent
	
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

	for i = 1, #tierTable do
		spellToCast = find_spell_by_name(spellBase .. tierTable[i])

		if spellToCast then
			if recasts[spellToCast.recast_id] == 0 and -- Spell is off cooldown
					spellToCast.mp_cost <= player.vitals.mp and -- player has enough MP
					((spellToCast.levels[player.main_job_id] and spellToCast.levels[player.main_job_id] <= player.main_job_level) or -- main job is high enough to cast it
					(spellToCast.levels[player.sub_job_id] and spellToCast.levels[player.sub_job_id] <= player.sub_job_level) or -- sub job is high enough to cast it
					spellUnlocked(spellToCast.english)) and -- player has unlocked it through job or merit points
					player_spells[spellToCast.id] then -- the player has learned the spell. IGNORES JOB!
				
				if debug then print('Casting: ' .. spellToCast.english) end
				windower.send_command('input /ma "' .. spellToCast.english .. '" <t>')
				spellSuccess = true
				break
			end
		end
	end

	if not spellSuccess and debug then
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
			windower.add_to_chat(4, 'MAA: Not enough job points to unlock ' .. spellBase .. '.')
		else
			windower.add_to_chat(4, 'MAA: ' .. spellBase .. ' failed for an unknown reason.')
		end
	end
end

function meritTest()
	--local main_job = string.lower(windower.ffxi.get_player().main_job)
	--local merits = windower.ffxi.get_player().merits

	for k, v in pairs(merits) do
		if meritUnlocks[main_job] and meritUnlocks[main_job][k] then
			if v ~= 0 then
				meritUnlocks[main_job][k].unlocked = true
				--print(meritUnlocks[main_job][k].name .. ' is unlocked.')
			end
		end
	end
end

function spellUnlocked(spellName)
	--local main_job = string.lower(windower.ffxi.get_player().main_job)
	--local jp_spent = windower.ffxi.get_player().job_points[main_job].jp_spent

	if tierUnlocks[main_job] and tierUnlocks[main_job][spellName] and tierUnlocks[main_job][spellName] <= jp_spent then
		return true
	elseif meritUnlocks[main_job] and meritUnlocks[main_job][spellName] and meritUnlocks[main_job][spellName].unlocked then
		return true
	end

	return false
end

function MBOrBestOffer(spell_selectedType, spell_selectedTier, forced)
	if forced then
		activeSkillchain = anyNuke
	end

	local tiers = spellTiers

	if spell_selectedType == 'nin' then
		tiers = ninjutsuTiers
	end

	spell_selectedTier = math.min(tonumber(spell_selectedTier), #tiers)

	if debug then print('Skillchain: ' .. activeSkillchain.english) end

	local weather_element = nil
	local day_element = nil
	local priority_element = nil
	local skillchain_element = nil
	local spellToCast = nil
	local player = windower.ffxi.get_player()
	local buff_name = ''

	-- Get weather. SCH Weather buff takes priority
	if #player.buffs > 0 then
		for i = 1, #player.buffs do
			buff_name = res.buffs[player.buffs[i]].name

			for o = 1, #storms do
				if buff_name == storms[o].name then
					weather_element = storms[i].weather
					if debug then print('SCH Weather Buff Found: ' .. weather_element) end
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
		if debug then print('Weather Found: ' .. weather_element) end
	end

	if weather_element == 'Lightning' then
		if debug then print('Changing weather from Lightning to Thunder') end
		weather_element = 'Thunder'
	end

	-- Get day element
	local day_element = res.elements[res.days[windower.ffxi.get_info().day].element].en
	if not day_element then
		if debug then print('day_element is nil') end
	else
		if day_element == 'Lightning' then
			if debug then print('Changing day from Lightning to Thunder') end
			day_element = 'Thunder'
		end
		if debug then print('Day Found: ' .. day_element) end
	end

	-- Determine which benefits the spell most; Weather, day, or priority
	if weather_element and T(activeSkillchain.elements):contains(weather_element) then
		skillchain_element = weather_element
		if debug then print('Bursting weather element: ' .. skillchain_element) end
	elseif day_element ~= nil and elements[day_element][spell_selectedType] and T(activeSkillchain.elements):contains(day_element) then
		skillchain_element = day_element
		if debug then print('Bursting day element: ' .. skillchain_element) end
	else -- If weather or day provide no benefit, just go by priority
		for i = 1, #spell_priorities do
			if T(activeSkillchain.elements):contains(spell_priorities[i]) then
				--print(spell_priorities[i] .. ' has priority in ' .. activeSkillchain.english)
				skillchain_element = spell_priorities[i]
				if debug then print('Bursting priority element: ' .. skillchain_element) end
				break
			end
		end
	end

	if not skillchain_element then
		print('No skillchain_element found for ' .. activeSkillchain.english)
		return
	end

	skillchain_element = mobExceptions(skillchain_element, forced)
	
	if elements[skillchain_element][spell_selectedType] then
		spellToCast = elements[skillchain_element][spell_selectedType] .. tiers[spell_selectedTier]
	end
	
	if spellToCast then
		--if debug then print('Casting: ' .. spellToCast) end
		--windower.send_command('input /ma "' .. spellToCast .. '" <t>')
		downgradeSpell(elements[skillchain_element][spell_selectedType], spell_selectedTier)
	else
		print('No valid spell for ' .. skillchain_element)
	end
end

function mobExceptions(skillchain_element, forced)
	local battle_target = windower.ffxi.get_mob_by_target(targetmode)
	if debug and battle_target then print('Target: ' .. battle_target.name) end

	if not battle_target then
		return skillchain_element
	end
	
	if battle_target.name:contains(' Crab') and skillchain_element == 'Water' and (activeSkillchain.english == 'Distortion' or activeSkillchain.english == 'Darkness' or forced) then
		if debug then print('Water detected on crab: Changing to Blizzard') end
		return 'Ice'
	elseif battle_target.name:contains(' Elemental') then
		if forced then
			if debug then print(skillchain_element .. ' forced on ' .. skillchain_element .. ' Elemental. Changing to weakness') end
			
			if battle_target.name == 'Air Elemental' then
				battle_target.name = 'Wind Elemental'
			end

			return spell_strengths[string.sub(battle_target.name, 1, string.find(battle_target.name, ' ') - 1)].weakness
		else

		end
	end

	return skillchain_element
end

windower.register_event('incoming chunk', function(id, orig)
	if id == 0x28 then
		local packet = windower.packets.parse_action(orig)
		
		for _, target in pairs(packet.targets) do
			local battle_target = windower.ffxi.get_mob_by_target(targetmode)
			
			if battle_target ~= nil and target.id == battle_target.id then
				for _, action in pairs(target.actions) do
					if action.add_effect_message > 287 and action.add_effect_message < 302 then
						if os.clock() - activeSkillchainStartTime <= 8 then
							windower.send_command('timers d "MAGIC BURST: ' .. activeSkillchain.english .. '"')
						end

						activeSkillchain = skillchains[action.add_effect_message]
						activeSkillchainStartTime = os.clock()
						windower.send_command('timers c "MAGIC BURST: ' .. activeSkillchain.english .. '" 8 down')

						if gearswapNotify then
							local tempElements = ''

							for i = 1, #activeSkillchain.elements do
								if activeSkillchain.elements[i] == 'Thunder' then
									tempElements = tempElements .. 'Lightning'
								else
									tempElements = tempElements .. activeSkillchain.elements[i]
								end
							end

							windower.send_command('gs c MAABurst ' .. tempElements)
						end

						if partyAnnounce then
							if partyCall then
								windower.send_command('input /party Skillchain: ' .. activeSkillchain.english .. '!  <call' .. callNumber .. '>')
							else
								windower.send_command('input /party Skillchain: ' .. activeSkillchain.english .. '!')
							end
						end

						if showSkillchainInChatWindow then
							windower.add_to_chat(8, 'Skillchain: ' .. activeSkillchain.english)
						end
					else
						if debug then
							if action.add_effect_message > 0 then
								--print(action.add_effect_message)
							end
						end
					end
				end
			end			
		end
	end
end)

function isValidSpell(spellName)
	for i = 1, #res.spells do
		if string.lower(spellName) == string.lower(res.spells[i].name) and res.spells[i].type ~= 'Trust' and res.spells[i].type ~= 'SummonerPact' then
			return true
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
    for spell in spells:it() do
        if spell['english']:lower() == spellname:lower() then
            return spell['recast_id']
        end
	end
	
    return nil
end

function find_spell_by_name(spellname)
	for spell in spells:it() do
		if spell['english']:lower() == spellname:lower() then
            return spell
        end
	end
	
    return nil
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