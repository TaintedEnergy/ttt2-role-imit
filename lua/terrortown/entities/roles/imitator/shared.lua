if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_imit.vmt")
	util.AddNetworkString("TTT2ImitationsRequest")
	util.AddNetworkString("TTT2ImitationsResponse")
end

function ROLE:PreInitialize()
	self.color = Color(185, 46, 73, 255)
	self.abbr = "imit" -- abbreviation
	
	self.scoreKillsMultiplier = 1
	self.scoreTeamKillsMultiplier = -16
	
	self.preventFindCredits = true
	self.preventKillCredits = true
	self.preventTraitorAloneCredits = true
	
	self.fallbackTable = {}
	self.defaultTeam = TEAM_TRAITOR
	
	-- ULX ConVars
	self.conVarData = {
		pct = 0.13,
		maximum = 1,
		minPlayers = 5,
		togglable = true,
		random = 30,

		traitorButton = 0,
		credits = 0,
		creditsTraitorKill = 0,
		creditsTraitorDead = 0,
		shopFallback = SHOP_DISABLED
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_TRAITOR)
end

local NUM_PLYS_AT_ROUND_BEGIN = 0
local ROLE_INNOCENT_ASTERISK = -1

local function IsInSpecDM(ply)
	return SpecDM and (ply.IsGhost and ply:IsGhost())
end

local function GetNumPlayers()
	if NUM_PLYS_AT_ROUND_BEGIN > 0 then
		return NUM_PLYS_AT_ROUND_BEGIN
	end
	local num_players = 0
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsSpec() and not IsInSpecDM(ply) then
			num_players = num_players + 1
		end
	end
	return num_players
end

local function DestroyImitations(ply)
	if SERVER then
		ply.imitations = nil
		net.Start("TTT2ImitationsResponse")
		net.Send(ply)
	else --CLIENT
		local client = LocalPlayer()
		if client.imit_frame and client.imit_frame.Close then
			client.imit_frame:Close()
		end
	end
end

hook.Add("TTTBeginRound", "TTTBeginRoundImitator", function() NUM_PLYS_AT_ROUND_BEGIN = GetNumPlayers() end)

local function ResetAllImitatorData()
	if SERVER then
		for _, ply in ipairs(player.GetAll()) do
			DestroyImitations(ply)
			ply.imit_has_voted = nil
		end
	end
	NUM_PLYS_AT_ROUND_BEGIN = 0
end
hook.Add("TTTPrepareRound", "TTTPrepareRoundImitator", ResetAllImitatorData)
hook.Add("TTTEndRound", "TTTEndRoundImitator", ResetAllImitatorData)

if SERVER then
	local function CreateClientImitationsEntry(role_id)
		local out_role_id = role_id
		if not GetConVar("ttt2_imitator_hide_secret_roles"):GetBool() then return out_role_id end
		--In a few cases the client is lied to about the role that they have (Currently that's the Shinigami, Wrath, Revenant and Lycanthrope).
		--For these cases, obscure them alongside the role that they're pretending to be, so that the client won't be able to unravel the role's secret.
		local num_players = GetNumPlayers()
		local shini_can_exist = (SHINIGAMI and GetConVar("ttt_shinigami_enabled"):GetBool() and num_players >= GetConVar("ttt_shinigami_min_players"):GetInt())
		local rev_can_exist = (REVENANT and GetConVar("ttt_revenant_enabled"):GetBool() and num_players >= GetConVar("ttt_revenant_min_players"):GetInt())
		local cloaked_wrath_can_exist = (WRATH and GetConVar("ttt_wrath_enabled"):GetBool() and num_players >= GetConVar("ttt_wrath_min_players"):GetInt() and GetConVar("ttt_wrath_cannot_see_own_role"):GetBool())
		local cloaked_lyc_can_exist = (LYCANTHROPE and GetConVar("ttt_lycanthrope_enabled"):GetBool() and num_players >= GetConVar("ttt_lycanthrope_min_players"):GetInt() and not GetConVar("ttt2_lyc_know_role"):GetBool())
		if (role_id == ROLE_INNOCENT and (shini_can_exist or rev_can_exist or cloaked_wrath_can_exist or cloaked_lyc_can_exist)) or
			(SHINIGAMI and role_id == ROLE_SHINIGAMI) or
			(REVENANT and role_id == ROLE_REVENANT) or
			(WRATH and role_id == ROLE_WRATH and GetConVar("ttt_wrath_cannot_see_own_role"):GetBool()) or
			(LYCANTHROPE and role_id == ROLE_LYCANTHROPE and not GetConVar("ttt2_lyc_know_role"):GetBool()) then
			out_role_id = ROLE_INNOCENT_ASTERISK
		end
		return out_role_id
	end
	
	function CreateImitations(ply)
		local imitations_list = {}
		local num_plys = GetNumPlayers()
		
		local inno_role_list = {}
		local role_data_list = roles.GetList()
		for i = 1, #role_data_list do
			local role_data = role_data_list[i]
			if role_data.notSelectable or role_data.index == ROLE_NONE then continue end
			
			local enabled = true
			local min_players = 0
			if not role_data.builtin then
				enabled = GetConVar("ttt_" .. role_data.name .. "_enabled"):GetBool()
				min_players = GetConVar("ttt_" .. role_data.name .. "_min_players"):GetInt()
			end
			if not enabled or min_players > num_plys then
				continue
			end
			
			if role_data.defaultTeam == TEAM_INNOCENT and (role_data.index == ROLE_INNOCENT or role_data.baserole == ROLE_INNOCENT) then
				inno_role_list[#inno_role_list + 1] = role_data.index
			end
		end
		
		for i = 1, GetConVar("ttt2_imitator_num_choices"):GetInt() do
			if #inno_role_list > 0 then
				imitations_list[#imitations_list + 1] = table.ExtractRandomEntry(inno_role_list)
			else
				break
			end
		end
		
		ply.imitations = imitations_list
		
		net.Start("TTT2ImitationsRequest")
		local client_imitations = {}
		for i = 1, #ply.imitations do
			client_imitations[i] = CreateClientImitationsEntry(ply.imitations[i])
		end
		net.WriteTable(client_imitations)
		net.Send(ply)
	end
	
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		if GetRoundState() ~= ROUND_POST then
			CreateImitations(ply)
		end
	end
	
	net.Receive("TTT2ImitationsResponse", function(len, ply)
		local imitations_id = net.ReadInt(16)
		local imitations_id_is_valid = (ply.imitations and imitations_id > 0 and imitations_id <= #ply.imitations)
		
		if GetRoundState() == ROUND_ACTIVE and ply:Alive() and not IsInSpecDM(ply) and imitations_id_is_valid then
			local role_id = ply.imitations[imitations_id]
			DestroyImitations(ply)
			
			ply:SetRole(role_id, TEAM_TRAITOR)
			SendFullStateUpdate()
			
			ply.imit_has_voted = true
		else
			DestroyImitations(ply)
		end
	end)
	
	hook.Add("TTT2PostPlayerDeath", "TTT2PostPlayerDeathImitator", function(victim, inflictor, attacker)
		if GetRoundState() == ROUND_ACTIVE and IsValid(victim) and victim:IsPlayer() and victim.imitations then
			DestroyImitations(victim)
		end
	end)

	hook.Add("TTT2CheckCreditAward", "ImitatorAvoidCreditAward", function(victim, inflictor, attacker)
		return not victim.imit_has_voted
	end)

	hook.Add("TTT2ConfirmPlayer", "TTT2ImitHideTeam", function(confirmed, finder, corpse)
		if IsValid(confirmed) and corpse and CORPSE.GetPlayer(corpse).imit_has_voted and CORPSE.GetPlayer(corpse):GetBaseRole() == ROLE_INNOCENT then
			confirmed:ConfirmPlayer(true)
			SendRoleListMessage(CORPSE.GetPlayer(corpse):GetSubRole(), TEAM_INNOCENT, {confirmed:EntIndex()})
			events.Trigger(EVENT_BODYFOUND, finder, corpse)

			return false
		end
	end)
end

if CLIENT then
	local function GetImitationsEntryStr(maybe_role_id)
		if maybe_role_id >= 0 then
			local role_data = roles.GetByIndex(maybe_role_id)
			return LANG.TryTranslation(role_data.name)
		end
		
		--Otherwise the role is lying about what it really is. Only give a hint (in the form of an asterisk) as to what it could be.
		
		--ROLE_INNOCENT_ASTERISK
		local role_data = roles.GetByIndex(ROLE_INNOCENT)
		return LANG.TryTranslation(role_data.name) .. "*"
	end
	
	net.Receive("TTT2ImitationsRequest", function()
		local client = LocalPlayer()
		local imitations = net.ReadTable()
		
		DestroyImitations()
		client.imit_frame = vgui.Create("DFrame")
		
		client.imit_frame:SetTitle(LANG.TryTranslation("IMITATIONS_TITLE_" .. IMITATOR.name))
		client.imit_frame:SetPos(5, ScrH() / 3)
		client.imit_frame:SetSize(150, 10 + (20 * (#imitations + 1)))
		client.imit_frame:SetVisible(true)
		client.imit_frame:SetDraggable(false)
		client.imit_frame:ShowCloseButton(false)
		
		if #imitations <= 0 then
			LANG.Msg("BAD_IMITATIONS_" .. IMITATOR.name, nil, MSG_MSTACK_ROLE)
			return
		end
		
		local i = 1
		for imitations_id, maybe_role_id in pairs(imitations) do
			local imitations_entry_str = GetImitationsEntryStr(maybe_role_id)
			local button = vgui.Create("DButton", client.imit_frame)
			button:SetText(imitations_entry_str)
			button:SetPos(0, 10 + (20 * i))
			button:SetSize(150,20)
			button.DoClick = function()
				net.Start("TTT2ImitationsResponse")
				net.WriteInt(imitations_id, 16)
				net.SendToServer()
				DestroyImitations()
			end
			i = i + 1
		end
	end)
	
	net.Receive("TTT2ImitationsResponse", function() DestroyImitations() end)
end