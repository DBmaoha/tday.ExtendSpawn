untyped
global function GamemodePFW_Init

const SQUADS_PER_TEAM = 4

global int harvesterDestoryed = 0
global bool elevatorReached = false
global bool destroyedNPCmlt = false
global bool destroyedNPCimc = false
table< int, vector > harvesterpos = { [0] = Vector(1538.4, -5492.91, 288.031), [1] = Vector(-1948.26, 2050.77, 224.031), [2] = Vector(-13411.7, 10524.7, 2331.39), [3] = Vector(-2043.77, 13798.8, 2588.03) }

void function GamemodePFW_Init()
{
	ClassicMP_SetLevelIntro( ClassicMP_DefaultNoIntro_Setup, ClassicMP_DefaultNoIntro_GetLength() )

	SetSpawnpointGamemodeOverride( "" )

	Riff_ForceTitanAvailability( eTitanAvailability.Never )
   	Riff_ForceBoostAvailability( eBoostAvailability.Disabled )

	AddCallback_GameStateEnter( eGameState.Playing, OnPlaying )
	AddCallback_OnPlayerRespawned( OnPlayerRespawned )
	AddCallback_OnClientConnected( OnClientConnected )
	AddCallback_OnPlayerKilled( OnPlayerKilled )
	AddSpawnCallback( "npc_soldier", SoldierConfig )

	AiGameModes_SetGruntWeapons( [ "mp_weapon_car", "mp_weapon_vinson", "mp_weapon_sniper" ] )
	AiGameModes_SetSpectreWeapons( [ "mp_weapon_mastiff", "mp_weapon_doubletake", "mp_weapon_hemlok_smg" ] )

	ClassicMP_ForceDisableEpilogue( true )
}

//------------------------------------------------------

void function OnPlaying()
{
	Hack_MapInit()

	//UpdateBTHealth()
	foreach( entity soldier in GetNPCArrayOfTeam(TEAM_IMC) )
	{
		if( IsValid(soldier) )
			soldier.Destroy()
	}
	initialplayercount = GetPlayerArray().len()

	thread SpawnIntroBatch_MLT()
	thread SpawnIntroBatch_IMC()
}

void function OnPlayerRespawned( entity player )
{
	RespawnPlayerInArea( player )
}

void function OnClientConnected( entity player )
{
	//UpdateBTHealth()
}

void function OnPlayerKilled( entity victim, entity attacker, var damageInfo )
{
	thread OnPlayerKilled_Threaded( victim )
}

void function OnPlayerKilled_Threaded( entity player )
{
	if( player.GetTeam() == TEAM_MILITIA )
	{
		wait 5
		if( IsValid(player) )
			ForceRespawnPlayerInArea( player )
	}
	if( player.GetTeam() == TEAM_IMC )
	{
		wait 10
		if( IsValid(player) )
			ForceRespawnPlayerInArea( player )
	}
}

void function SoldierConfig( entity soldier )
{
	soldier.SetMaxHealth(100)
	soldier.SetHealth(100)
}

//------------------------------------------------------

void function SpawnIntroBatch_MLT()
{
	wait 10

	thread Spawner_MLT( TEAM_MILITIA )
	thread SpawnerWeapons( TEAM_MILITIA )
	thread SpawnerTitans( TEAM_MILITIA )
}

