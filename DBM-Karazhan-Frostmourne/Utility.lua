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
function DBM_KFU.StartTimer(timer_obj, timing, offset)
	if timer_obj ~= nil and type(timer_obj.Start) == "function" and timing ~= DBM_KFU.TIMER_DISABLED then
		timer_obj:Start(timing + (offset or 0))
	end
end
