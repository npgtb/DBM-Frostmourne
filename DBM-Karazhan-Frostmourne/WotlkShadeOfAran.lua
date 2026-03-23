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
	EventString("SPELL_CAST_START", SPELLS.FROSTBOLT.ID, SPELLS.FIREBALL.ID, SPELLS.FLAME_WREATH_CAST.ID, SPELLS.WATER_BOLT.ID, SPELLS.ARCANE_EXPLOSION.ID, SPELLS.SUMMON_BLIZZARD.ID),
	EventString("SPELL_AURA_APPLIED", SPELLS.CHAINS_OF_ICE.ID),
	EventString("SPELL_DAMAGE", SPELLS.ARCANE_MISSILES.ID)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(TIMERS[difficulty].BERSERK)

--Kick group count
mod.vb.kick_groups = 3
mod.vb.current_kick_group = 0
--Kick warning for Frostbolt and Fireball
local frost_fire_kick_warning = mod:NewSpecialWarningInterruptCount(SPELLS.FROSTBOLT.ID, "HasInterrupt", nil, nil, 1, 2)
--Flame Wreath warning and timer
local flame_wreath_warning = mod:NewSpecialWarningMove(SPELLS.FLAME_WREATH_CAST.ID, nil, nil, nil, 1, 2)
local flame_wreath_timer = mod:NewCDTimer(TIMERS[difficulty].FLAME_WREATH_CD, SPELLS.FLAME_WREATH_CAST.ID, nil, nil, nil, 2)
--Chains of ice dispell warning
local warning_chains_of_ice = mod:NewSpecialWarningDispel(SPELLS.CHAINS_OF_ICE.ID, "MagicDispeller", nil, nil, 1, 2)
--Warning to start killing the water elementals
local kill_adds_warning = mod:NewSpecialWarning("Kill the adds!", nil, nil, nil, 1, 2)
--Arcane Explosion runaway warning and timer
local arcane_explosion_warning = mod:NewSpecialWarningMove(SPELLS.ARCANE_EXPLOSION.ID, nil, nil, nil, 1, 2)
local arcane_explosion_timer = mod:NewCDTimer(TIMERS[difficulty].ARCANE_EXPLOSION_CD, SPELLS.ARCANE_EXPLOSION.ID, nil, nil, nil, 2)
--Arcane Missiles warning
local arcane_missiles_warning = mod:NewSpecialWarningYou(SPELLS.ARCANE_MISSILES.ID, nil, nil, nil, 1, 2)
--Blizzard damage warning and summon timer
local blizzard_damage_warning = mod:NewSpecialWarningGTFO(SPELLS.BLIZZARD.ID, nil, nil, nil, 1, 8)
local summon_blizzard_timer = mod:NewCDTimer(TIMERS[difficulty].SUMMON_BLIZZARD_CD, SPELLS.SUMMON_BLIZZARD.ID, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	player_name = UnitName("player")
	player_guid = UnitGUID("player")
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
    --Register Blizzard move warnings
	self:RegisterShortTermEvents(
		EventString("SPELL_PERIODIC_DAMAGE", SPELLS.BLIZZARD.ID),
		EventString("SPELL_PERIODIC_MISSED", SPELLS.BLIZZARD.ID)
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
		flame_wreath_timer:Start(TIMERS[difficulty].FLAME_WREATH_CD)
	--Give warning to kill adds
	elseif args.spellId == SPELLS.WATER_BOLT.ID and self:AntiSpam() then
		kill_adds_warning:Show()
	--Give warning to runaway from arcane explosion
	elseif args.spellId == SPELLS.ARCANE_EXPLOSION.ID then
		arcane_explosion_warning:Show()
		arcane_explosion_warning:Play("runaway")
		arcane_explosion_timer:Start(TIMERS[difficulty].ARCANE_EXPLOSION_CD)
	elseif args.spellId == SPELLS.SUMMON_BLIZZARD.ID then
		summon_blizzard_timer:Start(TIMERS[difficulty].SUMMON_BLIZZARD_CD)
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