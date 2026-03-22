local mod	= DBM:NewMod("MaidenRot", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354272)
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

--Spell ids of the counter
local SPELLS = {
	DEEP_FREEZE = 72930,
	FRENZY = 12795
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		DEEP_FREEZE_CD = 30
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		DEEP_FREEZE_CD = 30
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		DEEP_FREEZE_CD = 30
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		DEEP_FREEZE_CD = 30
	},
}

mod:RegisterEventsInCombat(
	EventString("SPELL_CAST_START", SPELLS.DEEP_FREEZE),
	EventString("SPELL_AURA_APPLIED", SPELLS.FRENZY)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(TIMERS[difficulty].BERSERK)
--Deep freeze target warning and timer
local warning_targeted_deep_freeze = mod:NewSpecialWarningYou(SPELLS.DEEP_FREEZE, nil, nil, nil, 1, 2)
local timer_deep_freeze	= mod:NewCDTimer(TIMERS[difficulty].DEEP_FREEZE_CD, SPELLS.DEEP_FREEZE, nil, nil, nil, 2)
--Frenzy warning
local warning_frenzy = mod:NewSpellAnnounce(SPELLS.FRENZY, 3, nil, "Tank|Healer")

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	player_name = UnitName("player")
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
	--Begin timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
	timer_deep_freeze:Start(TIMERS[difficulty].DEEP_FREEZE_CD - delay)
end

function mod:SPELL_CAST_START(args)
	--Deep freeze casting
	if args.spellId == SPELLS.DEEP_FREEZE then
		--Start scanning for the target and reset the cd timer. 15 scans at 0.05 interval
		self:BossTargetScanner(args.sourceGUID, "deep_freeze_target_scan", 0.05, 15)
		timer_deep_freeze:Start(TIMERS[difficulty].DEEP_FREEZE_CD)
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
	if args.spellId == SPELLS.FRENZY then
		warning_frenzy:Show()
		warning_frenzy:Play("defensive")
	end
end