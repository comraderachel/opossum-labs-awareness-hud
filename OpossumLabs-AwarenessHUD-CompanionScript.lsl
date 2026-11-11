// Opossum Labs Awareness HUD v1.0 - Companion Script
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
// This script is the wearer's interface: every menu, every dialog and
// every chat line, plus the encounter log, the Core watchdog and
// its own quiescent self-heal reset.

// ---------- constants and globals ----------
integer LM_LANG_ASK = 19024;
integer LM_LANG_TELL = 19025;

integer LM_SAY = 19027;
integer LM_MENU_OPEN = 19028;
integer LM_UI_STATE = 19029;
integer LM_UI_CMD = 19030;
integer LM_WATCH_LIST = 19031;
integer LM_SWEEP_ASK = 19034;

integer LM_MEM_ASK = 19036;

integer LM_MEM_TELL = 19037;

integer MENU_TIMEOUT = 60;

string P = "SMH.";

string BUILD_NUM = "110626086";

string HUD_VERSION = "1.0";

integer ERR_LOG_SLOTS = 10;

integer DBG_SLOTS = 24;

integer CDBG_SLOTS = 8;

integer ENC_MAX = 50;

integer ENC_DAYS_DEFAULT = 30;

integer gChannel = -1;
integer gMode = 0;

integer gModeExpiry = 0;
integer gMenu = 0;

integer gPickDue = 0;

integer gRemPage;

integer gLowLast = 0;

integer gCoreWatch;

integer gWatchBlink;
integer gLinkPowerC;

integer gWatchGrace;

integer gTickLast;

integer gWelcome = FALSE;

integer gSetupDue = 0;

integer gEnabled = TRUE;
integer gScope = 0;
integer gRange = 25;
list gWatch = [];

integer strBytes(string s)
{

    string b = llStringToBase64(s);
    integer n = llStringLength(b) * 3 / 4;
    if (llGetSubString(b, -1, -1) == "=")
        n = n - 1;
    if (llGetSubString(b, -2, -2) == "=")
        n = n - 1;
    return n;
}

string nameUri(key k)
{

    return "secondlife:///app/agent/" + (string)k + "/displayname";
}

string payText(string pay)
{

    if (pay == "")
        return "Unavailable";
    integer m = (integer)pay;
    if (m & PAYMENT_INFO_ON_FILE)
    {
        if (m & PAYMENT_INFO_USED)
            return "On File & Used";
        return "On File";
    }
    if (m & PAYMENT_INFO_USED)
        return "Previously Used";
    return "None";
}

string flagText(integer f)
{

    string s = "";
    if (f & 2)
        s += " [NEW ACCOUNT]";
    if (f & 8)
        s += " [WATCHED]";
    return s;
}

string ageText(string age)
{
    integer d = (integer)age;
    if (d < 0)
        return "?";
    if (d < 365)
        return (string)d + "d";
    integer y = d / 365;
    integer rem = d % 365;
    if (rem == 0)
        return (string)y + "y";
    return (string)y + "y " + (string)rem + "d";
}

string entryText(string name, string age, string pay, string lang, string flags,
    integer dist)
{
    integer f = (integer)flags;
    string lead = "";
    if (f & 1)
        lead = "AUTOMATED AGENT: ";
    if (lang == "")
        lang = "Unknown";

    string s = lead + name + " | Age:" + ageText(age) + " | Pay:" + payText(pay) +
        " | Lang:" + lang;
    if (dist >= 0)
        s += " | " + (string)dist + "m away";
    return s + flagText(f);
}