void function SpawnIntroBatch_IMC()
{
	AiGameModes_SpawnHarvester( harvesterpos[0], TEAM_IMC )
	thread HarvesterThink()
	thread HarvesterAlarm()
	wait 10

	thread Spawner_IMC( TEAM_IMC )
	thread SpawnerWeapons( TEAM_IMC )
	thread SpawnerTitans( TEAM_IMC )
	thread UpdateHarvesterHealth()
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
			if( !checkingOOB[index] )
			{
				thread PlayerInAreaThink( team )
			}
		}
		else if( harvesterDestoryed >= 2 )
		{
			// NORMAL SPAWNS
			// TODO: this should possibly not count scripted npc spawns, probably only the ones spawned by this script
			array<entity> npcs = GetNPCArrayOfTeam( team )
			int count = npcs.len()
			if ( count < SQUADS_PER_TEAM * 4 - 2 )
			{
				Point node = DroppodSpawnArea( harvesterDestoryed, team )
				waitthread AiGameModes_SpawnDropPod( node.origin, node.angles, team, "npc_soldier", SquadHandler )
			}
		}
		if( elevatorReached && !destroyedNPCmlt ) //Elevator point, we need destroy npcs
		{
			array<entity> soldiers = GetNPCArrayOfTeam( TEAM_MILITIA )
			foreach( entity soldier in soldiers )
			{
				if( IsValid(soldier) )
					soldier.Dissolve( ENTITY_DISSOLVE_CORE, Vector( 0, 0, 0 ), 500 )
			}
			destroyedNPCmlt = true
			printt( "MLT NPCs destroyed" )
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
			if( !checkingOOB[index] )
			{
				thread PlayerInAreaThink( team )
			}
		}
		else if( harvesterDestoryed >= 2 )
		{
			// NORMAL SPAWNS
			// TODO: this should possibly not count scripted npc spawns, probably only the ones spawned by this script
			array<entity> npcs = GetNPCArrayOfTeam( team )
			int count = npcs.len()
			if ( count < SQUADS_PER_TEAM * 4 - 2 )
			{
				Point node = DroppodSpawnArea( harvesterDestoryed, team )
				waitthread AiGameModes_SpawnDropPod( node.origin, node.angles, team, "npc_spectre", SquadHandler )
			}
		}
		if( elevatorReached && !destroyedNPCimc ) //Elevator point, we need destroy npcs
		{
			array<entity> soldiers = GetNPCArrayOfTeam( TEAM_IMC )
			foreach( entity soldier in soldiers )
			{
				if( IsValid(soldier) )
					soldier.Dissolve( ENTITY_DISSOLVE_CORE, Vector( 0, 0, 0 ), 500 )
			}
			destroyedNPCimc = true
			printt( "IMC NPCs destroyed" )
		}
		thread CheckHarvesterStat()
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

			Point node = CarePackageDropArea( harvesterDestoryed, team )
			int packagecount = GetPlayerArrayOfTeam(GetOtherTeam(team)).len()/4+1
			for( int i = 0; i < packagecount ; i++ )
				waitthread AiGameModes_SpawnDropPodToGetWeapons( node.origin, node.angles )

		}
		else
			break
	}
}

void function SpawnerTitans( int team )
{
	while(true)
	{
		wait 60
		int packagecount = GetPlayerArrayOfTeam(GetOtherTeam(team)).len()/4+1
		Point titannode = DroppodSpawnArea( harvesterDestoryed, team )
		array<entity> titans = GetNPCArrayByClass( "npc_titan" )
		int titancount = 0
		if( harvesterDestoryed < 2 )
		{
			foreach( entity titan in titans )
			{
				if( titan.GetTeam() == team && !IsPetTitan( titan ) )
					titancount += 1
			}
			for( int i = 0; i < packagecount; i++ )
			{
				if ( titancount < packagecount )
				{
					titannode = DroppodSpawnArea( harvesterDestoryed, team )
					waitthread AiGameModes_SpawnTitanRandom( titannode.origin, titannode.angles, team, TitanHandler )
				}
			}
		}
		if( harvesterDestoryed >= 2 )
		{
			array<entity> titans = GetNPCArrayByClass( "npc_titan" )
			foreach( entity titan in titans )
			{
				if( titan.GetTeam() == team || !IsPetTitan( titan ) )
				{
					if( IsValid(titan) )
						titan.Dissolve( ENTITY_DISSOLVE_CORE, Vector( 0, 0, 0 ), 500 )
				}
			}
			printt( "Titans destroyed, gonna break" )
			break
		}
	}
}

//------------------------------------------------------

void function UpdateHarvesterHealth()
{
	while( true )
	{
		if( !(harvesterDestoryed == 4) )
		{
			if( IsValid(fd_harvester.harvester) )
				GameRules_SetTeamScore(TEAM_IMC, fd_harvester.harvester.GetHealth() )
			WaitFrame()
		}
		else
			break
	}
}

void function UpdateBTHealth()
{
	array<entity> titans = GetNPCArrayByClass( "npc_titan" )
	int health = ( GetPlayerArrayOfTeam(TEAM_IMC).len()+1 )*2500
	foreach( entity titan in titans )
	{
		if( IsPetTitan(titan) )
			continue
		titan.SetMaxHealth( health )
		titan.SetHealth( health*GetHealthFrac(titan) )
		foreach( entity weapon in titan.GetMainWeapons() )
			titan.TakeWeaponNow( weapon.GetWeaponClassName() )
		titan.GiveWeapon( "mp_titanweapon_xo16_vanguard" )

	}
}

