local mod	= DBM:NewMod("ArchMageAnton", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354288)
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
    SHADOWBOLT = 29317,
    FROSTBOLT = 55802,
    PRESENCE_OF_FROST = 9250005,
    PRESENCE_OF_SHADOW = 9250004,
    CHILL = 55699,
    BLIGHT = 70285,
    IMPENDING_DESPAIR = 72426,
    DESPAIR_STRICKEN = 72428,
    AURA_OF_SUFFERING = 41292
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600
	},
}

mod:RegisterEventsInCombat(
	EventString("SPELL_AURA_APPLIED", SPELLS.BLIGHT, SPELLS.IMPENDING_DESPAIR)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(TIMERS[difficulty].BERSERK)
--Warning to dispell Blight
local warning_dispell_blight = mod:NewSpecialWarningDispel(SPELLS.BLIGHT, "RemoveDisease", nil, nil, 1, 2)
--Warning to dispell Impending Despair
local warning_dispell_despair = mod:NewSpecialWarningDispel(SPELLS.IMPENDING_DESPAIR, "MagicDispeller", nil, nil, 1, 2)
--Ground damage warning
local warning_chill = mod:NewSpecialWarningGTFO(SPELLS.CHILL, nil, nil, nil, 1, 8)

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	player_name = UnitName("player")
	player_guid = UnitGUID("player")
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
    --Register chill move warning
	self:RegisterShortTermEvents(
		EventString("SPELL_PERIODIC_DAMAGE", SPELLS.CHILL),
		EventString("SPELL_PERIODIC_MISSED", SPELLS.CHILL)
	)
	--Begin timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
end

function mod:SPELL_AURA_APPLIED(args)
    --Blight
    if args.spellId == SPELLS.BLIGHT then
        -- Only show this to players who can dispel Disease/Nature
        warning_dispell_blight:Show(args.destName)
        warning_dispell_blight:Play("dispelnow")
    --Impending Despair
    elseif args.spellId == SPELLS.IMPENDING_DESPAIR then
        warning_dispell_despair:Show(args.destName)
        warning_dispell_despair:Play("dispelnow")
    end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Chill move warning
	if (spellId == SPELLS.CHILL) and destGUID == player_guid and self:AntiSpam() then
		warning_chill:Show(spellName)
		warning_chill:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE