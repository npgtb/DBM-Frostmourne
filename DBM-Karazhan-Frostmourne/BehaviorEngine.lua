--Shared utility namespace for the DBM_Karazhan_Frostmourne module
DBM_BEHAVIOR = DBM_BEHAVIOR or {}

--Common flag for a disabled timer
DBM_BEHAVIOR.TIMER_DISABLED = 0
DBM_BEHAVIOR.SPELL_UNKOWN_ID = 0

--Possible difficulties
DBM_BEHAVIOR.DIFFICULTY = {
	NORMAL_10 = "normal10",
	NORMAL_25 = "normal25",
	HEROIC_10 = "heroic10",
	HEROIC_25 = "heroic25"
}

--Support boss phases upto 9
DBM_BEHAVIOR.PHASES = {
	PHASE_ONE = 1,	
	PHASE_TWO = 2,
	PHASE_THREE = 3,
	PHASE_FOUR = 4,
	PHASE_FIVE = 5,
	PHASE_SIX = 6,
	PHASE_SEVEN = 7,
	PHASE_EIGHT = 8,
	PHASE_NINE = 9
}

--Define some warning types for the behavior system
DBM_BEHAVIOR.WARNING_TYPE = {
	NewSpecialWarningDispel = "NewSpecialWarningDispel",
	NewSpecialWarningGTFO = "NewSpecialWarningGTFO",
	NewSpecialWarningYou = "NewSpecialWarningYou",
	NewSpecialWarningStack = "NewSpecialWarningStack",
	NewSpecialWarningLookAway = "NewSpecialWarningLookAway",
	NewSpecialWarningInterruptCount = "NewSpecialWarningInterruptCount",
	NewSpecialWarningMove = "NewSpecialWarningMove",
	NewSpecialWarning = "NewSpecialWarning",
	NewSpellAnnounce = "NewSpellAnnounce",
	NewSpecialWarningDefensive = "NewSpecialWarningDefensive"
}

--Define some warning default parameters for the behavior system
DBM_BEHAVIOR.WARNING_CREATION_ARG_ORDER = {"text", "spell_id", "filter", "a", "threshold", "b", "c", "sound", "icon"}
DBM_BEHAVIOR.WARNING_DEFAULT_PARAMS = {
    NewSpecialWarningDispel = { spell_id = "", filter = "RemoveDisease", a = false, b = false, sound = 1, icon = 2 },
    NewSpecialWarningGTFO = { spell_id = "", a = false, b = false, c = false, sound = 1, icon = 8 },
    NewSpecialWarningYou = { spell_id = "", a = false, b = false, c = false, sound = 1, icon = 2 },
    NewSpecialWarningStack = { spell_id = "", a = false, threshold = 1, b = false, c = false, sound = 1, icon = 6 },
    NewSpecialWarningLookAway = { spell_id = "", a = false, b = false, c = false, sound = 1, icon = 2 },
    NewSpecialWarningInterruptCount = { spell_id = "", filter = "HasInterrupt", b = false, c = false, sound = 1, icon = 2 },
    NewSpecialWarningMove = { spell_id = "", a = false, b = false, c = false, sound = 1, icon = 2 },
	NewSpecialWarning = { text = "", a = false, b = false, c = false, sound = 1, icon = 2 },
    NewSpellAnnounce = { spell_id = "", a = 3, b = false, filter = "" },
	NewSpecialWarningDefensive = {spell_id = "", a = false, b = false, c = false, icon = 1, sound = 2}
}

--Define timer types for the behavior system
DBM_BEHAVIOR.TIMER_TYPE = {
	NewCDTimer = "NewCDTimer",
	NewBerserkTimer = "NewBerserkTimer"
}
--Define some warning default parameters for the behavior system
DBM_BEHAVIOR.TIMER_CREATION_ARG_ORDER = {"default_timing", "spell_id", "a", "b", "c", "icon"}
DBM_BEHAVIOR.TIMER_DEFAULT_PARAMS = {
    NewCDTimer = {default_timing = DBM_BEHAVIOR.TIMER_DISABLED, spell_id = "", a = false, b = false, c = false, icon = 2},
	NewBerserkTimer = {default_timing = DBM_BEHAVIOR.TIMER_DISABLED}
}

DBM_BEHAVIOR.HANDLE_CATEGORIES = {"TIMER_STARTS", "SCAN_TRIGGER", "WARNING_SHOW", "PLAY_SOUND"}
--This table is for immidiate use, do not ever cache it
DBM_BEHAVIOR.EVENT_REUSE_TABLE = {}

--Known events fired internally start patterns
DBM_BEHAVIOR.INTERNAL_EVENTS = {
	ON_COMBAT_START = false, 
	ON_SCAN = false,
	PHASE_START_1 = false,
	PHASE_START_2 = false,
	PHASE_START_3 = false,
	PHASE_START_4 = false,
	PHASE_START_5 = false,
	PHASE_START_6 = false,
	PHASE_START_7 = false,
	PHASE_START_8 = false,
	PHASE_START_9 = false,
	MANUAL_CAST_MONITOR = false
}

--Phase announcment sounds
DBM_BEHAVIOR.PHASE_ANNOUNCMENT_SOUND = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = "pone",
	[DBM_BEHAVIOR.PHASES.PHASE_TWO] = "ptwo",
	[DBM_BEHAVIOR.PHASES.PHASE_THREE] = "pthree",
	[DBM_BEHAVIOR.PHASES.PHASE_FOUR] = "pfour",
	[DBM_BEHAVIOR.PHASES.PHASE_FIVE] = "pfive",
	[DBM_BEHAVIOR.PHASES.PHASE_SIX] = "psix",
	[DBM_BEHAVIOR.PHASES.PHASE_SEVEN] = "pseven",
	[DBM_BEHAVIOR.PHASES.PHASE_EIGHT] = "peight",
	[DBM_BEHAVIOR.PHASES.PHASE_NINE] = "pnine",
}

--Give the update types ids
DBM_BEHAVIOR.UPDATE_SUBTYPE = {
	TIMER = 1,
	WARNING = 2,
	PLAY = 3
}

--Tie together the default arguments and behavior arguments
local function MakeBehaviourArgs(event, behavior_table, default_parameters, arg_order)
	local args = {}
	--Define like this so lua respects the ordering
	for _, name in ipairs(arg_order) do
		--Check if the call takes that argumetn
		if default_parameters[name] ~= nil then
			--Check if the default is overriden in behavior
			if behavior_table[name] ~= nil then
				table.insert(args, behavior_table[name])
			--Use the default value
			else
				table.insert(args, default_parameters[name])
			end
		end
	end
	return args
end

--Tries to create a warning based on the given behavior table
local function TryCreateDbmWarning(spell_behavior, spell_id, boss_mod)
	local engine = DBM_BEHAVIOR
	local warning = spell_behavior.WARNING
	--Check the datas existence
	if warning ~= nil then
		local warning_type = warning.type
		local method = engine.WARNING_TYPE[warning_type]
		--Check type and methods existence ([nil]==nil)
		if method ~= nil then
			--Create the warning args, set the spell_id override
			warning.spell_id = spell_id
			local creation_args = MakeBehaviourArgs(
				warning_type, warning, 
				engine.WARNING_DEFAULT_PARAMS[warning_type], engine.WARNING_CREATION_ARG_ORDER
			)
			--Create the warning
			warning.DBM = boss_mod[method](boss_mod, unpack(creation_args))
		end
	end
end

--Tries to create a timer based on the given behavior table
local function TryCreateDbmTimer(spell_behavior, spell_id, boss_mod)
	local engine = DBM_BEHAVIOR
	local timer = spell_behavior.TIMER
	--Check the datas existence
	if timer ~= nil then
		local timer_type = timer.type
		local method = engine.TIMER_TYPE[timer_type]
		--Check type and methods existence ([nil]==nil)
		if method ~= nil then
			--Create the timer args, set the spell_id override
			timer.spell_id = spell_id
			local creation_args = MakeBehaviourArgs(
				timer_type, timer, 
				engine.TIMER_DEFAULT_PARAMS[timer_type], engine.TIMER_CREATION_ARG_ORDER
			)
			--Create the timer
			timer.DBM = boss_mod[method](boss_mod, unpack(creation_args))
		end
	end
end

--Take the event argumentation and normalize them into one format
local function NormalizeArgumentation(event, ...)
	local args = ...
	if type(args) == "table" then
		return args
	end
	local _, event, _, destGUID, destName, _, spellId, spellName, spellSchool, amount = ...
	--3.3.5 LUA runs on single thread. This table is for immidiate use and not cached
	local reuse_table = DBM_BEHAVIOR.EVENT_REUSE_TABLE
	reuse_table.event = event
	reuse_table.destGUID = destGUID
	reuse_table.destName = destName
	reuse_table.amount = amount
	reuse_table.spellId = spellId
	reuse_table.spellName = spellName
	reuse_table.spellSchool = spellSchool
	return reuse_table
end

--Append handler functions to the dbm mod
local function AppendHandlers(spell_behavior, spell_id, boss_mod)
	local engine = DBM_BEHAVIOR
	local utility = DBM_KFU
	local handle_categories = engine.HANDLE_CATEGORIES
	local internal_events = engine.INTERNAL_EVENTS
	local encounter_spells = boss_mod.SPELLS
	--Run trough each handle containing category
	for _, category_name in ipairs(handle_categories) do
		local category = spell_behavior[category_name]
		if category ~= nil then
			--If we have the handle category in data, go trough it
			for trigger_name, trigger_data in pairs(category) do
				local internal_event_lookup = internal_events[trigger_name]
				--If internal event not blocked and boss mod doesnt have existing handle
				if boss_mod[trigger_name] == nil and internal_event_lookup ~= false then
					--Attach handlers to boss mod, capture trigger name as the events name
					local event_name = trigger_name
					boss_mod[event_name] = function(self, ...)
						local args = NormalizeArgumentation(event_name, ...)
						engine.HandleModelUpdate(args.spellId, event_name, self, args)
					end
				end
				--Special case manual cast monitor
				if trigger_name == "MANUAL_CAST_MONITOR" and encounter_spells ~= nil then
					--Store the spell
					boss_mod.cast_monitor_spells = boss_mod.cast_monitor_spells or {}
					boss_mod.cast_monitor_spells[utility.SolveSpellName(encounter_spells, spell_id)] = true
				--BossTargetscan function
				elseif trigger_name == "ON_SCAN" then
					local spell_scan_func = "ON_SCAN" .. spell_id
					--Attach the scan function to the boss_mod as requried by dbm
					boss_mod[spell_scan_func] = function(self, target_name)
						if target_name == self.player_name then
							engine.HandleModelUpdate(spell_id, "ON_SCAN", self, {destName = target_name})
						end
					end
				end
			end
		end
	end
end

-- Register events automatically based on the behavior definitions
local function RegisterSpellEvents(boss_mod)
	local registration_needs = {}
	local engine = DBM_BEHAVIOR
	local utility = DBM_KFU
	local internal_events = engine.INTERNAL_EVENTS
	local handle_categories = engine.HANDLE_CATEGORIES
	local behavior_model = boss_mod.BEHAVIOR

	--Run trough the behavior model and pick out events and spell ids tied to them
	for spell_id, spell_behavior in pairs(behavior_model) do
		--Go trough each category holding events
		for _, category_name in ipairs(handle_categories) do
			local category = spell_behavior[category_name]
			if category ~= nil then
				--Go trough the categories events
				for event, _ in pairs(category) do
					--Has boss mod handle and is not internal event
					if boss_mod[event] ~= nil and internal_events[event] == nil then
						--Note the need to register the spell for the event
						registration_needs[event] = registration_needs[event] or {}
						table.insert(registration_needs[event], spell_id)
					end
				end
			end
		end
	end
	--Generate registration strings
	local registration_strings = {}
	for event, spell_ids  in pairs(registration_needs) do
		table.insert(registration_strings, utility.EventString(event, unpack(spell_ids)))
	end
	--Register everything to DBM in one go
	boss_mod:RegisterEventsInCombat(unpack(registration_strings))
end

--Create the boss model from the given behavior table
function DBM_BEHAVIOR.CreateBossModel(boss_mod)
	--Check if we can find data to create the model
	if boss_mod ~= nil then
		local behavior_model = boss_mod.BEHAVIOR
		if behavior_model ~= nil then
			-- Loop trough per spell trough the behaviors table
			for spell_id, spell_behavior in pairs(behavior_model) do
				--Create warnings
				TryCreateDbmWarning(spell_behavior, spell_id, boss_mod)
				--Create timers
				TryCreateDbmTimer(spell_behavior, spell_id, boss_mod)
				--Append default behaviors
				AppendHandlers(spell_behavior, spell_id, boss_mod)
			end
			--Register combat events
			RegisterSpellEvents(boss_mod)
		end
	end
end

--Handle any triggering of timers
local function HandleTimerUpdate(spell_id, behavior, event, boss_mod, args)
	local timer_data = behavior.TIMER
	local utility = DBM_KFU
	local start_events = behavior.TIMER_STARTS
	--Do we have a timer data?
	if timer_data ~= nil and start_events~= nil then
		local timer = timer_data.DBM
		local trigger_data = start_events[event]
		--Do we have timer and data for this event?
		if timer ~= nil and trigger_data ~= nil then
			--Has a override func been defined
			if trigger_data.override ~= nil then
				trigger_data.override(boss_mod, trigger_data, timer, args)
			--Accept the judgement of a condition func
			elseif 
				trigger_data.condition == nil or
				trigger_data.condition(boss_mod, args, spell_id, DBM_BEHAVIOR.UPDATE_SUBTYPE.TIMER)
			then
				local injection = args[trigger_data.inject] or 0
				--Try starting the timer
				utility.TryStartTimer(
					timer,
					utility.GetTiming(boss_mod.TIMINGS, boss_mod.difficulty, boss_mod.phase, spell_id, event),
					injection
				)
			end
		end
	end
end

--Handle any triggering of warnings
local function HandleWarningUpdate(spell_id, behavior, event, boss_mod, args)
	local warning_data = behavior.WARNING
	local show_events = behavior.WARNING_SHOW
	--Do we have warning data?
	if warning_data ~= nil and show_events ~= nil then
		local trigger_data = show_events[event]
		local warning = warning_data.DBM
		--Do we have dbm and data for this event
		if warning ~= nil and trigger_data ~= nil then
			--Has a override func been defined
			if trigger_data.override ~= nil then
				trigger_data.override(boss_mod, trigger_data, warning, args)
			--Accept the judgement of a condition func
			elseif 
				trigger_data.condition == nil or
				trigger_data.condition(boss_mod, args, spell_id, DBM_BEHAVIOR.UPDATE_SUBTYPE.WARNING)
			then
				--Show warning
				local injection = args[trigger_data.inject]
				warning:Show(injection)
			end
		end
	end
end

--Handle any triggering of sounds
local function HandlePlayUpdate(spell_id, behavior, event, boss_mod, args)
	local warning_data = behavior.WARNING
	local play_events = behavior.PLAY_SOUND
	--Do we have ability to play sound and event data
	if warning_data ~= nil and play_events ~= nil then
		local warning = warning_data.DBM
		local trigger_data = play_events[event]
		--Do we have warning, data for this event and a sound file to play?
		if warning ~= nil and trigger_data ~= nil then
			local sound_id = trigger_data.sound
			if sound_id ~= nil then
				--Has a override func been defined
				if trigger_data.override ~= nil then
					trigger_data.override(boss_mod, trigger_data, warning, args)
				--Accept the judgement of a condition func
				elseif 
					trigger_data.condition == nil or
					trigger_data.condition(boss_mod, args, spell_id, DBM_BEHAVIOR.UPDATE_SUBTYPE.PLAY)
				then
					--Play the warning
					warning:Play(sound_id)
				end
			end
		end
	end
end

--Handle any triggering of sounds
local function HandleScanTrigger(spell_id, behavior, event, boss_mod, args)
	local scan_event_id = "ON_SCAN"
	local scan_triggers = behavior.SCAN_TRIGGER
	local source_guid = args.sourceGUID
	local engine = DBM_BEHAVIOR
	local scan_frequency = 0.25
	local scan_attempts = 15
	--Never loop and check if we have needed data
	if event ~= scan_event_id and scan_triggers ~= nil and source_guid ~= nil then
		local trigger_data = scan_triggers[event]
		--Check if we have indeed hit a event that requries scanning
		if trigger_data ~= nil then
			--Let behaviour override these if wanted
			scan_frequency = trigger_data.frequency or scan_frequency
			scan_attempts = trigger_data.scan_attempts or scan_attempts
			--Append spell scan func
			local spell_scan_func = scan_event_id .. spell_id
			--Start scanning
			boss_mod:BossTargetScanner(source_guid, spell_scan_func, scan_frequency, scan_attempts)
		end
	end
end

--Handle boss model update
function DBM_BEHAVIOR.HandleModelUpdate(spell_id, event, boss_mod, args)
	--Do we have a behavior defined for this spell?
	local behavior = boss_mod.BEHAVIOR[spell_id]
	if behavior ~= nil then
		HandleTimerUpdate(spell_id, behavior, event, boss_mod, args)
		HandleWarningUpdate(spell_id, behavior, event, boss_mod, args)
		HandlePlayUpdate(spell_id, behavior, event, boss_mod, args)
		HandleScanTrigger(spell_id, behavior, event, boss_mod, args)
	end
end

--Handle model event
function DBM_BEHAVIOR.HandleModelEvent(event, boss_mod, args)
	for spell_id, _ in pairs(boss_mod.BEHAVIOR) do
		DBM_BEHAVIOR.HandleModelUpdate(spell_id, event, boss_mod, args)
	end
end

--Create phase warnings for possible phases
local function CreatePhaseWarnings(boss_mod, max_phases)
	boss_mod.phase_warnings = {}
	local max_warnings = max_phases - 1
	--create max_phases-1 transit soon warnings
	for phase_id = 1, max_warnings do
		boss_mod.phase_warnings[phase_id] = boss_mod:NewPrePhaseAnnounce(phase_id + 1)
	end
end

--Initialize the phase monitoring system
function DBM_BEHAVIOR.InitPhaseMonitor(boss_mod, boss_unit, max_phases)
	--Check that we have the required data
	if boss_mod.PHASE_TRANSITION_THRESHOLDS ~= nil then
		--Store boss unit id and create phase warnings
		boss_mod.boss_unit_id = boss_unit
		boss_mod.phase_warning_triggerd = false
		CreatePhaseWarnings(boss_mod, max_phases)
		--Create the phase announcer
		boss_mod.phase_announcer = boss_mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
		--Append the health functions to the boss mod
		if boss_mod.UNIT_HEALTH == nil then
			boss_mod.UNIT_HEALTH = function(self, uId)
				if uId == self.boss_unit_id then
					local utility = DBM_KFU
					local engine = DBM_BEHAVIOR
					local health_percentage = utility.GetUnitHealthPercentage(uId)
					if health_percentage then
						engine.ShouldTransitionPhase(self, health_percentage)
					end
				end
			end
		end
	end
end

--Stop monitoring the phase changes
function DBM_BEHAVIOR.StopPhaseMonitor(boss_mod)
	--Stop the manual health monitor
	if boss_mod.boss_health_monitor then
		boss_mod.boss_health_monitor:Cancel()
	end
end

--Starts the phase monitor
function DBM_BEHAVIOR.StartPhaseMonitor(boss_mod)
	--Required data exists?
	if boss_mod.PHASE_TRANSITION_THRESHOLDS ~= nil then
		local utility = DBM_KFU
		local engine = DBM_BEHAVIOR
		--If boss boss unit does not exists, the UNIT_HEALTH events wont fire
		if not UnitExists(boss_mod.boss_unit_id) then
			print("Monitoring boss health manually")
			--Work around the issue by doing manual health monitoring
			boss_mod.boss_health_monitor = utility.MonitorBossHealth(
				boss_mod.creatureId, function(health) engine.ShouldTransitionPhase(boss_mod, health) end
			)
		else
			--If boss unit exists we prefer to use the DBM system, register us to it
			boss_mod:RegisterShortTermEvents(
				utility.EventString("UNIT_HEALTH", boss_mod.boss_unit_id)
			)
		end
	end
end

--Handles the logic of warning and transiting the phases
function DBM_BEHAVIOR.ShouldTransitionPhase(boss_mod, boss_health)
	local utility = DBM_KFU
	local engine = DBM_BEHAVIOR
	local treshold_table = boss_mod.PHASE_TRANSITION_THRESHOLDS
	--Based on the current phase, check if we should transition to the next phase
	if treshold_table ~= nil then
		--Get the phase specific section
		local transition_table = utility.GetTransitionThreshold(
			treshold_table, boss_mod.difficulty, boss_mod.phase
		)
		if transition_table ~= nil then
			local phase_warning = boss_mod.phase_warnings[boss_mod.phase]
			--Should we transition the phase?
			if boss_health <= transition_table.THRESHOLD then
				engine.TransitPhase(boss_mod, transition_table.NEXT)
			--Should we give pre warning?
			elseif 
				transition_table.WARNING ~= nil and
				boss_health <= transition_table.WARNING and
				phase_warning ~= nil and
				not boss_mod.phase_warning_triggerd
			then
				boss_mod.phase_warning_triggerd = true
				phase_warning:Show()
				phase_warning:Play("nextphasesoon")
			end
		end
	end
end

--Handle the phase transitions
function DBM_BEHAVIOR.TransitPhase(boss_mod, next_phase)
	local engine = DBM_BEHAVIOR
	boss_mod.phase = next_phase
	boss_mod.phase_warning_triggerd = false
	boss_mod.phase_announcer:Play(engine.PHASE_ANNOUNCMENT_SOUND[boss_mod.phase])
	DBM_KFU.Debug("DBM_BEHAVIOR: Phase " .. boss_mod.phase)
	engine.HandleModelEvent("PHASE_START_" .. boss_mod.phase, boss_mod, {})
end

--Starts the manual spell casting monitor
function DBM_BEHAVIOR.StartSpellCastingMonitor(boss_mod)
	--Do we have spells to monitor for?
	if boss_mod.cast_monitor_spells ~= nil then
		local utility = DBM_KFU
		local engine = DBM_BEHAVIOR
		boss_mod.boss_casting_monitor = utility.MonitorBossCasting(
			boss_mod.creatureId, boss_mod.cast_monitor_spells,
			function(spell_name) 
				local spell_id = utility.SolveSpellId(boss_mod.SPELLS, spell_name)
				if spell_id ~= nil then
					engine.HandleModelUpdate(spell_id, "MANUAL_CAST_MONITOR", boss_mod, {})
				end
			end
		)
	end
end

--Stop the manual spell casting monitor
function DBM_BEHAVIOR.StopSpellCastingMonitor(boss_mod)
	--Stop the manual health monitor
	if boss_mod.boss_casting_monitor then
		boss_mod.boss_casting_monitor:Cancel()
	end
end

--Get mission critical data for the fight
function DBM_BEHAVIOR.CombatStartFetchData(boss_mod)
	boss_mod.difficulty = DBM:GetCurrentInstanceDifficulty() or DBM_BEHAVIOR.DIFFICULTY.HEROIC_25
	boss_mod.phase = DBM_BEHAVIOR.PHASES.PHASE_ONE
	boss_mod.player_name = UnitName("player")
	boss_mod.player_guid = UnitGUID("player")
end

--Common conditions, Are we a tank?
function DBM_BEHAVIOR.IsTank(boss_mod, args, spell_id, update_subtype)
	return boss_mod:IsTank()
end

--Common conditions, Are we a healer?
function DBM_BEHAVIOR.IsHealer(boss_mod, args, spell_id, update_subtype)
	return boss_mod:IsHealer()
end

--Common conditions, Are we a dps?
function DBM_BEHAVIOR.IsDps(boss_mod, args, spell_id, update_subtype)
	return boss_mod:IsDps()
end

--Common conditions, Are we either the target or source of the spell (Spells that bind two player together)
function DBM_BEHAVIOR.IsTargetOrDest(boss_mod, args, spell_id, update_subtype)
	return args.destGUID == boss_mod.player_guid or args.sourceGUID == boss_mod.player_guid
end

--Common conditions, Something happening to us
function DBM_BEHAVIOR.OnSelf(boss_mod, args, spell_id, update_subtype)
	return args.destGUID == boss_mod.player_guid
end

--Common conditions, Something happening to us
function DBM_BEHAVIOR.DestIsSelf(boss_mod, args, spell_id, update_subtype)
	return args.destName == boss_mod.player_name
end

--Common conditions, DBM antispam
function DBM_BEHAVIOR.AntiSpam(boss_mod, args, spell_id, update_subtype)
	--Key the antispam with combo of spell_id + subtype
	return boss_mod:AntiSpam(nil, (spell_id + update_subtype))
end

--Common conditions, Something happening to us and dbm antispam
function DBM_BEHAVIOR.OnSelfAntiSpam(boss_mod, args, spell_id, update_subtype)
	--Key the antispam with combo of spell_id + subtype
	return args.destGUID == boss_mod.player_guid and boss_mod:AntiSpam(nil, (spell_id + update_subtype))
end