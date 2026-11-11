// Opossum Labs Awareness HUD v1.0 - Core Script
// Copyright (C) 2026 Opossum Labs (rachel.possum)
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version. Full license
// text is in the source repository (address below).
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// Source and docs: github.com/comraderachel/opossum-labs-awareness-hud
// This script owns the settings, the watch list, the panel buttons,
// the power light, persistence, and the failure sweep over the
// other three scripts.

// ---------- constants and globals ----------
integer MAX_WATCHED = 20;
string PING_SOUND = "notification";
string HELP_CARD = "Awareness Hud Help";

string COMPANION_SCRIPT_NAME = "Companion Script";
string DATA_SCRIPT_NAME = "Data Script";
string REGISTRAR_SCRIPT_NAME = "Registrar Script";

integer BUSY_TIMEOUT = 180;

integer SLOW_FETCH = 30;

integer HB_STALE = 120;

integer CAP_FULL = 60;

vector DEFAULT_POS = <0.00590, 0.15, -0.36976>;
vector DEFAULT_EULER = <0.0, 0.0, 180.0>;
integer HUD_PT_DESIGN = ATTACH_HUD_TOP_RIGHT;

integer SCOPE_REGION = 0;
integer SCOPE_RADIUS = 1;
integer SCOPE_PARCEL = 2;

string P = "SMH.";
string BUILD_NUM = "110226082";

integer CDBG_SLOTS = 8;

string HUD_VERSION = "1.0";

integer LM_LANG_ASK = 19024;
integer LM_LANG_TELL = 19025;
integer LM_SAY = 19027;

integer LM_MENU_OPEN = 19028;
integer LM_UI_STATE = 19029;

integer LM_UI_CMD = 19030;
integer LM_WATCH_LIST = 19031;

integer LM_DATA_ASK = 19032;
integer LM_DATA_TELL = 19033;

integer LM_SWEEP_ASK = 19034;

integer LM_EVENT = 19035;

integer LM_MEM_ASK = 19036;

integer LM_MEM_TELL = 19037;

string BUTTON_POWER = "Power Button";
string BUTTON_HELP = "Help Button";
string BUTTON_SOUND = "Sound Button";
string BUTTON_MENU = "Menu Button";
integer gLinkPower;
integer gLinkHelp;
integer gLinkSound;
integer gLinkMenu;
vector COLOR_ON = <0.20, 0.85, 0.30>;
vector COLOR_OFF = <0.90, 0.25, 0.25>;
vector COLOR_BUSY = <0.05, 0.25, 0.10>;
vector COLOR_CAP = <0.90, 0.75, 0.10>;
vector COLOR_DARK = <0.03, 0.03, 0.03>;

key gOwner;

integer gScope = SCOPE_PARCEL;
integer gRange = 25;
integer gEnabled = TRUE;
integer gPing = FALSE;
list gWatchList;

string LANG_MAP = "|en|English|en-us|English (US)|en-gb|English (UK)|fr|French|fr-ca|French (Canada)|de|German|es|Spanish|it|Italian|pt|Portuguese|pt-br|Portuguese (Brazil)|nl|Dutch|ru|Russian|pl|Polish|tr|Turkish|sv|Swedish|da|Danish|no|Norwegian|fi|Finnish|cs|Czech|el|Greek|ro|Romanian|hu|Hungarian|uk|Ukrainian|bg|Bulgarian|hr|Croatian|sr|Serbian|ja|Japanese|ko|Korean|zh|Chinese|zh-cn|Chinese (Simplified)|zh-tw|Chinese (Traditional)|th|Thai|vi|Vietnamese|id|Indonesian|ar|Arabic|he|Hebrew|hi|Hindi|";

integer gHaveLang;
integer gHaveData;
integer gBusy;

integer gBlinkOn;
integer gBusyStart;
integer gFailBits;

integer gFailLast;
integer gLitState;

integer gHbCore = 0;

integer gStallGrace = 0;

integer gStalled;

integer validUUID(string s)
{
    if (llStringLength(s) != 36)
        return FALSE;
    if (llGetSubString(s, 8, 8) != "-")
        return FALSE;
    if (llGetSubString(s, 13, 13) != "-")
        return FALSE;
    if (llGetSubString(s, 18, 18) != "-")
        return FALSE;
    if (llGetSubString(s, 23, 23) != "-")
        return FALSE;
    return TRUE;
}

string safeName(key id)
{

    return "secondlife:///app/agent/" + (string)id + "/displayname";
}

string scopeLabel()
{
    if (gScope == SCOPE_RADIUS)
        return (string)gRange + "m radius";
    if (gScope == SCOPE_PARCEL)
        return "parcel";
    return "region";
}

// ---------- functions ----------
// Every durable value is written to linkset data under the SMH. prefix,
// so any script can reset freely.
savePref(string name, string value)
{
    integer r = llLinksetDataWrite(P + name, value);
    if (r == LINKSETDATA_EMEMORY)
        llOwnerSay("Warning: HUD datastore full, '" + name + "' was NOT saved.");
}

saveWatch()
{
    savePref("watch", llDumpList2String(gWatchList, ","));
}

// boot-time settings load from linkset data
loadSettings()
{
    string storedOwner = llLinksetDataRead(P + "owner");
    if (storedOwner == "" || (key)storedOwner != gOwner)
    {

        if (storedOwner != "")
            llOwnerSay("New owner detected - watch list cleared, preferences kept.");
        llLinksetDataWrite(P + "watch", "");

        integer eo;
        for (eo = 0; eo < 50; eo++)
            llLinksetDataDelete(P + "enc" + (string)eo);
        llLinksetDataDelete(P + "encNext");

        llLinksetDataWrite(P + "lastpt", "");
        llLinksetDataWrite(P + "setup", "");
        savePref("owner", (string)gOwner);
        savePref("scope", "PARCEL");
        savePref("range", (string)gRange);
        savePref("enabled", "1");
        savePref("ping", "0");
        saveWatch();
    }
    else
    {
        string s = llLinksetDataRead(P + "scope");
        if (s == "RADIUS")
            gScope = SCOPE_RADIUS;
        else if (s == "PARCEL")
            gScope = SCOPE_PARCEL;
        else
            gScope = SCOPE_REGION;

        gRange = (integer)llLinksetDataRead(P + "range");
        if (gRange < 5)
            gRange = 25;

        gEnabled = (llLinksetDataRead(P + "enabled") != "0");
        gPing = (llLinksetDataRead(P + "ping") == "1");

        string w = llLinksetDataRead(P + "watch");
        if (w != "")
            gWatchList = llParseString2List(w, [","], []);
    }
}

vector hudSeatFor(integer pt)
{

    float Y = 0.0;
    float Z = 0.0;
    if (pt == ATTACH_HUD_TOP_RIGHT || pt == ATTACH_HUD_BOTTOM_RIGHT ||
        pt == ATTACH_HUD_CENTER_2)
        Y = 0.08;
    else if (pt == ATTACH_HUD_TOP_LEFT || pt == ATTACH_HUD_BOTTOM_LEFT ||
        pt == ATTACH_HUD_CENTER_1)
        Y = -0.08;
    if (pt == ATTACH_HUD_TOP_RIGHT || pt == ATTACH_HUD_TOP_CENTER ||
        pt == ATTACH_HUD_TOP_LEFT)
        Z = -0.08;
    else if (pt == ATTACH_HUD_BOTTOM_RIGHT || pt == ATTACH_HUD_BOTTOM ||
        pt == ATTACH_HUD_BOTTOM_LEFT)
        Z = 0.08;
    return <0.0, Y, Z>;
}

