--Shared utility namespace for the DBM_Karazhan_Frostmourne module
DBM_KFU = DBM_KFU or {}

--Common flag for a disabled timer
DBM_KFU.TIMER_DISABLED = 0

--Helper to build the event string
function DBM_KFU.EventString(event_name, ...)
	--Set everything in table
	local parts = {event_name}
	for i = 1, select("#", ...) do
		table.insert(parts, tostring(select(i, ...)))
	end
	-- Concat the table
	return table.concat(parts, " ")
end

--Helper function for retrieving timers
function DBM_KFU.GetTiming(timing_table, difficulty, phase, ability)
	--Search the timing table
	if timing_table ~= nil and timing_table[difficulty] ~= nil then
		if timing_table[difficulty][phase] ~= nil then
			if timing_table[difficulty][phase][ability] ~= nil then
				return timing_table[difficulty][phase][ability]
			end
		end
	end
	--If we can't find the ability in current difficulty/phase setting then mark it as disabled
	return DBM_KFU.TIMER_DISABLED
end

--Helper function to start timers if possible, respects the DISABLED value
function DBM_KFU.TryStartTimer(timer_obj, timing, offset)
	if timer_obj ~= nil and type(timer_obj.Start) == "function" and timing ~= DBM_KFU.TIMER_DISABLED then
		timer_obj:Start(timing + (offset or 0))
	end
end

--Attempts to get the units health as a percentage of its total health
function DBM_KFU.GetUnitHealthPercentage(unit)
	local health = nil
	if UnitExists(unit) then
		health = UnitHealth(unit) / UnitHealthMax(unit) * 100
	end
	return health
end

--Attempts to get the units health as a percentage of its total health
function DBM_KFU.GetUnitCastingSpellName(unit)
	local spell_name = nil
	if UnitExists(unit) then
		--Preferably we would get the id, but 3.3.5 api doesn't allow for that
		spell_name = select(1, UnitCastingInfo(unit))
	end
	return spell_name
end

--Helper to try to find the unit of the given creature id
function DBM_KFU.FindBossUnitFromTargeting(creature_id)
	local unit_checks = { "boss1", "boss2", "boss3", "boss4", "boss5", "focus", "target"}
	for _, unit in ipairs(unit_checks) do
		if UnitExists(unit) and DBM:GetUnitCreatureId(unit) == creature_id then
			return unit
		end
	end
	return nil
end

--Manual function for polling boss health, based on timer
local function FindAndGetHealth(creature_id, storage, callback_func, max_attempts)
	max_attempts = max_attempts or 60
	if storage.unit == nil then
		storage.unit = DBM_KFU.FindBossUnitFromTargeting(creature_id)
		storage.count = (storage.count or 0) + 1
		--Check if we should cancel the search
		if storage.count > max_attempts and storage.timer_obj then
			print("Manual boss health monitoring failed!")
			storage.timer_obj:Cancel()
		end
	-- If the unit is say target, we may end up in a scenario where the unit is not the boss
	elseif DBM:GetUnitCreatureId(storage.unit) == creature_id then
		--If we have unit get its health and give it to the callback func
		local health_percentage = DBM_KFU.GetUnitHealthPercentage(storage.unit)
		if health_percentage then
			callback_func(health_percentage)
			--If boss is dead, cancel the health monitor
			if(health_percentage <= 0) then
				storage.timer_obj:Cancel()
			end
		end
	end
end

--Access point to the manual boss health monitoring
function DBM_KFU.MonitorBossHealth(creature_id, callback_func, freaquency)
	freaquency = freaquency or 0.5
	local storage = {}
	--Start timer
	storage.timer_obj = C_Timer.NewTicker(
		freaquency, 
		function()
			FindAndGetHealth(creature_id, storage, callback_func)
		end
	)
	--Return handle for the mod
	return storage.timer_obj
end

--Manually monitor what spells the boss is casting
local function FindAndMonitorCasting(creature_id, spell_names, storage, callback_func, max_attempts)
	max_attempts = max_attempts or 60
	--Try to find the unit
	if storage.unit == nil then
		storage.unit = DBM_KFU.FindBossUnitFromTargeting(creature_id)
		storage.count = (storage.count or 0) + 1
		--Check if we should cancel the search
		if storage.count > max_attempts and storage.timer_obj then
			print("Manual boss casting monitoring failed!")
			storage.timer_obj:Cancel()
		end
	-- If the unit is say target, we may end up in a scenario where the unit is not the boss
	elseif DBM:GetUnitCreatureId(storage.unit) == creature_id then
		--If we have unit get its casting info and call the callback
		local spell_name = DBM_KFU.GetUnitCastingSpellName(storage.unit)
		if spell_names and spell_names[spell_name] then
			callback_func(spell_name)
		end
	end
end

--Access point to the manual boss casting monitoring
function DBM_KFU.MonitorBossCasting(creature_id, spell_names, callback_func, freaquency)
	freaquency = freaquency or 1
	local storage = {}
	--Start timer
	storage.timer_obj = C_Timer.NewTicker(
		freaquency, 
		function()
			FindAndMonitorCasting(creature_id, spell_names, storage, callback_func)
		end
	)
	--Return handle for the mod
	return storage.timer_obj
end
