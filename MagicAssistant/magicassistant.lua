_addon.version = '1.0.0'
_addon.name = 'Magic Assistant'
_addon.author = 'Valok@Asura'
_addon.commands = {'magicassistant', 'maa'}

res = require('resources')
spells = res.spells

debug = false
onlyDowngrade = true

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

spellTiers = {
	['1'] = '',
	['2'] = ' II',
	['3'] = ' III',
	['4'] = ' IV',
	['5'] = ' V',
	['6'] = ' VI',
}




windower.register_event('addon command', function(...)
	--[[

		maa base tier:  //maa Fire 5
		maa base best:  //maa Fire Best

	]]


	if #arg == 0 then -- for random testing

	end

	if #arg ~= 2 then
		print('MAA: Invalid command. Valid examples: maa Fire 4,   maa Watera 3,   maa Blizzard Best,   maa Thundaga 2')
		return
	elseif string.lower(arg[2]) ~= 'best' and not T({1, 2, 3, 4, 5, 6}):contains(tonumber(arg[2])) then
		print('MAA: Invalid Tier. Valid examples are: 1, 2, 3, 4, 5, 6, or Best')
		return
	elseif string.lower(arg[2]) == 'best' then
		downgradeSpell(arg[1], '6', false)
	else
		downgradeSpell(arg[1], arg[2], true)
	end
end)

function downgradeSpell(spell_original, maxTier, downgrade)
	--print('MAA: ' .. spell_original)
	--print(spell_original .. spellTiers[maxTier])
	--print('-------')

	local spellToCast = find_spell_by_name(spell_original .. spellTiers[maxTier])
	--local testTier = maxTier

	while not spellToCast do
		maxTier = tostring(tonumber(maxTier) - 1)
		spellToCast = find_spell_by_name(spell_original .. spellTiers[maxTier])
	end

	if not spellToCast then
		print('Invalid Spell: ' .. spell_original)
		return
	end

	local player = windower.ffxi.get_player()
	local player_spells = windower.ffxi.get_spells()
	local tierTable = {" VI", " V", " IV", " III", " II", ""} --{}
	local spellBase = string.mgsub(spell_original, "%s.+", "")
	local spellSuccess = false
	local recasts = windower.ffxi.get_spell_recasts()
	
	if downgrade then
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
				((spellToCast.levels[player.main_job_id] and spellToCast.levels[player.main_job_id] <= player.main_job_level) or -- main job is high enough to learn/cast it
				(spellToCast.levels[player.sub_job_id] and spellToCast.levels[player.sub_job_id] <= player.sub_job_level) or -- sub job is high enough to learn/cast it
				spellUnlocked(spellToCast.english)) and --then -- player has unlocked it through job points
				player_spells[spellToCast.id] then -- the player has learned the spell. IGNORES JOB!
				
				if debug then print('Casting: ' .. spellToCast.english) end
				windower.send_command('input /ma "' .. spellToCast.english .. '" <t>')
				spellSuccess = true
				break
			else
				--print(spellToCast.english)
				--print(player_spells[spellToCast.id])
			end
		else
			print('Invalid attempt: ' .. spellBase .. tierTable[i])
		end
	end

	if not spellSuccess then
		--print(spellToCast.levels[player.main_job_id])
		
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

function spellUnlocked(spellName)
	local main_job = string.lower(windower.ffxi.get_player().main_job)
	local jp_spent = windower.ffxi.get_player().job_points[main_job].jp_spent

	if tierUnlocks[main_job] and tierUnlocks[main_job][spellName] and tierUnlocks[main_job][spellName] <= jp_spent then
		return true
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