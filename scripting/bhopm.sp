#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.1"

public Plugin myinfo =
{
  name = "Bhop: 3D Recreation",
  author = "ugng",
  description = "Bunnyhop with modified behavior",
  version = PLUGIN_VERSION,
  url = "https://osyu.sh/"
}

Handle g_hBhopEnabled;
bool g_bHopping[MAXPLAYERS + 1];
float g_fPrevZVel[MAXPLAYERS + 1];
bool g_bPrevOnGround[MAXPLAYERS + 1];

public void OnPluginStart()
{
  CreateConVar("bhopm_version", PLUGIN_VERSION, "Bhop version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

  g_hBhopEnabled = CreateConVar("sm_bhop_enable", "1", "Enable/disable bhop globally", _, true, 0.0, true, 1.0);

  for (int i = 1; i <= MaxClients; i++)
  {
    if (IsClientInGame(i))
    {
      OnClientPutInServer(i);
    }
  }

  LoadTranslations("common.phrases");
  RegConsoleCmd("sm_bhop", BhopToggle, "Toggle bhop for yourself");
}

public void OnClientPutInServer(int iClient)
{
  g_bHopping[iClient] = true;
  SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnPlayerRunCmd(int iClient, int& iButtons)
{
  if (IsPlayerAlive(iClient) && GetConVarBool(g_hBhopEnabled) && g_bHopping[iClient])
  {
    static int iFlags;
    static float vVel[3];
    iFlags = GetEntityFlags(iClient);
    GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vVel);

    if ((iFlags & FL_ONGROUND) && !g_bPrevOnGround[iClient] && (iButtons & IN_JUMP))
    {
      vVel[2] = (iFlags & FL_DUCKING) ? (-g_fPrevZVel[iClient] > 267.0 ? -g_fPrevZVel[iClient] : 267.0) : 267.0;
      TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, vVel);
    }
    
    g_fPrevZVel[iClient] = vVel[2];
    g_bPrevOnGround[iClient] = view_as<bool>(iFlags & FL_ONGROUND);
  }

  return Plugin_Continue;
}

Action OnTakeDamage(int iVictim, int& iAttacker, int& iInflictor, float& fDamage, int& iType)
{
  if (iType == DMG_FALL && GetConVarBool(g_hBhopEnabled) && g_bHopping[iVictim] &&
    (GetClientButtons(iVictim) & IN_JUMP) && (GetEntityFlags(iVictim) & FL_DUCKING))
  {
    return Plugin_Handled;
  }

  return Plugin_Continue;
}

Action BhopToggle(int iClient, int iArgs)
{
  if (iClient == 0)
  {
    ReplyToCommand(iClient, "[SM] %t", "Command is in-game only");
    return Plugin_Handled;
  }
  else if (!GetConVarBool(g_hBhopEnabled))
  {
    ReplyToCommand(iClient, "[SM] Cannot toggle bhop because it's disabled globally.");
    return Plugin_Handled;
  }

  g_bHopping[iClient] = !g_bHopping[iClient];
  ReplyToCommand(iClient, "[SM] Bhop %s.", g_bHopping[iClient] ? "enabled" : "disabled");
  return Plugin_Handled;
}