// panel prim placement; the reseat command rebuilds it
applyDefaultPlacement(integer force)
{

    integer pt = llGetAttached();
    if (pt == 0)
        return;
    if (pt < ATTACH_HUD_TOP_RIGHT || pt > ATTACH_HUD_BOTTOM_LEFT)
    {
        llOwnerSay("This is a HUD - please attach it to a HUD position on your screen.");
        return;
    }
    if (!force && (integer)llLinksetDataRead(P + "lastpt") == pt)
        return;
    vector pos = DEFAULT_POS;
    if (pt != HUD_PT_DESIGN)
        pos = hudSeatFor(pt);
    llSetPos(pos);
    llSetRot(llEuler2Rot(DEFAULT_EULER * DEG_TO_RAD));
    savePref("lastpt", (string)pt);
}

integer reseatChannel()
{

    return -1000000000 -
        (integer)("0x" + llGetSubString((string)llGetOwner(), 0, 6));
}

// mirror broadcast to all scripts: enabled, scope, range
pushState()
{

    llMessageLinked(LINK_SET, LM_UI_STATE,
        (string)gEnabled + "|" + (string)gScope + "|" + (string)gRange, "");
    llMessageLinked(LINK_SET, LM_WATCH_LIST,
        llDumpList2String(gWatchList, ","), "");
}

notifyOwner(string msg)
{
    while (llStringLength(msg) > 800)
    {
        integer cut = 800;

        while (cut > 600 && llGetSubString(msg, cut, cut) != "\n")
            cut = cut - 1;
        llOwnerSay(llGetSubString(msg, 0, cut - 1));
        msg = llGetSubString(msg, cut + 1, -1);
    }
    llOwnerSay(msg);
}

integer findLinkByName(string name)
{

    integer n = llGetNumberOfPrims();
    integer i;
    for (i = 1; i <= n; i++)
    {
        if (llGetLinkName(i) == name)
            return i;
    }
    return -1;
}

integer capNarrowed()
{

    string s = llLinksetDataRead(P + "cap");
    if (s == "")
        return FALSE;
    if ((integer)s >= CAP_FULL)
        return FALSE;
    return TRUE;
}

// power light vocabulary: failure > OFF > busy blink
lightTick(integer now)
{

    if (gBusy > 0 && now - gBusyStart > BUSY_TIMEOUT)
        gBusy = 0;

    integer lslState;
    vector on = COLOR_ON;
    vector off = COLOR_ON;
    if (gFailBits != 0)
    {
        lslState = 5;
        on = COLOR_OFF;
        off = COLOR_DARK;
    }
    else if (!gEnabled)
    {
        lslState = 1;
        on = COLOR_OFF;
    }
    else if (gBusy > 0)
    {
        if (now - gBusyStart > SLOW_FETCH)
        {
            lslState = 4;
            on = COLOR_CAP;
            off = COLOR_ON;
        }
        else
        {
            lslState = 3;
            on = COLOR_BUSY;
            off = COLOR_ON;
        }
    }
    else if (capNarrowed())
    {
        lslState = 2;
        on = COLOR_CAP;
    }
    else
        lslState = 0;

    if (lslState != gLitState)
    {
        if (lslState >= 3)
            llSetTimerEvent(0.5);
        else
            llSetTimerEvent(5);
        gBlinkOn = FALSE;
        gLitState = lslState;
    }
    if (lslState >= 3)
        gBlinkOn = !gBlinkOn;
    if (gBlinkOn)
        llSetLinkPrimitiveParamsFast(gLinkPower,
            [PRIM_COLOR, ALL_SIDES, on, 1.0]);
    else
        llSetLinkPrimitiveParamsFast(gLinkPower,
            [PRIM_COLOR, ALL_SIDES, off, 1.0]);
}

updateButton()
{

    lightTick(llGetUnixTime());
}

updateSoundButton()
{
    if (gLinkSound == -1)
        return;

    if (gPing)
        llSetLinkPrimitiveParamsFast(gLinkSound,
            [PRIM_COLOR, ALL_SIDES, COLOR_ON, 1.0]);
    else
        llSetLinkPrimitiveParamsFast(gLinkSound,
            [PRIM_COLOR, ALL_SIDES, COLOR_OFF, 1.0]);
}

