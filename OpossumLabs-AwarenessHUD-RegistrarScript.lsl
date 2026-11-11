// Opossum Labs Awareness HUD v1.0 - Registrar Script
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
// This script owns every account-data fetch: arrival lookups, List All,
// the census, and the Watch+ picker. Its memory guards are priced
// against live population, and a quiescent self-heal reset keeps
// boot memory available.

// ---------- constants and globals ----------
string P = "SMH.";

string MSG_OFF_STANDBY = "The detector is off - click the power button to turn it back on.";
string BUILD_NUM = "110626085";

integer LM_SAY = 19027;
integer LM_MENU_OPEN = 19028;

integer LM_UI_STATE = 19029;
integer LM_UI_CMD = 19030;

integer LM_WATCH_LIST = 19031;

integer LM_DATA_TELL = 19033;

integer LM_SWEEP_ASK = 19034;
integer LM_EVENT = 19035;
integer LM_MEM_ASK = 19036;
integer LM_MEM_TELL = 19037;

integer SCAN_LIST_CAP = 20;

integer SCAN_BATCH = 3;

integer MAX_PENDING_REQUESTS = 30;

integer PENDING_TIMEOUT = 15;
integer STALE_DROP = 120;

integer CENSUS_ASK_MAX = 24;

integer CENSUS_LIST_CAP = 60;

integer ERR_LOG_SLOTS = 10;

integer DBG_SLOTS = 8;

integer SCOPE_FETCH_CAP = 100;

string NUDGE_CSV = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
string NUDGE_MINI = "1,1,1,1,1,1,1,1,1,1";

integer gScope;
integer gRange;
integer gEnabled;
integer gHaveState;
list gWatch;

list gPending;

list gRequests;

list gLangCache;
list gScanQueue;
integer gScanNext;
integer gScanLeft;
integer gScanCount;
integer gPumping;
integer gBootFree;

string gScanOut = "";
integer gScanLines = 0;

integer gCensusTotal;
integer gCensusLeft;
integer gCensusNew;
integer gCensusBots;
integer gCensusWatched;
integer gCensusDeadline;
integer gCensusMore;

string gCensusSrc = "A";

list gPickKeys;

integer gPickDue = 0;

integer PICK_LINGER = 120;

integer gChannel = -1;

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
    llLinksetDataWrite(P + "err" + (string)i, ts + "|Registrar|" + text);
    i = i + 1;
    if (i >= ERR_LOG_SLOTS)
        i = 0;
    llLinksetDataWrite(P + "errNext", (string)i);
}

dbgLog(string tag, string fields)
{

    if (llLinksetDataRead(P + "dlog") != "1")
        return;
    integer i = (integer)llLinksetDataRead(P + "rdbgNext");
    if (i < 0 || i >= DBG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);
    ts = llDumpList2String([llGetSubString(ts, 0, 9), " ",
        llGetSubString(ts, 11, -1)], "");
    llLinksetDataWrite(P + "rdbg" + (string)i,
        ts + "|Registrar|" + tag + "|" + fields);
    i = i + 1;
    if (i >= DBG_SLOTS)
        i = 0;
    llLinksetDataWrite(P + "rdbgNext", (string)i);
}

string nameUri(key id)
{

    return "secondlife:///app/agent/" + (string)id + "/displayname";
}

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

string pickName(key k)
{

    string n = llGetDisplayName(k);
    if (n == "")
        n = llKey2Name(k);
    if (n == "")
        return "Unknown Avatar";
    string full = n;
    while (strBytes(n) > 20)
        n = llDeleteSubString(n, -1, -1);
    if (n != full)
        n = n + "~";
    return n;
}

// force Mono's lazy GC so free-memory readings are honest
gcNudge()
{

    integer nf = llGetFreeMemory();
    if (nf > 2600)
    {
        list junk = llCSV2List(NUDGE_CSV);
        junk = llCSV2List(NUDGE_CSV);
        junk = llCSV2List(NUDGE_CSV);
    }
    else if (nf > 500)
    {
        list junk = llCSV2List(NUDGE_MINI);
        junk = llCSV2List(NUDGE_MINI);
        junk = llCSV2List(NUDGE_MINI);
    }
}

integer findAgentIndex(list data, key agent)
{
    integer i;
    for (i = 0; i < llGetListLength(data); i += 6)
    {
        if (llList2Key(data, i) == agent)
            return i;
    }
    return -1;
}

