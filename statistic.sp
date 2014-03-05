#include <sourcemod>
#include <sourcemod>
#include <console>
#define MAX_PLAYERS 10
#define TEAM_GOOD 2
#define TEAM_BAD 3
#define SQL_BUFFER 128

//Global vars
new Handle:db
new String:error[255] 
new match_id
// Store players
new String:player_name[MAX_PLAYERS][32]
new player_id[MAX_PLAYERS]
new player_team[MAX_PLAYERS]
new player_entid[MAX_PLAYERS]
new user_id[MAX_PLAYERS]

public Plugin:myinfo = {
	name = "statistics",
	author = "serkamikadze, kissarat",
	description = "Log player statistic",
	version = "1.1",
	url = "none"
}
public getIndexByPlayerID(PlayerID)
{
	for(new i=0;i<MAX_PLAYERS;i++)
		if(player_id[i]==PlayerID)
		{
			return i
		}
	return -1
}


//Return game name
bool:GetName(const String:game_name[], String:name[], maxlength) {
	new String:tmp[256]
	new Handle:kv = CreateKeyValues("lang")
	FileToKeyValues(kv, "dota_english.txt")
	if (!KvJumpToKey(kv, "Tokens")) {
		strcopy(name, maxlength, game_name)
		return false
	}
	KvGetString(kv, game_name, name, 32)
	CloseHandle(kv)
	return true
}

bool:GetEntName(id,String:buffer[])
{
	new st = SQL_PrepareQuery(db, "SELECT name FROM entid WHERE id=?", error, sizeof(error))
	if (INVALID_HANDLE == st) 
	{
		PrintToServer(error)
		return false
	}
	SQL_BindParamInt(st, 0, id, false)
	SQL_Execute(st)
	SQL_FetchRow(st)
	if(SQL_GetRowCount(st))
		return false
	new String:name[32]
	SQL_FetchString(st, 0, name, 32);
	GetName(name,buffer,32)
	return true
}

// Check client team
public bool:OnClientConnect(client_id, String:rejectmsg[], maxlen) {
	new userid = GetClientUserId(client_id)
	new index = -1
	for(new i = 0;i<MAX_PLAYERS;i++)
	{
		if(user_id[i]==userid && user_id[i]>=0)
		{
			index = i
		}
	}
	if(index<0)
	{
		strcopy(rejectmsg, maxlen, "You don't allow to connect")
		return false
	}
	SQL_LockDatabase(db)
	new st = SQL_PrepareQuery(db, "SELECT team FROM match_user WHERE match_id=? AND `index`=?", error, sizeof(error))
	if (INVALID_HANDLE == st) {
		PrintToServer(error)
		return false
	}
	SQL_BindParamInt(st, 0, match_id, false)
	SQL_BindParamInt(st, 	1, index, false)
	if (INVALID_HANDLE == st) {
		PrintToServer(error)
		return false
	}
	SQL_Execute(st)
	new bool:result = true
	if(!SQL_GetRowCount(st))
	{
		strcopy(rejectmsg, maxlen, "You don't allow to connect")
		result = false
	}
	CloseHandle(st)
	SQL_UnlockDatabase(db)
	return result
}
//Get PlayerID
public GetPlayerID(userid) {
	new offset = FindSendPropOffs("CDOTAPlayer", "m_iPlayerID")
	new client = GetClientOfUserId(userid)
	return GetEntData(client, offset)
}

public GetTotal(userid, String:name[]) {
	new client = GetClientOfUserId(userid)
	new offset = FindSendPropOffs("CDOTA_PlayerResource", name)
	return GetEntData(client, offset)
}

