--Shared utility namespace for the DBM_Karazhan_Frostmourne module
DBM_BEHAVIOR = DBM_BEHAVIOR or {}

--Common flag for a disabled timer
DBM_BEHAVIOR.TIMER_DISABLED = 0
DBM_BEHAVIOR.SPELL_UNKNOWN_ID = 0
DBM_BEHAVIOR.SPELL_UNKNOWN_KEY = "UNKOWN"
DBM_BEHAVIOR.SPELL_UNKNOWN_NAME = "Unknown"

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
	NewSpecialWarningDefensive = "NewSpecialWarningDefensive",
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

--Appends the given spell to the look table spell_id => spell_key
local function AppendToSpellLookUp(boss_mod, spell_id, spell_key)
	--When handling updates, we need to quickly solve the spell_id to a key
	boss_mod.SPELL_LOOKUP = boss_mod.SPELL_LOOKUP or {}
	boss_mod.SPELL_LOOKUP[spell_id] = spell_key
end

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
local function TryCreateDbmWarning(spell_behavior, spell_id, difficulty, boss_mod)
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
local function TryCreateDbmTimer(spell_behavior, spell_id, difficulty, boss_mod)
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
local function AppendHandlers(spell_behavior, spell_id, difficulty, boss_mod)
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
					local spell_name = utility.SpellIdToName(encounter_spells, spell_id, difficulty)
					if spell_name ~= nil then
						boss_mod.cast_monitor_spells = boss_mod.cast_monitor_spells or {}
						boss_mod.cast_monitor_spells[spell_name] = true
					end
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

--Go trough the category and pull out event/spell id combos 
local function AppendEventAndSpellsForCategory(
	category, spell_key, boss_mod, internal_events, registration_needs, loop_difficulties
)
	local utility = DBM_KFU
	--Go trough the categories events
	for event, _ in pairs(category) do
		--Has boss mod handle and is not internal event
		if boss_mod[event] ~= nil and internal_events[event] == nil then
			--Note the need to register the spell for the event
			registration_needs[event] = registration_needs[event] or {}
			--We need to pull all the spell ids into the registrar
			for _, diff_index in ipairs(loop_difficulties) do
				local spell_id = utility.SpellKeyToId(boss_mod.SPELLS, spell_key, diff_index)
				if spell_id ~= nil then
					registration_needs[event][spell_id] = true
					AppendToSpellLookUp(boss_mod, spell_id, spell_key)
				end
			end
		elseif event == "MANUAL_CAST_MONITOR" then
			--We need to pull all the spell ids into the lookup
			for _, diff_index in ipairs(loop_difficulties) do
				local spell_id = utility.SpellKeyToId(boss_mod.SPELLS, spell_key, diff_index)
				if spell_id ~= nil then
					AppendToSpellLookUp(boss_mod, spell_id, spell_key)
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
	local loop_difficulties = {
		"DEFAULT",
		DBM_BEHAVIOR.DIFFICULTY.NORMAL_10,
		DBM_BEHAVIOR.DIFFICULTY.NORMAL_25,
		DBM_BEHAVIOR.DIFFICULTY.HEROIC_10,
		DBM_BEHAVIOR.DIFFICULTY.HEROIC_25
	}

	--Run trough the behavior model and pick out events and spell ids tied to them, [spell_key] => {SPELL_BEHAVIOR}
	for spell_key, spell_behavior in pairs(behavior_model) do
		-- Loop trough the potential difficulty specific behaviors, [DIFFICULTY] => {DBM_DETAILS}
		for difficulty, dbm_details in pairs(spell_behavior) do
			local difficulty_behavior = spell_behavior[difficulty]
			--Go trough each category holding events
			for _, category_name in ipairs(handle_categories) do
				local category = difficulty_behavior[category_name]
				if category ~= nil then
					AppendEventAndSpellsForCategory(
						category, spell_key, boss_mod, internal_events, 
						registration_needs, loop_difficulties
					)
				end
			end
		end
	end
	--Generate registration strings
	local registration_strings = {}
	for event, spell_ids  in pairs(registration_needs) do
		local unique_spell_ids = {}
		for spell_id, _ in pairs(registration_needs[event]) do
			table.insert(unique_spell_ids, spell_id)
		end
		table.insert(registration_strings, utility.EventString(event, unpack(unique_spell_ids)))
	end
	--Register everything to DBM in one go
	boss_mod:RegisterEventsInCombat(unpack(registration_strings))