playPing()
{

    if (gPing && llGetInventoryType(PING_SOUND) == INVENTORY_SOUND)
        llPlaySound(PING_SOUND, 1.0);
}

// blink counter for running fetches; 180 s safety stop
setBusy(integer delta)
{

    integer was = gBusy;
    gBusy = gBusy + delta;
    if (gBusy < 0)
        gBusy = 0;
    if (gBusy > 0)
    {
        if (was <= 0)
            gBusyStart = llGetUnixTime();
    }

    lightTick(llGetUnixTime());
}

integer entryFlags(key id, integer age, string pay)
{
    integer f = 0;
    if (llGetAgentInfo(id) & AGENT_AUTOMATED)
        f += 1;
    if (age >= 0 && age < 7)
        f += 2;
    if (pay == "0")
        f += 4;

    if (llListFindList(gWatchList, [(string)id]) != -1)
        f += 8;
    return f;
}

annSend(string payload, key id)
{

    if (gHaveLang)
        llMessageLinked(LINK_SET, LM_SAY, payload, id);
    else
        notifyOwner(payload);
}

// flags pick the alert ping; distance is a snapshot
announceArrival(key id, string name, integer age, string pay, string lang)
{

    integer flags = entryFlags(id, age, pay);
    if (flags)
        playPing();

    integer dist = -1;
    vector p = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
    if (p != ZERO_VECTOR)
        dist = (integer)llVecDist(llGetPos(), p);
    annSend("A|" + scopeLabel() + "|" + name + "|" +
        (string)age + "|" + pay + "|" + lang + "|" + (string)flags + "|" +
        (string)dist, id);
}

rebase()
{

    llMessageLinked(LINK_SET, LM_SWEEP_ASK, "REBASE", "");
}

setScope(integer r)
{

    if (r == gScope)
        return;
    gScope = r;
    if (r == SCOPE_RADIUS)
        savePref("scope", "RADIUS");
    else if (r == SCOPE_PARCEL)
        savePref("scope", "PARCEL");
    else
        savePref("scope", "REGION");
    rebase();
    updateButton();
    pushState();
    notifyOwner("Scope set: " + scopeLabel() + ".");
}

setPower(integer on)
{

    gEnabled = on;
    savePref("enabled", (string)gEnabled);
    if (on)
        rebase();
    updateButton();
    pushState();
    if (on)
        notifyOwner("Detector ON.");
    else
        notifyOwner("Detector OFF. Click the power button to turn it back on.");
}

setPing()
{

    gPing = !gPing;
    savePref("ping", (string)gPing);
    if (gPing)
    {
        if (llGetInventoryType(PING_SOUND) != INVENTORY_SOUND)
            notifyOwner("Ping ON - add a sound named 'notification' to hear pings.");
        else
            notifyOwner("Ping ON.");
    }
    else
        notifyOwner("Ping OFF.");
    updateSoundButton();
    pushState();
}

setRange(integer metres)
{
    if (metres < 5 || metres > 256)
    {
        notifyOwner("Radius must be between 5 and 256 meters.");
        return;
    }
    gRange = metres;
    savePref("range", (string)gRange);
    if (gScope == SCOPE_RADIUS)
        rebase();
    updateButton();
    pushState();
    notifyOwner("Radius set to " + (string)gRange + "m.");
}

// the watch list persists to SMH.watch and broadcasts as CSV
addWatch(string s)
{
    if (!validUUID(s))
    {
        notifyOwner("That does not look like a UUID.");
        return;
    }
    key k = (key)s;

    if (llListFindList(gWatchList, [(string)k]) != -1)
    {
        notifyOwner("Already watching " + safeName(k) + ".");
        return;
    }
    if (llGetListLength(gWatchList) >= MAX_WATCHED)
    {
        notifyOwner("Watch list is full (" + (string)MAX_WATCHED + ").");
        return;
    }
    gWatchList += [k];
    saveWatch();

    pushState();
    notifyOwner("Now watching: " + safeName(k) + " (" + s + ")");
}

