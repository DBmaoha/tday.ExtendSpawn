global function ClGamemodePFW_Init

struct
{
	bool wantToCloseStore = false
	bool canToggleStore = false
	array<var> waveRuis
	table<string, var> waveAwardRuis
	bool showWaveIntro = false
	var harvesterRui
	entity harvester

	entity droz = null
	entity davis = null
	array<string> drozDropshipAnims = [ "commander_DLC_flyin_Droz_finally", "commander_DLC_flyin_Droz_everytime", "commander_DLC_flyin_Droz_brother" ]
	array<asset> drozDropshipProps = [ FD_MODEL_DROZ_TABLET_PROP, FD_MODEL_DROZ_TABLET_PROP, DATA_KNIFE_MODEL ] //Make sure this lines up in the same order as Droz's animations!
	array< string > davisDropshipAnims = [ "commander_DLC_flyin_Davis_finally", "commander_DLC_flyin_Davis_everytime", "commander_DLC_flyin_Davis_brother" ]

	table<entity,var> boostStoreRuis

	array<var> turretRuis
	var scoreboardIconCover
	var readyUpRui
	var superRodeoRui
	var harvesterShieldRui
	var tutorialTip
	int dropshipIntroAnimIndex = -1
	bool useHintActive = false

	array<FD_PlayerAwards> playerAwards

	var scoreSplashRui
	var scoreboardWaveData
	array<var> scoreboardExtraRui
	bool usingShieldBoost

	array<int> validTutorialBitIndices

	float nextAllowReadyUpSoundTime
} file

void function ClGamemodePFW_Init()
{

	#if CLIENT
	PFWMusic_Register()
	
	//RegisterSignal( "ActiveHarvesterChanged" )
	//RegisterNetworkedVariableChangeCallback_ent( "FD_activeHarvester", ActiveHarvesterChanged )

	AddCallback_GameStateEnter( eGameState.Postmatch, DisplayPostMatchTop3 )
	#endif
}

void function PFWMusic_Register()
{
	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_INTRO, "music_mp_fd_intro_hard", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_INTRO, "music_mp_fd_intro_hard", TEAM_MILITIA )

	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_WIN, "music_mp_fd_victory", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_WIN, "music_mp_fd_victory", TEAM_MILITIA )

	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_DRAW, "music_mp_fd_wavecleared", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_DRAW, "music_mp_fd_wavecleared", TEAM_MILITIA )

	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_LOSS, "music_mp_fd_defeat", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_LOSS, "music_mp_fd_defeat", TEAM_MILITIA )

	RegisterLevelMusicForTeam( eMusicPieceID.GAMEMODE_1, "music_mp_fd_earlywave", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.GAMEMODE_1, "music_mp_fd_earlywave", TEAM_MILITIA )

	RegisterLevelMusicForTeam( eMusicPieceID.GAMEMODE_2, "music_mp_fd_midwave", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.GAMEMODE_2, "music_mp_fd_midwave", TEAM_MILITIA )

	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_THREE_MINUTE, "music_mp_fd_finalwave", TEAM_IMC )
	RegisterLevelMusicForTeam( eMusicPieceID.LEVEL_THREE_MINUTE, "music_mp_fd_finalwave", TEAM_MILITIA )
}

void function ActiveHarvesterChanged( entity player, entity oldEnt, entity newEnt, bool actuallyChanged )
{
	if ( newEnt == null )
		return

	RuiTrackFloat( ClGameState_GetRui(), "friendlyShield", newEnt, RUI_TRACK_SHIELD_FRACTION )
	RuiTrackFloat( ClGameState_GetRui(), "friendlyHealth", newEnt, RUI_TRACK_HEALTH )
	RuiTrackInt( ClGameState_GetRui(), "remainingAI", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL_INT, GetNetworkedVariableIndex( "FD_AICount_Current" ) )
	RuiTrackInt( ClGameState_GetRui(), "totalAI", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL_INT, GetNetworkedVariableIndex( "FD_AICount_Total" ) )
	RuiTrackFloat( ClGameState_GetRui(), "harvesterShieldBoostTime", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL, GetNetworkedVariableIndex( "FD_harvesterInvulTime" ) )
	RuiTrackFloat( ClGameState_GetRui(), "nextWaveStartTime", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL, GetNetworkedVariableIndex( "FD_nextWaveStartTime" ) )
	RuiTrackInt( ClGameState_GetRui(), "currentWave", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL_INT, GetNetworkedVariableIndex( "FD_currentWave" ) )
	RuiTrackInt( ClGameState_GetRui(), "maxWaves", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL_INT, GetNetworkedVariableIndex( "FD_totalWaves" ) )
	RuiTrackInt( ClGameState_GetRui(), "waveState", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL_INT, GetNetworkedVariableIndex( "FD_waveState" ) )

	RuiTrackInt( ClGameState_GetRui(), "restartsRemaining", null, RUI_TRACK_SCRIPT_NETWORK_VAR_GLOBAL_INT, GetNetworkedVariableIndex( "FD_restartsRemaining" ) )

	RuiSetString( ClGameState_GetRui(), "difficultyString", FD_GetDifficultyString() )

	file.harvester = newEnt

	if ( file.harvesterRui != null )
	{
		RuiDestroy( file.harvesterRui )
	}

	file.harvesterRui = CreateCockpitRui( $"ui/overhead_icon_generic.rpak", MINIMAP_Z_BASE + 200 )
	RuiSetImage( file.harvesterRui, "icon", $"rui/hud/gametype_icons/fd/coop_harvester" )
 	RuiSetBool( file.harvesterRui, "isVisible", true )
 	RuiSetBool( file.harvesterRui, "showClampArrow", true )
 	RuiSetFloat2( file.harvesterRui, "iconSize", <96,96,0> )
 	RuiTrackFloat3( file.harvesterRui, "pos", newEnt, RUI_TRACK_ABSORIGIN_FOLLOW )

	thread TrackHarvesterDamage( file.harvester )
}

void function TrackHarvesterDamage( entity harvester )
{
	FlagWait( "ClientInitComplete" )
	clGlobal.levelEnt.Signal( "ActiveHarvesterChanged" )
	clGlobal.levelEnt.EndSignal( "ActiveHarvesterChanged" )

	int oldHealth = harvester.GetHealth()
	int oldShield = harvester.GetShieldHealth()

	while ( IsValid( harvester ) )
	{
		if ( harvester.GetHealth() < oldHealth || harvester.GetShieldHealth() < oldShield && file.scoreboardIconCover != null )
		{
			bool hasShield = harvester.GetShieldHealth() > 0

			var rui = CreatePermanentCockpitRui( $"ui/scoreboard_ping_fd.rpak", 1500 )
			RuiSetGameTime( rui, "startTime", Time() )
			RuiSetFloat( rui, "duration", 0.5 )

			vector color
			if ( hasShield )
			{
				color = TEAM_COLOR_FRIENDLY/255.0
				RuiSetFloat( rui, "scale", 3.0 )
			}
			else
			{
				float frac = GetHealthFrac( harvester )
				color = GraphCappedVector( frac, 1.0, 0.5, TEAM_COLOR_ENEMY/255.0, <1.0,0.0,0.0> )
				RuiSetFloat( rui, "scale", 6.0 )
			}
			RuiSetFloat3( rui, "iconColor", color )
		}
		oldHealth = harvester.GetHealth()
		oldShield = harvester.GetShieldHealth()

		WaitFrame()
	}
}