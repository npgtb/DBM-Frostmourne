local mod	= DBM:NewMod("CuratedOne", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354276)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

mod.MAX_PHASES = 4

--Spell ids of the counter
mod.SPELLS = {
	BERSERK = {KEY = "BERSERK", NAME = "Berserk", ID = {DEFAULT = 26662}},
	CHAOS_BOLT = {KEY = "CHAOS_BOLT", NAME = "Chaos Bolt", ID = {DEFAULT = 51287}},
	SOUL_FLAY = {KEY = "SOUL_FLAY", NAME = "Soul Flay", ID = {DEFAULT = 45442}},
	FEAR = {KEY = "FEAR", NAME = "Fear", ID = {DEFAULT = 30530}},
	AURA_OF_FEAR = {KEY = "AURA_OF_FEAR", NAME = "Aura of Fear", ID = {DEFAULT = 9250009}},
	MORTAL_FOUND = {KEY = "MORTAL_FOUND", NAME = "Mortal Wound", ID = {DEFAULT = 25646}},
	BLOOD_MIRROR = {KEY = "BLOOD_MIRROR", NAME = "Blood Mirror", ID = {DEFAULT = 70838}},
	DEATH_AND_DECAY = {KEY = "DEATH_AND_DECAY", NAME = "Death and Decay", ID = {DEFAULT = 72108, [DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = 71001}},
	COLDFLAME = {KEY = "COLDFLAME", NAME = "Coldflame", ID = {DEFAULT = 70823, [DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = 69146}},
	COLDFLAME_SUMMON = {KEY = "COLDFLAME_SUMMON", NAME = "Coldflame", ID = {DEFAULT = 69138}}
}

--We transition based on his health %
mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 75, WARNING = 80, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO},
	[DBM_BEHAVIOR.PHASES.PHASE_TWO] = {THRESHOLD = 40, WARNING = 45, NEXT = DBM_BEHAVIOR.PHASES.PHASE_THREE},
	[DBM_BEHAVIOR.PHASES.PHASE_THREE] = {THRESHOLD = 15, WARNING = 20, NEXT = DBM_BEHAVIOR.PHASES.PHASE_FOUR}
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
	[mod.SPELLS.CHAOS_BOLT.KEY] = {DEFAULT = 8.45},
	[mod.SPELLS.FEAR.KEY] = {DEFAULT = 25},
	[mod.SPELLS.BLOOD_MIRROR.KEY] = {DEFAULT = 25},
	[mod.SPELLS.DEATH_AND_DECAY.KEY] = {DEFAULT = 20},
	[mod.SPELLS.COLDFLAME_SUMMON.KEY] = {DEFAULT = 10}
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
	[mod.SPELLS.FEAR.KEY] = {
		DEFAULT = {
			TIMER = {type = "NewCDTimer"},TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_SUCCESS = {}}
		}
	},
	[mod.SPELLS.CHAOS_BOLT.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningYou"},
			TIMER = {type = "NewCDTimer"},
			TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_START = {}},
			SCAN_TRIGGER = {SPELL_CAST_START = {frequency = 0.05, scan_attempts = 10}},
			WARNING_SHOW = {ON_SCAN = {}},
			PLAY_SOUND = {ON_SCAN = {sound = "targetyou"}}
		}
	},
	[mod.SPELLS.BLOOD_MIRROR.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningYou"},
			TIMER = {type = "NewCDTimer"},
			TIMER_STARTS = {PHASE_START_3 = {}, SPELL_AURA_APPLIED = {}},
			WARNING_SHOW = {SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.IsTargetOrDest}},
			PLAY_SOUND = {SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.IsTargetOrDest, sound = "targetyou"}}
		}
	},
	[mod.SPELLS.SOUL_FLAY.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningYou"},
			WARNING_SHOW = {SPELL_CAST_SUCCESS = {condition = DBM_BEHAVIOR.OnSelf}},
			PLAY_SOUND = {SPELL_CAST_SUCCESS = {condition = DBM_BEHAVIOR.OnSelf, sound = "targetyou"}}
		}
	},
	[mod.SPELLS.MORTAL_FOUND.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningStack", threshold = 4},
			WARNING_SHOW = {
				SPELL_AURA_APPLIED_DOSE = {
					condition = function(boss_mod, args, spell_id, update_subtype) 
						return args.amount > 4 and DBM_BEHAVIOR.OnSelf(boss_mod, args) 
					end,
					inject = "amount"
				}
			},
			PLAY_SOUND = {
				SPELL_AURA_APPLIED_DOSE = {
					condition = function(boss_mod, args, spell_id, update_subtype) 
						return args.amount > 4 and DBM_BEHAVIOR.OnSelf(boss_mod, args) 
					end,
					sound = "stackhigh"
				}
			},
		}
	},
	[mod.SPELLS.COLDFLAME_SUMMON.KEY] = {
		DEFAULT = {
			TIMER = {type = "NewCDTimer"},TIMER_STARTS = {PHASE_START_4 = {}, SPELL_SUMMON = {}}
		}
	},
	[mod.SPELLS.COLDFLAME.KEY] = {
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
	[mod.SPELLS.DEATH_AND_DECAY.KEY] = {
		DEFAULT = {
			TIMER = {type = "NewCDTimer"},
			TIMER_STARTS = {PHASE_START_2 = {}, SPELL_CAST_SUCCESS = ""},
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
	[mod.SPELLS.AURA_OF_FEAR.KEY] = {
		DEFAULT = {
			WARNING = {type = "NewSpecialWarningLookAway"},
			WARNING_SHOW = {MANUAL_CAST_MONITOR = {condition = DBM_BEHAVIOR.AntiSpam}},
			PLAY_SOUND = {MANUAL_CAST_MONITOR = {condition = DBM_BEHAVIOR.AntiSpam, sound = "turnaway"}}
		}
	}
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