integer findRequestIndex(key requestId)
{
    integer i;
    for (i = 0; i < llGetListLength(gRequests); i += 3)
    {
        if (llList2Key(gRequests, i) == requestId)
            return i;
    }
    return -1;
}

integer calculateAgeFromBornDate(string bornDate)
{

    integer year = (integer)llGetSubString(bornDate, 0, 3);
    integer month = (integer)llGetSubString(bornDate, 5, 6);
    integer day = (integer)llGetSubString(bornDate, 8, 9);

    string currentDate = llGetDate();
    integer currentYear = (integer)llGetSubString(currentDate, 0, 3);
    integer currentMonth = (integer)llGetSubString(currentDate, 5, 6);
    integer currentDay = (integer)llGetSubString(currentDate, 8, 9);

    integer age = (currentYear - year) * 365 +
        (currentMonth - month) * 30 + (currentDay - day);
    if (age < 0)
    {

        logErr("born date " + bornDate + " parsed as a negative age (" +
            (string)age + "d) - clamped to 0d");
        return 0;
    }
    return age;
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

    if (llListFindList(gWatch, [(string)id]) != -1)
        f += 8;
    return f;
}

string scopeLabel()
{
    if (gScope == 1)
        return (string)gRange + "m radius";
    if (gScope == 2)
        return "parcel";
    return "region";
}

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

// one pipeline row: born and pay lookups, plus language
askAgent(key agent, string kind)
{

    integer idx = findAgentIndex(gPending, agent);
    if (idx != -1)
    {

        if (kind == "S" && llList2String(gPending, idx + 4) == "A")
            gPending = llListReplaceList(gPending, ["S"], idx + 4, idx + 4);
        return;
    }

    integer rowCap = (llGetFreeMemory() - 4500) / 160;
    if (rowCap > 36)
        rowCap = 36;
    if (rowCap < 8)
        rowCap = 8;
    if (llGetListLength(gPending) >= rowCap * 6)
    {
        gPending += [agent, -1, "", "", kind, llGetUnixTime()];
        sendEntry(llGetListLength(gPending) - 6);
        integer oi = findAgentIndex(gPending, agent);
        if (oi != -1)
            gPending = llDeleteSubList(gPending, oi, oi + 5);
        return;
    }

    string lang = llGetAgentLanguage(agent);
    if (lang != "")
    {
        integer ci = llListFindList(gLangCache, [lang]);
        if (ci != -1)
            lang = llList2String(gLangCache, ci + 1);
        else
        {
            string m = llLinksetDataRead(P + "langmap");
            string pat = "|" + lang + "|";
            integer mi = llSubStringIndex(m, pat);
            if (m != "" && mi != -1)
            {
                integer ns = mi + llStringLength(pat);
                string win = llGetSubString(m, ns, ns + 29);
                integer j = llSubStringIndex(win, "|");
                if (j > 0)
                {
                    string full = llGetSubString(win, 0, j - 1);
                    if (llGetListLength(gLangCache) > 40)
                        gLangCache = [];
                    gLangCache += [lang, full];
                    lang = full;
                }
            }

        }
    }
    gPending += [agent, -1, "", lang, kind, llGetUnixTime()];

    if (llGetListLength(gRequests) >= MAX_PENDING_REQUESTS * 3)
        return;

    gRequests += [llRequestAgentData(agent, DATA_BORN), agent, "B"];
    gRequests += [llRequestAgentData(agent, DATA_PAYINFO), agent, "P"];
}

// row kinds: A arrival -> Core, S listing buffer, X census counters
sendEntry(integer idx)
{

    key agent = llList2Key(gPending, idx);
    string kind = llList2String(gPending, idx + 4);
    integer age = llList2Integer(gPending, idx + 1);
    string pay = llList2String(gPending, idx + 2);
    string lang = llList2String(gPending, idx + 3);

    if (kind == "S")
    {

        integer dist = -1;
        vector pos = llList2Vector(llGetObjectDetails(agent, [OBJECT_POS]), 0);
        if (pos != ZERO_VECTOR)
            dist = (integer)llVecDist(llGetPos(), pos);

        gScanOut += entryText(nameUri(agent), (string)age, pay, lang,
            (string)entryFlags(agent, age, pay), dist) + "\n";
        gScanLines = gScanLines + 1;
// flush at 10 lines or 900 bytes (llOwnerSay caps at 1024)
        if (gScanLines % 10 == 0 || strBytes(gScanOut) > 900)
        {
            llOwnerSay(gScanOut);
            gScanOut = "";
        }
        gScanLeft = gScanLeft - 1;
        gScanCount = gScanCount - 1;
        if (gScanLeft <= 0 && gScanNext < llGetListLength(gScanQueue))
            pumpScan();
        if (gScanCount <= 0)
        {
            if (gScanOut != "")
            {
                llOwnerSay(gScanOut);
                gScanOut = "";
            }
            gScanLines = 0;
            llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
            resetScan();

        }
        return;
    }

    llMessageLinked(LINK_SET, LM_DATA_TELL,
        "0|" + (string)agent + "|" + nameUri(agent) + "|" +
        (string)age + "|" + pay + "|" + lang, "");
}

checkPending(integer idx)
{
    if (llList2Integer(gPending, idx + 1) == -1 ||
        llList2String(gPending, idx + 2) == "")
        return;
    sendEntry(idx);
    gPending = llDeleteSubList(gPending, idx, idx + 5);
}

resetScan()
{
    if (gScanCount > 0)
    {

        dbgLog("RABORT", "left=" + (string)gScanCount);
        if (gScanOut != "")
        {
            llOwnerSay(gScanOut);
            gScanOut = "";
        }
        gScanLines = 0;
        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
    }
    gScanQueue = [];
    gScanNext = 0;
    gScanLeft = 0;
    gScanCount = 0;
}

clearPipeline()
{

    if (gCensusTotal > 0)
        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
    gPending = [];
    gRequests = [];
    gCensusTotal = 0;
    gCensusLeft = 0;
    gCensusNew = 0;
    gCensusBots = 0;
    gCensusWatched = 0;
    gCensusMore = 0;
}

purgeCensusRows()
{

    integer r;
    for (r = llGetListLength(gRequests) - 3; r >= 0; r -= 3)
    {
        if (llList2String(gRequests, r + 2) == "X")
            gRequests = llDeleteSubList(gRequests, r, r + 2);
    }
}

// capped waves: never hold the whole region in the heap
pumpScan()
{

    if (gPumping)
        return;
    gPumping = TRUE;
    integer n = llGetListLength(gScanQueue);
    integer started = 0;
    while (gScanNext < n && started < SCAN_BATCH && gScanCount > 0)
    {
        key rk = llList2Key(gScanQueue, gScanNext);
        gScanNext = gScanNext + 1;
        started = started + 1;
        gScanLeft = gScanLeft + 1;
        askAgent(rk, "S");
    }
    gPumping = FALSE;
}

// List All: guard, top 20 in scope, wave pipeline
startScan()
{

    if (gHaveState && !gEnabled)
    {
        llOwnerSay(MSG_OFF_STANDBY);
        return;
    }
    if (gScanCount > 0)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SCANBUSY", "");
        return;
    }

    gcNudge();
// honest guard: a listing's cost scales with live population
    integer sfl = llGetRegionAgentCount() * 102 + 3500;
    if (llGetFreeMemory() < sfl)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SCANMEM", "");
        dbgLog("RREFUSE", "scan|free=" + (string)llGetFreeMemory() +
            "|guard=" + (string)sfl);
        return;
    }

    list agents = scopeAgentsFrom(llGetAgentList(AGENT_LIST_REGION, []),
        SCOPE_FETCH_CAP);
    integer n = llGetListLength(agents);
    if (n == 0)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SCANEMPTY|" + scopeLabel(), "");
        return;
    }
    if (n > SCAN_LIST_CAP)
    {
        agents = llList2List(agents, 0, SCAN_LIST_CAP - 1);
        n = SCAN_LIST_CAP;
    }

    integer capCtx = (integer)llLinksetDataRead(P + "cap");
    if (capCtx > 0 && n > capCtx)
        llOwnerSay("(" + (string)llGetRegionAgentCount() +
            " avatars in the region - detection is tracking the first " +
            (string)capCtx + " for alerts.)");
    llOwnerSay("=== AVATARS IN " + llToUpper(scopeLabel()) +
        " (" + (string)n + ") ===");
    llOwnerSay("Fetching account data - the power button blinks until the list is ready.");
    llMessageLinked(LINK_SET, LM_EVENT, "BUSY|1", "");
    gScanQueue = agents;
    gScanNext = 0;
    gScanCount = n;
    pumpScan();
}