//mix_start command
//mix_start "STEAM_1:0:75447624,STEAM_1:0:18774902" 2,3
public Action:MixStart(client,args) {
	if (2 != args)
	{
		PrintToConsole(client, "Invalid arguments count")
		return Plugin_Handled
	}
	new Handle:h = SQL_Query(db,"INSERT INTO `match`() VALUES()")
	match_id = SQL_GetInsertId(h)
	CloseHandle(h)
	new length = 256
	new String:arg[length]
	new String:steam_id[MAX_PLAYERS][20]
	new String:team[MAX_PLAYERS][4]
	GetCmdArg(1, arg, length)
	new steam_id_count = ExplodeString(arg, ",", steam_id, MAX_PLAYERS, 20)
	GetCmdArg(2, arg, length)
	new team_count = ExplodeString(arg, ",", team, MAX_PLAYERS, 4)
	if(steam_id_count != team_count)
	{
		PrintToConsole(client, "Invalid team or steamid count")
		return Plugin_Handled
	}
	for (new i=0; i<steam_id_count; i++) {
		new team_id = StringToInt(team[i])
		if (TEAM_GOOD == team_id || TEAM_BAD == team_id) 
		{
			new st = SQL_PrepareQuery(db, "INSERT INTO match_user(match_id, steam_id, team) VALUES (?,?,?)", error, sizeof(error))
			if (INVALID_HANDLE == st)
				PrintToServer(error)
			SQL_BindParamInt(st, 0, match_id, false)
			SQL_BindParamString(st, 1, steam_id[i], false)
			SQL_BindParamInt(st, 2, team_id, false)
			SQL_Execute(st)
			CloseHandle(st)
		}
	}
	PrintToConsole(client, "Statistic::Player and team selected, match_id=%i",match_id)
	return Plugin_Handled
}

public SQL_Callback(Handle:owner, Handle:h, const String:error[], any:data) {
	if (h == INVALID_HANDLE)
		PrintToServer(error)
}

public LogEvent(String:name[], String:message[]) {
	new String:sql[SQL_BUFFER]
	Format(sql, SQL_BUFFER, "INSERT INTO event(match_id, name, message) VALUES (%d, '%s', '%s')", match_id, name, message)
	SQL_TQuery(db, SQL_Callback, sql)
}


public Action:Timer_UpdateTimer(Handle:timer)
{
	//SQL_FastQuery(db, "тут запрос на обновление статуса")
	return Plugin_Continue;
}

public SQL_ConnectCallback(Handle:owner, Handle:h, const String:error[], any:data) {
	if (h == INVALID_HANDLE) {
		PrintToServer(error)
		return
	}
	SQL_TQuery(h, SQL_Callback, "SET NAMES 'utf8'")
}

public OnPluginStart() {
	PrintToServer("---- Plugin:Statistic loaded ----")
	CreateTimer(60.0, Timer_UpdateTimer, _, TIMER_REPEAT);
	new String:tmp[32]
	for(new i=0;i<MAX_PLAYERS;i++)
	{
		player_id[i]=-1
		player_entid[i]=-1
		user_id[i]=-1
	}
	// Connect to MySQL
	db = SQL_TConnect(SQL_ConnectCallback)
	
	// Register console command
	//RegServerCmd("mix_start", MixStart)
	RegAdminCmd("mix_start",MixStart,ADMFLAG_RCON)
	
	// Hooks for game event
	HookEvent("player_connect",				 player_connect)
	HookEvent("player_connect_full",		 player_connect_full)
	HookEvent("dota_player_pick_hero",		 dota_player_pick_hero)
	HookEvent("dota_item_purchased",		 dota_item_purchased)
	HookEvent("dota_player_learned_ability", dota_player_learned_ability)
	HookEvent("dota_player_used_ability",	 dota_player_used_ability)
	HookEvent("dota_player_gained_level",	 dota_player_gained_level)
	HookEvent("entity_killed",				 entity_killed)
	HookEvent("dota_match_done",			 dota_match_done)
}

public player_connect(Handle:event, const String:name[], bool:dontBroadcast) {
	new String:steam_id[32]
	new String:user_name[32]
	new index = GetEventInt(event, "index")
	new userid = GetEventInt(event, "userid")
	GetEventString(event, "networkid", steam_id, 32)
	GetEventString(event, "name", user_name, 32)
	strcopy(player_name[index], 32, user_name)
	user_id[index] = userid
	SQL_LockDatabase(db)
	new st = SQL_PrepareQuery(db, "UPDATE match_user SET user_name=?, `index`=?, connected=NOW() WHERE match_id=? AND steam_id=?", error, sizeof(error))
	if (INVALID_HANDLE == st) {
		PrintToServer(error)
		SQL_UnlockDatabase(db)
		return
	}
	SQL_BindParamString(st, 0, user_name,	false)
	SQL_BindParamInt(st, 	1, index,		false)
	SQL_BindParamInt(st, 	2, match_id,	false)
	SQL_BindParamString(st, 3, steam_id,	false)
	new result = SQL_Execute(st);
	if (INVALID_HANDLE == result) {
		SQL_GetError(st, error, sizeof(error))
		PrintToServer(error)
	}
	CloseHandle(st)
	SQL_UnlockDatabase(db)
}

public player_connect_full(Handle:event, const String:name[], bool:dontBroadcast) {
	new client_id = GetClientOfUserId(GetEventInt(event, "userid"))
	new index = GetEventInt(event, "index")
	SQL_LockDatabase(db)
	new st = SQL_PrepareQuery(db, "SELECT team FROM match_user WHERE match_id=? AND `index`=?", error, sizeof(error))
	if (st == INVALID_HANDLE) {
		PrintToServer(error)
		SQL_UnlockDatabase(db)
		return
	}
	SQL_BindParamInt(st, 0, match_id, false)
	SQL_BindParamInt(st, 1, index, false)
	SQL_Execute(st)
	SQL_FetchRow(st)
	new team = SQL_FetchInt(st, 0)
	player_team[index] = team
	ChangeClientTeam(client_id, team)
	if (TEAM_GOOD == team)
		LogEvent(player_name[index], "присоединился к светлой стороне")
	else if (TEAM_BAD == team)
		LogEvent(player_name[index], "присоединился к силам тьмы")
	CloseHandle(st)
	SQL_UnlockDatabase(db)
}


public dota_player_pick_hero(Handle:event, const String:name[], bool:dontBroadcast) {
	new index = GetEventInt(event, "player")-1
	player_entid[index] = GetEventInt(event, "heroindex")
	player_id[index] = GetPlayerID(user_id[index])
	new String:message[64]
	new String:h_name[32]
	new String:name[32]
	PrintToServer("Player index:%i",index)
	PrintToServer("PlayerID:%i",player_id[index])
	GetEventString(event, "hero", h_name, sizeof(h_name))
	if(!GetName(h_name,name,32))
	{
		PrintToServer("Invalid hero name:%s",h_name)
		return
	}
	Format(message,64,"выбрал героя: %s",name)
	LogEvent(player_name[index], message)
}

public dota_item_purchased(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetEventInt(event, "PlayerID")
	new index = getIndexByPlayerID(id)
	if(index < 0)
		return
	new String:message[64]
	new String:item_name[32]
	new String:name[32]
	GetEventString(event, "itemname", item_name, sizeof(item_name))
	if(!GetName(item_name,name,256))
	{
		PrintToServer("Invalid item name:%s",item_name)
		return
	}
	Format(message,64,"купил %s",name)
	LogEvent(player_name[index], message)
}


public dota_player_learned_ability(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetEventInt(event, "PlayerID")
	new index = getIndexByPlayerID(id)
	if(index < 0)
		return
	new String:message[64]
	new String:ability_name[32]
	new String:name[32]
	GetEventString(event, "abilityname", ability_name, sizeof(ability_name))
	if(!GetName(ability_name,name,256))
	{
		PrintToServer("Invalid ability name:%s",ability_name)
		return
	}
	Format(message,64,"изучил способность %s",name)
	LogEvent(player_name[index], message)
}


public dota_player_used_ability(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetEventInt(event, "PlayerID")
	new index = getIndexByPlayerID(id)
	if(index < 0)
		return
	new String:message[64]
	new String:ability_name[32]
	new String:name[32]
	GetEventString(event, "abilityname", ability_name, sizeof(ability_name))
	if(!GetName(ability_name,name,256))
	{
		PrintToServer("Invalid ability name:%s",ability_name)
		return
	}
	Format(message,64,"использовал %s",name)
	LogEvent(player_name[index], message)
}


