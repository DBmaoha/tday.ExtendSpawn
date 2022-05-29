global function Sh_GamemodePFW_Init

global const string GAMEMODE_PFW = "pfw"

void function Sh_GamemodePFW_Init()
{
	// create custom gamemode
	AddCallback_OnCustomGamemodesInit( CreateGamemodePFW )
}

void function CreateGamemodePFW()
{
	GameMode_Create( GAMEMODE_PFW )
	GameMode_SetName( GAMEMODE_PFW, "鉄馭邊境戰爭" )
	GameMode_SetDesc( GAMEMODE_PFW, "摧毀或防守采集機。進攻方得四分勝，防守方於時間結束時獲勝" )
	GameMode_SetIcon( GAMEMODE_PFW, $"ui/menu/playlist/lts" )
	GameMode_SetDefaultScoreLimits( GAMEMODE_PFW, 1, 0 )
	GameMode_SetDefaultTimeLimits( GAMEMODE_PFW, 15, 0.0 )
	GameMode_SetGameModeAnnouncement( GAMEMODE_PFW, "fortwar_modeName" )
	GameMode_AddScoreboardColumnData( GAMEMODE_PFW, "#SCOREBOARD_SCORE", PGS_ASSAULT_SCORE, 3 )
	GameMode_AddScoreboardColumnData( GAMEMODE_PFW, "#SCOREBOARD_KILLS", PGS_PILOT_KILLS, 2 )
	GameMode_AddScoreboardColumnData( GAMEMODE_PFW, "#SCOREBOARD_TITAN_KILLS", PGS_TITAN_KILLS, 1 )
	GameMode_AddScoreboardColumnData( GAMEMODE_PFW, "#SCOREBOARD_GRUNT_KILLS", PGS_NPC_KILLS, 2 )
	GameMode_SetColor( GAMEMODE_PFW, [147, 204, 57, 255] )

	AddPrivateMatchMode( GAMEMODE_PFW ) // add to private lobby modes
	
	#if SERVER
		GameMode_AddServerInit( GAMEMODE_PFW, GamemodePFW_Init )
		GameMode_AddServerInit( GAMEMODE_PFW, GamemodeAITdmShared_Init )
	#elseif CLIENT
		GameMode_AddClientInit( GAMEMODE_PFW, ClGamemodePFW_Init )
	#endif
	#if !UI
		GameMode_SetScoreCompareFunc( GAMEMODE_PFW, CompareAssaultScore )
		GameMode_AddSharedInit( GAMEMODE_PFW, GamemodeAITdmShared_Init )
	#endif
}