// one summary line; born-date asks budgeted against free memory
startCensus(list agents, string src)
{

    llMessageLinked(LINK_SET, LM_EVENT, "BUSY|1", "");

    purgeCensusRows();

    gCensusMore = 0;
    integer fit = (llGetFreeMemory() - 2500) / 156;
    if (fit < 1)
        fit = 1;
    integer tot = llGetListLength(agents);

    gCensusNew = 0;
    gCensusBots = 0;
    gCensusWatched = 0;
    gCensusSrc = src;
    integer i;
    for (i = 0; i < tot; i++)
    {
        key a = llList2Key(agents, i);
        if (llGetAgentInfo(a) & AGENT_AUTOMATED)
        {
            gCensusBots++;

            llMessageLinked(LINK_SET, LM_SAY,
                "AE|" + nameUri(a) + "|" + (string)a, "");
        }

// the watch mirror holds strings: cast or the match always fails
        if (llListFindList(gWatch, [(string)a]) != -1)
            gCensusWatched++;
    }
    if (tot > fit)
    {
        gCensusMore = tot - fit;
        agents = llList2List(agents, 0, fit - 1);
        tot = fit;
    }
    gCensusTotal = tot;
    if (gCensusTotal == 0)
    {
        sendCensus();
        return;
    }

    integer ask = gCensusTotal;
    if (ask > CENSUS_ASK_MAX)
        ask = CENSUS_ASK_MAX;
    integer cw = CENSUS_LIST_CAP;
    if (cw > gCensusTotal)
        cw = gCensusTotal;
    integer budget = (llGetFreeMemory() -
        (gCensusTotal + cw) * 102 - 2000) / 260;
    if (ask > budget)
        ask = budget;
    if (ask <= 0)
    {
        gCensusNew = -1;
        sendCensus();
        return;
    }
    gCensusLeft = ask;
    gCensusDeadline = llGetUnixTime() + PENDING_TIMEOUT;
    for (i = 0; i < ask; i++)
        gRequests += [llRequestAgentData(llList2Key(agents, i), DATA_BORN),
            llList2Key(agents, i), "X"];
}

sendCensus()
{

    integer capCtx = (integer)llLinksetDataRead(P + "cap");
    if (capCtx < 0)
        capCtx = 0;
    llMessageLinked(LINK_SET, LM_SAY, "C|" + scopeLabel() + "|" +
        (string)gCensusTotal + "|" + (string)gCensusNew + "|" +
        (string)gCensusBots + "|" + (string)gCensusWatched + "|" +
        gCensusSrc + "|" + (string)gCensusMore + "|" + (string)capCtx, "");
    llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");

    purgeCensusRows();
    gCensusLeft = 0;
    gCensusTotal = 0;
    gCensusNew = 0;
    gCensusBots = 0;
    gCensusWatched = 0;
    gCensusMore = 0;
    gCensusSrc = "A";
}

startCensusNow()
{

    if (gHaveState && !gEnabled)
    {
        llOwnerSay(MSG_OFF_STANDBY);
        return;
    }

    if (gCensusLeft > 0)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SUMSTOCK", "");
        return;
    }
    startCensus(scopeAgentsFrom(llGetAgentList(AGENT_LIST_REGION, []),
        CENSUS_LIST_CAP), "M");
}

// Watch+: top-10 nearest, dialog on this script's own channel
doWatchPlus()
{

    if (gHaveState && !gEnabled)
    {
        llMessageLinked(LINK_SET, LM_SAY, "NR|ok", "");
        llOwnerSay(MSG_OFF_STANDBY);
        return;
    }
    llMessageLinked(LINK_SET, LM_SAY, "NR|ok", "");

    gcNudge();
// same honest guard, applied to the picker
    integer nearNeed = llGetRegionAgentCount() * 102 + 3500;
    if (llGetFreeMemory() < nearNeed)
    {
        dbgLog("RREFUSE", "near|free=" + (string)llGetFreeMemory() +
            "|need=" + (string)nearNeed);
        llDialog(llGetOwner(),
            "The region is too busy to rank nearby people safely right now.\nManual Add still works with an avatar key.",
            ["Manual Add", "Back"], gChannel);
        return;
    }
    list regionAgents = llGetAgentList(AGENT_LIST_REGION, []);
    vector here = llGetPos();

    list top;
    integer i;
    for (i = 0; i < llGetListLength(regionAgents); i++)
    {
        key a = llList2Key(regionAgents, i);
        if (a != llGetOwner() && a != NULL_KEY)
        {
            vector p = llList2Vector(llGetObjectDetails(a, [OBJECT_POS]), 0);
            integer dist = 9999;
            if (p != ZERO_VECTOR)
                dist = (integer)llVecDist(here, p);
            integer j = 0;
            while (j < llGetListLength(top) && llList2Integer(top, j) <= dist)
                j += 2;
            if (j < 20)
            {
                top = llListInsertList(top, [dist, a], j);
                if (llGetListLength(top) > 20)
                    top = llDeleteSubList(top, -2, -1);
            }
        }
    }

    gPickKeys = [];
    for (i = 1; i < llGetListLength(top); i += 2)
        gPickKeys += [llList2Key(top, i)];
    if (llGetListLength(gPickKeys) == 0)
    {
        llDialog(llGetOwner(),
            "Nobody else is in the region.\nUse Manual Add for a key.",
            ["Manual Add", "Back"], gChannel);
        return;
    }

    list buttons;
    for (i = 0; i < llGetListLength(gPickKeys); i++)
    {
        string label = (string)(i + 1) + " " + pickName(llList2Key(gPickKeys, i));
        buttons += [llGetSubString(label, 0, 23)];
    }
    buttons += ["Manual Add", "Back"];

    gPickDue = llGetUnixTime() + PICK_LINGER;
    llDialog(llGetOwner(),
        "Add who to the watch list?\nNearest people first. Click a name to add.",
        buttons, gChannel);
}

