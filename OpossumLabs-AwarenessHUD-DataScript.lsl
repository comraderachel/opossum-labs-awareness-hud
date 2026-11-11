// Opossum Labs Awareness HUD v1.0 - Data Script
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
// This script is the detection engine: a 2 s sweep loop that diffs the
// region against what it already knows and hands every account
// lookup to the Registrar. It never touches the dataserver.

// ---------- constants and globals ----------
integer LM_SAY = 19027;
integer LM_UI_STATE = 19029;
integer LM_UI_CMD = 19030;
integer LM_WATCH_LIST = 19031;
integer LM_DATA_ASK = 19032;
integer LM_DATA_TELL = 19033;
integer LM_SWEEP_ASK = 19034;
integer LM_EVENT = 19035;
integer LM_MEM_ASK = 19036;

integer LM_MEM_TELL = 19037;

string P = "SMH.";
string BUILD_NUM = "110226081";

integer ERR_LOG_SLOTS = 10;

integer DBG_SLOTS = 24;

integer SWEEP_INTERVAL = 2;

integer POP_CAP = 60;
integer CAP_FLOOR = 10;

string memPct(integer freeBytes)
{

    return (string)freeBytes + " free (" +
        (string)((100 * (65536 - freeBytes)) / 65536) + "% used)";
}

// ---------- functions ----------
logErr(string text)
{

    integer i = (integer)llLinksetDataRead(P + "errNext");
    if (i < 0 || i >= ERR_LOG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);

    ts = llDumpList2String([llGetSubString(ts, 0, 9), " ",
        llGetSubString(ts, 11, -1)], "");
    llLinksetDataWrite(P + "err" + (string)i, ts + "|Data|" + text);
    i = i + 1;
    if (i >= ERR_LOG_SLOTS)
        i = 0;
    llLinksetDataWrite(P + "errNext", (string)i);
}

dbgLog(string tag, string fields)
{

    if (llLinksetDataRead(P + "dlog") != "1")
        return;
    integer i = (integer)llLinksetDataRead(P + "dbgNext");
    if (i < 0 || i >= DBG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);
    ts = llDumpList2String([llGetSubString(ts, 0, 9), " ",
        llGetSubString(ts, 11, -1)], "");
    llLinksetDataWrite(P + "dbg" + (string)i,
        ts + "|Data|" + tag + "|" + fields);
    i = i + 1;
    if (i >= DBG_SLOTS)
        i = 0;
    llLinksetDataWrite(P + "dbgNext", (string)i);
}

string nameUri(key id)
{

    return "secondlife:///app/agent/" + (string)id + "/displayname";
}

integer gHaveState;
integer gEnabled = TRUE;
integer gScope = 2;
integer gRange = 25;
list gWatch;

string gKnownPad;

integer gBaselined;
key gParcelId;
string gBaseRegion;

list gWatchedIn;
integer gWatchBase;
integer gWatchAnnounce;

integer gCapNoted;
integer gCapCrowd;

integer gWideTick;

integer gBootFree;

string NUDGE_CSV = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
string NUDGE_MINI = "1,1,1,1,1,1,1,1,1,1";

integer gMemNoted;

integer gMemProbe;
integer gHb = 0;

integer gSweepSec;

integer gSweepTick;

integer gWearT;

integer gCap;

integer gPrevCap;

integer gCapPub = -1;

float DILATION_LOW = 0.50;
float DILATION_OK  = 0.90;

integer gDilLow;

integer gCensusOnAdopt;

string gAdoptWhy = "";

list scopeAgentsFrom(list agents, integer max)
{

    integer n = llGetListLength(agents);
    if (n > max)
        n = max;
    integer i;

    if (gScope == 1)
    {

        vector here = llGetPos();
        list rad;
        for (i = 0; i < n; i++)
        {
            key a = llList2Key(agents, i);
            if (a != llGetOwner() && a != NULL_KEY)
            {
                vector p = llList2Vector(llGetObjectDetails(a, [OBJECT_POS]), 0);

                if (p != ZERO_VECTOR && llVecDist(here, p) <= (float)gRange)
                    rad += [a];
            }
        }
        return rad;
    }

    if (gScope == 2)
    {
        key myParcel = llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_ID]), 0);
        list par;
        for (i = 0; i < n; i++)
        {
            key a = llList2Key(agents, i);
            if (a != llGetOwner() && a != NULL_KEY)
            {
                vector p = llList2Vector(llGetObjectDetails(a, [OBJECT_POS]), 0);

                if (p != ZERO_VECTOR &&
                    llList2Key(llGetParcelDetails(p, [PARCEL_DETAILS_ID]), 0) == myParcel)
                    par += [a];
            }
        }
        return par;
    }

    list out;
    for (i = 0; i < n; i++)
    {
        key a = llList2Key(agents, i);
        if (a != llGetOwner() && a != NULL_KEY)
            out += [a];
    }
    return out;
}

list watchedInRegion(list regionAgents)
{

    list out;
    integer i;
    for (i = 0; i < llGetListLength(gWatch); i++)
    {
        key w = llList2Key(gWatch, i);
        if (llListFindList(regionAgents, [w]) != -1)
            out += [w];
    }
    return out;
}

string knownCsv(list agents)
{

    if (llGetListLength(agents) == 0)
        return "";
    return "," + llDumpList2String(agents, ",") + ",";
}

integer knownHas(string pad, key a)
{

    if (pad == "")
        return FALSE;
    return (llSubStringIndex(pad, "," + (string)a + ",") != -1);
}

// region jump or rebase: drop old-region state
travelReset(string why)
{

    gKnownPad = "";

    gBaselined = FALSE;
    gCap = POP_CAP;
    gCapCrowd = FALSE;
    gWatchedIn = [];
    gWatchBase = FALSE;
    gCensusOnAdopt = TRUE;
    gAdoptWhy = why;
    gWatchAnnounce = TRUE;
    gDilLow = FALSE;

    gMemNoted = FALSE;

    gMemProbe = 0;

    llMessageLinked(LINK_SET, LM_SWEEP_ASK, "RESET", "");
    gBaseRegion = llGetRegionName();

}

// the 2 s detection pass: region list -> scope filter -> watch diff
// -> arrival diff. Scope filter and tracking cap follow the settings
// mirror broadcast by the Core Script.
sweep()
{

    if (!gHaveState || !gEnabled)
        return;

    if (gBaselined && llGetRegionName() != gBaseRegion)
        travelReset("region");

    integer livePop = llGetRegionAgentCount();

    integer rung = gCap;
    if (livePop > 70 && rung > 20)
        rung = 20;
    else if (livePop > 40 && rung > 35)
        rung = 35;

    integer freeNow = llGetFreeMemory();

    integer scopeN = rung;
    if (scopeN > livePop)
        scopeN = livePop;
    integer passNeed = (livePop + scopeN) * 102 + 2000;
    while (passNeed > freeNow && rung > CAP_FLOOR)
    {
        if (rung > 35)
            rung = 35;
        else if (rung > 20)
            rung = 20;
        else
            rung = CAP_FLOOR;
        scopeN = rung;
        if (scopeN > livePop)
            scopeN = livePop;
        passNeed = (livePop + scopeN) * 102 + 2000;
    }

    if (rung < gCap)
    {
        gCap = rung;
        gCapNoted = FALSE;
        gCapCrowd = FALSE;

    }
    if (passNeed > freeNow)
    {
        if (!gMemNoted)
        {
            gMemNoted = TRUE;
            gMemProbe = 0;
            logErr("memory valve: detection paused at " +
                (string)llGetFreeMemory() + " free");

            dbgLog("TRIP", "free=" + (string)freeNow +
                "|pop=" + (string)livePop +
                "|need=" + (string)passNeed);
// honest degradation: the cap ladder narrows, sweeps slow to 10 s
            llMessageLinked(LINK_SET, LM_SAY, "N|MEMPAUSE", "");

            gCap = CAP_FLOOR;
            gCapNoted = FALSE;

            gCapCrowd = FALSE;

            gBaselined = FALSE;

            gKnownPad = "";
            return;
        }
        gMemProbe = gMemProbe + 1;
        if (gMemProbe < 15)
            return;
        gMemProbe = 0;

        integer nfPre = llGetFreeMemory();
        if (nfPre > 2600)
        {
            list junk = llCSV2List(NUDGE_CSV);
            junk = llCSV2List(NUDGE_CSV);
            junk = llCSV2List(NUDGE_CSV);
        }
        else if (nfPre > 500)
        {

            list junk = llCSV2List(NUDGE_MINI);
            junk = llCSV2List(NUDGE_MINI);
            junk = llCSV2List(NUDGE_MINI);
        }
        integer pn = llGetRegionAgentCount();
        integer pc = gCap;
        if (pc > pn)
            pc = pn;
        integer pfit = (pn + pc) * 102 + 2000;
        if (llGetFreeMemory() <= pfit)
        {
            dbgLog("PROBE", "pre=" + (string)nfPre +
                "|post=" + (string)llGetFreeMemory() +
                "|pop=" + (string)pn +
                "|need=" + (string)pfit + "|paused");
            return;
        }
        dbgLog("PROBE", "pre=" + (string)nfPre +
            "|post=" + (string)llGetFreeMemory() +
            "|pop=" + (string)pn +
            "|need=" + (string)pfit + "|resumed");

    }
    if (gMemNoted)
    {

        integer rn = llGetRegionAgentCount();
        integer rw = POP_CAP;
        if (rw > rn)
            rw = rn;
        if (llGetFreeMemory() > (rn + rw) * 102 + 2000)
        {
        gMemNoted = FALSE;

        gCap = POP_CAP;
        gBaselined = FALSE;
        gCapNoted = FALSE;
        gCapCrowd = FALSE;
        }
    }

    if (!gMemNoted && !gCapCrowd && gCap < POP_CAP)
    {

        integer wideN = POP_CAP;
        if (wideN > livePop)
            wideN = livePop;
        if (llGetFreeMemory() > (livePop + wideN) * 102 + 2000)
        {
            gWideTick = gWideTick + 1;
            if (gWideTick >= 15)
            {
                gWideTick = 0;
                gCap = POP_CAP;
                gCapCrowd = FALSE;
                gBaselined = FALSE;
                gCapNoted = FALSE;
            }
        }
        else
            gWideTick = 0;
    }
    else
        gWideTick = 0;

    list regionAgents = llGetAgentList(AGENT_LIST_REGION, []);

    if (llGetAttached() != 0 && llGetListLength(regionAgents) == 0)
        return;

    integer n = llGetListLength(regionAgents);

    if (n > 70 && gCap > 20)
    {
        gCap = 20;
        gCapNoted = FALSE;
        gCapCrowd = TRUE;
    }
    else if (n > 40 && gCap > 35)
    {
        gCap = 35;
        gCapNoted = FALSE;
        gCapCrowd = TRUE;
    }
    if (gCap != gPrevCap && gBaselined)
        gBaselined = FALSE;
    if (n > gCap && !gCapNoted)
    {

        gCapNoted = TRUE;

        llMessageLinked(LINK_SET, LM_SAY,
            "N|BUSY|" + (string)n + "|" + (string)gCap + "|" +
            (string)gCapCrowd, "");
    }

    if (gCap != gCapPub)
    {
        gCapPub = gCap;
        llLinksetDataWrite(P + "cap", (string)gCap);
    }

    if (gScope == 2)
    {
        key pk = llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_ID]), 0);
        if (pk != gParcelId)
        {
            gParcelId = pk;
            gBaselined = FALSE;
            gCensusOnAdopt = TRUE;
            gAdoptWhy = "parcel";
        }
    }

    list scopeAgents = scopeAgentsFrom(regionAgents, gCap);

    if (!gWatchBase)
    {
        gWatchedIn = watchedInRegion(regionAgents);
        gWatchBase = TRUE;
        if (gWatchAnnounce)
        {

            gWatchAnnounce = FALSE;
            integer wi;
            for (wi = 0; wi < llGetListLength(gWatchedIn); wi++)
                llMessageLinked(LINK_SET, LM_EVENT,
                    "WFOUND|" + nameUri(llList2Key(gWatchedIn, wi)) + "|" +
                        llList2String(gWatchedIn, wi), "");
        }
    }
    else
    {
        integer i;
        for (i = 0; i < llGetListLength(gWatch); i++)
        {
            key w = llList2Key(gWatch, i);
            integer inNow = (llListFindList(regionAgents, [w]) != -1);
            integer wi = llListFindList(gWatchedIn, [w]);
            integer wasIn = (wi != -1);
            if (inNow && !wasIn)
            {
                gWatchedIn += [w];

                if (!gBaselined ||
                    llListFindList(scopeAgents, [w]) == -1 ||
                    knownHas(gKnownPad, w))
                    llMessageLinked(LINK_SET, LM_EVENT,
                        "WIN|" + nameUri(w) + "|" + (string)w, "");
            }
            else if (!inNow && wasIn)
            {
                gWatchedIn = llDeleteSubList(gWatchedIn, wi, wi);

                if (!knownHas(gKnownPad, w))
                    llMessageLinked(LINK_SET, LM_EVENT,
                        "WOUT|" + nameUri(w), "");
            }
        }
    }

    regionAgents = [];

    if (!gBaselined)
    {
        gKnownPad = knownCsv(scopeAgents);
        gBaselined = TRUE;
        gBaseRegion = llGetRegionName();

        gPrevCap = gCap;
        if (gCensusOnAdopt)
        {

            gCensusOnAdopt = FALSE;

            if (gAdoptWhy == "region" || gAdoptWhy == "parcel")
                llOwnerSay("New " + gAdoptWhy +
                    " detected - counting who is here now. The power button " +
                    "blinks while the HUD fetches account data; a summary follows.");
            gAdoptWhy = "";
            llMessageLinked(LINK_SET, LM_SWEEP_ASK, "CENSUS|A", "");
        }
        return;
    }

    integer k;
    for (k = 0; k < llGetListLength(scopeAgents); k++)
    {
        key a = llList2Key(scopeAgents, k);
        if (!knownHas(gKnownPad, a))

            llMessageLinked(LINK_SET, LM_SWEEP_ASK,
// hand the lookup to the Registrar: memory lives there
                "LOOK|" + (string)a, "");
    }

    integer tlen = llStringLength(gKnownPad);
    for (k = 1; k + 35 < tlen; k += 37)
    {
        key a = (key)llGetSubString(gKnownPad, k, k + 35);
        if (llListFindList(scopeAgents, [a]) == -1)
        {

            llMessageLinked(LINK_SET, LM_EVENT, "OUT|" + (string)a + "|" +
                nameUri(a), "");
        }
    }
    gKnownPad = knownCsv(scopeAgents);
}

// re-adopt the scope silently after a settings change
rebaseData()
{

    gCensusOnAdopt = FALSE;
    gAdoptWhy = "";
    gWatchAnnounce = FALSE;
    gCap = POP_CAP;
    gCapCrowd = FALSE;

    list regionAgents = llGetAgentList(AGENT_LIST_REGION, []);
    if (llGetAttached() != 0 && llGetListLength(regionAgents) == 0)
    {

        gBaselined = FALSE;
        return;
    }
    gKnownPad = knownCsv(scopeAgentsFrom(regionAgents, gCap));
    gBaselined = TRUE;
    gBaseRegion = llGetRegionName();
    gPrevCap = gCap;
}

// ---------- events ----------
default
{
// boot: load mirrors, start the 2 s timer
    state_entry()
    {
        gSweepSec = SWEEP_INTERVAL;
        llSetTimerEvent(gSweepSec);

        gCap = POP_CAP;
        gCapCrowd = FALSE;
        gPrevCap = POP_CAP;
        gCensusOnAdopt = TRUE;
        gWatchAnnounce = TRUE;

        llLinksetDataDelete(P + "gap");

        llLinksetDataDelete(P + "starve");

        gKnownPad = "";

        llMessageLinked(LINK_SET, LM_DATA_TELL, "ping=ok", "");

        llMessageLinked(LINK_SET, LM_UI_CMD, "SYNC", "");

        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");

    gBootFree = llGetFreeMemory();
    llOwnerSay("Data Script ready (Build " + BUILD_NUM +
        "). Memory: " + memPct(gBootFree));

    dbgLog("BOOT", "free=" + (string)gBootFree);
    }

// owner change resets; region jump rebases
    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
        if (change & (CHANGED_REGION | CHANGED_TELEPORT))
        {

            if (gBaselined && llGetRegionName() == gBaseRegion)
            {
                if (gScope == 1 && (change & CHANGED_TELEPORT))
                    gBaselined = FALSE;
                return;
            }
            travelReset("region");
        }
    }

