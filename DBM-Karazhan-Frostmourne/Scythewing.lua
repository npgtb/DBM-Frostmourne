local mod	= DBM:NewMod("Scythewing", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354284)
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
	PHASE_TWO = "phase_two",
	PHASE_THREE = "phase_three",
	PHASE_FOUR = "phase_four"
}

--default to 25H difficulty for now
local difficulty = DIFFICULTY.HEROIC_25
local phase = PHASE.PHASE_ONE
local phase_warning_triggerd = false
local player_name = nil
local player_guid = nil

--Spell ids of the counter
local SPELLS = {
	DEADEN = {NAME = "Deaden", ID = 41410},
	BLISTERING_COLD = {NAME = "Blistering Cold", ID = 71047},
	TAILSWEEP = {NAME = "Tail Sweep", ID = 55696},
	FROSTBOLT_VOLLEY = {NAME = "Frostbolt Volley", ID = 72906}
}

--We transition based on his health %
local PHASE_TRANSITION_THRESHOLDS = {
	[PHASE.PHASE_ONE] = {THRESHOLD = 80, WARNING = 85, NEXT = PHASE.PHASE_TWO},
	[PHASE.PHASE_TWO] = {THRESHOLD = 50, WARNING = 55, NEXT = PHASE.PHASE_THREE},
	[PHASE.PHASE_THREE] = {THRESHOLD = 20, WARNING = 25, NEXT = PHASE.PHASE_FOUR}
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		}
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		}
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		}
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			DEADEN_CD = 15,
			BLISTERING_COLD_CD = 60,
			FROSTBOLT_VOLLEY_CD = 20,
			TAILSWEEP_CD = 10
		}
	},
}

local boss_unit_id = "boss1"
local boss_health_monitor = nil

mod:RegisterEventsInCombat(
	DBM_KFU.EventString("SPELL_CAST_START", SPELLS.DEADEN.ID, SPELLS.BLISTERING_COLD.ID),
	DBM_KFU.EventString("SPELL_CAST_SUCCESS", SPELLS.TAILSWEEP.ID, SPELLS.FROSTBOLT_VOLLEY.ID),
	DBM_KFU.EventString("SPELL_AURA_APPLIED", SPELLS.DEADEN.ID),
	DBM_KFU.EventString("UNIT_HEALTH", boss_unit_id)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(DBM_KFU.TIMER_DISABLED)
--Deaden warning and timer
local deaden_warning = mod:NewSpecialWarningYou(SPELLS.DEADEN.ID, nil, nil, nil, 1, 2)
local timer_deaden = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.DEADEN.ID, nil, nil, nil, 2)
--Blistering Cold warning and timer
local blistering_cold_warning = mod:NewSpecialWarningGTFO(SPELLS.BLISTERING_COLD.ID, nil, nil, nil, 1, 8)
local timer_blistering_cold = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.BLISTERING_COLD.ID, nil, nil, nil, 2)
--Frostbolt Volley CD timer
local timer_frostbolt_volley = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.FROSTBOLT_VOLLEY.ID, nil, nil, nil, 2)
--Tailsweep CD timer
local timer_tailsweep = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.TAILSWEEP.ID, nil, nil, nil, 2)
--Phase warning
--Phase warning
local warning_phase_soon = {
	[PHASE.PHASE_ONE] = mod:NewPrePhaseAnnounce(2),
	[PHASE.PHASE_TWO] = mod:NewPrePhaseAnnounce(3),
	[PHASE.PHASE_THREE] = mod:NewPrePhaseAnnounce(4)
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
		timer_deaden,
		DBM_KFU.GetTiming(TIMERS, difficulty, phase, "DEADEN_CD"),
		-delay
	)
	DBM_KFU.TryStartTimer(
		timer_tailsweep,
		DBM_KFU.GetTiming(TIMERS, difficulty, phase, "TAILSWEEP_CD"),
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
	--Deaden casting
	if args.spellId == SPELLS.DEADEN.ID then
		DBM_KFU.TryStartTimer(
			timer_deaden,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "DEADEN_CD")
		)
	--Blistering cold cast started
    elseif args.spellId == SPELLS.BLISTERING_COLD.ID then
		DBM_KFU.TryStartTimer(
			timer_blistering_cold,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "BLISTERING_COLD_CD")
		)
        blistering_cold_warning:Show()
        blistering_cold_warning:Play("runaway")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	-- Tailsweep
	if args.spellId == SPELLS.TAILSWEEP.ID then
		DBM_KFU.TryStartTimer(
			timer_tailsweep,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "TAILSWEEP_CD")
		)
	-- Frostbolt volley
    elseif args.spellId == SPELLS.FROSTBOLT_VOLLEY.ID then
		DBM_KFU.TryStartTimer(
			timer_frostbolt_volley,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "FROSTBOLT_VOLLEY_CD")
		)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	-- Deaden applied to us
	if args.spellId == SPELLS.DEADEN.ID then
		if args.destName == player_name then
			deaden_warning:Show()
			deaden_warning:Play("targetyou")
		end
	end
end

--Handle the phase transitions
local function TransitPhase(next_phase)
	phase = next_phase
	phase_warning_triggerd = false
	if next_phase == PHASE.PHASE_TWO then
		warning_new_phase:Play("ptwo")
		DBM_KFU.TryStartTimer(
			timer_blistering_cold,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "BLISTERING_COLD_CD")
		)
	elseif next_phase == PHASE.PHASE_THREE then
		warning_new_phase:Play("pthree")
		DBM_KFU.TryStartTimer(
			timer_frostbolt_volley,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "FROSTBOLT_VOLLEY_CD")
		)
	elseif next_phase == PHASE.PHASE_FOUR then
		warning_new_phase:Play("pfour")
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