removeWatchByIndex(integer num)
{
    if (num < 1 || num > llGetListLength(gWatchList))
    {
        notifyOwner("There is no entry number " + (string)num + ".");
        return;
    }
    key k = llList2Key(gWatchList, num - 1);
    gWatchList = llDeleteSubList(gWatchList, num - 1, num - 1);
    saveWatch();
    pushState();
    notifyOwner("Removed " + safeName(k) + " from the watch list.");
}

string memPct(integer freeBytes)
{

    return (string)freeBytes + " free (" +
        (string)((100 * (65536 - freeBytes)) / 65536) + "% used)";
}

string statusLine()
{
    string onoff;
    if (gEnabled)
        onoff = "ON";
    else
        onoff = "OFF";

    string health = "";

    if (llGetInventoryType(DATA_SCRIPT_NAME) == INVENTORY_SCRIPT)
    {
        if (!llGetScriptState(DATA_SCRIPT_NAME))
            health = health + " | DATA SCRIPT STOPPED - reset it or re-wear the HUD";
    }
    if (llGetInventoryType(REGISTRAR_SCRIPT_NAME) == INVENTORY_SCRIPT)
    {
        if (!llGetScriptState(REGISTRAR_SCRIPT_NAME))
            health = health + " | REGISTRAR SCRIPT STOPPED - reset it or re-wear the HUD";
    }
    if (llGetInventoryType(COMPANION_SCRIPT_NAME) == INVENTORY_SCRIPT)
    {
        if (!llGetScriptState(COMPANION_SCRIPT_NAME))
            health = health + " | COMPANION SCRIPT STOPPED - reset it or re-wear the HUD";
    }

    string area = scopeLabel();
    area = llGetSubString(llToUpper(area), 0, 0) + llDeleteSubString(area, 0, 0);
    return onoff + " | Area: " + area +
        " | Watch:" + (string)llGetListLength(gWatchList) +
        " | Build:" + BUILD_NUM + health;
}

sendHelp()
{

    if (llGetInventoryType(HELP_CARD) == INVENTORY_NOTECARD)
    {
        llGiveInventory(gOwner, HELP_CARD);
        notifyOwner("Help notecard delivered - open it from the notice you just received.");
        return;
    }
    notifyOwner("No help notecard found. Add one named '" + HELP_CARD +
        "' to the HUD contents. Power = on/off (green = on), Sound = alert ping, Help = this guide, Menu = settings.");
}

cDbg(string tag, string fields)
{

    if (llLinksetDataRead(P + "dlog") != "1")
        return;
    integer i = (integer)llLinksetDataRead(P + "cdbgNext");
    if (i < 0 || i >= CDBG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);
    ts = llDumpList2String([llGetSubString(ts, 0, 9), " ",
        llGetSubString(ts, 11, -1)], "");
    llLinksetDataWrite(P + "cdbg" + (string)i,
        ts + "|Core|" + tag + "|" + fields);
    i = i + 1;
    if (i >= CDBG_SLOTS)
        i = 0;
    llLinksetDataWrite(P + "cdbgNext", (string)i);
}

integer failBitsFor(string name, string hbKey, integer mask)
{

    if (llGetInventoryType(name) != INVENTORY_SCRIPT)
        return mask;
    if (!llGetScriptState(name))
        return mask;
    integer hb = (integer)llLinksetDataRead(hbKey);
    if (hb != 0 && llGetUnixTime() - hb > HB_STALE)
        return mask;
    return 0;
}

string failNames(integer mask)
{

    string s = "";
    if (mask & 1)
        s = "The Data Script";
    if (mask & 2)
    {
        if (s != "")
            s = s + " and ";
        s = s + "the Registrar Script";
    }
    if (mask & 4)
    {
        if (s != "")
            s = s + " and ";
        s = s + "the Companion Script";
    }
    return s;
}

// stale worker heartbeat -> red failure blink naming the script
checkFailures(integer now)
{

    if (gFailLast != 0 && now - gFailLast < 5)
        return;
    gFailLast = now;

    if (now < gStallGrace)
        return;
    integer was = gFailBits;
    integer bits = 0;
    bits = bits | failBitsFor(DATA_SCRIPT_NAME, P + "hb", 1);
    bits = bits | failBitsFor(REGISTRAR_SCRIPT_NAME, P + "rhb", 2);
    bits = bits | failBitsFor(COMPANION_SCRIPT_NAME, P + "chb", 4);
    integer newBits = bits & ~was;
    integer goneBits = was & ~bits;
    if (newBits != 0)
    {
        notifyOwner(failNames(newBits) +
            " not responding - take the HUD off and wear it again to fix it.");
        cDbg("FAIL", "mask=" + (string)newBits);
    }
    if (goneBits != 0)
    {
        notifyOwner(failNames(goneBits) + " responding again.");
        cDbg("FAILOK", "mask=" + (string)goneBits);
    }
    gFailBits = bits;
}

// deletes every SMH key; every script boots fresh after
doWipe()
{

    llLinksetDataDelete(P + "owner");
    llLinksetDataDelete(P + "scope");
    llLinksetDataDelete(P + "range");
    llLinksetDataDelete(P + "enabled");
    llLinksetDataDelete(P + "watch");
    llLinksetDataDelete(P + "ping");
    llLinksetDataDelete(P + "lastpt");
    llLinksetDataDelete(P + "setup");

    integer ei;
    for (ei = 0; ei < 10; ei++)
        llLinksetDataDelete(P + "err" + (string)ei);
    llLinksetDataDelete(P + "errNext");

    llLinksetDataDelete(P + "gap");
    llLinksetDataDelete(P + "coregap");
    llLinksetDataDelete(P + "starve");

    llLinksetDataDelete(P + "cap");

    llLinksetDataDelete(P + "hb");
    llLinksetDataDelete(P + "rhb");
    llLinksetDataDelete(P + "corehb");
    llLinksetDataDelete(P + "chb");

    integer di;
    for (di = 0; di < 24; di++)
        llLinksetDataDelete(P + "dbg" + (string)di);
    llLinksetDataDelete(P + "dbgNext");
    for (di = 0; di < 8; di++)
        llLinksetDataDelete(P + "cdbg" + (string)di);
    llLinksetDataDelete(P + "cdbgNext");

    for (di = 0; di < 8; di++)
        llLinksetDataDelete(P + "rdbg" + (string)di);
    llLinksetDataDelete(P + "rdbgNext");

    cDbg("WIPE", "fresh");
    llLinksetDataDelete(P + "dlog");

    for (ei = 0; ei < 50; ei++)
        llLinksetDataDelete(P + "enc" + (string)ei);
    llLinksetDataDelete(P + "encNext");
    llLinksetDataDelete(P + "encdays");

    if (llGetInventoryType(COMPANION_SCRIPT_NAME) == INVENTORY_SCRIPT)
        llResetOtherScript(COMPANION_SCRIPT_NAME);
    if (llGetInventoryType(DATA_SCRIPT_NAME) == INVENTORY_SCRIPT)
        llResetOtherScript(DATA_SCRIPT_NAME);
    if (llGetInventoryType(REGISTRAR_SCRIPT_NAME) == INVENTORY_SCRIPT)
        llResetOtherScript(REGISTRAR_SCRIPT_NAME);

    gScope = SCOPE_PARCEL;
    gRange = 25;
    gEnabled = TRUE;
    gPing = FALSE;
    gWatchList = [];
    rebase();
    updateButton();
    updateSoundButton();
    pushState();
    notifyOwner("All saved data erased. Defaults restored: parcel scope, ON, empty watch list. All scripts reset.");

    llResetScript();
}

