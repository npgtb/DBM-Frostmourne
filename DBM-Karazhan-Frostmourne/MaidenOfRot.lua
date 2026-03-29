local mod	= DBM:NewMod("MaidenRot", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354272)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

--Spell ids of the counter
mod.SPELLS = {
	BERSERK = {KEY = "BERSERK", NAME = "Berserk", ID = {DEFAULT = 26662}},
	DEEP_FREEZE = {KEY = "DEEP_FREEZE", NAME = "Deep Freeze", ID = {DEFAULT = 72930}},
	FRENZY = {KEY = "FRENZY", NAME = "Frenzy", ID = {DEFAULT = 12795}}
}

--We transition based on his health %
mod.MAX_PHASES = 2
mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 20, WARNING = 25, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO}
}
mod.PHASE_TRANSITION_THRESHOLDS = {
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
}

--Timing tables
mod.TIMINGS_PHASE_DEFAULT = {
	[mod.SPELLS.BERSERK.KEY] = {DEFAULT = 600},
	[mod.SPELLS.DEEP_FREEZE.KEY] = {DEFAULT = 30}
}
mod.TIMINGS = {
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
}

--Define the model behavior
mod.BEHAVIOR = {
	[mod.SPELLS.BERSERK.KEY] = {
		TIMER = {
			DEFAULT = {TIMER = {type = "NewBerserkTimer"}, TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}}}
		}
	},
	[mod.SPELLS.DEEP_FREEZE.KEY] = {
		WARN_CAST = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningYou"},
				TIMER = {type = "NewCDTimer"},
				TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_START = {}},
				SCAN_TRIGGER = {SPELL_CAST_START = {}},
				WARNING_SHOW = {ON_SCAN = {}},
				PLAY_SOUND = {ON_SCAN = {sound = "targetyou"}}
			}
		}
	},
	[mod.SPELLS.FRENZY.KEY] = {
		WARN_AURA = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningDefensive"},
				WARNING_SHOW = {SPELL_AURA_APPLIED = {}},
				PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "defensive", condition = DBM_BEHAVIOR.IsTank}}
			}
		}
	}
}
local boss_unit_id = "boss1"

function mod:OnCombatStart(delay)
	DBM_BEHAVIOR.CombatStartFetchData(mod)
	DBM_BEHAVIOR.StartPhaseMonitor(mod, boss_unit_id)
	DBM_BEHAVIOR.HandleModelEvent("ON_COMBAT_START", mod, {offset=-delay})
end

function mod:OnCombatEnd(wipe)
	DBM_BEHAVIOR.StopPhaseMonitor(mod)
end

--Initialize the model
DBM_BEHAVIOR.CreateBossModel(mod)
DBM_BEHAVIOR.InitPhaseMonitor(mod, boss_unit_id, mod.MAX_PHASES)