end

--Creates the dbm objects for the given settings
local function CreateBehavior(dbm_details, spell_id, difficulty, boss_mod)
	if spell_id ~= nil then 
		--Create warnings
		TryCreateDbmWarning(dbm_details, spell_id, difficulty, boss_mod)
		--Create timers
		TryCreateDbmTimer(dbm_details, spell_id, difficulty, boss_mod)
		--Append default behaviors
		AppendHandlers(dbm_details, spell_id, difficulty, boss_mod)
	end
end

--Create the behaviors for the difficulty levels
local function CreateBehaviorForDifficulties(loop_difficulties, spell_behavior, boss_mod, spell_key)
	local utility = DBM_KFU
	local missing_behaviors = {}
	-- Loop trough the potential difficulty specific behaviors, [DIFFICULTY] => {DBM_DETAILS}
	for _, difficulty in ipairs(loop_difficulties) do
		local dbm_details = spell_behavior[difficulty]
		local spell_id = utility.SpellKeyToId(boss_mod.SPELLS, spell_key, difficulty)
		--We have a valid difficult behavior override
		if dbm_details ~= nil then
			CreateBehavior(dbm_details, spell_id, difficulty, boss_mod)
		else
			missing_behaviors[difficulty] = true
		end
	end
	return missing_behaviors
end

--Expand the DEFAULT behavior per missing difficulty level
local function ExpandDefaultBehavior(missing_behaviors, spell_behavior, boss_mod, spell_key)
	local default_behavior = "DEFAULT"
	if spell_behavior[default_behavior] ~= nil then
		local utility = DBM_KFU
		--Loop trough the missing difficulties
		for missing_diff, _ in pairs(missing_behaviors) do
			--We need to append new table for the default/diff combo
			local diff_default_key = missing_diff
			spell_behavior[diff_default_key] = utility.CopyTable(spell_behavior[default_behavior])
			--Solve the spell id for this difficulty
			local spell_id = utility.SpellKeyToId(boss_mod.SPELLS, spell_key, missing_diff)
			--Create the DBM objects
			CreateBehavior(spell_behavior[diff_default_key], spell_id, missing_diff, boss_mod)
		end
	end
end

--Create the boss model from the given behavior table
function DBM_BEHAVIOR.CreateBossModel(boss_mod)
	--Check if we can find data to create the model
	if boss_mod ~= nil then
		local utility = DBM_KFU
		local engine = DBM_BEHAVIOR
		local behavior_model = boss_mod.BEHAVIOR
		local loop_difficulties = {
			DBM_BEHAVIOR.DIFFICULTY.NORMAL_10,
			DBM_BEHAVIOR.DIFFICULTY.NORMAL_25,
			DBM_BEHAVIOR.DIFFICULTY.HEROIC_10,
			DBM_BEHAVIOR.DIFFICULTY.HEROIC_25
		}
		if behavior_model ~= nil then
			-- Loop trough per spell trough the behaviors table, [spell_key] => {SPELL_BEHAVIOR}
			for spell_key, spell_behavior in pairs(behavior_model) do
				--We need to create behavior for every difficulty that exists.
				--There is no load barrier when switching difficulties.
				--Create the "override" behaviors per difficulty
				local missing_behaviors = CreateBehaviorForDifficulties(
					loop_difficulties, spell_behavior, boss_mod, spell_key
				)
				--Expand the DEFAULT behavior per difficulty that does not have specific behavior override
				ExpandDefaultBehavior(missing_behaviors, spell_behavior, boss_mod, spell_key)
			end
			--Register combat events
			RegisterSpellEvents(boss_mod)
		end
	end
end

