local mod	= DBM:NewMod("CuratedOne", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354276)

mod:SetEncounterID(924)
mod:SetModelID(18720)

mod:RegisterCombat("combat")
mod:SetWipeTime(600)

mod:RegisterEventsInCombat(
    "SPELL_CAST_START 51287", -- Chaos Bolt
	"SPELL_CAST_SUCCESS 45442 30530", -- Soul Flay, Fear
	"SPELL_AURA_APPLIED_DOSE 25646", -- Mortal Found
	"SPELL_AURA_APPLIED 70838" -- Blood Mirror 
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(600)
--Soul Flay target warning
local warning_targeted_soul_flay = mod:NewSpecialWarningYou(45442, nil, nil, nil, 1, 2)
--Chaos bolt target warning and timer
local warning_chaos_bolt = mod:NewSpecialWarningYou(51287, nil, nil, nil, 1, 2)
local timer_chaos_bolt = mod:NewCDTimer(7, 51287, nil, nil, nil, 2)
--Mortal Wound (from chaos bolt) stack warning
local mortal_wound_warning_threshold = 4
local mortal_wound_stack_warning = mod:NewSpecialWarningStack(25646, nil, mortal_wound_warning_threshold, nil, nil, 1, 6)
--Fear warning and timer
local timer_fear = mod:NewCDTimer(25, 30530, nil, nil, nil, 2)
--Ground damage warning
local warning_death_and_decay = mod:NewSpecialWarningGTFO(72108, nil, nil, nil, 1, 8)
--Blood Mirror Warning
local warning_blood_mirror = mod:NewSpecialWarningYou(70838, nil, nil, nil, 1, 2)
local blood_mirror_timer = mod:NewCDTimer(25, 70838, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
    enrage_timer:Start(-delay)
    --Register d&d and coldflame move warnings
	self:RegisterShortTermEvents(
		"SPELL_PERIODIC_DAMAGE 72108 70823",
		"SPELL_PERIODIC_MISSED 72108 70823"
	)
end

function mod:chaos_bolt_target_scan(targetname)
	--Is the target us? if so show/play warning
	if not targetname then return end
	if targetname == UnitName("player") then
		warning_chaos_bolt:Show()
		--warning_chaos_bolt:Play("targetyou")
	end
end

function mod:SPELL_CAST_START(args)
	--Chaos bolt casting
	if args.spellId == 51287 then
		--Start scanning for the target and reset the cd timer. 15 scans at 0.05 interval
		self:BossTargetScanner(args.sourceGUID, "chaos_bolt_target_scan", 0.05, 15)
		timer_chaos_bolt:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	--Soul Flay casting, show/play warning to the targeted playerspecWarnFearDispel
	if args.spellId == 45442 and args.destName == UnitName("player") then
        warning_targeted_soul_flay:Show()
		warning_targeted_soul_flay:Play("targetyou")
    --Fear timer reset
    elseif args.spellId == 30530 then
		timer_fear:Start()
    end
end

function mod:SPELL_AURA_APPLIED(args)
	-- Blood mirror applied to us
	if args.spellId == 70838 then
		if args.destName == UnitName("player") then
			warning_blood_mirror:Show()
			warning_blood_mirror:Play("targetyou")
		end
		blood_mirror_timer:Start()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	--Mortal Found, if stacks > threashold, play warning
	if args.spellId == 25646 then
		local amount = args.amount or 1
		if args:IsPlayer() and amount >= mortal_wound_warning_threshold then
			mortal_wound_stack_warning:Show(args.amount)
			mortal_wound_stack_warning:Play("stackhigh")
		end
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Death and Decay & ColdFlame move warning
	if (spellId == 72108 or spellId == 70823) and destGUID == UnitGUID("player") and self:AntiSpam() then
		warning_death_and_decay:Show(spellName)
		warning_death_and_decay:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE