local mod	= DBM:NewMod("MaidenRot", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354272)

mod:SetEncounterID(924)
mod:SetModelID(18720)

mod:RegisterCombat("combat")
mod:SetWipeTime(600)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 72930", -- Deep freeze
	"SPELL_AURA_APPLIED 12795" -- Frenzy
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(600)
--Deep freeze target warning and timer
local warning_targeted_deep_freeze	= mod:NewSpecialWarningYou(72930, nil, nil, nil, 1, 2)
local timer_deep_freeze		= mod:NewCDTimer(30, 72930, nil, nil, nil, 2)
--Frenzy warning
local warning_frenzy = mod:NewSpellAnnounce(12795, 3, nil, "Tank|Healer")


function mod:OnCombatStart(delay)
	enrage_timer:Start(-delay)
	--timer_deep_freeze:Start()
end

function mod:SPELL_CAST_START(args)
	--Deep freeze casting
	if args.spellId == 72930 then
		--Start scanning for the target and reset the cd timer. 15 scans at 0.05 interval
		self:BossTargetScanner(args.sourceGUID, "deep_freeze_target_scan", 0.05, 15)
		timer_deep_freeze:Start()
	end
end


function mod:deep_freeze_target_scan(targetname)
	--Is the target us? if so show/play warning
	if not targetname then return end
	if targetname == UnitName("player") then
		warning_targeted_deep_freeze:Show()
		warning_targeted_deep_freeze:Play("targetyou")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	--Frenzy buff applied to the boss => massive melee haste gained
	if args.spellId == 12795 then
		warning_frenzy:Show()
		warning_frenzy:Play("defensive")
	end
end