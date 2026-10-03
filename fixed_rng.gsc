#include maps\mp\gametypes\zombies;
#include maps\mp\zombies\_wall_buys;

main()
{
    replacefunc( ::randomizepickuplist, ::fixedpickuplist );

    setdvar("g_useholdtime", 0);
    common_scripts\utility::create_dvar("fb", "crossbow nano mahem monkey");

    common_scripts\utility::create_dvar("sr", "30");
    replacefunc( maps\mp\gametypes\zombies::calculatenextspecialround, ::calculatenextspecialroundcustom );
    replacefunc( maps\mp\gametypes\zombies::calculatespecialroundtype, ::calculatespecialroundtypecustom );

    replacefunc( maps\mp\gametypes\zombies::chancetospawnpickup, ::chancetospawnpickupguaranteed );
}

init()
{
    level thread resetroundkillsonwavestart();

    level.originalMagicboxWeapons = [];
    level thread storeMagicboxWeapons();

    level thread initWeaponDatabase();
    level thread firstbox();

    wait 1;
    iPrintLn( "^:F^7ixed ^:R^7NG" );
}

fixedpickuplist()
{
    level.pickuprotation = getpickuporder( getdvar( "mapname" ) );
}

getpickuporder( mapname )
{
    switch ( mapname )
    {
        case "mp_zombie_lab":
        case "mp_zombie_brg":
            return [ "double_points", "insta_kill", "nuke", "ammo", "trap" ];
        case "mp_zombie_ark":
        case "mp_zombie_h2o":
            return [ "double_points", "nuke", "ammo", "explosive_touch", "trap" ];
    }
}

// First half of the round: original drop behaviour (1-2% chance + score schedule).
// Second half: the chance scales with how many drops are still missing, so the
// missing drops are spread out but always happen before the round ends.
// The last ( missing drops * 2 ) kills of a round are a 100% chance, which leaves
// room for kills that can never drop (traps, killstreaks, outside enabled zones).

resetroundkillsonwavestart()
{
    level endon( "game_ended" );
    level.roundkills = 0;

    for (;;)
    {
        level waittill( "zombie_wave_started" );
        level.roundkills = 0;
    }
}

// Returns the drop chance (0-100) for the current kill.
// var_0 = kills this round including the current one
// var_1 = total enemies this round
// var_2 = drops still missing this round
calculatedropchance( var_0, var_1, var_2 )
{
    if ( var_0 * 2 < var_1 )
        return level.percentchancetodrop;

    var_3 = int( max( var_1 - var_0 + 1, 1 ) );
    var_4 = int( 100 * var_2 * 2 / var_3 );

    if ( var_4 > 100 )
        return 100;

    return var_4;
}

chancetospawnpickupguaranteed( var_0, var_1, var_2, var_3 )
{
    level.roundkills++;

    if ( maps\mp\zombies\_util::arepickupsdisabled() )
        return;

    if ( isdefined( level.candroppickupsfunc[level.roundtype] ) && ![[ level.candroppickupsfunc[level.roundtype] ]]( var_0 ) )
    {
        var_4 = 0;

        if ( !var_4 )
            return;
    }

    if ( level.currentpickupcount >= level.maxpickupsperround )
        return;

    if ( isdefined( level.canspawnpickupoverridefunc ) )
    {
        if ( ![[ level.canspawnpickupoverridefunc ]]( var_0, var_1, var_2, var_3 ) )
            return 0;
    }

    if ( isdefined( var_2 ) && var_2 == "MOD_SUICIDE" )
        return;

    if ( maps\mp\zombies\_util::is_true( var_1.killedbynuke ) )
        return;

    if ( maps\mp\zombies\_util::is_true( var_1.nopickups ) )
        return;

    if ( isdefined( var_3 ) && maps\mp\zombies\_util::istrapweapon( var_3 ) )
        return;

    if ( isdefined( var_0 ) && isagent( var_0 ) && !isscriptedagent( var_0 ) )
        return;

    if ( isdefined( level.nopickuppenalty ) && level.nopickuppenalty == 1 )
        return;

    level endon( "game_ended" );
    var_5 = randomint( 100 );
    var_6 = "none";
    var_11 = calculatedropchance( level.roundkills, level.totaldesiredai, level.maxpickupsperround - level.currentpickupcount );

    if ( var_5 > var_11 )
    {
        if ( !level.dropscheduled )
            return;

        var_6 = "score";
    }
    else
        var_6 = "random";

    if ( isdefined( level.zone_data ) && !maps\mp\zombies\_zombies_zone_manager::iszombieinenabledzone( var_1 ) )
        return;

    var_7 = common_scripts\utility::ter_op( level.dropscheduled, "true ", "false " );
    var_8 = common_scripts\utility::ter_op( var_5 > var_11, "false ", "true " );
    var_9 = "Scheduled: " + var_7 + "Chance: " + var_8 + "(" + var_5 + "<=" + var_11 + ")";
    level.dropscheduled = 0;
    var_10 = maps\mp\gametypes\zombies::selectnextvalidpickup();
    maps\mp\gametypes\zombies::createpickup( var_10, var_1.origin, var_9 );
}

storeMagicboxWeapons()
{
    wait 0.5;

    for(i = 0; i < level.magicboxweapons.size; i++)
    {
        level.originalMagicboxWeapons[i] = level.magicboxweapons[i];
    }
}

initWeaponDatabase()
{
    level.weaponData = [];
    level.weaponData["rw1"] = ["iw5_rw1zm", "npc_rw1_main_base_static_holo", &"ZOMBIES_RW1", "none", "none", "none", undefined];
    level.weaponData["vbr"] = ["iw5_vbrzm", "npc_vbr_base_static_holo", &"ZOMBIES_VBR", "none", "none", "none", undefined];
    level.weaponData["gm6"] = ["iw5_gm6zm", "npc_gm6_base_static_holo", &"ZOMBIES_GM6", "gm6scope", "none", "none", undefined];
    level.weaponData["lsat"] = ["iw5_lsatzm", "npc_lsat_base_static_holo", &"ZOMBIES_LSAT", "none", "none", "none", undefined];
    level.weaponData["asaw"] = ["iw5_asawzm", "npc_ameli_base_static_holo", &"ZOMBIES_ASAW", "none", "none", "none", undefined];
    level.weaponData["ak12"] = ["iw5_ak12zm", "npc_ak12_base_static_holo", &"ZOMBIES_AK12", "none", "none", "none", undefined];
    level.weaponData["bal27"] = ["iw5_bal27zm", "npc_bal27_base_black_static_holo", &"ZOMBIES_BAL27", "none", "none", "none", undefined];
    level.weaponData["himar"] = ["iw5_himarzm", "npc_himar_base_static_holo", &"ZOMBIES_IMR", "none", "none", "none", undefined];
    level.weaponData["asm1"] = ["iw5_asm1zm", "npc_asm1_base_static_holo", &"ZOMBIES_ASM1", "none", "none", "none", undefined];
    level.weaponData["sn6"] = ["iw5_sn6zm", "npc_sn6_base_black_static_holo", &"ZOMBIES_SN6", "none", "none", "none", undefined];
    level.weaponData["sac3"] = ["iw5_sac3zm", "npc_sac3_base_static_holo", &"ZOMBIES_SAC3", "none", "none", "none", undefined];
    level.weaponData["em1"] = ["iw5_em1zm", "npc_em1_base_static_holo", &"ZOMBIES_EM1", "none", "none", "none", undefined];
    level.weaponData["ae4"] = ["iw5_dlcgun1zm","npc_dear_base_static_holo", &"ZOMBIES_DLC_GUN_1", "none", "none", "none", undefined];
    level.weaponData["ohm"] = ["iw5_dlcgun2zm", "npc_lmg_shotgun_base_static_holo", &"ZOMBIE_WEAPONDLC2_GUN", "none", "none", "none", undefined];
    level.weaponData["m1"] = ["iw5_dlcgun3zm", "npc_m1_irons_base_static_holo", &"ZOMBIE_WEAPONDLC3_GUN", "none", "none", "none", undefined];
    level.weaponData["s12"] = ["iw5_rhinozm", "npc_rhino_base_static_holo", &"ZOMBIES_RHINO", "none", "none", "none", undefined];
    level.weaponData["cel3"] = ["iw5_fusionzm", "npc_fusion_shotgun_base_holo", &"ZOMBIES_FUSION_RIFLE", "none", "none", "none", 2];
    level.weaponData["crossbow"] = ["iw5_exocrossbowzm", "npc_crossbow_base_static_holo", &"ZOMBIES_CROSSBOW", "none", "none", "none", undefined];
    level.weaponData["mahem"] = ["iw5_mahemzm", "npc_mahem_base_holo", &"ZOMBIES_MAHEM", "none", "none", "none", undefined];
    level.weaponData["magnetron"] = ["iw5_microwavezm", "dlc_npc_microwave_gun_holo", &"ZOMBIES_MWG", "none", "none", "none", 1];
    level.weaponData["limbo"] = ["iw5_linegunzm", "npc_zom_line_gun_holo", &"ZOMBIE_WEAPON_LINEGUN_PICKUP", "none", "none", "none", 2];
    level.weaponData["trident"] = ["iw5_tridentzm", "npc_zom_trident_base_holo", &"ZOMBIE_WEAPON_TRIDENT_PICKUP", "none", "none", "none", 2];
    level.weaponData["blunderbuss"] = ["iw5_dlcgun4zm", "npc_blunderbuss_base_holo", &"ZOMBIE_WEAPONDLC4_GUN", "none", "none", "none", 2];
    level.weaponData["monkey"] = ["distraction_drone_zombie", "dlc_distraction_drone_01_holo", &"ZOMBIES_DISTRACTION_DRONE", "none", "none", "none", 2];
    level.weaponData["nano"] = ["dna_aoe_grenade_zombie", "npc_exo_launcher_grenade_holo", &"ZOMBIES_DNA_AOE", "none", "none", "none", 2];
    level.weaponData["repulsor"] = ["repulsor_zombie", "dlc3_repulsor_device_01_holo", &"ZOMBIE_DLC3_REPULSOR", "none", "none", "none", 2];
}