// owner chat commands
handleCmd(string cmd)
{

    integer bar = llSubStringIndex(cmd, "|");
    if (bar == -1)
    {
        if (cmd == "SCAN")
        {
            if (gHaveData)
                llMessageLinked(LINK_SET, LM_SWEEP_ASK, "SCAN", "");
            else
                notifyOwner("Data Script missing - add it to the HUD contents for detection and List All.");
        }
        else if (cmd == "CENSUS")
        {

            if (gHaveData)
                llMessageLinked(LINK_SET, LM_SWEEP_ASK, "CENSUS", "");
            else
                notifyOwner("Data Script missing - add it to the HUD contents for detection, List All and Summary.");
        }
        else if (cmd == "STATUS")
            notifyOwner(statusLine());
        else if (cmd == "WIPE")
            doWipe();
        else if (cmd == "SYNC")
            pushState();
        return;
    }
    string head = llGetSubString(cmd, 0, bar - 1);
    string arg = llGetSubString(cmd, bar + 1, -1);
    if (head == "POWER")
        setPower((integer)arg);
    else if (head == "SCOPE")
        setScope((integer)arg);
    else if (head == "RANGE")
        setRange((integer)arg);
    else if (head == "ADD")
        addWatch(arg);
    else if (head == "REM")
        removeWatchByIndex((integer)arg);
}

// ---------- events ----------
default
{
// boot: load settings, place the panel, broadcast state, ask workers to SYNC
    state_entry()
    {

        llOwnerSay("Core boot (Build " + BUILD_NUM +
            "), memory: " + memPct(llGetFreeMemory()));

        cDbg("CBOOT", "free=" + (string)llGetFreeMemory());
        gOwner = llGetOwner();

        llLinksetDataDelete(P + "coregap");

        llLinksetDataWrite(P + "langmap", LANG_MAP);
        loadSettings();
        gLinkPower = findLinkByName(BUTTON_POWER);
        if (gLinkPower == -1)
            gLinkPower = LINK_ROOT;
        gLinkHelp = findLinkByName(BUTTON_HELP);
        gLinkSound = findLinkByName(BUTTON_SOUND);
        gLinkMenu = findLinkByName(BUTTON_MENU);

        applyDefaultPlacement(FALSE);
        llListen(reseatChannel(), "", llGetOwner(), "");

        llMessageLinked(LINK_SET, LM_LANG_ASK, "ping", "");
        llMessageLinked(LINK_SET, LM_DATA_ASK, "ping", "");

        llSetTimerEvent(5);
        gStallGrace = llGetUnixTime() + 30;

        updateButton();
        updateSoundButton();
        pushState();

        llOwnerSay("Opossum Labs Awareness HUD v" + HUD_VERSION + " ready. " + statusLine());

        llOwnerSay("If the HUD ever sits off-screen: type /" +
            (string)reseatChannel() + " reseat to bring it back.");
    }

// re-rezzed: same boot path
    on_rez(integer start_param)
    {

        if (llGetOwner() != gOwner)
            llResetScript();
    }

// attach/detach bookkeeping
    attach(key avatar)
    {

        if (avatar != NULL_KEY)
            applyDefaultPlacement(FALSE);
    }

// owner change wipes everything; region change rebases
    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();

    }

// every 5 s (0.5 s while blinking): heartbeat, gap record, light, failure sweep
    timer()
    {
        integer now = llGetUnixTime();

        if (gHbCore != 0 && now - gHbCore > 300)
        {
            llLinksetDataWrite(P + "coregap",
                (string)(now - gHbCore) + "|" + (string)now);

            cDbg("CGAP", "dead=" + (string)(now - gHbCore) + "s");
        }

        if (gHbCore == 0 || now - gHbCore > 300)
            gStallGrace = now + 30;
        gHbCore = now;

        llLinksetDataWrite(P + "corehb", (string)now);

        if (now > gStallGrace &&
            llGetInventoryType(DATA_SCRIPT_NAME) == INVENTORY_SCRIPT)
        {
            if (llGetScriptState(DATA_SCRIPT_NAME))
            {
                integer hb = (integer)llLinksetDataRead(P + "hb");
                if (hb != 0 && now - hb > 120 && !gStalled)
                {
                    gStalled = TRUE;

                    cDbg("STALL", "stale=" + (string)(now - hb) + "s");
                }
                else if (gStalled && (hb == 0 || now - hb <= 120))
                {
                    gStalled = FALSE;

                    cDbg("STALLOK", "hb=" + (string)hb);
                }
            }
        }

        checkFailures(now);
        lightTick(now);
    }

