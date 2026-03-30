
local mod	= DBM:NewMod("ArchMageAnton", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354288)
mod:SetEncounterID(924)
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
    BLIGHT_SMALL = {
		KEY = "BLIGHT_SMALL", NAME = "Blight", ID = {
			DEFAULT = 9250042,
			[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = 9250041,
			[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = 9250042,
			[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = 9250043,
			[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = 9250044
		}
	},
    BLIGHT_BIG = {
		KEY = "BLIGHT_BIG", NAME = "Blight", ID = {
			DEFAULT = 9250046,
			[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = 9250045,
			[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = 9250046,
			[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = 9250047,
			[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = 9250048
		}
	},
	CURSE_OF_DOOM = {
		KEY = "CURSE_OF_DOOM", NAME = "Curse of Doom", ID = {
			DEFAULT = 9250050,
			[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = 9250049,
			[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = 9250050,
			[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = 9250051,
			[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = 9250052
		}
	},
    AURA_OF_SUFFERING = {KEY = "AURA_OF_SUFFERING", NAME = "Aura of Suffering", ID = {DEFAULT = 41292}},
    FINGER_OF_DEATH = {KEY = "FINGER_OF_DEATH", NAME = "Finger of Death", ID = {DEFAULT = 31984}},
	SPELL_DISRUPTION = {KEY = "SPELL_DISRUPTION", NAME = "Spell Disruption", ID = {DEFAULT = 29310}},
	PERMAFROST = {KEY = "PERMAFROST", NAME = "Permafrost", ID = {DEFAULT = 67856}},
	SHROUD_OF_DARKNESS = {KEY = "SHROUD_OF_DARKNESS", NAME = "Shroud of Darkness", ID = {DEFAULT = 54525}}
}

--We transition based on his health %
mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 60, WARNING = 65, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO},
	[DBM_BEHAVIOR.PHASES.PHASE_TWO] = {THRESHOLD = 10, WARNING = 15, NEXT = DBM_BEHAVIOR.PHASES.PHASE_THREE}
}
mod.PHASE_HEROIC_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 60, WARNING = 65, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO},
	[DBM_BEHAVIOR.PHASES.PHASE_TWO] = {THRESHOLD = 20, WARNING = 25, NEXT = DBM_BEHAVIOR.PHASES.PHASE_THREE}
}
mod.PHASE_TRANSITION_THRESHOLDS = {
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_10] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.NORMAL_25] = { TRANSITION_DEFAULT = mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_10] = { TRANSITION_DEFAULT = mod.PHASE_HEROIC_TRANSITION_THRESHOLDS_DEFAULT },
	[DBM_BEHAVIOR.DIFFICULTY.HEROIC_25] = { TRANSITION_DEFAULT = mod.PHASE_HEROIC_TRANSITION_THRESHOLDS_DEFAULT },
}

--Timing tables
mod.TIMINGS_PHASE_DEFAULT = {
	[mod.SPELLS.BERSERK.KEY] = {DEFAULT = 600},
	[mod.SPELLS.CURSE_OF_DOOM.KEY] = {DEFAULT = 15},
	[mod.SPELLS.PERMAFROST.KEY] = {DEFAULT = 30, ON_COMBAT_START = 20},
	[mod.SPELLS.SHROUD_OF_DARKNESS.KEY] = {DEFAULT = 12},
	[DBM_BEHAVIOR.SPELL_UNKNOWN_KEY] = {
		WATER_ELEMENTAL_TIMER = {DEFAULT = 75, ON_COMBAT_START = 50},
		DEATH_ELEMENTAL_TIMER = {DEFALT = 65, ON_COMBAT_START = 40}
	}
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
		TIMER = {DEFAULT = {TIMER = {type = "NewBerserkTimer"}, TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}}}}
	},
	[mod.SPELLS.BLIGHT_SMALL.KEY] = {
		APPLIED_WARN = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningDispel", filter = "RemoveDisease", option_name = "Small Blight cure warning"}, 
				WARNING_SHOW = {SPELL_AURA_APPLIED = {inject = "destName"}}}
		}
	},
	[mod.SPELLS.BLIGHT_BIG.KEY] = {
		APPLIED_WARN = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningDispel", filter = "RemoveDisease", option_name = "Big Blight cure warning"},
				WARNING_SHOW = {SPELL_AURA_APPLIED = {inject = "destName"}},
				PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "dispelnow", condition = DBM_BEHAVIOR.CanCleanseDisease}}
			}
		}
	},
	[mod.SPELLS.CURSE_OF_DOOM.KEY] = {
		APPLIED_WARN = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningDispel", filter = "RemoveCurse", option_name = "Curse of Doom decurse warning"},
				TIMER = {type = "NewCDTimer", option_name = "Curse of Doom cooldown"},
				TIMER_STARTS = {PHASE_START_2 = {}, SPELL_AURA_APPLIED = {}},
				WARNING_SHOW = {SPELL_AURA_APPLIED = {inject = "destName"}},
				PLAY_SOUND = {SPELL_AURA_APPLIED = {sound = "helpdispel", condition = DBM_BEHAVIOR.CanDecurse}}
			}
		}
	},
	--[[[mod.SPELLS.FINGER_OF_DEATH.KEY] = {
		CAST_WARN = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningYou"},
				WARNING_SHOW = {SPELL_CAST_START = {condition = DBM_BEHAVIOR.OnSelf}},
				PLAY_SOUND = {SPELL_CAST_START = {condition = DBM_BEHAVIOR.OnSelf, sound = "targetyou"}}
			}
		}
	},--]]
	[mod.SPELLS.PERMAFROST.KEY] = {
		DAMAGE_WARN = {
			DEFAULT = {
				TIMER = {type = "NewCDTimer", option_name = "Permafrost damage announcement"},
				TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_SUCCESS = {}},
				WARNING = {type = "NewSpecialWarningGTFO", option_name = "Permafrost damage warning"},
				WARNING_SHOW = {
					SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}, 
					SPELL_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}
				},
				PLAY_SOUND = {
					SPELL_AURA_APPLIED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "watchfeet"}, 
					SPELL_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "watchfeet"}
				}
			}
		}
	},
	[mod.SPELLS.CHILL.KEY] = {
		DAMAGE_WARN = {
			DEFAULT = {
				WARNING = {type = "NewSpecialWarningGTFO", option_name = "Blizzard damage announcement"},
				WARNING_SHOW = {
					SPELL_PERIODIC_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}, 
					SPELL_PERIODIC_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}
				},
				PLAY_SOUND = {
					SPELL_PERIODIC_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "watchfeet"}, 
					SPELL_PERIODIC_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "watchfeet"}
				}
			}
		}
	},
	[mod.SPELLS.SHROUD_OF_DARKNESS.KEY] = {
		APPLIED_WARN = {
			DEFAULT = {
				TIMER = {type = "NewCDTimer", option_name = "Shroud of Darkness cooldown"},
				TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_SUCCESS = {}},
				WARNING = {type = "NewSpecialWarningStack", stacks = 2, option_name = "Shroud of Darkness stack warning"},
				WARNING_SHOW = {
					SPELL_AURA_APPLIED_DOSE = {
						condition = function(boss_mod, args, spell_id, update_subtype) 
							return args.amount > 2 and DBM_BEHAVIOR.OnSelf(boss_mod, args) 
						end,
						inject = "amount"
					}
				},
				PLAY_SOUND = {
					SPELL_AURA_APPLIED_DOSE = {
						condition = function(boss_mod, args, spell_id, update_subtype) 
							return args.amount > 2 and DBM_BEHAVIOR.OnSelf(boss_mod, args) 
						end,
						sound = "stackhigh"
					}
				},
			}
		}
	},
	[DBM_BEHAVIOR.SPELL_UNKNOWN_KEY] = {
		WATER_ELEMENTAL_TIMER = {
			DEFAULT = {
				TIMER = {
					type = "NewCDTimer", spell_id = 31687, option_name = "Summon Water Elemental cooldown"
				},
				TIMER_STARTS = {
					ON_COMBAT_START = {inject = "offset"}, 
					MANUAL_NEW_ENTITY = {
						entity = "Water Elemental",
						condition = function(boss_mod, args, spell_id, update_subtype) 
							return args.entity ~= nil and args.entity == "Water Elemental"
						end
					}
				}
			}
		},
		DEATH_ELEMENTAL_TIMER = {
			DEFAULT = {
				TIMER = {
					type = "NewCDTimer", spell_id = 697, text = "Death Elemental", option_name = "Summon Death Elemental cooldown"
				},
				TIMER_STARTS = {
					ON_COMBAT_START = {inject = "offset"}, 
					MANUAL_NEW_ENTITY = {
						entity = "Death Elemental",
						condition = function(boss_mod, args, spell_id, update_subtype) 
							return args.entity ~= nil and args.entity == "Death Elemental"
						end
					}
				}
			}
		}
	}
}

local boss_unit_id = "boss1"

function mod:OnCombatStart(delay)
	--Fetch difficulty from dbm
	DBM_BEHAVIOR.CombatStartFetchData(mod)
	DBM_BEHAVIOR.StartPhaseMonitor(mod, boss_unit_id)
	DBM_BEHAVIOR.StartNewEntityMonitor(mod)
	DBM_BEHAVIOR.HandleModelEvent("ON_COMBAT_START", mod, {offset=-delay})
end

function mod:OnCombatEnd(wipe)
    --Stop the monitors
	DBM_BEHAVIOR.StopNewEntityMonitor(mod)
	DBM_BEHAVIOR.StopPhaseMonitor(mod)
end

function mod:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
    print("HERE WE GO")
end

--Initialize the model
DBM_BEHAVIOR.CreateBossModel(mod)
DBM_BEHAVIOR.InitPhaseMonitor(mod, boss_unit_id, mod.MAX_PHASES)