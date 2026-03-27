
local mod	= DBM:NewMod("ArchMageAnton", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354288)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

mod.MAX_PHASES = 3

--Spell ids of the counter
mod.SPELLS = {
	BERSERK = {KEY = "BERSERK", NAME = "Berserk", ID = {DEFAULT = 26662}},
    SHADOWBOLT = {KEY = "SHADOWBOLT", NAME = "Shadow Bolt", ID = {DEFAULT = 29317}},
    FROSTBOLT = {KEY = "FROSTBOLT", NAME = "Frostbolt", ID = {DEFAULT = 55802}},
    PRESENCE_OF_FROST = {KEY = "PRESENCE_OF_FROST", NAME = "Presence of Frost", ID = {DEFAULT = 9250005}},
    PRESENCE_OF_SHADOW = {KEY = "PRESENCE_OF_SHADOW", NAME = "Presence of Shadow", ID = {DEFAULT = 9250004}},
    CHILL = {KEY = "CHILL", NAME = "Chill", ID = {DEFAULT = 55699, [DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] =  28547}},
    BLIGHT = {KEY = "BLIGHT", NAME = "Blight", ID = {DEFAULT = 70285}},
    IMPENDING_DESPAIR = {KEY = "IMPENDING_DESPAIR", NAME = "Impending Despair", ID = {DEFAULT = 72426}},
    DESPAIR_STRICKEN = {KEY = "DESPAIR_STRICKEN", NAME = "Despair Stricken", ID = {DEFAULT = 72428}},
    AURA_OF_SUFFERING = {KEY = "AURA_OF_SUFFERING", NAME = "Aura of Suffering", ID = {DEFAULT = 41292}},
	SPELL_DISRUPTION = {KEY = "SPELL_DISRUPTION", NAME = "Spell Disruption", ID = {DEFAULT = 29310}}
}

--We transition based on his health %
mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 60, WARNING = 65, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO},
	[DBM_BEHAVIOR.PHASES.PHASE_TWO] = {THRESHOLD = 10, WARNING = 15, NEXT = DBM_BEHAVIOR.PHASES.PHASE_THREE}
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
	[mod.SPELLS.BLIGHT.KEY] = {DEFAULT = 15},
	[mod.SPELLS.IMPENDING_DESPAIR.KEY] = {DEFAULT = 15},
	[mod.SPELLS.SPELL_DISRUPTION.KEY] = {DEFAULT = 30}
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
		DEFAULT = {
			TIMER = {type = "NewBerserkTimer"}, TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}}
		}
	},
	[mod.SPELLS.BLIGHT.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningDispel", filter = "RemoveDisease"},
			TIMER = {type = "NewCDTimer"},
			TIMER_STARTS = {PHASE_START_2 = {}, SPELL_AURA_APPLIED = {}},
			WARNING_SHOW = {SPELL_AURA_APPLIED = {}},
			PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "dispelnow"}}
		}
	},
	[mod.SPELLS.IMPENDING_DESPAIR.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningDispel", filter = "RemoveDisease"},
			TIMER = {type = "NewCDTimer"},
			TIMER_STARTS = {PHASE_START_2 = {}, SPELL_AURA_APPLIED = {}},
			WARNING_SHOW = {SPELL_AURA_APPLIED = {}},
			PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "dispelnow"}}
		}
	},
	[mod.SPELLS.SPELL_DISRUPTION.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningYou"},
			TIMER = {type = "NewCDTimer"},
			TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_SUCCESS = {}},
			WARNING_SHOW = {SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.OnSelf}},
			PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "targetyou", condition = DBM_BEHAVIOR.OnSelf}}
		}
	},
	[mod.SPELLS.CHILL.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningGTFO"},
			WARNING_SHOW = {
				SPELL_PERIODIC_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}, 
				SPELL_PERIODIC_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}
			},
			PLAY_SOUND = {
				SPELL_PERIODIC_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "watchfeet"}, 
				SPELL_PERIODIC_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "watchfeet"}
			}
		}
	},
}

local boss_unit_id = "boss1"

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	DBM_BEHAVIOR.CombatStartFetchData(mod)
	DBM_BEHAVIOR.StartPhaseMonitor(mod, boss_unit_id)
	DBM_BEHAVIOR.StartSpellCastingMonitor(mod)
	DBM_BEHAVIOR.HandleModelEvent("ON_COMBAT_START", mod, {offset=-delay})
end

function mod:OnCombatEnd(wipe)
    --Stop the monitors
	DBM_BEHAVIOR.StopPhaseMonitor(mod)
	DBM_BEHAVIOR.StopSpellCastingMonitor(mod)
end

--Initialize the model
DBM_BEHAVIOR.CreateBossModel(mod)
DBM_BEHAVIOR.InitPhaseMonitor(mod, boss_unit_id, mod.MAX_PHASES)