// ---------- events ----------
default
{
// boot: random dialog channel, listener, SYNC ask
    state_entry()
    {

        gBootFree = llGetFreeMemory();
        llOwnerSay("Registrar Script ready (Build " + BUILD_NUM +
            "). Memory: " + memPct(gBootFree));
        dbgLog("RBOOT", "free=" + (string)gBootFree);

        gChannel = -(integer)llFrand(1000000000) - 1000000000;
        llListen(gChannel, "", llGetOwner(), "");

        llMessageLinked(LINK_SET, LM_UI_CMD, "SYNC", "");

        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
        llSetTimerEvent(2);
    }

// every 2 s: heartbeat, stale purge, partial flush, census deadline,
// pick expiry, self-heal gate
    timer()
    {

        integer now = llGetUnixTime();

        llLinksetDataWrite(P + "rhb", (string)now);

        integer i;
        integer errStale = 0;
        for (i = llGetListLength(gPending) - 6; i >= 0; i -= 6)
        {
            if (now - llList2Integer(gPending, i + 5) >= STALE_DROP)
            {
                key sa = llList2Key(gPending, i);

                integer sri = llListFindList(gRequests, [sa]);
                while (sri != -1)
                {
                    integer row = sri - 1;
                    gRequests = llDeleteSubList(gRequests, row, row + 2);
                    sri = llListFindList(gRequests, [sa]);
                }

                if (gScanCount > 0 && llList2String(gPending, i + 4) == "S")
                {

                    gScanLeft = gScanLeft - 1;
                    gScanCount = gScanCount - 1;
                    if (gScanCount <= 0)
                    {
                        dbgLog("RABORT", "purge|listing closed");
                        if (gScanOut != "")
                        {
                            llOwnerSay(gScanOut);
                            gScanOut = "";
                        }
                        gScanLines = 0;
                        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
                        resetScan();
                    }
                }
                gPending = llDeleteSubList(gPending, i, i + 5);
                errStale = errStale + 1;
            }
        }
        if (errStale > 0)
        {
            dbgLog("RPURGE", "stale=" + (string)errStale);
            logErr("dropped " + (string)errStale +
                " stale lookup(s) that survived a logout - not announced");
        }
        integer errData = 0;
        for (i = llGetListLength(gPending) - 6; i >= 0; i -= 6)
        {
            if (now - llList2Integer(gPending, i + 5) >= PENDING_TIMEOUT)
            {
                key a = llList2Key(gPending, i);

                integer ri = llListFindList(gRequests, [a]);
                if (ri != -1)
                {
                    errData = errData + 1;
                    while (ri != -1)
                    {
                        integer row = ri - 1;
                        gRequests = llDeleteSubList(gRequests, row, row + 2);
                        ri = llListFindList(gRequests, [a]);
                    }
                }
                sendEntry(i);
                gPending = llDeleteSubList(gPending, i, i + 5);
            }
        }
        if (errData > 0)
        {
            dbgLog("RTIMEOUT", "noreply=" + (string)errData);
            logErr("dataserver did not reply in time for " + (string)errData +
                " avatar lookup(s) - shown with partial data");
        }

        if (gCensusLeft > 0 && now >= gCensusDeadline)
        {
            if (now - gCensusDeadline >= STALE_DROP)
            {

                purgeCensusRows();
                gCensusLeft = 0;
                gCensusTotal = 0;
                gCensusNew = 0;
                gCensusBots = 0;
                gCensusWatched = 0;
                gCensusMore = 0;
                llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
            }
            else
                sendCensus();
        }

// pick-dialog expiry: a dismissed dialog must not wedge the gate
        if (gPickDue != 0 && now >= gPickDue)
        {
            gPickKeys = [];
            gPickDue = 0;
        }

// self-heal: reset at a quiescent moment restores boot memory
        if (llGetFreeMemory() < 6000 && gScanCount == 0 &&
            gCensusLeft == 0 && gScanLines == 0 &&
            llGetListLength(gPickKeys) == 0 &&
            llGetListLength(gPending) == 0)
        {
            gcNudge();
            if (llGetFreeMemory() < 6000)
            {
                logErr("selfheal: reset at " +
                    (string)llGetFreeMemory() + " free");
                llResetScript();
            }
        }
    }

// reply routing by row kind
    dataserver(key requestId, string data)
    {
        integer ri = findRequestIndex(requestId);
        if (ri == -1)
            return;

        key agent = llList2Key(gRequests, ri + 1);
        string kind = llList2String(gRequests, ri + 2);
        gRequests = llDeleteSubList(gRequests, ri, ri + 2);

        if (kind == "X")
        {

            if (gCensusTotal > 0 && gCensusLeft > 0)
            {
                if (calculateAgeFromBornDate(data) < 7)
                    gCensusNew++;
                gCensusLeft = gCensusLeft - 1;
                if (gCensusLeft == 0)
                    sendCensus();
            }
            return;
        }

        integer idx = findAgentIndex(gPending, agent);
        if (idx == -1)
            return;

        if (kind == "B")
            gPending = llListReplaceList(gPending,
                [calculateAgeFromBornDate(data)], idx + 1, idx + 1);
        else
            gPending = llListReplaceList(gPending, [data], idx + 2, idx + 2);
        checkPending(idx);
    }

// SCAN, REBASE, RESET, CENSUS, LOOK, NEAR requests
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == LM_SWEEP_ASK)
        {
            if (str == "SCAN")
                startScan();
            else if (str == "REBASE")
            {

                resetScan();
                clearPipeline();
            }
            else if (str == "RESET")
            {

                resetScan();
                clearPipeline();
            }
            else if (str == "CENSUS")
                startCensusNow();

            else if (llGetSubString(str, 0, 6) == "CENSUS|")
            {

                startCensus(scopeAgentsFrom(llGetAgentList(
                    AGENT_LIST_REGION, []), CENSUS_LIST_CAP), "A");
            }
            else if (llGetSubString(str, 0, 4) == "LOOK|")
                askAgent((key)llGetSubString(str, 5, -1), "A");
            else if (str == "NEAR")
                doWatchPlus();
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
            return;
        }

        if (num == LM_MEM_ASK)
        {

            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Registrar Script|" + (string)llGetFreeMemory() +
                "|" + BUILD_NUM, "");
            return;
        }
    }

