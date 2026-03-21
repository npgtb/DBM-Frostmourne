local mod	= DBM:NewMod("Scythewing", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354284)

mod:SetEncounterID(924)
mod:SetModelID(18720)

mod:RegisterCombat("combat")
mod:SetWipeTime(600)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 41410 71047", -- Deaden, Blistering Cold
    "SPELL_CAST_SUCCESS 55696 72906", -- Tail swipe, Frostbolt Volley
	"SPELL_AURA_APPLIED 41410" -- Deaden
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(600)
--Deaden warning and timer
local deaden_warning = mod:NewSpecialWarningYou(41410, nil, nil, nil, 1, 2)
local timer_deaden = mod:NewCDTimer(15, 41410, nil, nil, nil, 2)
--Blistering Cold warning and timer
local blistering_cold_warning = mod:NewSpecialWarningGTFO(71047, nil, nil, nil, 1, 8)
local timer_blistering_cold = mod:NewCDTimer(60, 71047, nil, nil, nil, 2)
--Frostbolt Volley CD timer
local timer_frostbolt_volley = mod:NewCDTimer(20, 72906, nil, nil, nil, 2)
--Tailsweep CD timer
local timer_tailsweep = mod:NewCDTimer(10, 55696, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	enrage_timer:Start(-delay)
end

function mod:SPELL_CAST_START(args)
	--Deaden casting
	if args.spellId == 41410 then
		timer_deaden:Start()
    elseif args.spellId == 71047 then
        timer_blistering_cold:Start()
        blistering_cold_warning:Show()
        blistering_cold_warning:Play("runaway")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	-- Tailsweep
	if args.spellId == 55696 then
        timer_tailsweep:Start()
    elseif args.spellId == 72906 then
        timer_frostbolt_volley:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	-- Deaden applied to us
	if args.spellId == 41410 then
		if args.destName == UnitName("player") then
			deaden_warning:Show()
			deaden_warning:Play("targetyou")
		end
	end
end