//------------------------------------------------------

void function RespawnPlayerInArea( entity player )
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

void function ForceRespawnPlayerInArea( entity player )
{
	Point point
	if( player.GetTeam() == TEAM_MILITIA )
		point = PlayerSpawnArea( harvesterDestoryed, TEAM_MILITIA )
	if( player.GetTeam() == TEAM_IMC )
		point = PlayerSpawnArea( harvesterDestoryed, TEAM_IMC )
	
	if( !IsAlive( player ) )
	{
		entity spawnpoint = CreateEntity( "script_mover" )
		spawnpoint.SetOrigin( point.origin )
		spawnpoint.SetAngles( point.angles )
		player.RespawnPlayer( spawnpoint )
	}

	player.SetShieldHealthMax( 100 )
	player.SetShieldHealth( 100 )
}

//------------------------------------------------------

void function CheckHarvesterStat()
{
	while(true)
	{
		if( IsValid(fd_harvester.harvester) )
		{
			
			fd_harvester.harvester.SetMaxHealth( HarvesterHealth() )
			fd_harvester.harvester.SetHealth( HarvesterHealth() * GetHealthFrac( fd_harvester.harvester ) )
			fd_harvester.harvester.SetShieldHealthMax( int(HarvesterHealth()*0.5) )
			return
		}
		if( harvesterDestoryed == 4 )
		{
			OlaTakeOff()
			return
		}
		else if( !IsValid(fd_harvester.harvester) )
		{
			foreach( entity player in GetPlayerArrayOfTeam( TEAM_MILITIA ) )
			{
				ClientCommand( player, "script_client AnnouncementMessage( GetLocalClientPlayer(), \"采集機已被摧毀！\", \"出生點已推進，繼續進攻！\" )" )
			}
			AddTeamScore( TEAM_MILITIA, 1 )
			harvesterDestoryed += 1
			WaitFrame()		
			if( harvesterDestoryed == 2 )
				elevatorReached = true
			if( !(harvesterDestoryed == 4) )
			{
				AiGameModes_SpawnHarvester( harvesterpos[harvesterDestoryed], TEAM_IMC )
				thread HarvesterThink()
				thread HarvesterAlarm()
			}
			foreach( entity player in GetPlayerArrayOfTeam( TEAM_IMC ) )
			{
				ClientCommand( player, "script_client AnnouncementMessage( GetLocalClientPlayer(), \"采集機已被摧毀\", \"出生點已後撤，保持防禦\" )" )
			}
			return
		}
		WaitFrame()
	}
}

//------------------------------------------------------

void function SquadHandler( string squad )
{
	array< entity > guys

	array<entity> titans

	vector point

	vector point_mlt
	vector point_imc

	// We need to try catch this since some dropships fail to spawn
	try
	{
		guys = GetNPCArrayBySquad( squad )

		titans = GetNPCArrayByClass( "npc_titan" )

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

void function TitanHandler( entity titan )
{
	vector point

	vector point_mlt
	vector point_imc

	point = harvesterpos[ harvesterDestoryed ]

	array<entity> players = GetPlayerArrayOfEnemies( titan.GetTeam() )

	try
	{
		//Setup Titan
		if( IsPetTitan(titan) )
			return
		titan.EnableNPCFlag( NPC_ALLOW_INVESTIGATE | NPC_ALLOW_HAND_SIGNALS | NPC_ALLOW_FLEE )
		titan.DisableNPCFlag( NPC_ALLOW_PATROL )
		titan.AssaultPoint( point )
		titan.AssaultSetGoalRadius( 2500 )

		foreach ( player in players )
			titan.Minimap_AlwaysShow( 0, player )

		thread AITdm_CleanupBoredNPCThread( titan )

		while( true )
		{
			point_mlt = harvesterpos[ harvesterDestoryed ]
			Point imchandler = DroppodSpawnArea( harvesterDestoryed, TEAM_MILITIA )
			point_imc = imchandler.origin

			if( IsPetTitan(titan) )
				continue
			if( titan.GetTeam() == TEAM_MILITIA )
			{
				titan.AssaultPoint( point_mlt )
				titan.AssaultSetGoalRadius( 1000 )
			}
			else
			{
				titan.AssaultPoint( point_imc )
				titan.AssaultSetGoalRadius( 4000 )
			}

			wait 15
		}
	}
	catch(ex)
	{
		printt( "Titan doesn't exist or has been killed off" )
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