// detach stops detection
    attach(key avatar)
    {

        if (avatar != NULL_KEY)
        {
            gWearT = llGetUnixTime();
            travelReset("rewear");
        }
    }

// sweep, dilation watch, heartbeat, gap diagnostics
    timer()
    {

        integer now = llGetUnixTime();
        integer prevHb = gHb;

        if (gHb != 0 && now - gHb > 300)
        {
            llLinksetDataWrite(P + "gap", (string)(now - gHb) + "|" + (string)now);

            dbgLog("GAP", "dead=" + (string)(now - gHb) + "s");

            if (gEnabled && gHaveState)
            {
                integer gmin = (now - gHb) / 60;
                if (gmin < 1)
                    gmin = 1;
                llOwnerSay("Detection resumed after about " + (string)gmin +
                    " minute(s) - the HUD is ON and a region summary follows.");
                llMessageLinked(LINK_SET, LM_SWEEP_ASK, "CENSUS|A", "");
            }
        }
        gHb = now;

        llLinksetDataWrite(P + "hb", (string)now);

        if (prevHb != 0 && prevHb >= gWearT && now - prevHb >= 15)
        {

            list sf = llParseString2List(llLinksetDataRead(P + "starve"), ["|"], []);
            integer sc = 1;
            integer sl = now - prevHb;
            if (llGetListLength(sf) == 3)
            {
                sc = llList2Integer(sf, 0) + 1;
                if (llList2Integer(sf, 1) > sl)
                    sl = llList2Integer(sf, 1);
            }
            llLinksetDataWrite(P + "starve", (string)sc + "|" + (string)sl + "|" + (string)now);
        }

        if (prevHb != 0 && prevHb >= gWearT && now - prevHb >= 60 &&
            now - prevHb < 300)
            llMessageLinked(LINK_SET, LM_SAY,
                "N|PAUSE|" + (string)(now - prevHb), "");
        if (prevHb != 0 && prevHb >= gWearT && now - prevHb > gSweepSec * 3)
        {
            if (gSweepSec == SWEEP_INTERVAL)
            {
                gSweepSec = 10;
                gSweepTick = 0;
                llSetTimerEvent(10);
            }
        }
        else if (gSweepSec != SWEEP_INTERVAL)
        {
            gSweepTick = gSweepTick + 1;
            if (gSweepTick >= 10)
            {
                gSweepSec = SWEEP_INTERVAL;
                llSetTimerEvent(SWEEP_INTERVAL);
            }
        }
        else
            gSweepTick = 0;

        if (gHaveState && gEnabled)
        {
// sim speed watch: one line down, one line back
            float dil = llGetRegionTimeDilation();
            integer pct = (integer)(dil * 100);
            if (!gDilLow && dil < DILATION_LOW)
            {
                gDilLow = TRUE;
                llMessageLinked(LINK_SET, LM_SAY, "D|low|" + (string)pct, "");
            }
            else if (gDilLow && dil >= DILATION_OK)
            {
                gDilLow = FALSE;
                llMessageLinked(LINK_SET, LM_SAY, "D|ok|" + (string)pct, "");
            }
        }

        sweep();
    }

// UI_STATE mirror updates, REBASE, ping handshake, debug replies
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == LM_DATA_ASK)
        {

            if (str == "ping")
                llMessageLinked(LINK_SET, LM_DATA_TELL, "ping=ok", "");
            return;
        }

        if (num == LM_MEM_ASK)
        {

            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Data Script|" + (string)llGetFreeMemory() + "|" +
                BUILD_NUM, "");

            string gap = llLinksetDataRead(P + "gap");
            if (gap != "")
            {
                list gf = llParseString2List(gap, ["|"], []);
                llMessageLinked(LINK_SET, LM_SAY, "N|GAP|" +
                    llList2String(gf, 0) + "|" + llList2String(gf, 1), "");
            }
            return;
        }

        if (num == LM_SWEEP_ASK)
        {

            if (str == "REBASE")
                rebaseData();
            return;
        }

        if (num == LM_UI_STATE)
        {
            list f = llParseString2List(str, ["|"], []);
            gEnabled = (llList2String(f, 0) == "1");
            gScope = llList2Integer(f, 1);
            gRange = llList2Integer(f, 2);
            gHaveState = TRUE;
            return;
        }

        if (num == LM_WATCH_LIST)
        {
            if (str == "")
                gWatch = [];
            else
                gWatch = llParseString2List(str, [","], []);

            integer i;
            for (i = llGetListLength(gWatchedIn) - 1; i >= 0; i--)
            {

                if (llListFindList(gWatch,
                    [llList2String(gWatchedIn, i)]) == -1)
                    gWatchedIn = llDeleteSubList(gWatchedIn, i, i);
            }

            if (gWatchBase)
            {
                list regionAgents = llGetAgentList(AGENT_LIST_REGION, []);
                for (i = 0; i < llGetListLength(gWatch); i++)
                {
                    key w = llList2Key(gWatch, i);
                    if (llListFindList(regionAgents, [w]) != -1 &&
                        llListFindList(gWatchedIn, [w]) == -1)
                        gWatchedIn += [w];
                }
            }
            return;
        }
    }
}