integer daysFromCivil(integer y, integer m)
{

    if (m <= 2)
        y -= 1;
    integer era = y / 400;
    integer yoe = y - era * 400;

    integer mp = m + 9;
    if (m > 2) mp = m - 3;
    integer doy = (153 * mp + 2) / 5;
    integer doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

integer civilFromDays(integer z)
{

    z += 719468;
    integer era = z / 146097;
    integer doe = z - era * 146097;
    integer yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    integer y = yoe + era * 400;
    integer doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    integer mp = (5 * doy + 2) / 153;
    integer d = doy - (153 * mp + 2) / 5 + 1;
    integer m = mp + 3;
    if (mp >= 10)
        m = mp - 9;
    if (m <= 2)
        y += 1;
    return y * 10000 + m * 100 + d;
}

string encP2(integer n)
{

    if (n < 10)
        return "0" + (string)n;
    return (string)n;
}

string sltFromUnix(integer u)
{

    integer ymd = civilFromDays(u / 86400);
    integer y = ymd / 10000;
    integer march1 = daysFromCivil(y, 3);
    integer nov1 = daysFromCivil(y, 11);
    integer start = (march1 + (7 - (march1 + 4) % 7) % 7 + 7) * 86400 + 36000;
    integer end = (nov1 + (7 - (nov1 + 4) % 7) % 7) * 86400 + 32400;
    integer off = 28800;
    if (u >= start && u < end)
        off = 25200;
    integer lu = u - off;
    ymd = civilFromDays(lu / 86400);
    integer ls = lu % 86400;
    return (string)(ymd / 10000) + "-" + encP2((ymd / 100) % 100) + "-" +
        encP2(ymd % 100) + " " + encP2(ls / 3600) + ":" +
        encP2((ls % 3600) / 60);
}

// ---------- functions ----------
// The encounter log is a ring in linkset data (SMH.enc).
encPurge()
{

    integer now = llGetUnixTime();
    integer limit = ENC_DAYS_DEFAULT * 86400;
    integer i;
    for (i = 0; i < ENC_MAX; i++)
    {
        string e = llLinksetDataRead(P + "enc" + (string)i);
        if (e != "" && now - (integer)llList2String(
            llParseStringKeepNulls(e, ["|"], []), 0) >= limit)
            llLinksetDataDelete(P + "enc" + (string)i);
    }
}

encLog(key id, string uri, integer automated)
{

    integer now = llGetUnixTime();
    string region = llGetRegionName();
    integer i;
    for (i = 0; i < ENC_MAX; i++)
    {
        string e = llLinksetDataRead(P + "enc" + (string)i);
        if (e != "")
        {
            list f = llParseStringKeepNulls(e, ["|"], []);
            if (llSubStringIndex(llList2String(f, 1), (string)id) != -1 &&
                llList2String(f, 2) == region &&
                now - (integer)llList2String(f, 0) < 86400)
                return;
        }
    }
    string parcel = "";
    vector p = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
    if (p != ZERO_VECTOR)
        parcel = llList2String(llGetParcelDetails(p, [PARCEL_DETAILS_NAME]), 0);
    integer slot = (integer)llLinksetDataRead(P + "encNext") + 1;
    if (slot >= ENC_MAX || slot < 0)
        slot = 0;
    string entry = (string)now + "|" + uri + "|" + region + "|" + parcel;
    if (automated)
        entry += "|A";
    llLinksetDataWrite(P + "enc" + (string)slot, entry);
    llLinksetDataWrite(P + "encNext", (string)slot);
}

encShow()
{

    encPurge();
    integer nxt = (integer)llLinksetDataRead(P + "encNext");
    if (nxt < 0 || nxt >= ENC_MAX)
        nxt = 0;
    integer shown = 0;
    string out = "";
    integer i;
    for (i = 1; i <= ENC_MAX; i++)
    {
        string e = llLinksetDataRead(
            P + "enc" + (string)((nxt + i) % ENC_MAX));
        if (e != "")
        {
            list f = llParseStringKeepNulls(e, ["|"], []);
            string who = llList2String(f, 1);
            if (llList2String(f, 4) == "A")
                who += " [AUTOMATED AGENT]";
            string line = sltFromUnix((integer)llList2String(f, 0)) +
                " SLT - " + who + " - " + llList2String(f, 2);
            if (llList2String(f, 3) != "")
                line += " (" + llList2String(f, 3) + ")";
            out += line + "\n";
            shown++;
            if (strBytes(out) > 750)
            {
                llOwnerSay(out);
                out = "";
            }
        }
    }
    if (shown == 0)
        llOwnerSay("Encounters: none recorded yet (kept " +
            (string)ENC_DAYS_DEFAULT + " days).");
    else
    {
        if (out != "")
            llOwnerSay(out);
        llOwnerSay("(" + (string)shown + " shown; kept " +
            (string)ENC_DAYS_DEFAULT + " days, oldest dropped past 50 entries)");
    }
}

string gapText(integer secs)
{

    string dur = (string)(secs / 60) + "m";
    if (secs >= 3600)
        dur = (string)(secs / 3600) + "h " + (string)((secs % 3600) / 60) + "m";
    return dur;
}

// the text valve: every worker code becomes one chat line
// (A arrivals, L left, W watch, AE encounters, C census, D slowdown,
// N notes, NR the Watch+ handshake)
handleSay(string str, key id)
{

    list f = llParseStringKeepNulls(str, ["|"], []);
    string kind = llList2String(f, 0);
    if (kind == "A")
    {

        integer dist = (integer)llList2String(f, 7);
        llOwnerSay("ARRIVED (" + llList2String(f, 1) + "): " +
            entryText(llList2String(f, 2), llList2String(f, 3),
                      llList2String(f, 4), llList2String(f, 5), llList2String(f, 6),
                      dist));

        integer afl = (integer)llList2String(f, 6);
        if (afl & 1)
            encLog(id, llList2String(f, 2), TRUE);
        else if (afl & 8)
            encLog(id, llList2String(f, 2), FALSE);
    }
    else if (kind == "L")
    {
        string t = "LEFT (" + llList2String(f, 1) + "): " + llList2String(f, 2);
        if (llList2String(f, 3) == "1")
            t += " [WATCHED]";
        llOwnerSay(t);
    }
    else if (kind == "W")
    {
        string t = "WATCHED: " + llList2String(f, 1);
        if (llList2String(f, 2) == "1")
            t += " entered the region.";
        else if (llList2String(f, 2) == "2")
            t += " is already in the region.";
        else
            t += " left the region.";
        llOwnerSay(t);

        if (llGetListLength(f) > 3 &&
            (llList2String(f, 2) == "1" || llList2String(f, 2) == "2"))
            encLog((key)llList2String(f, 3), llList2String(f, 1), FALSE);
    }
    else if (kind == "AE")
    {

        encLog((key)llList2String(f, 2), llList2String(f, 1), TRUE);
    }

    else if (kind == "C")
    {

        string label = "ARRIVAL SUMMARY";
        if (llList2String(f, 6) == "M")
            label = "SUMMARY";
        string newT = llList2String(f, 3);
        if (newT == "-1")
            newT = "not counted (low script memory)";

        string extra = "";
        integer more = llList2Integer(f, 7);
        if (more > 0)
            extra = " | and " + (string)more + " more (low memory)";
        integer capCtx = llList2Integer(f, 8);
        if (capCtx > 0 && llList2Integer(f, 2) > capCtx)
            extra += " | detection tracking the first " + (string)capCtx;
        llOwnerSay(label + " (" + llList2String(f, 1) + "): " +
            llList2String(f, 2) + " avatars | Scripted agents: " + llList2String(f, 4) +
            " | New accounts: " + newT +
            " | On watch list: " + llList2String(f, 5) + extra);
    }
    else if (kind == "D")
    {

        if (llList2String(f, 1) == "low")

            llOwnerSay("REGION SLOWDOWN: the sim is running at " +
                llList2String(f, 2) + "% of normal speed. " +
                "You will hear when it recovers.");
        else
            llOwnerSay("Region speed recovered: " + llList2String(f, 2) +
                "% of normal.");
    }
    else if (kind == "NR")
    {

        gPickDue = 0;
    }
    else if (kind == "N")
    {

        string code = llList2String(f, 1);
        if (code == "MEMPAUSE")
            llOwnerSay("Low script memory in this region - arrival and watch alerts are paused so the HUD does not crash. They come back on their own as the region quiets down. Menus still work; Settings > Debug > Status Check shows the memory numbers.");
        else if (code == "BUSY")
        {

            if (llGetListLength(f) > 4 && llList2String(f, 4) == "1")
                llOwnerSay("Very busy region (" + llList2String(f, 2) + " avatars) - tracking the first " + llList2String(f, 3) + " only, to protect memory.");
            else
                llOwnerSay("Low script memory - tracking the first " + llList2String(f, 3) + " of " + llList2String(f, 2) + " avatars for now. Tracking widens again on its own as memory recovers.");
        }
        else if (code == "SCANBUSY")
            llOwnerSay("A scan is already running - please wait.");

        else if (code == "SCANMEM")

            llOwnerSay("Too little free memory to list people safely here - Summary still works for a quick count.");
        else if (code == "SCANEMPTY")
            llOwnerSay("No avatars currently in " + llList2String(f, 2) + ".");

        else if (code == "SUMSTOCK")
            llOwnerSay("Still taking stock of this region - try Summary again in a few seconds.");
        else if (code == "PAUSE")
        {

            llOwnerSay("Scanning was paused for " +
                gapText((integer)llList2String(f, 2)) +
                " - usually a parcel with scripts disabled (the HUD cannot run there) or a sim too busy to run it. Scanning has resumed.");
        }
        else if (code == "GAP")
        {

            llOwnerSay("Detection made no pass for " +
                gapText((integer)llList2String(f, 2)) +
                ", ending " + sltFromUnix((integer)llList2String(f, 3)) +
                " SLT - the HUD was frozen, detached or logged out.");
        }
    }
}

string scopeLabel()
{
    if (gScope == 1)
        return (string)gRange + "m radius";
    if (gScope == 2)
        return "parcel";
    return "region";
}

string memPct(integer freeBytes)
{

    return (string)freeBytes + " free (" +
        (string)((100 * (65536 - freeBytes)) / 65536) + "% used)";
}

string lsdPct(integer freeBytes)
{

    return (string)freeBytes + " free (" +
        (string)((100 * (131072 - freeBytes)) / 131072) + "% used)";
}

string uiStatus()
{
    string onoff = "OFF";
    if (gEnabled)
        onoff = "ON";

    string area = scopeLabel();
    area = llGetSubString(llToUpper(area), 0, 0) + llDeleteSubString(area, 0, 0);
    return onoff + " | Area: " + area +
        " | Watch:" + (string)llGetListLength(gWatch);
}

showMainMenu()
{

    gMode = 0;
    gMenu = 0;
    llDialog(llGetOwner(), "Opossum Labs Awareness HUD v" + HUD_VERSION + "\n" + uiStatus(),
        ["Summary", "List All", "Watch+",
         "Watch-", "Watch List", "Encounters",
         "Status", "Settings"],
        gChannel);
}

showSettingsMenu()
{

    gMode = 0;
    gMenu = 1;
    llDialog(llGetOwner(),
        "Settings\n" + uiStatus(),
        ["Area", "Debug", "Wipe", "Back"],
        gChannel);
}

showDebugMenu()
{

    gMode = 0;
    gMenu = 7;
    string dl = "OFF";
    if (llLinksetDataRead(P + "dlog") == "1")
        dl = "ON";
    llDialog(llGetOwner(),
        "Diagnostics\nDebug Log: " + dl + "\n\n" +
        "Status Check - the full report: version,\n" +
        "settings, channel, linkset-data space, one\n" +
        "memory line per script, recent errors and\n" +
        "freeze notes.\n\n" +
        "Debug Log - record boot numbers, memory\n" +
        "snapshots and valve events to a ring.\n" +
        "Dump Log - print the story, oldest first.",
        ["Status Check", "Debug Log", "Dump Log", "Back"],
        gChannel);
}

dumpDbg()
{

    llOwnerSay("Debug log - Data events:");
    integer n = (integer)llLinksetDataRead(P + "dbgNext");
    if (n < 0 || n >= DBG_SLOTS)
        n = 0;
    integer shown = 0;
    integer k;
    for (k = 0; k < DBG_SLOTS; k++)
    {
        string e = llLinksetDataRead(
            P + "dbg" + (string)((n + k) % DBG_SLOTS));
        if (e != "")
        {
            llOwnerSay("Debug log: " + e);
            shown = shown + 1;
        }
    }
    if (shown == 0)
        llOwnerSay("Debug log: none recorded.");
    llOwnerSay("Debug log - Core events:");
    integer cn = (integer)llLinksetDataRead(P + "cdbgNext");
    if (cn < 0 || cn >= CDBG_SLOTS)
        cn = 0;
    shown = 0;
    for (k = 0; k < CDBG_SLOTS; k++)
    {
        string e = llLinksetDataRead(
            P + "cdbg" + (string)((cn + k) % CDBG_SLOTS));
        if (e != "")
        {
            llOwnerSay("Debug log: " + e);
            shown = shown + 1;
        }
    }
    if (shown == 0)
        llOwnerSay("Debug log: none recorded.");
}

showAreaMenu()
{

    gMode = 0;
    gMenu = 2;
    llDialog(llGetOwner(),
        "Where do you want to watch?\nCurrently: " + scopeLabel() +
        "\n\nParcel - the parcel you are standing on" +
        "\nRegion - the whole region (very busy areas: first ~20 only)" +
        "\nRadius - a sphere around YOU that travels with you",
        ["Parcel", "Region", "Radius",
         "Back"],
        gChannel);
}

showRadiusMenu()
{

    gMode = 0;
    gMenu = 5;
    llDialog(llGetOwner(),
        "Radius size (sphere around you)\nCurrently: " + (string)gRange + "m" +
        "\n\nPick a size, or Custom for a pop-up box:",
        ["10m", "25m", "50m",
         "100m", "Custom", "Back"],
        gChannel);
}

// first boot or post-Wipe setup flow
showWelcomeMenu()
{

    gMode = 0;
    gMenu = 6;
    llDialog(llGetOwner(),
        "Welcome to your Opossum Labs Awareness HUD v" + HUD_VERSION + "!\n\n" +
        "It quietly tells you when someone enters where you are " +
        "watching - with their account age, payment status and " +
        "viewer language. Nobody nearby sees or hears any of it.\n\n" +
        "To start, WHERE should it watch?\n" +
        "Parcel - the parcel you are standing on (suggested)\n" +
        "Region - the whole region (very busy areas: first ~20 only)\n" +
        "Radius - a sphere around you (pick a size next)\n\n" +
        "You can change this later in Settings > Area. " +
        "Click Ignore to keep the defaults.",
        ["Parcel", "Region", "Radius"],
        gChannel);
}

finishSetup()
{

    gWelcome = FALSE;
    gMenu = 0;
    llOwnerSay("Setup complete. Click the Menu button for watch lists and settings; the Help button has the full guide.");
}

showAddMenu()
{

    gMenu = 3;
    gPickDue = llGetUnixTime() + 10;
// 10 s safety net: a silent Registrar still gets an honest answer
    llMessageLinked(LINK_SET, LM_SWEEP_ASK, "NEAR", "");
}

// Watch-: pages of six names
showRemoveMenu()
{

    integer n = llGetListLength(gWatch);
    if (n == 0)
    {
        llOwnerSay("The watch list is empty.");
        return;
    }
    gMenu = 4;
    integer pages = (n + 5) / 6;
    if (gRemPage >= pages)
        gRemPage = 0;
    integer start = gRemPage * 6;
    integer end = start + 6;
    if (end > n)
        end = n;

    string body = "Remove who?\n";
    list buttons;
    integer i;
    for (i = start; i < end; i++)
    {
        body += (string)(i + 1) + ". " + nameUri(llList2Key(gWatch, i)) + "\n";
        buttons += [(string)(i + 1)];
    }
    if (pages > 1)
        buttons += ["More"];
    buttons += ["Back"];
    llDialog(llGetOwner(),
        body + "Page " + (string)(gRemPage + 1) + " of " + (string)pages,
        buttons, gChannel);
}

// Encounters: prints the log from SMH.enc
showRoster()
{
    integer n = llGetListLength(gWatch);
    if (n == 0)
    {
        llOwnerSay("The watch list is empty.");
        return;
    }

    string out = "Watch list (" + (string)n + "):\n";
    integer i;
    for (i = 0; i < n; i++)
    {
        key k = llList2Key(gWatch, i);
        out += (string)(i + 1) + ". " + nameUri(k) + " (" + (string)k + ")\n";
        if (strBytes(out) > 900 && i < n - 1)
        {
            llOwnerSay(out);
            out = "";
        }
    }
    if (out != "")
        llOwnerSay(out);
}

// error ring entries (SMH.err)
watchRing(string what)
{

    integer i = (integer)llLinksetDataRead(P + "errNext");
    if (i < 0 || i >= ERR_LOG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);
    ts = llDumpList2String([llGetSubString(ts, 0, 9), " ",
        llGetSubString(ts, 11, -1)], "");
    llLinksetDataWrite(P + "err" + (string)i,
        ts + "|Companion|" + what);
    i = i + 1;
    if (i >= ERR_LOG_SLOTS)
        i = 0;
    llLinksetDataWrite(P + "errNext", (string)i);
}

integer findPowerLink()
{

    integer n = llGetNumberOfPrims();
    integer i;
    for (i = 1; i <= n; i++)
    {
        if (llGetLinkName(i) == "Power Button")
            return i;
    }
    return LINK_ROOT;
}

// ---------- events ----------
default
{
// boot: reload every mirror from linkset data
    state_entry()
    {

        gChannel = -(integer)llFrand(1000000000) - 1000000000;
        llListen(gChannel, "", llGetOwner(), "");

        llSetTimerEvent(5);

        gWatchGrace = llGetUnixTime() + 30;

        encPurge();

        integer fresh = (llLinksetDataRead(P + "setup") != "1");
        string storedOwner = llLinksetDataRead(P + "owner");
        if (storedOwner != "" && (key)storedOwner != llGetOwner())
            fresh = TRUE;
        if (fresh)
        {
            gWelcome = TRUE;
            llLinksetDataWrite(P + "setup", "1");
            gSetupDue = llGetUnixTime() + 8;
        }

        llMessageLinked(LINK_SET, LM_UI_CMD, "SYNC", "");

        llMessageLinked(LINK_SET, LM_LANG_TELL, "ping=ok", "");
        llOwnerSay("Companion ready (Build " + BUILD_NUM +
            "). Memory: " + memPct(llGetFreeMemory()));
    }

// owner change resets everything
    changed(integer change)
    {

        if (change & CHANGED_OWNER)
            llResetScript();
    }

// every 2 s: heartbeat, menu expiries, Core watchdog, low-water
// report, self-heal gate
    timer()
    {

        integer now = llGetUnixTime();

        llLinksetDataWrite(P + "chb", (string)now);

        if (gTickLast != 0 && now - gTickLast > 60)
            gWatchGrace = now + 30;
        gTickLast = now;
        if (now >= gWatchGrace)
        {
            integer cb = (integer)llLinksetDataRead(P + "corehb");
// Core watchdog: a dead Core cannot report itself
            if (!gCoreWatch && cb != 0 && now - cb > 120)
            {
                gCoreWatch = TRUE;
                llSetTimerEvent(0.5);
                llOwnerSay("The Core Script is not responding - take the HUD off and wear it again to fix it.");
                watchRing("corewatch: corehb stale " +
                    (string)(now - cb) + "s");
            }
            else if (gCoreWatch && (cb == 0 || now - cb <= 120))
            {
                gCoreWatch = FALSE;
                llSetTimerEvent(5);
                llOwnerSay("The Core Script is responding again.");
                watchRing("corewatchok: hb=" + (string)cb);
            }
        }
        if (gCoreWatch)
        {

            if (gLinkPowerC == 0)
                gLinkPowerC = findPowerLink();
            gWatchBlink = !gWatchBlink;
            if (gWatchBlink)
                llSetLinkPrimitiveParamsFast(gLinkPowerC,
                    [PRIM_COLOR, ALL_SIDES, <0.90, 0.25, 0.25>, 1.0]);
            else
                llSetLinkPrimitiveParamsFast(gLinkPowerC,
                    [PRIM_COLOR, ALL_SIDES, <0.03, 0.03, 0.03>, 1.0]);
        }

        integer cf = llGetFreeMemory();
        if (cf < 2500 && llGetUnixTime() - gLowLast >= 600)
        {
            gLowLast = llGetUnixTime();
            integer i = (integer)llLinksetDataRead(P + "errNext");
            if (i < 0 || i >= ERR_LOG_SLOTS)
                i = 0;
            string ts = llGetSubString(llGetTimestamp(), 0, 18);
            ts = llDumpList2String([llGetSubString(ts, 0, 9), " ",
                llGetSubString(ts, 11, -1)], "");
            llLinksetDataWrite(P + "err" + (string)i,
                ts + "|Companion|low: " + (string)cf + " free");
            i = i + 1;
            if (i >= ERR_LOG_SLOTS)
                i = 0;
            llLinksetDataWrite(P + "errNext", (string)i);
        }

// self-heal: below 2000 free at a quiescent moment, reset
        if (cf < 2000 && gMode == 0 && gPickDue == 0 &&
            !gWelcome && gSetupDue == 0 && !gCoreWatch)
        {
            watchRing("selfheal: reset at " + (string)cf + " free");
            llResetScript();
        }

        if (gMode != 0 && llGetUnixTime() > gModeExpiry)
            gMode = 0;

        if (gSetupDue != 0 && llGetUnixTime() >= gSetupDue)
        {
            gSetupDue = 0;
            string storedOwner = llLinksetDataRead(P + "owner");
            if (storedOwner == "" || (key)storedOwner == llGetOwner())
                showWelcomeMenu();
        }

        if (gPickDue != 0 && llGetUnixTime() >= gPickDue)
        {
            gPickDue = 0;

            if (gMenu == 3)
                llDialog(llGetOwner(),
                    "The Registrar Script did not answer.\nManual Add still works with an avatar key.",
                    ["Manual Add", "Back"], gChannel);
        }
    }

// menu clicks and typed input (UUID, radius)
    listen(integer channel, string name, key id, string msg)
    {
        if (channel != gChannel || id != llGetOwner())
            return;
        msg = llStringTrim(msg, STRING_TRIM);

        if (gMode == 1)
        {
            gMode = 0;

            llMessageLinked(LINK_SET, LM_UI_CMD, "ADD|" + msg, "");
            return;
        }
        if (gMode == 2)
        {
            gMode = 0;

            llMessageLinked(LINK_SET, LM_UI_CMD, "SCOPE|1", "");
            llMessageLinked(LINK_SET, LM_UI_CMD, "RANGE|" + msg, "");
            if (gWelcome)
                finishSetup();
            return;
        }

        if (msg == "Summary")
        {

            llMessageLinked(LINK_SET, LM_UI_CMD, "CENSUS", "");
            return;
        }
        if (msg == "List All")
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "SCAN", "");
            return;
        }
        if (msg == "Area")
        {
            showAreaMenu();
            return;
        }
        if (msg == "Settings")
        {
            showSettingsMenu();
            return;
        }
        if (msg == "Encounters")
        {

            encShow();
            return;
        }
        if (msg == "Watch+")
        {
            showAddMenu();
            return;
        }
        if (msg == "Manual Add")
        {

            gMode = 1;
            gModeExpiry = llGetUnixTime() + MENU_TIMEOUT;
            llTextBox(llGetOwner(),
                "Paste the avatar key (UUID) you want to watch, then click Submit:",
                gChannel);
            return;
        }
        if (msg == "More")
        {

            gRemPage = gRemPage + 1;
            showRemoveMenu();
            return;
        }
        if (msg == "Watch-")
        {
            showRemoveMenu();
            return;
        }
        if (msg == "Watch List")
        {
            showRoster();
            return;
        }

        if (msg == "Status")
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "STATUS", "");
            return;
        }
        if (msg == "Debug")
        {

            showDebugMenu();
            return;
        }
        if (msg == "Status Check")
        {

            llOwnerSay("Opossum Labs Awareness HUD v" + HUD_VERSION +
                " | " + uiStatus() +
                " | Channel: " + (string)gChannel +
                " | LinksetData: " + lsdPct(llLinksetDataAvailable()));

            integer en = (integer)llLinksetDataRead(P + "errNext");
            if (en < 0 || en >= ERR_LOG_SLOTS)
                en = 0;
            integer shown = 0;
            integer ek;
            for (ek = 0; ek < ERR_LOG_SLOTS; ek++)
            {
                string e = llLinksetDataRead(
                    P + "err" + (string)((en + ek) % ERR_LOG_SLOTS));
                if (e != "")
                {
                    llOwnerSay("Debug error: " + e);
                    shown = shown + 1;
                }
            }
            if (shown == 0)
                llOwnerSay("Debug errors: none recorded.");
            llMessageLinked(LINK_SET, LM_MEM_ASK, "", "");
            return;
        }

        if (msg == "Debug Log")
        {

            if (llLinksetDataRead(P + "dlog") == "1")
            {
                llLinksetDataWrite(P + "dlog", "");
                llOwnerSay("Debug Log OFF.");
            }
            else
            {
                llLinksetDataWrite(P + "dlog", "1");
                llOwnerSay("Debug Log ON - boot numbers, memory " +
                    "snapshots and valve events are recorded. " +
                    "Diagnostics > Dump Log prints the story.");
            }
            showDebugMenu();
            return;
        }
        if (msg == "Dump Log")
        {
            dumpDbg();
            return;
        }
        if (msg == "Wipe")
        {
            llDialog(llGetOwner(), "Erase ALL saved settings and the watch list from this HUD?",
                ["Confirm Wipe", "Cancel"], gChannel);
            return;
        }
        if (msg == "Confirm Wipe")
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "WIPE", "");
            return;
        }
        if (msg == "Cancel" || msg == "Back")
        {

            if (gMenu == 5)
            {
                if (gWelcome)
                    showWelcomeMenu();
                else
                    showAreaMenu();
            }
            else if (gMenu == 2 || gMenu == 7)
                showSettingsMenu();
            else
                showMainMenu();
            return;
        }
        if (msg == "Radius")
        {

            showRadiusMenu();
            return;
        }
        if (msg == "Region")
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "SCOPE|0", "");
            if (gWelcome)
                finishSetup();
            return;
        }
        if (msg == "Parcel")
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "SCOPE|2", "");
            if (gWelcome)
                finishSetup();
            return;
        }
        if (msg == "10m" || msg == "25m" || msg == "50m" || msg == "100m")
        {

            llMessageLinked(LINK_SET, LM_UI_CMD, "SCOPE|1", "");
            llMessageLinked(LINK_SET, LM_UI_CMD,
                "RANGE|" + llGetSubString(msg, 0, llStringLength(msg) - 2), "");
            if (gWelcome)
                finishSetup();
            return;
        }
        if (msg == "Custom")
        {

            gMode = 2;
            gModeExpiry = llGetUnixTime() + MENU_TIMEOUT;
            llTextBox(llGetOwner(),
                "Type the radius in meters (5-256), then click Submit:",
                gChannel);
            return;
        }

        integer num = (integer)msg;
        if (num > 0 && (string)num == msg && gMenu == 4 &&
            num <= llGetListLength(gWatch))
        {
            gMenu = 0;
            llMessageLinked(LINK_SET, LM_UI_CMD, "REM|" + (string)num, "");
            showRemoveMenu();
            return;
        }
    }

// text valve input, UI_STATE mirror, debug replies
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == LM_MENU_OPEN)
        {
            showMainMenu();
            return;
        }

        if (num == LM_UI_STATE)
        {
            list f = llParseString2List(str, ["|"], []);
            gEnabled = (llList2String(f, 0) == "1");
            gScope = llList2Integer(f, 1);
            gRange = llList2Integer(f, 2);

            return;
        }

        if (num == LM_WATCH_LIST)
        {
            if (str == "")
                gWatch = [];
            else
                gWatch = llParseString2List(str, [","], []);
            return;
        }

        if (num == LM_SAY)
        {
            handleSay(str, id);
            return;
        }

        if (num == LM_MEM_ASK)
        {

            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Companion Script|" + (string)llGetFreeMemory() +
                "|" + BUILD_NUM, "");
            return;
        }

        if (num == LM_MEM_TELL)
        {

            list f = llParseString2List(str, ["|"], []);
            string mline = "Debug: " + llList2String(f, 0) + " - " +
                memPct((integer)llList2String(f, 1));
            string bld = llList2String(f, 2);
            if (bld != "")
                mline = mline + " | Build:" + bld;
            llOwnerSay(mline);

            if (llList2String(f, 0) == "Core Script")
            {
                string cg = llLinksetDataRead(P + "coregap");
                if (cg != "")
                {
                    list gf = llParseString2List(cg, ["|"], []);
                    llOwnerSay("Debug: Core made no pass for " +
                        gapText((integer)llList2String(gf, 0)) +
                        ", ending " + sltFromUnix((integer)llList2String(gf, 1)) +
                        " SLT - the HUD was frozen, detached or logged out.");
                }
            }

            if (llList2String(f, 0) == "Data Script")
            {
                string sv = llLinksetDataRead(P + "starve");
                if (sv != "")
                {
                    list sf = llParseString2List(sv, ["|"], []);
                    if (llGetListLength(sf) == 3)
                        llOwnerSay("Debug: sim starved the HUD " +
                            llList2String(sf, 0) + " time(s) while worn, longest " +
                            llList2String(sf, 1) + "s, last at " +
                            sltFromUnix(llList2Integer(sf, 2)) +
                            " SLT - the short-freeze pattern (Trace shows them live).");
                }
            }
            return;
        }

        if (num != LM_LANG_ASK)
            return;

        if (str == "ping")
            llMessageLinked(LINK_SET, LM_LANG_TELL, "ping=ok", "");
    }
}