--Handle any triggering of timers
local function HandleTimerUpdate(spell_id, spell_mapping, behavior, event, boss_mod, args)
	local timer_data = behavior.TIMER
	local utility = DBM_KFU
	local start_events = behavior.TIMER_STARTS
	--Do we have a timer data?
	if timer_data ~= nil and start_events ~= nil then
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
					utility.GetTiming(boss_mod.TIMINGS, boss_mod.difficulty, boss_mod.phase, spell_mapping, event),
					injection
				)
			end
		end
	end
end

--Handle any triggering of warnings
local function HandleWarningUpdate(spell_id, spell_mapping, behavior, event, boss_mod, args)
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
local function HandlePlayUpdate(spell_id, spell_mapping, behavior, event, boss_mod, args)
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
local function HandleScanTrigger(spell_id, spell_mapping, behavior, event, boss_mod, args)
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

--Based on Difficulty and spellid, solves the behavior model we should execute
local function GetSpellBehavior(boss_mod, spell_mapping)
	--Has the spell been mapped to a name?
	if spell_mapping ~= nil then
		local behaviors = boss_mod.BEHAVIOR[spell_mapping]
		--Does the spell have a behaviors defined?
		if behaviors ~= nil then
			--Prefer the difficulty specific behavior over the default one
			return behaviors[boss_mod.difficulty] or behaviors["DEFAULT"]
		end
	end
	return nil
end

--Handle boss model update
function DBM_BEHAVIOR.HandleModelUpdate(spell_id, event, boss_mod, args, spell_key)
	spell_id = spell_id or DBM_KFU.SpellKeyToId(boss_mod.SPELLS, spell_key, boss_mod.difficulty)
	local spell_mapping = spell_key or boss_mod.SPELL_LOOKUP[spell_id]
	local behavior = GetSpellBehavior(boss_mod, spell_mapping)
	--Do we have a behavior defined for this spell?
	if behavior ~= nil then
		HandleTimerUpdate(spell_id, spell_mapping, behavior, event, boss_mod, args)
		HandleWarningUpdate(spell_id, spell_mapping, behavior, event, boss_mod, args)
		HandlePlayUpdate(spell_id, spell_mapping, behavior, event, boss_mod, args)
		HandleScanTrigger(spell_id, spell_mapping, behavior, event, boss_mod, args)
	end
end

--Handle model event
function DBM_BEHAVIOR.HandleModelEvent(event, boss_mod, args)
	for spell_key, _ in pairs(boss_mod.BEHAVIOR) do
		
		DBM_BEHAVIOR.HandleModelUpdate(nil, event, boss_mod, args, spell_key)
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
			DBM_KFU.Debug("Monitoring boss health manually")
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
				local spell_id = utility.SpellNameToId(boss_mod.SPELLS, spell_name, boss_mod.difficulty)
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
	boss_mod.player_can_kick = DBM_KFU.KnowsInteruptSpell()
	boss_mod.player_can_dispell = DBM_KFU.CanCleanseType("magic")
	boss_mod.player_can_decurse = DBM_KFU.CanCleanseType("curse")
	boss_mod.player_can_cleanse_disease = DBM_KFU.CanCleanseType("disease")
	boss_mod.player_can_cleanse_poison = DBM_KFU.CanCleanseType("poison")
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

--Common conditions, Can we kick?
function DBM_BEHAVIOR.CanKick(boss_mod, args, spell_id, update_subtype)
	return boss_mod.player_can_kick
end

--Common conditions, Can we dispell magic?
function DBM_BEHAVIOR.CanDispell(boss_mod, args, spell_id, update_subtype)
	return boss_mod.player_can_dispell
end

--Common conditions, Can we decurse?
function DBM_BEHAVIOR.CanDecurse(boss_mod, args, spell_id, update_subtype)
	return boss_mod.player_can_decurse
end

--Common conditions, Can we dispell magic?
function DBM_BEHAVIOR.CanCleanseDisease(boss_mod, args, spell_id, update_subtype)
	return boss_mod.player_can_cleanse_disease
end

--Common conditions, Can we dispell magic?
function DBM_BEHAVIOR.CanCleansePoison(boss_mod, args, spell_id, update_subtype)
	return boss_mod.player_can_cleanse_poison
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