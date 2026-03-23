local mod	= DBM:NewMod("Scythewing", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354284)
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
	DEADEN = {NAME = "Deaden", ID = 41410},
	BLISTERING_COLD = {NAME = "Blistering Cold", ID = 71047},
	TAILSWEEP = {NAME = "Tail Sweep", ID = 55696},
	FROSTBOLT_VOLLEY = {NAME = "Frostbolt Volley", ID = 72906}
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		DEADEN_CD = 15,
		BLISTERING_COLD_CD = 60,
		FROSTBOLT_VOLLEY_CD = 20,
		TAILSWEEP_CD = 10
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		DEADEN_CD = 15,
		BLISTERING_COLD_CD = 60,
		FROSTBOLT_VOLLEY_CD = 20,
		TAILSWEEP_CD = 10
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		DEADEN_CD = 15,
		BLISTERING_COLD_CD = 60,
		FROSTBOLT_VOLLEY_CD = 20,
		TAILSWEEP_CD = 10
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		DEADEN_CD = 15,
		BLISTERING_COLD_CD = 60,
		FROSTBOLT_VOLLEY_CD = 20,
		TAILSWEEP_CD = 10
	},
}

mod:RegisterEventsInCombat(
	EventString("SPELL_CAST_START", SPELLS.DEADEN.ID, SPELLS.BLISTERING_COLD.ID),
	EventString("SPELL_CAST_SUCCESS", SPELLS.TAILSWEEP.ID, SPELLS.FROSTBOLT_VOLLEY.ID),
	EventString("SPELL_AURA_APPLIED", SPELLS.DEADEN.ID)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(TIMERS[difficulty].BERSERK)
--Deaden warning and timer
local deaden_warning = mod:NewSpecialWarningYou(SPELLS.DEADEN.ID, nil, nil, nil, 1, 2)
local timer_deaden = mod:NewCDTimer(TIMERS[difficulty].DEADEN_CD, SPELLS.DEADEN.ID, nil, nil, nil, 2)
--Blistering Cold warning and timer
local blistering_cold_warning = mod:NewSpecialWarningGTFO(SPELLS.BLISTERING_COLD.ID, nil, nil, nil, 1, 8)
local timer_blistering_cold = mod:NewCDTimer(TIMERS[difficulty].BLISTERING_COLD_CD, SPELLS.BLISTERING_COLD.ID, nil, nil, nil, 2)
--Frostbolt Volley CD timer
local timer_frostbolt_volley = mod:NewCDTimer(TIMERS[difficulty].FROSTBOLT_VOLLEY_CD, SPELLS.FROSTBOLT_VOLLEY.ID, nil, nil, nil, 2)
--Tailsweep CD timer
local timer_tailsweep = mod:NewCDTimer(TIMERS[difficulty].TAILSWEEP_CD, SPELLS.TAILSWEEP.ID, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	player_name = UnitName("player")
	player_guid = UnitGUID("player")
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
	--Begin timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
	timer_deaden:Start(TIMERS[difficulty].DEADEN_CD - delay)
	timer_tailsweep:Start(TIMERS[difficulty].TAILSWEEP_CD - delay)
end

function mod:SPELL_CAST_START(args)
	--Deaden casting
	if args.spellId == SPELLS.DEADEN.ID then
		timer_deaden:Start(TIMERS[difficulty].DEADEN_CD)
	--Blistering cold cast started
    elseif args.spellId == SPELLS.BLISTERING_COLD.ID then
		timer_blistering_cold:Start(TIMERS[difficulty].BLISTERING_COLD_CD)
        blistering_cold_warning:Show()
        blistering_cold_warning:Play("runaway")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	-- Tailsweep
	if args.spellId == SPELLS.TAILSWEEP.ID then
		timer_tailsweep:Start(TIMERS[difficulty].TAILSWEEP_CD)
	-- Frostbolt volley
    elseif args.spellId == SPELLS.FROSTBOLT_VOLLEY.ID then
		timer_frostbolt_volley:Start(TIMERS[difficulty].FROSTBOLT_VOLLEY_CD)
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
