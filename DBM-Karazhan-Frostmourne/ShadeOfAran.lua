
local mod	= DBM:NewMod("WotlkShadeAran", "DBM-Karazhan-Frostmourne")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20250929220131")
mod:SetCreatureID(354280)
mod:SetEncounterID(924)
mod:SetModelID(18720)
mod:RegisterCombat("combat")

mod.MAX_PHASES = 2

--Spell ids of the counter
mod.SPELLS = {
	BERSERK = {NAME = "Berserk", ID = 26662},
	FROSTBOLT = {NAME = "Frostbolt", ID = 29954},
	FIREBALL = {NAME = "Fireball", ID = 29953},
	FLAME_WREATH_CAST = {NAME = "Flame Wreath", ID = 30004},
	FLAME_WREATH = {NAME = "Flame Wreath", ID = 29946},
	WATER_BOLT = {NAME = "Water Bolt", ID = 37054},
	ARCANE_EXPLOSION = {NAME = "Arcane Explosion", ID = 29973},
	CHAINS_OF_ICE = {NAME = "Chains of Ice", ID = 29991},
	SUMMON_BLIZZARD = {NAME = "Summon Blizzard", ID = 29969},
	BLIZZARD = {NAME = "Blizzard", ID = 29951},
	ARCANE_MISSILES = {NAME = "Arcane Missiles", ID = 29956},
	COUNTERSPELL = {NAME = "Counterspell", ID = 29961}
}

