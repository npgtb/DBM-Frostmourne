local mod	= DBM:NewMod("ArchMageAnton", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354288)
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
	PHASE_THREE = "phase_three"
}

--default to 25H difficulty for now
local difficulty = DIFFICULTY.HEROIC_25
local phase = PHASE.PHASE_ONE
local phase_warning_triggerd = false
local player_name = nil
local player_guid = nil

--Spell ids of the counter
local SPELLS = {
    SHADOWBOLT = {NAME = "Shadow Bolt", ID = 29317},
    FROSTBOLT = {NAME = "Frostbolt", ID = 55802},
    PRESENCE_OF_FROST = {NAME = "Presence of Frost", ID = 9250005},
    PRESENCE_OF_SHADOW = {NAME = "Presence of Shadow", ID = 9250004},
    CHILL = {NAME = "Chill", ID = 55699},
    BLIGHT = {NAME = "Blight", ID = 70285},
    IMPENDING_DESPAIR = {NAME = "Impending Despair", ID = 72426},
    DESPAIR_STRICKEN = {NAME = "Despair Stricken", ID = 72428},
    AURA_OF_SUFFERING = {NAME = "Aura of Suffering", ID = 41292},
}

--We transition based on his health %
local PHASE_TRANSITION_THRESHOLDS = {
	[PHASE.PHASE_ONE] = {THRESHOLD = 60, WARNING = 65, NEXT = PHASE.PHASE_TWO},
	[PHASE.PHASE_TWO] = {THRESHOLD = 10, WARNING = 15, NEXT = PHASE.PHASE_THREE},
}

--Timing tables
local TIMERS_PHASE_DEFAULT = {
	BLIGHT_CD = 15,
	IMPENDING_DESPAIR_CD = 15
}
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		PHASE_DEFAULT = TIMERS_PHASE_DEFAULT,
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		PHASE_DEFAULT = TIMERS_PHASE_DEFAULT,
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		PHASE_DEFAULT = TIMERS_PHASE_DEFAULT,
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		PHASE_DEFAULT = TIMERS_PHASE_DEFAULT,
	},
}

local boss_unit_id = "boss1"
local boss_health_monitor = nil

mod:RegisterEventsInCombat(
	DBM_KFU.EventString("SPELL_AURA_APPLIED", SPELLS.BLIGHT.ID, SPELLS.IMPENDING_DESPAIR.ID),
	DBM_KFU.EventString("UNIT_HEALTH", boss_unit_id)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(DBM_KFU.TIMER_DISABLED)
--Warning to dispell Blight and blight timers
local timer_blight = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.BLIGHT.ID, nil, nil, nil, 2)
local warning_dispell_blight = mod:NewSpecialWarningDispel(SPELLS.BLIGHT.ID, "RemoveDisease", nil, nil, 1, 2)
--Warning to dispell Impending Despair and timer
local timer_impending_despair = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.IMPENDING_DESPAIR.ID, nil, nil, nil, 2)
local warning_dispell_despair = mod:NewSpecialWarningDispel(SPELLS.IMPENDING_DESPAIR.ID, "MagicDispeller", nil, nil, 1, 2)
--Ground damage warning
local warning_chill = mod:NewSpecialWarningGTFO(SPELLS.CHILL.ID, nil, nil, nil, 1, 8)
--Phase warning
local warning_phase_soon = {
	[PHASE.PHASE_ONE] = mod:NewPrePhaseAnnounce(2),
	[PHASE.PHASE_TWO] = mod:NewPrePhaseAnnounce(3)
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
    --Register chill move warning
	self:RegisterShortTermEvents(
		DBM_KFU.EventString("SPELL_PERIODIC_DAMAGE", SPELLS.CHILL.ID),
		DBM_KFU.EventString("SPELL_PERIODIC_MISSED", SPELLS.CHILL.ID)
	)
	--Begin timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
end

function mod:OnCombatEnd(wipe)
    --Stop the health monitor
	if boss_health_monitor then
		boss_health_monitor:Cancel()
	end
end

function mod:SPELL_AURA_APPLIED(args)
    --Blight
    if args.spellId == SPELLS.BLIGHT.ID then
        -- Only show this to players who can dispel Disease/Nature
        warning_dispell_blight:Show(args.destName)
        warning_dispell_blight:Play("dispelnow")
		DBM_KFU.TryStartTimer(
			timer_blight,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "BLIGHT_CD")
		)
    --Impending Despair
    elseif args.spellId == SPELLS.IMPENDING_DESPAIR.ID then
        warning_dispell_despair:Show(args.destName)
        warning_dispell_despair:Play("dispelnow")
		DBM_KFU.TryStartTimer(
			timer_impending_despair,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "IMPENDING_DESPAIR_CD")
		)
    end
end

mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Chill move warning
	if (spellId == SPELLS.CHILL.ID) and destGUID == player_guid and self:AntiSpam() then
		warning_chill:Show(spellName)
		warning_chill:Play("watchfeet")
	end
end

--Handle the phase transitions
local function TransitPhase(next_phase)
	phase = next_phase
	phase_warning_triggerd = false
	if next_phase == PHASE.PHASE_TWO then
		warning_new_phase:Play("ptwo")
		DBM_KFU.TryStartTimer(
			timer_blight,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "BLIGHT_CD")
		)
		DBM_KFU.TryStartTimer(
			timer_impending_despair,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "IMPENDING_DESPAIR_CD")
		)
	elseif next_phase == PHASE.PHASE_THREE then
		warning_new_phase:Play("pthree")
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