// owner chat commands
    listen(integer channel, string name, key id, string msg)
    {

        if (msg != "reseat" && msg != ":reseat")
            return;
        applyDefaultPlacement(TRUE);
        llOwnerSay("HUD re-seated to its default screen position. " +
            "Nudge it in the viewer if you want it elsewhere.");
    }

// panel button presses
    touch_start(integer total_number)
    {

        if (llDetectedKey(0) != gOwner)
            return;

        integer btn = llDetectedLinkNumber(0);

        if (btn == gLinkPower)
            setPower(!gEnabled);
        else if (btn == gLinkHelp)
            sendHelp();
        else if (btn == gLinkSound)
            setPing();
        else if (btn == gLinkMenu)
            llMessageLinked(LINK_SET, LM_MENU_OPEN, "", "");

    }

// menu commands from the Companion, worker events, debug replies
    link_message(integer sender_num, integer num, string str, key id)
    {

        if (num == LM_MEM_ASK)
        {

            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Core Script|" + (string)llGetFreeMemory() + "|" +
                BUILD_NUM, "");

            if (llLinksetDataRead(P + "dlog") == "1")
            {
                llOwnerSay("Debug log - Registrar events:");
                integer rn = (integer)llLinksetDataRead(P + "rdbgNext");
                if (rn < 0 || rn >= 8)
                    rn = 0;
                integer shown = 0;
                integer rk;
                for (rk = 0; rk < 8; rk++)
                {
                    string re = llLinksetDataRead(P + "rdbg" +
                        (string)((rn + rk) % 8));
                    if (re != "")
                    {
                        llOwnerSay("Debug log: " + re);
                        shown = shown + 1;
                    }
                }
                if (shown == 0)
                    llOwnerSay("Debug log: none recorded.");
            }
            return;
        }

        if (num == LM_UI_CMD)
        {
            handleCmd(str);
            return;
        }

        if (num == LM_DATA_TELL)
        {
            if (str == "ping=ok")
            {
                gHaveData = TRUE;
                return;
            }

            list f = llParseStringKeepNulls(str, ["|"], []);
            key a = (key)llList2String(f, 1);
            string name = llList2String(f, 2);
            integer age = (integer)llList2String(f, 3);
            string pay = llList2String(f, 4);
            string lang = llList2String(f, 5);
            announceArrival(a, name, age, pay, lang);
            return;
        }

        if (num == LM_EVENT)
        {
            list f = llParseStringKeepNulls(str, ["|"], []);
            string kind = llList2String(f, 0);
            if (kind == "OUT")
            {

                key a = (key)llList2String(f, 1);

                annSend("L|" + scopeLabel() + "|" + llList2String(f, 2) + "|" +
                    (string)(llListFindList(gWatchList, [(string)a]) != -1), a);
            }
            else if (kind == "WIN")
            {
                playPing();

                annSend("W|" + llList2String(f, 1) + "|1|" + llList2String(f, 2), "");
            }
            else if (kind == "WFOUND")
            {

                playPing();
                annSend("W|" + llList2String(f, 1) + "|2|" + llList2String(f, 2), "");
            }
            else if (kind == "BUSY")
            {

                if (llList2String(f, 1) == "1")
                    setBusy(1);
                else
                    setBusy(-1);
            }
            else if (kind == "WOUT")
                annSend("W|" + llList2String(f, 1) + "|0", "");
            return;
        }

        if (num != LM_LANG_TELL)
            return;
        if (str == "ping=ok")
            gHaveLang = TRUE;
    }
}
