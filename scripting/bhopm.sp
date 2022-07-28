#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
  name = "BhopM",
  author = "ugng, ReFlexPoison",
  description = "Bunnyhop with modified behavior",
  version = PLUGIN_VERSION,
  url = "https://osyu.sh/"
}

ConVar g_hBhopEnabled;
bool g_bHopping[MAXPLAYERS + 1];
float g_fPrevZVel[MAXPLAYERS + 1];
bool g_bPrevOnGround[MAXPLAYERS + 1];

public void OnPluginStart()
{
  CreateConVar("bhopm_version", PLUGIN_VERSION, "BhopM version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

  g_hBhopEnabled = CreateConVar("sm_bhop_enable", "1", "Enable/disable bhop globally", _, true, 0.0, true, 1.0);

  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i))
    {
      OnClientPutInServer(i);
    }
  }

  LoadTranslations("common.phrases");
  RegConsoleCmd("sm_bhop", BhopToggle, "Toggle bhop");
}

public void OnClientPutInServer(int client)
{
  g_bHopping[client] = true;
  SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
  if (!(g_hBhopEnabled.BoolValue && g_bHopping[client]))
  {
    return Plugin_Continue;
  }

  if (IsPlayerAlive(client))
  {
    static int flags;
    static float vel[3];
    flags = GetEntityFlags(client);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);

    if ((flags & FL_ONGROUND) && !g_bPrevOnGround[client] && (buttons & IN_JUMP))
    {
      vel[2] = (flags & FL_DUCKING) ? (-g_fPrevZVel[client] > 267.0 ? -g_fPrevZVel[client] : 267.0) : 267.0;
      TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
    }
    
    g_fPrevZVel[client] = vel[2];
    g_bPrevOnGround[client] = flags & FL_ONGROUND != 0;
  }

  return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& type)
{
  if (type == DMG_FALL && g_hBhopEnabled.BoolValue && g_bHopping[victim] && (GetClientButtons(victim) & IN_JUMP) && (GetEntityFlags(victim) & FL_DUCKING))
  {
    return Plugin_Handled;
  }

  return Plugin_Continue;
}

public Action BhopToggle(int client, int args)
{
  if (client == 0)
  {
    ReplyToCommand(client, "[SM] %t", "Command is in-game only");
    return Plugin_Handled;
  }
  if (!(g_hBhopEnabled.BoolValue))
  {
    ReplyToCommand(client, "[SM] Cannot toggle bhop because it's disabled globally.");
    return Plugin_Handled;
  }

  g_bHopping[client] = !g_bHopping[client];
  ReplyToCommand(client, "[SM] Bhop %s.", g_bHopping[client] ? "enabled" : "disabled");
  return Plugin_Handled;
}
