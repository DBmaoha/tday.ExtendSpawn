untyped
global function GamemodePFW_Init

const SQUADS_PER_TEAM_MLT = 4
const SQUADS_PER_TEAM_IMC = 4

global int harvesterDestoryed = 0
table< int, vector > harvesterpos = { [0] = Vector(1538.4, -5492.91, 288.031), [1] = Vector(-4197.01, 2755.03, 224.031), [2] = Vector(-13371, 10409.8, 2347.54), [3] = Vector(-722.411, 13421.1, 2592.03) }

void function GamemodePFW_Init()
{
	ClassicMP_SetLevelIntro( ClassicMP_DefaultNoIntro_Setup, ClassicMP_DefaultNoIntro_GetLength() )

	SetSpawnpointGamemodeOverride( "" )

	Riff_ForceTitanAvailability( eTitanAvailability.Never )
   	Riff_ForceBoostAvailability( eBoostAvailability.Disabled )

	AddCallback_GameStateEnter( eGameState.Playing, OnPlaying )
	AddCallback_OnPlayerRespawned( OnPlayerRespawned )

	AiGameModes_SetGruntWeapons( [ "mp_weapon_car", "mp_weapon_vinson", "mp_weapon_sniper" ] )
	AiGameModes_SetSpectreWeapons( [ "mp_weapon_defender", "mp_weapon_epg", "mp_weapon_rocket_launcher", "mp_weapon_smr" ] )

	ClassicMP_ForceDisableEpilogue( true )
}

//------------------------------------------------------

void function OnPlaying()
{
	Hack_MapInit()
	initialplayercount = GetPlayerArray().len()

	thread SpawnIntroBatch_MLT()
	thread SpawnIntroBatch_IMC()

}

void function OnPlayerRespawned( entity player )
{
	Point point
	if( player.GetTeam() == TEAM_MILITIA )
		point = PlayerSpawnArea( harvesterDestoryed, TEAM_MILITIA )
	if( player.GetTeam() == TEAM_IMC )
		point = PlayerSpawnArea( harvesterDestoryed, TEAM_IMC )

	player.SetOrigin( point.origin )
	player.SetAngles( point.angles )

	player.SetShieldHealthMax( 100 )
	player.SetShieldHealth( 100 )
}

//------------------------------------------------------

void function SpawnIntroBatch_MLT()
{
	wait 10

	thread Spawner_MLT( TEAM_MILITIA )
	thread SpawnerWeapons( TEAM_MILITIA )
}

void function SpawnIntroBatch_IMC()
{
	AiGameModes_SpawnHarvester( harvesterpos[0], TEAM_IMC )
	thread HarvesterThink()
	thread HarvesterAlarm()
	wait 10

	thread Spawner_IMC( TEAM_IMC )
	thread SpawnerWeapons( TEAM_IMC )
}

// Populates the match
void function Spawner_MLT( int team )
{
	svGlobal.levelEnt.EndSignal( "GameStateChanged" )
	int index = team == TEAM_MILITIA ? 0 : 1

	while( true )
	{
		if( !(harvesterDestoryed == 4) )
		{
			// TODO: this should possibly not count scripted npc spawns, probably only the ones spawned by this script
			array<entity> npcs = GetNPCArrayOfTeam( team )
			int count = npcs.len()

			// NORMAL SPAWNS
			if ( count < SQUADS_PER_TEAM_MLT * 4 - 2 )
			{
				Point node = DroppodSpawnArea( harvesterDestoryed, team )
				waitthread AiGameModes_SpawnDropPod( node.origin, node.angles, team, "npc_soldier", SquadHandler )
			}

			if( !checkingOOB[index] )
			{
				thread PlayerInAreaThink( harvesterDestoryed+1, team )
			}
		}
		else
			break
		WaitFrame()
	}
}

void function Spawner_IMC( int team )
{
	svGlobal.levelEnt.EndSignal( "GameStateChanged" )
	int index = team == TEAM_MILITIA ? 0 : 1

	while( true )
	{
		if( !(harvesterDestoryed == 4) )
		{
			if( IsValid(fd_harvester.harvester) )
				GameRules_SetTeamScore(TEAM_IMC, fd_harvester.harvester.GetHealth() )

			// TODO: this should possibly not count scripted npc spawns, probably only the ones spawned by this script
			array<entity> npcs = GetNPCArrayOfTeam( team )
			int count = npcs.len()

			// NORMAL SPAWNS
			if ( count < SQUADS_PER_TEAM_IMC * 4 - 2 )
			{
				Point node = DroppodSpawnArea( harvesterDestoryed, team )
				waitthread AiGameModes_SpawnDropPod( node.origin, node.angles, team, "npc_spectre", SquadHandler )
			}

			if( !checkingOOB[index] )
			{
				thread PlayerInAreaThink( harvesterDestoryed, team )
			}

			thread CheckHarvesterStat()

		}
		else
			break
		WaitFrame()
	}
}

void function SpawnerWeapons( int team )
{
	//svGlobal.levelEnt.EndSignal( "GameStateChanged" )
	while( true )
	{
		wait 60
		if( !(harvesterDestoryed == 4) )
		{

			foreach( entity player in GetPlayerArray() )
			{
				if( IsValid(player) )
					SendHudMessage(player, "正在運送補給艙\n使用补给舱可获得一次泰坦降落机会",  -1, 0.3, 255, 255, 0, 255, 0.15, 3, 1)
			}

			Point node = DroppodSpawnArea( harvesterDestoryed, team )
			waitthread AiGameModes_SpawnDropPodToGetWeapons( node.origin, node.angles )
		}
		else
			break
	}
}