firstbox()
{
    level endon( "game_ended" );
    level waittill( "zombie_wave_started" );
    level.magicboxweapons = [];
    map = maps\mp\_utility::getmapname();
    fb_dvar = getDvar("fb");
    weapons = strtok(fb_dvar, " ");

    if (weapons.size < 1)
    {
        iPrintLn("Firstbox needs at least 1 weapon!");
        thread resetMagicbox();
    }

    for(i = 0; i < weapons.size; i++)
    {
        addWeaponFromDvar(weapons[i], i + 1);
    }
    level thread checkRound();
}

checkRound()
{
    level endon("game_ended");
    while (true)
    {
        round = level.wavecounter;
        level waittill("zombie_wave_ended");

        if (round >= 19)
        {
            resetMagicbox();
            break;
        }
    }
}

resetMagicbox()
{
    level.magicboxweapons = [];
    for(i = 0; i < level.originalMagicboxWeapons.size; i++)
    {
        weapon = level.originalMagicboxWeapons[i];
        maps\mp\zombies\_wall_buys::addmagicboxweapon(
            weapon["baseNameNoMP"],
            weapon["displayModel"],
            weapon["displayString"],
            weapon["attachment1"],
            weapon["attachment2"],
            weapon["attachment3"],
            weapon["limit"]
        );
    }
    iPrintLn("^:F^7irstbox off");
}

addWeaponFromDvar(weaponName, order)
{
    if (isDefined(level.weaponData[weaponName]))
    {
        weapon = level.weaponData[weaponName];
        maps\mp\zombies\_wall_buys::addmagicboxweapon(weapon[0], weapon[1], weapon[2], weapon[3], weapon[4], weapon[5], weapon[6], order);
    }
    else
    {
        iPrintLn("Error: Unknown weapon '" + weaponName + "'");
    }
}

getspecialroundschedulerounds( var_0 )
{
    switch ( var_0 )
    {
        case "30":
            return [ 4, 9, 13, 17, 21, 25, 29 ];
        case "50":
            return [ 4, 9, 13, 17, 21, 25, 29, 33, 37, 41, 45, 49 ];
        case "70":
            return [ 4, 9, 13, 17, 22, 26, 30, 35, 39, 43, 48, 52, 56, 61, 65, 69 ];
        case "100":
            return [ 4, 9, 13, 17, 22, 26, 30, 35, 39, 43, 47, 51, 55, 59, 63, 67, 71, 75, 79, 83, 87, 91, 95, 99 ];
        case "highrounds":
            return [];
    }

    iPrintLn("Error: Unknown sr value '" + var_0 + "', use 30, 50, 70, 100 or highrounds");
    return [];
}

isspecialroundindexhost( var_0 )
{
    return var_0 % 3 == 1;
}

calculatenextspecialroundcustom()
{
    var_0 = getspecialroundschedulerounds( getdvar( "sr" ) );

    if ( level.specialroundcounter < var_0.size )
        return var_0[level.specialroundcounter];

    if ( isspecialroundindexhost( level.specialroundcounter ) )
        return level.specialroundnumber + 5;

    return level.specialroundnumber + 4;
}

calculatespecialroundtypecustom()
{
    if ( isspecialroundindexhost( level.specialroundcounter - 1 ) )
        return "zombie_host";

    return "zombie_dog";
}