public dota_player_gained_level(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetEventInt(event, "PlayerID")
	new index = getIndexByPlayerID(id)
	if(index < 0)
		return
	new String:message[64]
	new level = GetEventInt(event, "level")
	Format(message,64,"получил %i уровень",level)
	LogEvent(player_name[index], message)
}

public entity_killed(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetEventInt(event, "entindex_attacker")
	new killed = GetEventInt(event, "entindex_killed")
	new String:attacker_name[32]
	new String:killer_name[32]
	new String:message[32]
	for(new i=0;i<MAX_PLAYERS;i++)
	{
		if(player_entid[i]==attacker && player_entid[i]==killed)
		{
			LogEvent(player_name[i], "совершил самоубийство")
			return
		}
		if(player_entid[i]==attacker)
		{
			for(new y=0;y<MAX_PLAYERS;y++)
			{
				if(player_entid[y]==killed)
				{
					strcopy(killer_name,32,player_name[y])
					Format(message,32,"убил %s",player_name[y])
					LogEvent(player_name[i], message)
					return
				}
			}
			new String:tmp[32]
			if(GetEntName(killed,tmp))
			{
				Format(message,32,"убил %s",tmp)
				LogEvent(player_name[i], message)
				return
			}				
		}
		if(player_entid[i]==killed)
		{
			for(new y=0;y<MAX_PLAYERS;y++)
			{
				if(player_entid[y]==attacker)
				{
					strcopy(killer_name,32,player_name[y])
					Format(message,32,"был убит %s",player_name[y])
					LogEvent(player_name[i], message)
					return
				}
			}
			new String:tmp[32]
			if(GetEntName(attacker,tmp))
			{
				Format(message,32,"был убит %s",tmp)
				LogEvent(player_name[i], message)
				return
			}
			else
			{
				if(player_team[i]==2)
				{
					LogEvent(player_name[i], "был убит силами зла")
					return
				}
				if(player_team[i]==3)
				{
					LogEvent(player_name[i], "был убит силами добра")
					return
				}
			}
		}
	}
}

public dota_match_done(Handle:event, const String:name[], bool:dontBroadcast) {
	new winner = GetEventInt(event, "winningteam")
	if (TEAM_GOOD == winner)
		LogEvent("Конец игры:", "победили силы добра")
	else if (TEAM_BAD == winner)
		LogEvent("Конец игры:", "зло победило")
	SQL_LockDatabase(db)
	for (new i=0; i<MAX_PLAYERS; i++) {
		new player_index = player_entid[i]
		if (player_index  >= 0) {
			new Handle:q = SQL_PrepareQuery(db, "UPDATE match_user SET death=?, assist=?, kill=?, gold=?, xp=?, level=? WHERE match_id=? AND index=?", error, sizeof(error))
			if (INVALID_HANDLE == q) {
				PrintToServer(error);
				SQL_UnlockDatabase(db)
				return
			}
			SQL_BindParamInt(q, 0, GetTotal(user_id[i], "m_iDeaths"))
			SQL_BindParamInt(q, 1, GetTotal(user_id[i], "m_iAssists"))
			SQL_BindParamInt(q, 2, GetTotal(user_id[i], "m_iKills"))
			SQL_BindParamInt(q, 3, GetTotal(user_id[i], "m_iTotalEarnedGold"))
			SQL_BindParamInt(q, 4, GetTotal(user_id[i], "m_iTotalEarnedXP"))
			SQL_BindParamInt(q, 5, GetTotal(user_id[i], "m_iLevel"))
			SQL_BindParamInt(q, 6, match_id)
			SQL_BindParamInt(q, 7, player_index)
			SQL_Execute(q)
			if (SQL_GetError(q, error, sizeof(error)))
				PrintToServer(error)
			CloseHandle(q)
		}
	}
	SQL_UnlockDatabase(db)
}