local mod	= DBM:NewMod("ArchMageAnton", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354288)

mod:SetEncounterID(924)
mod:SetModelID(18720)

mod:RegisterCombat("combat")
mod:SetWipeTime(600)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 70285 72426" -- Blight, Impending Despair
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(600)
--Warning to dispell Blight
local warning_dispell_blight = mod:NewSpecialWarningDispel(70285, "RemoveDisease", nil, nil, 1, 2)
--Warning to dispell Impending Despair
local warning_dispell_despair = mod:NewSpecialWarningDispel(72426, "MagicDispeller", nil, nil, 1, 2)
--Ground damage warning
local warning_chill = mod:NewSpecialWarningGTFO(55699, nil, nil, nil, 1, 8)

function mod:OnCombatStart(delay)
	enrage_timer:Start(-delay)
    --Register Chill move warnings
	self:RegisterShortTermEvents(
		"SPELL_PERIODIC_DAMAGE 55699",
		"SPELL_PERIODIC_MISSED 55699"
	)
end

function mod:SPELL_AURA_APPLIED(args)
    --Blight
    if args.spellId == 70285 then
        -- Only show this to players who can dispel Disease/Nature
        warning_dispell_blight:Show(args.destName)
        warning_dispell_blight:Play("dispelnow")
    --Impending Despair
    elseif args.spellId == 72426 then
        warning_dispell_despair:Show(args.destName)
        warning_dispell_despair:Play("dispelnow")
    end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Death and Decay & ColdFlame move warning
	if (spellId == 55699) and destGUID == UnitGUID("player") and self:AntiSpam() then
		warning_chill:Show(spellName)
		warning_chill:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE