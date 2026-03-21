local mod	= DBM:NewMod("WotlkShadeAran", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354280)

mod:SetEncounterID(924)
mod:SetModelID(18720)

mod:RegisterCombat("combat")
mod:SetWipeTime(600)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 29954 29953 30004 37054 29973", -- Frostbolt, Fireball, Flame Weath, Water Bolt, Arcane Explosion
	"SPELL_AURA_APPLIED 29991", -- Chains of Ice
	"SPELL_DAMAGE 29956" -- Arcane Missiles
)

--Enrage timer
local enrage_timer = mod:NewBerserkTimer(600)

--Kick group count
mod.vb.kick_groups = 3
mod.vb.current_kick_group = 0
--Kick warning for Frostbolt and Fireball
local frost_fire_kick_warning = mod:NewSpecialWarningInterruptCount(29954, "HasInterrupt", nil, nil, 1, 2)
--Flame Wreath warning and timer
local flame_wreath_warning = mod:NewSpecialWarningMove(30004, nil, nil, nil, 1, 2)
local flame_wreath_timer = mod:NewCDTimer(20, 30004, nil, nil, nil, 2)
--Chains of ice dispell warning
local warning_chains_of_ice = mod:NewSpecialWarningDispel(29991, "MagicDispeller", nil, nil, 1, 2)
--Warning to start killing the water elementals
local kill_adds_warning = mod:NewSpecialWarning("Kill the adds!", nil, nil, nil, 1, 2)
--Arcane Explosion runaway warning and timer
local arcane_explosion_warning = mod:NewSpecialWarningMove(29973, nil, nil, nil, 1, 2)
--Arcane Missiles warning
local arcane_missiles_warning = mod:NewSpecialWarningYou(29956, nil, nil, nil, 1, 2)

--Blizzard damage warning
local blizzard_damage_warning = mod:NewSpecialWarningGTFO(29951, nil, nil, nil, 1, 8)

function mod:OnCombatStart(delay)
	enrage_timer:Start(-delay)
	--Register even for blizzard damage
	self:RegisterShortTermEvents(
		"SPELL_PERIODIC_DAMAGE 29951",
		"SPELL_PERIODIC_MISSED 29951"
	)
end

function mod:SPELL_CAST_START(args)
	--Kick Frostbolt and Fireball warning
	if args.spellId == 29954 or args.spellId == 29953 then
		--Figure out the current group number
		self.vb.current_kick_group = self.vb.current_kick_group + 1
		if self.vb.current_kick_group == (self.vb.kick_groups+1) then
			self.vb.current_kick_group = 1
		end
		--Give the warning
		frost_fire_kick_warning:Show(args.sourceName, self.vb.current_kick_group)
		frost_fire_kick_warning:Play("kick"..self.vb.current_kick_group.."r")
	--Flame Wreath warning to stop moving
	elseif args.spellId == 30004 then
		flame_wreath_warning:Show()
		flame_wreath_warning:Play("aesoon")
		flame_wreath_timer:Start()
	elseif args.spellId == 37054 and self:AntiSpam() then
		kill_adds_warning:Show()
	elseif args.spellId == 29973 then
		arcane_explosion_warning:Show()
		arcane_explosion_warning:Play("runaway")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	--Chains of ice dispell warning
	if args.spellId == 29991 then
		warning_chains_of_ice:Show(args.destName)
	end
end

function mod:SPELL_DAMAGE(sourceGUID, _, _, _, _, _, spellId)
	--Arcane Missiles warning
	if spellId == 29956 and self:AntiSpam() then
		arcane_missiles_warning:Show()
		arcane_missiles_warning:Play("defensive")
	end
end

function mod:SPELL_PERIODIC_DAMAGE(_, _, _, destGUID, _, _, spellId, spellName)
    --Death and Decay & ColdFlame move warning
	if (spellId == 29951) and destGUID == UnitGUID("player") and self:AntiSpam() then
		blizzard_damage_warning:Show(spellName)
		blizzard_damage_warning:Play("watchfeet")
	end
end
mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE