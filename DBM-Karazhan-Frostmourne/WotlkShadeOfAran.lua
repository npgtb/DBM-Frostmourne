local mod	= DBM:NewMod("WotlkShadeAran", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354280)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

--Helper to build the event string
local function EventString(event_name, ...)
	--Set everything in table
	local parts = {event_name}
	for i = 1, select("#", ...) do
		table.insert(parts, tostring(select(i, ...)))
	end
	-- Concat the table
	return table.concat(parts, " ")
end

--Possible difficulties of the fight
local DIFFICULTY = {
	NORMAL_10 = "normal10",
	NORMAL_25 = "normal25",
	HEROIC_10 = "heroic10",
	HEROIC_25 = "heroic25"
}

--default to 25H difficulty for now
local difficulty = DIFFICULTY.HEROIC_25
local player_name = nil
local player_guid = nil

--Spell ids of the counter
local SPELLS = {
	FROSTBOLT = 29954,
	FIREBALL = 29953,
	FLAME_WREATH_CAST = 30004,
	FLAME_WREATH = 29946,
	WATER_BOLT = 37054,
	ARCANE_EXPLOSION = 29973,
	CHAINS_OF_ICE = 29991,
	SUMMON_BLIZZARD = 29969,
	BLIZZARD = 29951,
	ARCANE_MISSILES = 29956
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		FLAME_WREATH_CD = 60,
		ARCANE_EXPLOSION_CD = 60,
		SUMMON_BLIZZARD_CD = 60
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		FLAME_WREATH_CD = 60,
		ARCANE_EXPLOSION_CD = 60,
		SUMMON_BLIZZARD_CD = 60
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		FLAME_WREATH_CD = 60,
		ARCANE_EXPLOSION_CD = 60,
		SUMMON_BLIZZARD_CD = 60
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		FLAME_WREATH_CD = 60,
		ARCANE_EXPLOSION_CD = 60,
		SUMMON_BLIZZARD_CD = 60
	},
}

mod:RegisterEventsInCombat(
	EventString("SPELL_CAST_START", SPELLS.FROSTBOLT, SPELLS.FIREBALL, SPELLS.FLAME_WREATH_CAST, SPELLS.WATER_BOLT, SPELLS.ARCANE_EXPLOSION, SPELLS.SUMMON_BLIZZARD),
	EventString("SPELL_AURA_APPLIED", SPELLS.CHAINS_OF_ICE),
	EventString("SPELL_DAMAGE", SPELLS.ARCANE_MISSILES)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(TIMERS[difficulty].BERSERK)

--Kick group count
mod.vb.kick_groups = 3
mod.vb.current_kick_group = 0
--Kick warning for Frostbolt and Fireball
local frost_fire_kick_warning = mod:NewSpecialWarningInterruptCount(SPELLS.FROSTBOLT, "HasInterrupt", nil, nil, 1, 2)
--Flame Wreath warning and timer
local flame_wreath_warning = mod:NewSpecialWarningMove(SPELLS.FLAME_WREATH_CAST, nil, nil, nil, 1, 2)
local flame_wreath_timer = mod:NewCDTimer(TIMERS[difficulty].FLAME_WREATH_CD, SPELLS.FLAME_WREATH_CAST, nil, nil, nil, 2)
--Chains of ice dispell warning
local warning_chains_of_ice = mod:NewSpecialWarningDispel(SPELLS.CHAINS_OF_ICE, "MagicDispeller", nil, nil, 1, 2)
--Warning to start killing the water elementals
local kill_adds_warning = mod:NewSpecialWarning("Kill the adds!", nil, nil, nil, 1, 2)
--Arcane Explosion runaway warning and timer
local arcane_explosion_warning = mod:NewSpecialWarningMove(SPELLS.ARCANE_EXPLOSION, nil, nil, nil, 1, 2)
local arcane_explosion_timer = mod:NewCDTimer(TIMERS[difficulty].ARCANE_EXPLOSION_CD, SPELLS.ARCANE_EXPLOSION, nil, nil, nil, 2)
--Arcane Missiles warning
local arcane_missiles_warning = mod:NewSpecialWarningYou(SPELLS.ARCANE_MISSILES, nil, nil, nil, 1, 2)
--Blizzard damage warning and summon timer
local blizzard_damage_warning = mod:NewSpecialWarningGTFO(SPELLS.BLIZZARD, nil, nil, nil, 1, 8)
local summon_blizzard_timer = mod:NewCDTimer(TIMERS[difficulty].SUMMON_BLIZZARD_CD, SPELLS.SUMMON_BLIZZARD, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	player_name = UnitName("player")
	player_guid = UnitGUID("player")
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
    --Register Blizzard move warnings
	self:RegisterShortTermEvents(
		EventString("SPELL_PERIODIC_DAMAGE", SPELLS.BLIZZARD),
		EventString("SPELL_PERIODIC_MISSED", SPELLS.BLIZZARD)
	)

	--Start timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
	--Currently seems like everything starts of CD
	--flame_wreath_timer:Start(TIMERS[difficulty].FLAME_WREATH_CD - delay)
	--arcane_explosion_timer:Start(TIMERS[difficulty].ARCANE_EXPLOSION_CD - delay)
	--summon_blizzard_timer:Start(TIMERS[difficulty].SUMMON_BLIZZARD_CD - delay)
end

function mod:SPELL_CAST_START(args)
	--Kick Frostbolt and Fireball warning
	if args.spellId == SPELLS.FROSTBOLT or args.spellId == SPELLS.FIREBALL then
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
	elseif args.spellId == SPELLS.FLAME_WREATH_CAST then
		flame_wreath_warning:Show()
		flame_wreath_warning:Play("aesoon")
		flame_wreath_timer:Start(TIMERS[difficulty].FLAME_WREATH_CD)
	--Give warning to kill adds
	elseif args.spellId == SPELLS.WATER_BOLT and self:AntiSpam() then
		kill_adds_warning:Show()
	--Give warning to runaway from arcane explosion
	elseif args.spellId == SPELLS.ARCANE_EXPLOSION then
		arcane_explosion_warning:Show()
		arcane_explosion_warning:Play("runaway")
		arcane_explosion_timer:Start(TIMERS[difficulty].ARCANE_EXPLOSION_CD)
	elseif args.spellId == SPELLS.SUMMON_BLIZZARD then
		summon_blizzard_timer:Start(TIMERS[difficulty].SUMMON_BLIZZARD_CD)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	--Chains of ice dispell warning
	if args.spellId == SPELLS.CHAINS_OF_ICE then
		warning_chains_of_ice:Show(args.destName)
	end
end

function mod:SPELL_DAMAGE(sourceGUID, _, _, destGUID, _, _, spellId)
	--Arcane Missiles warning
	if spellId == SPELLS.ARCANE_MISSILES and destGUID == player_guid and self:AntiSpam() then
		arcane_missiles_warning:Show()
		arcane_missiles_warning:Play("targetyou")
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Blizzard move warning
	if (spellId == SPELLS.BLIZZARD) and destGUID == player_guid and self:AntiSpam() then
		blizzard_damage_warning:Show(spellName)
		blizzard_damage_warning:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE