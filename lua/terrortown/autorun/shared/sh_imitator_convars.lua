CreateConVar("ttt2_imitator_num_choices", "3", {FCVAR_ARCHIVE, FCVAR_NOTFIY})
CreateConVar("ttt2_imitator_hide_secret_roles", "1", {FCVAR_ARCHIVE, FCVAR_NOTFIY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicUndecidedCVars", function(tbl)
	tbl[ROLE_IMITATOR] = tbl[ROLE_IMITATOR] or {}

	table.insert(tbl[ROLE_IMITATOR], {
		cvar = "ttt2_imitator_num_choices",
		slider = true,
		min = 2,
		max = 25,
		decimal = 0,
		desc = "ttt2_imitator_num_choices (def: 3)"
	})

	table.insert(tbl[ROLE_UNDECIDED], {
		cvar = "ttt2_imitator_hide_secret_roles",
		checkbox = true,
		desc = "ttt2_imitator_hide_secret_roles (def: 1)"
	})
end)

hook.Add("TTT2SyncGlobals", "AddUndecidedGlobals", function()
	SetGlobalInt("ttt2_imitator_num_choices", GetConVar("ttt2_imitator_num_choices"):GetInt())
	SetGlobalBool("ttt2_imitator_hide_secret_roles", GetConVar("ttt2_imitator_hide_secret_roles"):GetBool())
end)

cvars.AddChangeCallback("ttt2_imitator_num_choices", function(name, old, new)
	SetGlobalInt("ttt2_imitator_num_choices", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_imitator_hide_secret_roles", function(name, old, new)
	SetGlobalBool("ttt2_imitator_hide_secret_roles", tobool(tonumber(new)))
end)

