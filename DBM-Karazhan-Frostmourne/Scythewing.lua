local mod	= DBM:NewMod("Scythewing", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354284)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

mod.MAX_PHASES = 4

--Spell ids of the counter
mod.SPELLS = {
	BERSERK = {NAME = "Berserk", ID = 26662},
	DEADEN = {NAME = "Deaden", ID = 41410},
	BLISTERING_COLD = {NAME = "Blistering Cold", ID = 71047},
	TAILSWEEP = {NAME = "Tail Sweep", ID = 55696},
	FROSTBOLT_VOLLEY = {NAME = "Frostbolt Volley", ID = 72906},
}

--We transition based on his health %
mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 80, WARNING = 85, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO},
	[DBM_BEHAVIOR.PHASES.PHASE_TWO] = {THRESHOLD = 50, WARNING = 55, NEXT = DBM_BEHAVIOR.PHASES.PHASE_THREE},
	[DBM_BEHAVIOR.PHASES.PHASE_THREE] = {THRESHOLD = 20, WARNING = 25, NEXT = DBM_BEHAVIOR.PHASES.PHASE_FOUR}
}
mod.PHASE_TRANSITION_THRESHOLDS = {
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
}

--Timing tables
mod.TIMINGS_PHASE_DEFAULT = {
	[mod.SPELLS.BERSERK.ID] = {DEFAULT = 600},
	[mod.SPELLS.DEADEN.ID] = {DEFAULT = 30, ON_COMBAT_START = 15},
	[mod.SPELLS.BLISTERING_COLD.ID] = {DEFAULT = 60},
	[mod.SPELLS.FROSTBOLT_VOLLEY.ID] = {DEFAULT = 20},
	[mod.SPELLS.TAILSWEEP.ID] = {DEFAULT = 10}
}
mod.TIMINGS = {
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = { PHASE_DEFAULT = mod.TIMINGS_PHASE_DEFAULT },
}

--Define the model behavior
mod.BEHAVIOR = {
	[mod.SPELLS.BERSERK.ID] = {
		TIMER = {type = "NewBerserkTimer"}, TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}}
	},
	[mod.SPELLS.DEADEN.ID] = {
		WARNING = {type = "NewSpecialWarningYou"},
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_START = {}},
		WARNING_SHOW = {SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.OnSelf}},
		PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "targetyou"}}
	},
	[mod.SPELLS.TAILSWEEP.ID] = {
		TIMER = {type = "NewCDTimer"}, TIMER_STARTS = {ON_COMBAT_START = {}, SPELL_CAST_SUCCESS = {}}
	},
	[mod.SPELLS.FROSTBOLT_VOLLEY.ID] = {
		TIMER = {type = "NewCDTimer"}, TIMER_STARTS = {PHASE_START_3 = {}, SPELL_CAST_SUCCESS = {}}
	},
	[mod.SPELLS.BLISTERING_COLD.ID] = {
		WARNING = {type = "NewSpecialWarningGTFO"},
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {PHASE_START_2 = {}, SPELL_CAST_START = {}},
		WARNING_SHOW = {SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.OnSelf}},
		PLAY_SOUND = {SPELL_CAST_START = {sound = "runaway"}}
	}
}

local boss_unit_id = "boss1"

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	DBM_BEHAVIOR.CombatStartFetchData(mod)
	DBM_BEHAVIOR.StartPhaseMonitor(mod, boss_unit_id)
	DBM_BEHAVIOR.StartSpellCastingMonitor(mod)
	DBM_BEHAVIOR.HandleModelEvent("ON_COMBAT_START", mod, {offset=delay})
end

function mod:OnCombatEnd(wipe)
    --Stop the monitors
	DBM_BEHAVIOR.StopPhaseMonitor(mod)
	DBM_BEHAVIOR.StopSpellCastingMonitor(mod)
end

--Initialize the model
DBM_BEHAVIOR.CreateBossModel(mod)
DBM_BEHAVIOR.InitPhaseMonitor(mod, boss_unit_id, mod.MAX_PHASES)