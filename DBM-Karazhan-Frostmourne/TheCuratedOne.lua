local mod	= DBM:NewMod("CuratedOne", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354276)
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
	CHAOS_BOLT = 51287,
	SOUL_FLAY = 45442,
	FEAR = 30530,
	MORTAL_FOUND = 25646,
	BLOOD_MIRROR = 70838,
	DEATH_AND_DECAY = 72108,
	COLDFLAME = 70823,
	COLDFLAME_SUMMON = 69138
}

--Timing table
local TIMERS = {
	[DIFFICULTY.NORMAL_10] = {
		BERSERK = 600,
		CHAOS_BOLT_CD = 7,
		FEAR_CD = 25,
		BLOOD_MIRROR_CD = 25,
		DEATH_AND_DECAY_CD = 20,
		COLDFLAME_CD = 10
	},
	[DIFFICULTY.NORMAL_25] = {
		BERSERK = 600,
		CHAOS_BOLT_CD = 7,
		FEAR_CD = 25,
		BLOOD_MIRROR_CD = 25,
		DEATH_AND_DECAY_CD = 20,
		COLDFLAME_CD = 10
	},
	[DIFFICULTY.HEROIC_10] = {
		BERSERK = 600,
		CHAOS_BOLT_CD = 7,
		FEAR_CD = 25,
		BLOOD_MIRROR_CD = 25,
		DEATH_AND_DECAY_CD = 20,
		COLDFLAME_CD = 10
	},
	[DIFFICULTY.HEROIC_25] = {
		BERSERK = 600,
		CHAOS_BOLT_CD = 7,
		FEAR_CD = 25,
		BLOOD_MIRROR_CD = 25,
		DEATH_AND_DECAY_CD = 20,
		COLDFLAME_CD = 10
	},
}

mod:RegisterEventsInCombat(
	EventString("SPELL_CAST_START", SPELLS.CHAOS_BOLT),
	EventString("SPELL_CAST_SUCCESS", SPELLS.SOUL_FLAY, SPELLS.FEAR, SPELLS.DEATH_AND_DECAY),
	EventString("SPELL_AURA_APPLIED_DOSE", SPELLS.MORTAL_FOUND),
	EventString("SPELL_AURA_APPLIED", SPELLS.BLOOD_MIRROR),
	EventString("SPELL_SUMMON", SPELLS.COLDFLAME_SUMMON)
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(TIMERS[difficulty].BERSERK)
--Soul Flay target warning
local warning_targeted_soul_flay = mod:NewSpecialWarningYou(SPELLS.SOUL_FLAY, nil, nil, nil, 1, 2)
--Chaos bolt target warning and timer
local warning_chaos_bolt = mod:NewSpecialWarningYou(SPELLS.CHAOS_BOLT, nil, nil, nil, 1, 2)
local timer_chaos_bolt = mod:NewCDTimer(TIMERS[difficulty].CHAOS_BOLT_CD, SPELLS.CHAOS_BOLT, nil, nil, nil, 2)
--Mortal Wound (from chaos bolt) stack warning
local mortal_wound_warning_threshold = 4
local mortal_wound_stack_warning = mod:NewSpecialWarningStack(SPELLS.MORTAL_FOUND, nil, mortal_wound_warning_threshold, nil, nil, 1, 6)
--Fear warning and timer
local timer_fear = mod:NewCDTimer(TIMERS[difficulty].FEAR_CD, SPELLS.FEAR, nil, nil, nil, 2)
--Ground damage warning
local ground_damage_warning = mod:NewSpecialWarningGTFO(SPELLS.DEATH_AND_DECAY, nil, nil, nil, 1, 8)
--Death and decay timer
local timer_death_and_decay = mod:NewCDTimer(TIMERS[difficulty].DEATH_AND_DECAY_CD, SPELLS.DEATH_AND_DECAY, nil, nil, nil, 2)
--Cold flame timer
local timer_cold_flame = mod:NewCDTimer(TIMERS[difficulty].COLDFLAME_CD, SPELLS.COLDFLAME, nil, nil, nil, 2)
--Blood Mirror Warning
local warning_blood_mirror = mod:NewSpecialWarningYou(SPELLS.BLOOD_MIRROR, nil, nil, nil, 1, 2)
local blood_mirror_timer = mod:NewCDTimer(TIMERS[difficulty].BLOOD_MIRROR_CD, SPELLS.BLOOD_MIRROR, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	difficulty = DBM:GetCurrentInstanceDifficulty() or DIFFICULTY.HEROIC_25
	player_name = UnitName("player")
	player_guid = UnitGUID("player")
	--Assume berserk ends it all
	mod:SetWipeTime(TIMERS[difficulty].BERSERK)
    --Register d&d and coldflame move warnings
	self:RegisterShortTermEvents(
		EventString("SPELL_PERIODIC_DAMAGE", SPELLS.DEATH_AND_DECAY, SPELLS.COLDFLAME),
		EventString("SPELL_PERIODIC_MISSED", SPELLS.DEATH_AND_DECAY, SPELLS.COLDFLAME)
	)
	--Start timers
	enrage_timer:Start(TIMERS[difficulty].BERSERK - delay)
	timer_fear:Start(TIMERS[difficulty].FEAR_CD - delay)
	timer_chaos_bolt:Start(TIMERS[difficulty].CHAOS_BOLT_CD - delay)
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
	if args.spellId == SPELLS.CHAOS_BOLT then
		--Start scanning for the target and reset the cd timer. 15 scans at 0.05 interval
		self:BossTargetScanner(args.sourceGUID, "chaos_bolt_target_scan", 0.05, 15)
		timer_chaos_bolt:Start(TIMERS[difficulty].CHAOS_BOLT_CD)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	--Soul Flay casting, show/play warning to the targeted playerspecWarnFearDispel
	if args.spellId == SPELLS.SOUL_FLAY and args.destName == player_name then
        warning_targeted_soul_flay:Show()
		warning_targeted_soul_flay:Play("targetyou")
    --Fear timer reset
    elseif args.spellId == SPELLS.FEAR then
		timer_fear:Start(TIMERS[difficulty].FEAR_CD)
	-- Death and decay timer rest
	elseif args.spellId == SPELLS.DEATH_AND_DECAY then
		timer_death_and_decay:Start(TIMERS[difficulty].DEATH_AND_DECAY_CD)
    end
end

function mod:SPELL_AURA_APPLIED(args)
	-- Blood mirror applied to us
	if args.spellId == SPELLS.BLOOD_MIRROR then
		if args.destName == player_name then
			warning_blood_mirror:Show()
			warning_blood_mirror:Play("targetyou")
		end
		blood_mirror_timer:Start(TIMERS[difficulty].BLOOD_MIRROR_CD)
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	--Mortal Found, if stacks > threashold, play warning
	if args.spellId == SPELLS.MORTAL_FOUND then
		local amount = args.amount or 1
		if args:IsPlayer() and amount >= mortal_wound_warning_threshold then
			mortal_wound_stack_warning:Show(args.amount)
			mortal_wound_stack_warning:Play("stackhigh")
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Death and Decay & ColdFlame move warning
	if (spellId == SPELLS.COLDFLAME or spellId == SPELLS.DEATH_AND_DECAY) and 
		destGUID == player_guid and self:AntiSpam() then
		ground_damage_warning:Show(spellName)
		ground_damage_warning:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE

function mod:SPELL_SUMMON(args)
	--Reset coldflame timer
	if args.spellId == SPELLS.COLDFLAME_SUMMON then
		timer_cold_flame:Start(TIMERS[difficulty].COLDFLAME_CD)
	end
end