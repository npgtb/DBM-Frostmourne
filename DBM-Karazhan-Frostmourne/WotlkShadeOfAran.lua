local mod	= DBM:NewMod("WotlkShadeAran", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354280)
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
	FROSTBOLT = {NAME = "Frostbolt", ID = 29954},
	FIREBALL = {NAME = "Fireball", ID = 29953},
	FLAME_WREATH_CAST = {NAME = "Flame Wreath", ID = 30004},
	FLAME_WREATH = {NAME = "Flame Wreath", ID = 29946},
	WATER_BOLT = {NAME = "Water Bolt", ID = 37054},
	ARCANE_EXPLOSION = {NAME = "Arcane Explosion", ID = 29973},
	CHAINS_OF_ICE = {NAME = "Chains of Ice", ID = 29991},
	SUMMON_BLIZZARD = {NAME = "Summon Blizzard", ID = 29969},
	BLIZZARD = {NAME = "Blizzard", ID = 29951},
	ARCANE_MISSILES = {NAME = "Arcane Missiles", ID = 29956}
}

--We transition based on his health %
local PHASE_TRANSITION_THRESHOLDS = {
	[PHASE.PHASE_ONE] = {THRESHOLD = 40, WARNING = 45, NEXT = PHASE.PHASE_TWO},
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		},
		[PHASE.PHASE_TWO] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		}
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		},
		[PHASE.PHASE_TWO] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		}
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		},
		[PHASE.PHASE_TWO] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		}
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		[PHASE.PHASE_ONE] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		},
		[PHASE.PHASE_TWO] = {
			FLAME_WREATH_CD = 60,
			ARCANE_EXPLOSION_CD = 60,
			SUMMON_BLIZZARD_CD = 60
		}
	},
}

local boss_unit_id = "boss1"
local boss_health_monitor = nil

mod:RegisterEventsInCombat(
	DBM_KFU.EventString("SPELL_CAST_START", SPELLS.FROSTBOLT.ID, SPELLS.FIREBALL.ID, SPELLS.FLAME_WREATH_CAST.ID, SPELLS.ARCANE_EXPLOSION.ID, SPELLS.SUMMON_BLIZZARD.ID),
	DBM_KFU.EventString("SPELL_AURA_APPLIED", SPELLS.CHAINS_OF_ICE.ID),
	DBM_KFU.EventString("SPELL_DAMAGE", SPELLS.ARCANE_MISSILES.ID),
	DBM_KFU.EventString("UNIT_HEALTH", boss_unit_id)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(DBM_KFU.TIMER_DISABLED)

--Kick group count
mod.vb.kick_groups = 3
mod.vb.current_kick_group = 0
--Kick warning for Frostbolt and Fireball
local frost_fire_kick_warning = mod:NewSpecialWarningInterruptCount(SPELLS.FROSTBOLT.ID, "HasInterrupt", nil, nil, 1, 2)
--Flame Wreath warning and timer
local flame_wreath_warning = mod:NewSpecialWarningMove(SPELLS.FLAME_WREATH_CAST.ID, nil, nil, nil, 1, 2)
local flame_wreath_timer = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.FLAME_WREATH_CAST.ID, nil, nil, nil, 2)
--Chains of ice dispell warning
local warning_chains_of_ice = mod:NewSpecialWarningDispel(SPELLS.CHAINS_OF_ICE.ID, "MagicDispeller", nil, nil, 1, 2)
--Warning to start killing the water elementals
local kill_adds_warning = mod:NewSpecialWarning("Kill the adds!", nil, nil, nil, 1, 2)
--Arcane Explosion runaway warning and timer
local arcane_explosion_warning = mod:NewSpecialWarningMove(SPELLS.ARCANE_EXPLOSION.ID, nil, nil, nil, 1, 2)
local arcane_explosion_timer = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.ARCANE_EXPLOSION.ID, nil, nil, nil, 2)
--Arcane Missiles warning
local arcane_missiles_warning = mod:NewSpecialWarningYou(SPELLS.ARCANE_MISSILES.ID, nil, nil, nil, 1, 2)
--Blizzard damage warning and summon timer
local blizzard_damage_warning = mod:NewSpecialWarningGTFO(SPELLS.BLIZZARD.ID, nil, nil, nil, 1, 8)
local summon_blizzard_timer = mod:NewCDTimer(DBM_KFU.TIMER_DISABLED, SPELLS.SUMMON_BLIZZARD.ID, nil, nil, nil, 2)
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
    --Register Blizzard move warnings
	self:RegisterShortTermEvents(
		DBM_KFU.EventString("SPELL_PERIODIC_DAMAGE", SPELLS.BLIZZARD.ID),
		DBM_KFU.EventString("SPELL_PERIODIC_MISSED", SPELLS.BLIZZARD.ID)
	)

	--Start timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
end

function mod:OnCombatEnd(wipe)
    --Stop the health monitor
	if boss_health_monitor then
		boss_health_monitor:Cancel()
	end
end

function mod:SPELL_CAST_START(args)
	--Kick Frostbolt and Fireball warning
	if args.spellId == SPELLS.FROSTBOLT.ID or args.spellId == SPELLS.FIREBALL.ID then
		--Figure out the current group number
		self.vb.current_kick_group = self.vb.current_kick_group + 1
		if self.vb.current_kick_group == (self.vb.kick_groups+1) then
			self.vb.current_kick_group = 1
		end
		local kick_audio_string = "kick"..self.vb.current_kick_group.."r"
		--Give the warning
		frost_fire_kick_warning:Show(args.sourceName, self.vb.current_kick_group)
		frost_fire_kick_warning:Play(kick_audio_string)
	--Flame Wreath warning to stop moving
	elseif args.spellId == SPELLS.FLAME_WREATH_CAST.ID then
		flame_wreath_warning:Show()
		flame_wreath_warning:Play("aesoon")
		DBM_KFU.TryStartTimer(
			flame_wreath_timer,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "FLAME_WREATH_CD")
		)
	--Give warning to runaway from arcane explosion
	elseif args.spellId == SPELLS.ARCANE_EXPLOSION.ID then
		arcane_explosion_warning:Show()
		arcane_explosion_warning:Play("runaway")
		DBM_KFU.TryStartTimer(
			arcane_explosion_timer,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "ARCANE_EXPLOSION_CD")
		)
	elseif args.spellId == SPELLS.SUMMON_BLIZZARD.ID then
		DBM_KFU.TryStartTimer(
			summon_blizzard_timer,
			DBM_KFU.GetTiming(TIMERS, difficulty, phase, "SUMMON_BLIZZARD_CD")
		)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	--Chains of ice dispell warning
	if args.spellId == SPELLS.CHAINS_OF_ICE.ID then
		warning_chains_of_ice:Show(args.destName)
	end
end

function mod:SPELL_DAMAGE(sourceGUID, _, _, destGUID, _, _, spellId)
	--Arcane Missiles warning
	if spellId == SPELLS.ARCANE_MISSILES.ID and destGUID == player_guid and self:AntiSpam() then
		arcane_missiles_warning:Show()
		arcane_missiles_warning:Play("targetyou")
	end
end

mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Blizzard move warning
	if (spellId == SPELLS.BLIZZARD.ID) and destGUID == player_guid and self:AntiSpam() then
		blizzard_damage_warning:Show(spellName)
		blizzard_damage_warning:Play("watchfeet")
	end
end

--Handle the phase transitions
local function TransitPhase(next_phase)
	phase = next_phase
	phase_warning_triggerd = false
	if next_phase == PHASE.PHASE_TWO then
		warning_new_phase:Play("ptwo")
		kill_adds_warning:Show()
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