//------------------------------------------------------

void function CheckHarvesterStat()
{
	while(true)
	{
		if( IsValid(fd_harvester.harvester) || harvesterDestoryed == 4 )
			return
		else if( !IsValid(fd_harvester.harvester) )
		{
			foreach( entity player in GetPlayerArrayOfTeam( TEAM_MILITIA ) )
			{
				ClientCommand( player, "script_client AnnouncementMessage( GetLocalClientPlayer(), \"采集機已被摧毀！\", \"出生點已推進，繼續進攻！\" )" )
			}
			AddTeamScore( TEAM_MILITIA, 1 )
			harvesterDestoryed += 1

			WaitFrame()
			if( !(harvesterDestoryed == 4) )
				AiGameModes_SpawnHarvester( harvesterpos[harvesterDestoryed], TEAM_IMC )
			thread HarvesterThink()
			thread HarvesterAlarm()
			foreach( entity player in GetPlayerArrayOfTeam( TEAM_IMC ) )
			{
				ClientCommand( player, "script_client AnnouncementMessage( GetLocalClientPlayer(), \"采集機已被摧毀\", \"出生點已後撤，保持防禦\" )" )
			}
			initialplayercount = GetPlayerArray().len()
			return
		}
		WaitFrame()
	}
}

//------------------------------------------------------

void function SquadHandler( string squad )
{
	array< entity > guys

	vector point

	vector point_mlt
	vector point_imc

	// We need to try catch this since some dropships fail to spawn
	try
	{
		guys = GetNPCArrayBySquad( squad )

		point = harvesterpos[ harvesterDestoryed ]

		array<entity> players = GetPlayerArrayOfEnemies( guys[0].GetTeam() )

		// Setup AI
		foreach ( guy in guys )
		{
			guy.EnableNPCFlag( NPC_ALLOW_INVESTIGATE | NPC_ALLOW_HAND_SIGNALS | NPC_ALLOW_FLEE )
			guy.DisableNPCFlag( NPC_ALLOW_PATROL)
			guy.AssaultPoint( point )
			guy.AssaultSetGoalRadius( 2500 )

			// show on enemy radar
			foreach ( player in players )
				guy.Minimap_AlwaysShow( 0, player )

			thread AITdm_CleanupBoredNPCThread( guy )
		}

		// Every 15 secs change AssaultPoint
		while ( true )
		{
			guys = GetNPCArrayBySquad( squad )

			point_mlt = harvesterpos[ harvesterDestoryed ]
			Point imchandler = DroppodSpawnArea( harvesterDestoryed, TEAM_MILITIA )
			point_imc = imchandler.origin

			foreach ( guy in guys )
			{
				if( guy.GetTeam() == TEAM_MILITIA )
					guy.AssaultPoint( point_mlt )
				else
				{
					guy.AssaultPoint( point_imc )
					guy.AssaultSetGoalRadius( 4000 )
				}
			}

			wait 15
		}
	}
	catch ( ex )
	{
		printt( "Squad doesn't exist or has been killed off" )
	}
}

void function AITdm_CleanupBoredNPCThread( entity guy )
{
	// track all ai that we spawn, ensure that they're never "bored" (i.e. stuck by themselves doing fuckall with nobody to see them) for too long
	// if they are, kill them so we can free up slots for more ai to spawn
	// we shouldn't ever kill ai if players would notice them die

	// NOTE: this partially covers up for the fact that we script ai alot less than vanilla probably does
	// vanilla probably messes more with making ai assaultpoint to fights when inactive and stuff like that, we don't do this so much

	guy.EndSignal( "OnDestroy" )
	wait 15.0 // cover spawning time from dropship/pod + before we start cleaning up

	int cleanupFailures = 0 // when this hits 2, cleanup the npc
	while ( cleanupFailures < 2 )
	{
		wait 10.0

		if ( guy.GetParent() != null )
			continue // never cleanup while spawning

		array<entity> otherGuys = GetPlayerArray()
		otherGuys.extend( GetNPCArrayOfTeam( GetOtherTeam( guy.GetTeam() ) ) )

		bool failedChecks = false

		foreach ( entity otherGuy in otherGuys )
		{
			// skip dead people
			if ( !IsAlive( otherGuy ) )
				continue

			failedChecks = false

			// don't kill if too close to anything
			if ( Distance( otherGuy.GetOrigin(), guy.GetOrigin() ) < 2000.0 )
				break

			// don't kill if ai or players can see them
			if ( otherGuy.IsPlayer() )
			{
				if ( PlayerCanSee( otherGuy, guy, true, 135 ) )
					break
			}
			else
			{
				if ( otherGuy.CanSee( guy ) )
					break
			}

			// don't kill if they can see any ai
			if ( guy.CanSee( otherGuy ) )
				break

			failedChecks = true
		}

		if ( failedChecks )
			cleanupFailures++
		else
			cleanupFailures--
	}

	print( "cleaning up bored npc: " + guy + " from team " + guy.GetTeam() )
	guy.Destroy()
}

