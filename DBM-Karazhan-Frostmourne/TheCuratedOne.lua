local mod	= DBM:NewMod("CuratedOne", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354276)
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
	CHAOS_BOLT = {NAME = "Chaos Bolt", ID = 51287},
	SOUL_FLAY = {NAME = "Soul Flay", ID = 45442},
	FEAR = {NAME = "Fear", ID = 30530},
	AURA_OF_FEAR = {NAME = "Aura of Fear", ID = 9250009},
	MORTAL_FOUND = {NAME = "Mortal Wound", ID = 25646},
	BLOOD_MIRROR = {NAME = "Blood Mirror", ID = 70838},
	DEATH_AND_DECAY = {NAME = "Death and Decay", ID = 72108},
	COLDFLAME = {NAME = "Coldflame", ID = 70823},
	COLDFLAME_SUMMON = {NAME = "Coldflame", ID = 69138}
}

--We transition based on his health %
local PHASE_TRANSITION_THRESHOLDS = {
	[PHASE.PHASE_ONE] = {THRESHOLD = 75, WARNING = 80, NEXT = PHASE.PHASE_TWO},
	[PHASE.PHASE_TWO] = {THRESHOLD = 40, WARNING = 45, NEXT = PHASE.PHASE_THREE},
	[PHASE.PHASE_THREE] = {THRESHOLD = 15, WARNING = 20, NEXT = PHASE.PHASE_FOUR}
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		}
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		}
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		}
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_TWO] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_THREE] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		},
		[PHASE.PHASE_FOUR] = {
			CHAOS_BOLT_CD = 7,
			FEAR_CD = 25,
			BLOOD_MIRROR_CD = 25,
			DEATH_AND_DECAY_CD = 20,
			COLDFLAME_CD = 10
		}
	},
}

local boss_unit_id = "boss1"
local boss_health_monitor = nil
local boss_casting_monitor = nil
local manual_spell_monitors = {
	[SPELLS.AURA_OF_FEAR.NAME] = true
}

mod:RegisterEventsInCombat(
	DBM_KFU.EventString("SPELL_CAST_START", SPELLS.CHAOS_BOLT.ID),
	DBM_KFU.EventString("SPELL_CAST_SUCCESS", SPELLS.SOUL_FLAY.ID, SPELLS.FEAR.ID, SPELLS.DEATH_AND_DECAY.ID),
	DBM_KFU.EventString("SPELL_AURA_APPLIED_DOSE", SPELLS.MORTAL_FOUND.ID),
	DBM_KFU.EventString("SPELL_AURA_APPLIED", SPELLS.BLOOD_MIRROR.ID),
	DBM_KFU.EventString("SPELL_SUMMON", SPELLS.COLDFLAME_SUMMON.ID),
	DBM_KFU.EventString("UNIT_HEALTH", boss_unit_id)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(DBM_KFU.TIMER_DISABLED)
--Soul Flay target warning
local warning_targeted_soul_flay = mod:NewSpecialWarningYou(SPELLS.SOUL_FLAY.ID, nil, nil, nil, 1, 2)
--Chaos bolt target warning and timer
local warning_chaos_bolt = mod:NewSpecialWarningYou(SPELLS.CHAOS_BOLT.ID, nil, nil, nil, 1, 2)
local timer_chaos_bolt = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.CHAOS_BOLT.ID, nil, nil, nil, 2)
--Mortal Wound (from chaos bolt) stack warning
local mortal_wound_warning_threshold = 4
local mortal_wound_stack_warning = mod:NewSpecialWarningStack(SPELLS.MORTAL_FOUND.ID, nil, mortal_wound_warning_threshold, nil, nil, 1, 6)
--Fear warning and timer
local timer_fear = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.FEAR.ID, nil, nil, nil, 2)
--Ground damage warning
local ground_damage_warning = mod:NewSpecialWarningGTFO(SPELLS.DEATH_AND_DECAY.ID, nil, nil, nil, 1, 8)
--Death and decay timer
local timer_death_and_decay = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.DEATH_AND_DECAY.ID, nil, nil, nil, 2)
--Cold flame timer
local timer_cold_flame = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.COLDFLAME.ID, nil, nil, nil, 2)
--Blood Mirror Warning
local warning_blood_mirror = mod:NewSpecialWarningYou(SPELLS.BLOOD_MIRROR.ID, nil, nil, nil, 1, 2)
local blood_mirror_timer = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.BLOOD_MIRROR.ID, nil, nil, nil, 2)
--Aura of fear warning
local warning_aura_of_fear = mod:NewSpecialWarningLookAway(SPELLS.AURA_OF_FEAR.ID, nil, nil, nil, 1, 2)
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
	--Start manual monitor for aura of fear casts
	boss_casting_monitor = DBM_KFU.MonitorBossCasting(
		mod.creatureId, manual_spell_monitors,
		function(spell_name) mod:SPELL_MANUAL_MONITOR(spell_name) end
	)
    --Register d&d and coldflame move warnings
	self:RegisterShortTermEvents(
		DBM_KFU.EventString("SPELL_PERIODIC_DAMAGE", SPELLS.DEATH_AND_DECAY.ID, SPELLS.COLDFLAME.ID),
		DBM_KFU.EventString("SPELL_PERIODIC_MISSED", SPELLS.DEATH_AND_DECAY.ID, SPELLS.COLDFLAME.ID)
	)
	--Start timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
	DBM_KFU.TryStartTimer(
		timer_fear,
		DBM_KFU.GetTiming(TIMERS, difficulty, phase, "FEAR_CD"),
		-delay
	)
	DBM_KFU.TryStartTimer(
		timer_chaos_bolt,
		DBM_KFU.GetTiming(TIMERS, difficulty, phase, "CHAOS_BOLT_CD"),
		-delay
	)
end

function mod:OnCombatEnd(wipe)
    --Stop the health monitor
	if boss_health_monitor then
		boss_health_monitor:Cancel()
	end
    --Stop the casting monitor
	if boss_casting_monitor then
		boss_casting_monitor:Cancel()
	end
end

function mod:chaos_bolt_target_scan(targetname)
	--Is the target us? if so show/play warning
	if not targetname then return end
	if targetname == player_name then
		warning_chaos_bolt:Show()
		warning_chaos_bolt:Play("targetyou")
	end
end

function mod:SPELL_CAST_START(args)
	--Chaos bolt casting
	if args.spellId == SPELLS.CHAOS_BOLT.ID then
		--Start scanning for the target and reset the cd timer. 15 scans at 0.05 interval
		self:BossTargetScanner(args.sourceGUID, "chaos_bolt_target_scan", 0.05, 15)
		DBM_KFU.TryStartTimer(
			timer_chaos_bolt,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "CHAOS_BOLT_CD")
		)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	--Soul Flay casting, show/play warning to the targeted playerspecWarnFearDispel
	if args.spellId == SPELLS.SOUL_FLAY.ID and args.destName == player_name then
        warning_targeted_soul_flay:Show()
		warning_targeted_soul_flay:Play("targetyou")
    --Fear timer reset
    elseif args.spellId == SPELLS.FEAR.ID then
		DBM_KFU.TryStartTimer(
			timer_fear,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "FEAR_CD")
		)
	-- Death and decay timer rest
	elseif args.spellId == SPELLS.DEATH_AND_DECAY.ID then
		DBM_KFU.TryStartTimer(
			timer_death_and_decay,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "DEATH_AND_DECAY_CD")
		)
    end
end

function mod:SPELL_AURA_APPLIED(args)
	-- Blood mirror applied to us
	if args.spellId == SPELLS.BLOOD_MIRROR.ID then
		if args.destName == player_name then
			warning_blood_mirror:Show()
			warning_blood_mirror:Play("targetyou")
		end
		DBM_KFU.TryStartTimer(
			blood_mirror_timer,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "BLOOD_MIRROR_CD")
		)
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	--Mortal Found, if stacks > threashold, play warning
	if args.spellId == SPELLS.MORTAL_FOUND.ID then
		local amount = args.amount or 1
		if args:IsPlayer() and amount >= mortal_wound_warning_threshold then
			mortal_wound_stack_warning:Show(args.amount)
			mortal_wound_stack_warning:Play("stackhigh")
		end
	end
end

mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Death and Decay & ColdFlame move warning
	if (spellId == SPELLS.COLDFLAME.ID or spellId == SPELLS.DEATH_AND_DECAY.ID) and 
		destGUID == player_guid and self:AntiSpam() then
		ground_damage_warning:Show(spellName)
		ground_damage_warning:Play("watchfeet")
	end
end

function mod:SPELL_SUMMON(args)
	--Reset coldflame timer
	if args.spellId == SPELLS.COLDFLAME_SUMMON.ID then
		DBM_KFU.TryStartTimer(
			timer_cold_flame,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "COLDFLAME_CD")
		)
	end
end

function mod:SPELL_MANUAL_MONITOR(spell_name)
	--Aura of fear turn away
	if spell_name == SPELLS.AURA_OF_FEAR.NAME and self:AntiSpam() then
		warning_aura_of_fear:Show()
		warning_aura_of_fear:Play("turnaway")
	end
end

--Handle the phase transitions
local function TransitPhase(next_phase)
	phase = next_phase
	phase_warning_triggerd = false
	if next_phase == PHASE.PHASE_TWO then
		warning_new_phase:Play("ptwo")
		DBM_KFU.TryStartTimer(
			timer_death_and_decay,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "DEATH_AND_DECAY_CD")
		)
	elseif next_phase == PHASE.PHASE_THREE then
		warning_new_phase:Play("pthree")
		DBM_KFU.TryStartTimer(
			blood_mirror_timer,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "BLOOD_MIRROR_CD")
		)
	elseif next_phase == PHASE.PHASE_FOUR then
		warning_new_phase:Play("pfour")
		DBM_KFU.TryStartTimer(
			timer_cold_flame,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "COLDFLAME_CD")
		)
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