// Watch+ picks, Manual Add, Back
    listen(integer channel, string name, key id, string msg)
    {

        if (channel != gChannel || id != llGetOwner())
            return;
        msg = llStringTrim(msg, STRING_TRIM);
        if (msg == "")
            return;

        if (msg == "Back")
        {

            gPickKeys = [];
            gPickDue = 0;
            llMessageLinked(LINK_SET, LM_MENU_OPEN, "", "");
            return;
        }

        if (msg == "Manual Add")
        {

            gPickDue = llGetUnixTime() + PICK_LINGER;
            llTextBox(id, "Paste the avatar key (UUID) you want " +
                "to watch, then click Submit:", gChannel);
            return;
        }

        integer sp = llSubStringIndex(msg, " ");
        if (sp > 0)
        {
            integer num = (integer)llGetSubString(msg, 0, sp - 1);
            if (num > 0 && num <= llGetListLength(gPickKeys))
            {
                llMessageLinked(LINK_SET, LM_UI_CMD,
                    "ADD|" + llList2String(gPickKeys, num - 1), "");
                doWatchPlus();
                return;
            }
        }

        if (llStringLength(msg) == 36)
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "ADD|" + msg, "");
            doWatchPlus();
        }
    }

// owner change resets; region jump aborts the listing
    changed(integer change)
    {

        if (change & CHANGED_OWNER)
        {
            llResetScript();
            return;
        }

        if (change & (CHANGED_REGION | CHANGED_TELEPORT))
        {
            resetScan();
            clearPipeline();
        }
    }
}