--We transition based on his health %
mod.PHASE_TRANSITION_THRESHOLDS_DEFAULT = {
	[DBM_BEHAVIOR.PHASES.PHASE_ONE] = {THRESHOLD = 40, WARNING = 45, NEXT = DBM_BEHAVIOR.PHASES.PHASE_TWO}
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
	[mod.SPELLS.FLAME_WREATH_CAST.ID] = {DEFAULT = 63},
	[mod.SPELLS.ARCANE_EXPLOSION.ID] = {DEFAULT = 67},
	[mod.SPELLS.SUMMON_BLIZZARD.ID] = {DEFAULT = 63},
	[mod.SPELLS.CHAINS_OF_ICE.ID] = {DEFAULT = 60},
	[mod.SPELLS.COUNTERSPELL.ID] = {DEFAULT = 10}
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
	[mod.SPELLS.FLAME_WREATH_CAST.ID] = {
		WARNING = {type = "NewSpecialWarningMove"},
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {SPELL_CAST_START = {}},
		WARNING_SHOW = {SPELL_CAST_START = {}},
		PLAY_SOUND = {SPELL_CAST_START = {sound = "aesoon"}}
	},
	[mod.SPELLS.ARCANE_EXPLOSION.ID] = {
		WARNING = {type = "NewSpecialWarningMove"},
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {SPELL_CAST_START = {}},
		WARNING_SHOW = {SPELL_CAST_START = {}},
		PLAY_SOUND = {SPELL_CAST_START = {sound = "runaway"}}
	},
	[mod.SPELLS.CHAINS_OF_ICE.ID] = {
		WARNING = {type = "NewSpecialWarningDispel", filter = "MagicDispeller"},
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_AURA_APPLIED = {}},
		WARNING_SHOW = {SPELL_AURA_APPLIED = { condition = DBM_BEHAVIOR.CanDispell, inject = "destName" }}
	},
	[mod.SPELLS.ARCANE_MISSILES.ID] = {
		WARNING = {type = "NewSpecialWarningYou"},
		WARNING_SHOW = {SPELL_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}},
		PLAY_SOUND = {SPELL_DAMAGE = {sound = "targetyou", condition = DBM_BEHAVIOR.OnSelfAntiSpam}}
	},
	[mod.SPELLS.SUMMON_BLIZZARD.ID] = {
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_START = {}},
	},
	[mod.SPELLS.COUNTERSPELL.ID] = {
		WARNING = {type = "NewSpecialWarningYou"},
		TIMER = {type = "NewCDTimer"},
		TIMER_STARTS = {ON_COMBAT_START = {inject = "offset"}, SPELL_CAST_START = {}},
		WARNING_SHOW = {SPELL_CAST_START = {condition = DBM_BEHAVIOR.OnSelf}},
		PLAY_SOUND = {SPELL_CAST_START = {sound = "targetyou", condition = DBM_BEHAVIOR.OnSelf}}
	},
	[mod.SPELLS.BLIZZARD.ID] = {
		WARNING = {type = "NewSpecialWarningMove"},
		WARNING_SHOW = {
			SPELL_PERIODIC_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}, 
			SPELL_PERIODIC_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam}
		},
		PLAY_SOUND = {
			SPELL_PERIODIC_DAMAGE = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "runaway"},
			SPELL_PERIODIC_MISSED = {condition = DBM_BEHAVIOR.OnSelfAntiSpam, sound = "runaway"}
		}
	},
	[DBM_BEHAVIOR.SPELL_UNKNOWN_ID] = {
		WARNING = {type = "NewSpecialWarning", text = "Kill the adds!"},
		WARNING_SHOW = {PHASE_START_2 = {}},
	},
	[mod.SPELLS.FROSTBOLT.ID] = {
		WARNING = {type = "NewSpecialWarningInterruptCount", filter = "HasInterrupt"},
		WARNING_SHOW = {
			SPELL_CAST_START = {
				override = function (boss_mod, trigger_data, warning, args)
					--Warn the current kick group to kick the caster
					if boss_mod.player_can_kick then
						warning:Show(args.sourceName, boss_mod.SolveKickGroup())
					end
				end
			}
		},
		PLAY_SOUND = {
			SPELL_CAST_START = {
				sound = "kick",
				override = function (boss_mod, trigger_data, warning, args)
					--Execute order Warning => Play. We only play sound here
					if boss_mod.player_can_kick then
						local base_sound = trigger_data.sound or "kick"
						local kick_audio_string = base_sound .. boss_mod.vb.current_kick_group .. "r"
						warning:Play(kick_audio_string)
					end
				end
			}
		}
	},
	[mod.SPELLS.FIREBALL.ID] = {
		WARNING = {type = "NewSpecialWarningInterruptCount", filter = "HasInterrupt"},
		WARNING_SHOW = {
			SPELL_CAST_START = {
				override = function (boss_mod, trigger_data, warning, args)
					--Warn the current kick group to kick the caster
					if boss_mod.player_can_kick then
						warning:Show(args.sourceName, boss_mod.SolveKickGroup())
					end
				end
			}
		},
		PLAY_SOUND = {
			SPELL_CAST_START = {
				sound = "kick",
				override = function (boss_mod, trigger_data, warning, args)
					--Execute order Warning => Play. We only play sound here
					if boss_mod.player_can_kick then
						local base_sound = trigger_data.sound or "kick"
						local kick_audio_string = base_sound .. boss_mod.vb.current_kick_group .. "r"
						warning:Play(kick_audio_string)
					end
				end
			}
		}
	},
}

local boss_unit_id = "boss1"
mod.vb.kick_group_count = 3
mod.vb.current_kick_group = 0

--Solves the current kick group
function mod:SolveKickGroup()
	--Solve the current kick group number
	mod.vb.current_kick_group = mod.vb.current_kick_group + 1
	if mod.vb.current_kick_group > mod.vb.kick_group_count then
		mod.vb.current_kick_group = 1
	end
	return mod.vb.current_kick_group
end

function mod:OnCombatStart(delay)
	DBM_BEHAVIOR.CombatStartFetchData(mod)
	DBM_BEHAVIOR.StartPhaseMonitor(mod, boss_unit_id)
	DBM_BEHAVIOR.HandleModelEvent("ON_COMBAT_START", mod, {offset=-delay})
end

function mod:OnCombatEnd(wipe)
    --Stop the health monitor
	DBM_BEHAVIOR.StopPhaseMonitor(mod)
end



--Initialize the model
DBM_BEHAVIOR.CreateBossModel(mod)
DBM_BEHAVIOR.InitPhaseMonitor(mod, boss_unit_id, mod.MAX_PHASES)
