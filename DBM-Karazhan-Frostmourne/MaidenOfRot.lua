local mod	= DBM:NewMod("MaidenRot", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354272)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

--Possible difficulties of the fight
local DIFFICULTY = {
	NORMAL_10 = "normal10",
	NORMAL_25 = "normal25",
	HEROIC_10 = "heroic10",
	HEROIC_25 = "heroic25"
}
--Possible phases of the encounter
local PHASE = {
	PHASE_ONE = "phase_one",	
	PHASE_TWO = "phase_two"
}

--default to 25H difficulty for now
local difficulty = DIFFICULTY.HEROIC_25
local phase = PHASE.PHASE_ONE
local phase_warning_triggerd = false
local player_name = nil
local player_guid = nil

--Spell ids of the counter
local SPELLS = {
	DEEP_FREEZE = {NAME = "Deep Freeze", ID = 72930},
	FRENZY = {NAME = "Frenzy", ID = 12795}
}

--We transition based on his health %
local PHASE_TRANSITION_THRESHOLDS = {
	[PHASE.PHASE_ONE] = {THRESHOLD = 20, WARNING = 25, NEXT = PHASE.PHASE_TWO}
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEEP_FREEZE_CD = 30
		},
		[PHASE.PHASE_TWO] = {
			DEEP_FREEZE_CD = 30
		}
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEEP_FREEZE_CD = 30
		},
		[PHASE.PHASE_TWO] = {
			DEEP_FREEZE_CD = 30
		}
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEEP_FREEZE_CD = 30
		},
		[PHASE.PHASE_TWO] = {
			DEEP_FREEZE_CD = 30
		}
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEEP_FREEZE_CD = 30
		},
		[PHASE.PHASE_TWO] = {
			DEEP_FREEZE_CD = 30
		}
	},
}

local boss_unit_id = "boss1"
local boss_health_monitor = nil

mod:RegisterEventsInCombat(
	DBM_KFU.EventString("SPELL_CAST_START", SPELLS.DEEP_FREEZE.ID),
	DBM_KFU.EventString("SPELL_AURA_APPLIED", SPELLS.FRENZY.ID),
	DBM_KFU.EventString("UNIT_HEALTH", boss_unit_id)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(DBM_KFU.TIMER_DISABLED)
--Deep freeze target warning and timer
local warning_targeted_deep_freeze = mod:NewSpecialWarningYou(SPELLS.DEEP_FREEZE.ID, nil, nil, nil, 1, 2)
local timer_deep_freeze	= mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.DEEP_FREEZE.ID, nil, nil, nil, 2)
--Frenzy warning
local warning_frenzy = mod:NewSpellAnnounce(SPELLS.FRENZY.ID, 3, nil, "Tank|Healer")
--Phase warning
local warning_phase_soon = {
	[PHASE.PHASE_ONE] = mod:NewPrePhaseAnnounce(2)
}
local warning_new_phase = mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)

--Fetch and reset boss data on combat start
local function CombatStartFetch()
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	phase = PHASE.PHASE_ONE
	phase_warning_triggerd = false
	player_name = UnitName("player")
	player_guid = UnitGUID("player")
end

function mod:OnCombatStart(delay)
	CombatStartFetch()
	--If the boss1 unit does not exist, UNIT_HEALTH events won't fire
	if not UnitExists(boss_unit_id) then
		print("Monitoring boss health manually")
		--Work around the issue
		boss_health_monitor = DBM_KFU.MonitorBossHealth(mod.creatureId, function(health) mod:ShouldTransitionPhase(health) end)
	end
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
	--Begin timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
	DBM_KFU.TryStartTimer(
		timer_deep_freeze,
		DBM_KFU.GetTiming(TIMERS, difficulty, phase, "DEEP_FREEZE_CD"),
		-delay
	)
end

function mod:OnCombatEnd(wipe)
    --Stop the health monitor
	if boss_health_monitor then
		boss_health_monitor:Cancel()
	end
end

function mod:SPELL_CAST_START(args)
	--Deep freeze casting
	if args.spellId == SPELLS.DEEP_FREEZE.ID then
		--Start scanning for the target and reset the cd timer. 15 scans at 0.05 interval
		self:BossTargetScanner(args.sourceGUID, "deep_freeze_target_scan", 0.05, 15)
		DBM_KFU.TryStartTimer(
			timer_deep_freeze,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "DEEP_FREEZE_CD")
		)
	end
end

function mod:deep_freeze_target_scan(targetname)
	--Is the target us? if so show/play warning
	if not targetname then return end
	if targetname == player_name then
		warning_targeted_deep_freeze:Show()
		warning_targeted_deep_freeze:Play("targetyou")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	--Frenzy buff applied to the boss => massive melee haste gained
	if args.spellId == SPELLS.FRENZY.ID then
		warning_frenzy:Show()
		warning_frenzy:Play("defensive")
	end
end

--Handle the phase transitions
local function TransitPhase(next_phase)
	phase = next_phase
	phase_warning_triggerd = false
	if next_phase == PHASE.PHASE_TWO then
		warning_new_phase:Play("ptwo")
	end
end

function mod:ShouldTransitionPhase(boss_health)
	--Based on the current phase, check if we should transition to the next phase
	if PHASE_TRANSITION_THRESHOLDS[phase] ~= nil then
		--Should we transition the phase?
		if boss_health <= PHASE_TRANSITION_THRESHOLDS[phase].THRESHOLD then
			TransitPhase(PHASE_TRANSITION_THRESHOLDS[phase].NEXT)
		--Should we give pre warning?
		elseif 
			boss_health <= PHASE_TRANSITION_THRESHOLDS[phase].WARNING and
			warning_phase_soon[phase] ~= nil and
			not phase_warning_triggerd
		then
				phase_warning_triggerd = true
				warning_phase_soon[phase]:Show()
				warning_phase_soon[phase]:Play("nextphasesoon")
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if uId == boss_unit_id then
		local health_percentage = DBM_KFU.GetUnitHealthPercentage(uId)
		if health_percentage then
			mod:ShouldTransitionPhase(health_percentage)
		end
	end
end