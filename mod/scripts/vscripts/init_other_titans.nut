untyped
global function initUnusedTitanModels

void function initUnusedTitanModels() {
    ServerCommand("host_thread_mode 0")
    PrecacheModel( $"models/titans/stryder/stryder_titan.mdl")
    PrecacheModel( $"models/titans/ogre/ogre_titan.mdl")
    PrecacheModel( $"models/titans/atlas/atlas_titan.mdl")
    PrecacheModel( $"models/weapons/arms/stryderpov.mdl")
    PrecacheModel($"models/titans/buddy/titan_buddy.mdl")
    PrecacheModel($"models/titans/buddy/ar_battery.mdl")
    PrecacheModel($"models/titans/buddy/bt_battery_idle_2_static.mdl")
    PrecacheModel($"models/titans/buddy/bt_battery_idle_3_static.mdl")
    PrecacheModel($"models/titans/buddy/bt_posed.mdl")
    PrecacheModel($"models/weapons/arms/buddypov.mdl")
    PrecacheParticleSystem( $"P_BT_eye_SM" )
}