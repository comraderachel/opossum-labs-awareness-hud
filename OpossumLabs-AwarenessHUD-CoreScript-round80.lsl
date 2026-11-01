// ROUND 80 (2026-11-01) - latest version: paste the whole
// script over the old one. PAIRED with the round-80 Data,
// Registrar AND Companion Scripts (all four change this
// round) and the round-80 help notecard. This round: the
// design seat point moves to TOP-RIGHT (the measured
// position now assumes it - re-attach to Top-Right once
// when pasting), a "reseat" chat command on a fixed
// owner-derived channel recovers an off-screen HUD, the
// Status line and boot lines gain the build stamp, the
// trace mode is cut (touches, blinks and the Wipe entry),
// Wipe clears the new SMH.cap publish, and the header's
// arrival-TELL attribution is fixed (the Registrar sends it
// since round 79).
// ============================================================
// OPOSSUM LABS AWARENESS HUD - Core Script (ROOT prim)
// ------------------------------------------------------------
// VERSION HISTORY (newest first):
//   round 80: FIVE ITEMS. (1) SEAT RE-ANCHOR: the design
//     point moves from TOP-LEFT to TOP-RIGHT (Rachel's
//     placement), and DEFAULT_POS is re-measured for it -
//     <0.00590, 0.15, -0.36976> sits a panel's width in
//     from the right edge and below the top bar, ON SCREEN
//     where the old left-edge coordinate could drift off
//     after a viewer UI change (the off-screen complaint
//     that started this). Migration: re-attach the HUD to
//     Top-Right once (a POINT CHANGE re-seats; the old
//     "lastpt" guard keeps any same-point re-wear frozen).
//     (2) THE "RESEAT" CHAT COMMAND: LSL cannot detect a
//     window resize (no event, no dimension API - the saved
//     wiki page says so plainly), so an off-screen HUD needs
//     a way back that does not depend on clicking it: a
//     listener on the fixed owner-key-derived channel (the
//     same derivation the Registrar's transfer radio uses)
//     accepts the word "reseat" from the owner and
//     applies the seat UNCONDITIONALLY - bypassing the
//     lastpt guard, because the whole point is recovering a
//     seat the viewer lost track of. Typed form is
//     "/<channel> reseat" (channel, SPACE, word - the
//     documented viewer syntax; a colon after the channel
//     number is delivered as part of the message, so the
//     listen event accepts "reseat" AND ":reseat" to cover
//     both typing styles). The channel number
//     prints at boot and lives in the help notecard.
//     (3) BUILD STAMP: every boot line, the Status line and
//     the Status Check memory line carry Build:110126080
//     (MMDDYY + zero-padded round; the LM_MEM_TELL reply
//     carries this script's build as a third field - a
//     pre-field amendment so Status Check shows WHICH build
//     EACH script runs) - a field log now always shows
//     which build ran.
//     (4) TRACE CUT: the touch and blink narrations and the
//     Wipe entry for SMH.trace are deleted with the trace
//     mode everywhere. (5) WIPE gains SMH.cap (the Data
//     Script's new tracking-cap publish) and the header's
//     LM_DATA_TELL attribution is corrected - the Registrar
//     has sent the arrival TELL since round 79, not the Data
//     Script. (6) THE TYPE-TRAP AUDIT REACHED CORE TOO:
//     gWatchList is a STRING mirror, and three sites passed
//     KEY needles - the addWatch "Already watching" dedupe
//     (NEVER fired; a double-add made a silent duplicate),
//     entryFlags' [WATCHED] bit and the LEFT line's [WATCHED]
//     tag (never rendered). All three needles are cast to
//     (string), the same fix as the Registrar's and Data's
//     sites this round - the audit is a standing step now.
//   round 78: the 4th-script split, part 1 (with the Data
//     Script and the NEW Registrar Script). List All and
//     Watch+ move out of Data into the Registrar, which
//     answers "SCAN" and "NEAR" on the same LM_SWEEP_ASK
//     wire - Core's dispatch code is UNCHANGED (the wire
//     was already a LINK_SET broadcast). Core's changes:
//     the Wipe reset list gains the Registrar (guarded
//     llResetOtherScript, exact inventory name
//     "Registrar Script"), Status Check's memory poll
//     gains a fourth line automatically (the Registrar
//     answers LM_MEM_ASK like its siblings), Wipe clears
//     the Registrar's debug ring (SMH.rdbg0..7) with the
//     other rings, and - same round, pre-field amendment -
//     Core becomes the READER of that ring: with Debug Log
//     on, Status Check appends the Registrar's recorded
//     events oldest-first (the Companion's Dump Log prints
//     only the Data and Core rings and the Companion stays
//     frozen at 94%; a halted writer's story must survive
//     the halt, so the reader lives in another script).
//     Status Check prints whichever scripts answer - a
//     missing Registrar degrades to three lines, nothing
//     else.
//   round 75: the Debug Log (with the Data Script and the
//     Companion). This script keeps its own 8-slot ring in
//     linkset data (SMH.cdbg0..7 + SMH.cdbgNext): CBOOT, a
//     dead-pipeline CGAP (the gap recorder now logs too), the
//     stall detector firing and recovering (STALL / STALLOK),
//     and WIPE itself. The Companion's Debug menu toggles
//     SMH.dlog (the exact Trace pattern) and its Dump Log
//     prints both rings oldest-first; Wipe clears the rings
//     and the flag. Unfreezes this script for the first time
//     since round 67 - the additions are deliberately tiny
//     (Core holds the most free memory of the three).
//   round 58: the language map now lives in LINKSET DATA - this
//     script writes it at boot; the Data Script reads it lazily
//     and caches per code. Fixes the round-57 regression: the
//     map's Mono list form cost Data ~4.5KB and tripped the
//     memory valve in a 16-avatar region. Also: the trace log
//     confirmed event starvation (a 48s tick + a queued touch
//     processed only after release), so Data now RECORDS short
//     starvation events to SMH.starve for the Debug report.
//   round 57: Trace mode (Settings > Debug > Trace toggles
//     SMH.trace):
//     this script narrates button touches and blink on/off
//     while hunting the freeze bug. Language map moved from
//     Companion to Data; the alive ping handshake is unchanged.
// ------------------------------------------------------------
// Three scripts share the HUD linkset (this one must sit in
// the ROOT prim - touches on unscripted child prims pass up
// to the root's touch handler):
//   Core (this)  - persistence, buttons, watch-list storage,
//                  menu command handling, assembling
//                  announcements from finished facts. Never
//                  walks the region agent list.
//   Companion    - ALL text formatting and
//                  the entire dialog menu system (the strings
//                  live in ITS 64KB Mono budget). The language
//                  map moved to Data in round 57.
//   Data (REQUIRED, any prim) - the detection sweep AND the
//                  dataserver pipeline: region agent list,
//                  scope filter (parcel / region / radius),
//                  arrival/departure diff, watch-list
//                  presence, List All scan. In Core the same
//                  key lists (102 B/key in Mono) caused
//                  Stack-Heap Collisions in busy regions; here
//                  they sit in a nearly empty budget behind
//                  graceful guards. Without it the HUD detects
//                  nothing (List All says so).
//
// HUD notes (SL wiki "Creating HUDs"):
//   * llPlaySound on a HUD is heard by the WEARER ONLY (the
//     alert ping; llTriggerSound would be heard by bystanders
//     and is avoided). Needs a sound named "notification" in
//     the HUD contents.
//   * HUDs render full-bright and capture clicks even on
//     transparent parts - keep the root prim small.
//   * Buttons are found by prim NAME ("Power Button", "Help
//     Button", "Sound Button", "Menu Button"), so relinking
//     never breaks them. Power button: GREEN = monitoring on,
//     RED = paused, blinking = fetching account data (not a
//     fault). Sound button: GREEN = ping on, RED = off. Only
//     the named Menu Button opens the dialog menus; other
//     prims ignore clicks. A missing button prim is inert; a
//     missing power button falls back to the root prim.
//   * The menu offers List All / Watch+ / Watch- / Watch List
//     / Encounters / Status / Settings; anything the panel
//     already has a physical button for (Power, Help, Sound)
//     is deliberately not duplicated there.
//
// Persistence: linkset data, prefix P ("SMH.") - survives
// script resets, does NOT count against script memory. Keys:
//   owner, scope, range, enabled, watch, ping,
//   lastpt  (HUD seat point: a point CHANGE re-seats, a
//            same-point re-wear keeps the wearer's nudges),
//   setup   (welcome flag - WRITTEN by the Companion, cleared
//            here on Wipe and owner change so it re-runs),
//   err0..9 + errNext (error ring - written by the Data
//            Script, printed by Debug, cleared by Wipe),
//   enc0..49 + encNext + encdays (encounter ring - written
//            and read by the Companion only).
// NOTE: attachment datastores can roll back on a viewer crash
// or an unsaved logout - occasional loss of the last change is
// possible.
//
// VERSION: round 67 (2026-10-30): the full-script audit round
// (Rachel's request: efficiency, outlying bugs, dead code) -
// plus a ROUND stamp as the FIRST line of every script, so a
// pasted copy always shows its version at the top. Findings
// here: (1) pushState's 4th payload field (this script's free
// memory) was DEAD - the Companion and the Data Script read
// fields 0-2 only (memory belongs to Status Check, which asks
// each script live), so the field and the per-push
// llGetFreeMemory call are gone; (2) Wipe now deletes
// SMH.trace too - the fresh-start rule had one survivor (a
// wiped, handed-over HUD could keep printing TRACE lines to
// the next owner). The audit's accepted-as-is items are
// recorded in the Data Script's round-67 block. Round 63
// remains below. (Full history in the project notes.)
//
// VERSION: round 63 (2026-10-30): two field-report items.
// (1) Wipe left the freeze diagnostics behind: the field
// log showed "starved the HUD 1 time(s)" and "Core made no
// pass for 27m" still printing on Status Check AFTER a Wipe
// (the error ring was already cleared - SMH.starve and
// SMH.coregap simply had no deleter). doWipe now deletes
// both (plus SMH.gap, belt-and-braces - the Data Script
// clears that at its own reset), and state_entry below now
// clears THIS script's own gap record (fresh start = fresh
// evidence; a freeze that merely wakes never runs
// state_entry, so the record survives exactly in the cases
// it is proof for). (2) The status line labels its scope:
// "ON | Area: Parcel | Watch:0" (was "ON | parcel | Watch:0")
// - the bare word read as noise; statusLine capitalizes the
// label and the Companion's uiStatus matches. First
// functional Core change since round 58. Round 56 remains
// below. (Full history in the project notes.)
//
// VERSION: round 56 (2026-10-30): Core becomes the freeze
// witness. The alt's freeze again woke on the next crossing
// (the known SL attachment-script-death signature), and a
// dead script cannot self-report - so the round-55 liveness
// recorder now runs HERE too, plus the one thing only a
// second script can add: cross-witnessing. The timer never
// stops anymore (0.5 s while blinking, 5 s otherwise): every
// tick stamps a heartbeat, records a 5+ minute outage in
// "SMH.coregap" for Debug, and watches the Data Script's
// published heartbeat ("SMH.hb") - llGetScriptState cannot
// see a hung script (it still reports running), so a stale
// heartbeat past a 30 s grace is the only in-world signal
// for "scheduled but stuck". One warn per stall, one
// recovery line. Debug now shows BOTH scripts' outage gaps:
// equal = the sim stopped scheduling the prim (the SL
// failure); only one = a single-script problem. Also fixed
// a latent no-short-circuit flaw: statusLine's inventory
// guard now nests its llGetScriptState call (LSL && always
// evaluates both operands). Round 50 remains below.
// (Full history in the project notes.)
//
// VERSION: round 50 (2026-10-28): new "CENSUS" command for the
// menu's Summary button (forwards to the Data Script's on-
// demand census); the Data Script's low-memory valve now
// recovers on its own, and its census gained a source field
// (see the C protocol line above). Recent behavior rounds
// (full history in the project notes):
//   49 - dead-code removal (orphan PING/HELP command branches)
//        + comment cleanup; behavior unchanged.
//   48/45 - a watched arrival/departure INSIDE the scope gets
//           ONE notice (ARRIVED/LEFT with [WATCHED]); the
//           "entered/left the region" lines fire only for
//           people outside the scope.
//   45    - encounter log: WIN/WFOUND forwards carry the
//           avatar key; Wipe and owner-change clear the ring.
//   35    - first-wear placement adapts to the HUD point
//           (hudSeatFor; "lastpt" remembers the seat point).
//   30    - names in chat lines are viewer display-name LINKS
//           (work even for offline avatars).
//   24    - v1.0; memory listings show "% used"; Debug report.
// ============================================================

// ---------- Tunable configuration ----------
integer MAX_WATCHED = 20;         // watch list capacity
string PING_SOUND = "notification"; // inventory sound played for alerts (rename freely)
string HELP_CARD = "Awareness Hud Help"; // help notecard (EXACT name, case-sensitive)
// NOTE: DATA_NAME is a RESERVED LSL constant (an llRequestAgentData
// code, like DATA_BORN) - declaring a global with that name is a
// syntax error. Never name a global after an LSL constant.
string COMPANION_SCRIPT_NAME = "Companion Script"; // EXACT inventory names,
string DATA_SCRIPT_NAME = "Data Script";           // case-sensitive: Wipe resets
string REGISTRAR_SCRIPT_NAME = "Registrar Script"; // all by name; the Registrar
                                                   // (round 78) owns List All /
                                                   // Watch+. Status
                                                   // both by name; Status
                                                   // health-checks the Data one
integer BUSY_TIMEOUT = 180;     // power-button blink safety stop (seconds):
                                // a full scan worst case is ~150s; if BUSY|0
                                // never arrives, the Data Script died mid-fetch

// First-wear screen placement (relative to the HUD attachment point
// it was designed for). Applied when the wearer switches attachment
// points; afterwards the wearer's own repositioning is respected.
// Round 80: the design point is TOP-RIGHT (Rachel's
// placement). DEFAULT_POS is re-measured for the TOP_RIGHT
// frame: +Y is INWARD from the right edge (0.15 = a panel's
// width in), -Z is down from the top bar - the panel sits
// fully ON SCREEN, where the old left-frame coordinate could
// drift off the edge after a viewer UI change.
vector DEFAULT_POS = <0.00590, 0.15, -0.36976>;
vector DEFAULT_EULER = <0.0, 0.0, 180.0>; // degrees (Z rotation)
integer HUD_PT_DESIGN = ATTACH_HUD_TOP_RIGHT; // the point the
// measured position above was taken on. Migration when
// pasting this round: re-attach the HUD to TOP-RIGHT once -
// a POINT CHANGE re-seats (lastpt guard), a same-point
// re-wear keeps the wearer's nudges.

// ---------- Scope constants ----------
integer SCOPE_REGION = 0;
integer SCOPE_RADIUS = 1;
integer SCOPE_PARCEL = 2;  // default scope for a fresh HUD

string P = "SMH.";  // linkset data name prefix
string BUILD_NUM = "110126080"; // round 80: the build stamp
                                // (MMDDYY 110126 + zero-padded round
                                // 080) - printed on every boot line
                                // and on the Status line, so a field
                                // log always shows WHICH build ran
                                // (kept identical in all four
                                // scripts; bump the round digits
                                // every round)
integer CDBG_SLOTS = 8; // round 75: Core debug-log ring size
                        // (SMH.cdbg0..7); keep in sync with
                        // the Companion's Dump Log reader

string HUD_VERSION = "1.0"; // user-facing HUD version, shown in the
                           // boot line and the Debug report (keep
                           // in sync with the Companion's copy)

// Inter-script messages (numbers MUST match the other scripts
// exactly). "ping"/"ping=ok" is the startup handshake.
integer LM_LANG_ASK = 19024;   // -> Companion: str = code to resolve
integer LM_LANG_TELL = 19025;  // <- Companion: str = "code=FullName"
integer LM_SAY = 19027;        // -> Companion: announce/scan text
                               //    (the Data Script sends SB/S/SE
                               //    scan lines the same way)
integer LM_MENU_OPEN = 19028;  // -> Companion: open the main menu
integer LM_UI_STATE = 19029;   // -> LINK_SET: "enabled|scope|range"
                               //    (the Data Script mirrors its
                               //    sweep settings from this)
integer LM_UI_CMD = 19030;     // <- Companion (or Data): "SYNC" etc.
integer LM_WATCH_LIST = 19031; // -> LINK_SET: CSV of watch-list keys
                               //    (the Data Script mirrors it)
integer LM_DATA_ASK = 19032;  // -> Data Script: "ping" handshake only
integer LM_DATA_TELL = 19033; // <- Data Script: "ping=ok";
                              //    <- REGISTRAR Script (since round
                              //    79, when the arrival pipeline
                              //    moved): "mode|key|name|age|pay|
                              //    lang" for a finished ARRIVAL
                              //    lookup (round 80 header fix -
                              //    this was misattributed to Data)
integer LM_SWEEP_ASK = 19034; // -> Data Script: "SCAN" / "REBASE" /
                              //    "CENSUS" (the menu's Summary
                              //    button)
integer LM_EVENT = 19035;     // <- Data Script: "OUT|key|name" (left
                              //    scope), "WIN|name|key" / "WOUT|name"
                              //    (watched entered/left region),
                              //    "WFOUND|name|key" (watched avatar was
                              //    already present when we arrived),
                              //    "BUSY|1/0" (a scan/census fetch
                              //    started/ended -> power-blink)
integer LM_MEM_ASK = 19036;   // -> LINK_SET (Debug button): every
                              //    script answers with LM_MEM_TELL
integer LM_MEM_TELL = 19037;  // <- any script: "name|freeBytes|build"
                              //    (the Companion prints the debug lines)
// (19026 was LM_HELP_ASK - retired: the help guide is a notecard in
// the HUD, given by the Help button via llGiveInventory. Gap kept
// reserved so the number is never reused.)
// LM_SAY str = "kind|field|field|..." (fields never contain "|"):
//   "A|scope|name|age|pay|lang|flags|dist"  arrival (dist = meters
//                                           from the wearer, -1
//                                           = unknown)
//   "L|scope|name|watch"               left scope
//   "W|name|entered|key"              watched enter/left region
//                                       (entered: 1 = entered,
//                                       2 = already present on
//                                       arrival, 0 = left; the key
//                                       rides WIN/WFOUND for the
//                                       encounter log, absent on
//                                       WOUT and raw fallback)
//   "SB|scope|count"                   scan listing header
//   "S|name|age|pay|lang|flags|dist"   one scan line (dist = meters
//                                       from you when composed)
//   "SE|"                              scan listing end (flush)
//   "D|low|pct" / "D|ok|pct"           region slowdown / recovery
//                                       (pct = % of normal sim speed)
//   "C|scope|total|new|bots|watched|src"  one-line population
//                                       census (arrival summary;
//                                       src "M" = the menu's
//                                       Summary button)
// flags bits: 1 automated, 2 new account, 4 no payment, 8 watched.
// (Bit 4 still triggers the ping, but the companion does NOT
// render it as a tag - the Pay: field already shows the status.)

// The button prims are found BY NAME at startup (see findLinkByName),
// so relinking the HUD can never break them. Name them in the Edit
// window: "Power Button", "Help Button", "Sound Button",
// "Menu Button". ONLY the named Menu Button opens the dialog menu;
// clicks on the panel body or any other prim are ignored. Missing
// prims are simply inert; the power button falls back to the root
// prim.
string BUTTON_POWER = "Power Button";
string BUTTON_HELP = "Help Button";
string BUTTON_SOUND = "Sound Button";
string BUTTON_MENU = "Menu Button";
integer gLinkPower;
integer gLinkHelp;
integer gLinkSound;
integer gLinkMenu;
vector COLOR_ON = <0.20, 0.85, 0.30>;   // green = monitoring
vector COLOR_OFF = <0.90, 0.25, 0.25>; // red = paused
vector COLOR_BUSY = <0.05, 0.25, 0.10>;  // dim green = busy blink

// ---------- Runtime state ----------
key gOwner;

integer gScope = SCOPE_PARCEL; // fresh HUDs start in parcel scope
integer gRange = 25;
integer gEnabled = TRUE;
integer gPing = FALSE;
list gWatchList;       // watched avatar keys

string LANG_MAP = "|en|English|en-us|English (US)|en-gb|English (UK)|fr|French|fr-ca|French (Canada)|de|German|es|Spanish|it|Italian|pt|Portuguese|pt-br|Portuguese (Brazil)|nl|Dutch|ru|Russian|pl|Polish|tr|Turkish|sv|Swedish|da|Danish|no|Norwegian|fi|Finnish|cs|Czech|el|Greek|ro|Romanian|hu|Hungarian|uk|Ukrainian|bg|Bulgarian|hr|Croatian|sr|Serbian|ja|Japanese|ko|Korean|zh|Chinese|zh-cn|Chinese (Simplified)|zh-tw|Chinese (Traditional)|th|Thai|vi|Vietnamese|id|Indonesian|ar|Arabic|he|Hebrew|hi|Hindi|";
// (One single long literal on purpose: LSL does NO constant
// folding at global scope, so `"...|...|..." + "..."` in a
// global initializer is a SYNTAX ERROR - the compiler wants a
// plain literal here. A long line is fine; only the notecard
// has a wrap-width rule.)
// Round 58: the language map lives in LINKSET DATA (written at
// boot below), not in any script's 64KB heap - the Mono LIST
// form cost the Data Script ~4.5KB and pushed it to 93% used
// in a 16-avatar region (detection paused). A flat string in
// the 128KB linkset datastore costs every script NOTHING at
// rest. Pipe-delimited "|code|Name|" pairs with a LEADING pipe
// so the Data Script can find a code with an exact
// llSubStringIndex("|" + code + "|") match; names never
// contain pipes, so a code can only match at a pair boundary.

integer gHaveLang;    // TRUE once the Companion Script answers "ping"
integer gHaveData;    // TRUE once the Data Script answers "ping"
integer gBusy;        // > 0 while a scan or the arrival census is
                      // fetching account data (power-button blink)
integer gBlinkOn;     // power-button blink toggle
integer gBusyStart;   // llGetUnixTime() when this blink session began
integer gHbCore = 0;  // liveness heartbeat: unix time of the last
                      // timer tick. The timer NEVER stops now (0.5 s
                      // while blinking, 5 s otherwise) - it is the
                      // blinker AND the health recorder. A 5+ minute
                      // tick gap means the script engine was not
                      // running this script at all.
integer gStallGrace = 0; // unix time before which the Data Script's
                      // published heartbeat is not yet trusted
                      // (boot, or Core's own wake from a gap)
integer gStalled;     // the Data-stall warning has fired (one per
                      // stall, one recovery line)
// The agent-list diff, scan queue and dataserver pipeline all
// live in the DATA SCRIPT (see header). Core only receives
// finished facts: LM_DATA_TELL arrivals, LM_EVENT departures
// and watch transitions - which is why Core now stays tiny
// enough to be safe in ANY region.

// ============================================================
// SMALL HELPERS
// ============================================================

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
    // Watch add/remove confirmations: a viewer-resolved
    // display-name LINK (clickable, opens the profile) - works
    // even for OFFLINE avatars (Manual Add), where script-side
    // lookups return nothing.
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

// ============================================================
// PERSISTENCE (linkset data in the HUD object itself)
// ============================================================

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

loadSettings()
{
    string storedOwner = llLinksetDataRead(P + "owner");
    if (storedOwner == "" || (key)storedOwner != gOwner)
    {
        // First run, or the HUD was sold/transferred: keep general
        // preferences, but clear the previous owner's personal list.
        if (storedOwner != "")
            llOwnerSay("New owner detected - watch list cleared, preferences kept.");
        llLinksetDataWrite(P + "watch", "");
        // The encounter history is personal too - clear it for
        // the new owner (the keep-days preference is general
        // and kept, like the other preferences).
        integer eo;
        for (eo = 0; eo < 50; eo++)
            llLinksetDataDelete(P + "enc" + (string)eo);
        llLinksetDataDelete(P + "encNext");
        // New owner: designed placement back on first wear, and
        // the Companion's one-time welcome re-runs.
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
    // Inward seat for HUD points OTHER than the design point
    // (empirical sign conventions: +Y moves inward on
    // right-side and center-2 frames, -Y on left-side and
    // center-1; Z pulls away from the top/bottom edge). The
    // 0.1 m panel clears the edge with 0.08; fine-tuning is
    // the wearer's job - the viewer remembers nudges.
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

applyDefaultPlacement(integer force)
{
    // Seat the HUD for the worn attachment point: the measured
    // comfort position applies at the DESIGN point, other HUD
    // points get hudSeatFor's inward nudge, non-HUD attachments
    // are refused with a note. "lastpt" makes a point CHANGE
    // re-seat while a same-point re-wear keeps the wearer's
    // position (the viewer remembers it); cleared on owner
    // change and Wipe. Round 80: the FORCE flag is the
    // "reseat" chat command's path - it bypasses the lastpt
    // guard, because the whole point is recovering a seat the
    // viewer has lost track of (an off-screen panel).
    integer pt = llGetAttached();
    if (pt == 0)
        return; // not worn: never move a rezzed build around
    if (pt < ATTACH_HUD_TOP_RIGHT || pt > ATTACH_HUD_BOTTOM_LEFT)
    {
        llOwnerSay("This is a HUD - please attach it to a HUD position on your screen.");
        return;
    }
    if (!force && (integer)llLinksetDataRead(P + "lastpt") == pt)
        return; // same point as last time: keep the wearer's seat
    vector pos = DEFAULT_POS;
    if (pt != HUD_PT_DESIGN)
        pos = hudSeatFor(pt);
    llSetPos(pos);
    llSetRot(llEuler2Rot(DEFAULT_EULER * DEG_TO_RAD));
    savePref("lastpt", (string)pt);
}

integer reseatChannel()
{
    // Round 80: the fixed channel for the "reseat" recovery
    // command - deterministic and derived from the OWNER KEY
    // (the same derivation as the Registrar's transfer radio),
    // deep negative so no resident ever types there by
    // accident. The listener filters on the owner id and the
    // word (both "reseat" and ":reseat" - see the listen
    // event), so nobody else can move the panel.
    return -1000000000 -
        (integer)("0x" + llGetSubString((string)llGetOwner(), 0, 6));
}

pushState()
{
    // Mirror settings + watch list to the Companion (menus) and the
    // Data Script (sweep). Sent at boot, after every change, and on
    // SYNC request (a sibling script may boot after Core does).
    llMessageLinked(LINK_SET, LM_UI_STATE,
        (string)gEnabled + "|" + (string)gScope + "|" + (string)gRange, "");
    llMessageLinked(LINK_SET, LM_WATCH_LIST,
        llDumpList2String(gWatchList, ","), "");
}

// ============================================================
// WEARER NOTIFICATION (llOwnerSay is private and has no delay;
// chunk long text because owner chat still caps around 1k)
// ============================================================

notifyOwner(string msg)
{
    while (llStringLength(msg) > 800)
    {
        integer cut = 800;
        // Try to break on a newline so lines stay readable.
        while (cut > 600 && llGetSubString(msg, cut, cut) != "\n")
            cut = cut - 1;
        llOwnerSay(llGetSubString(msg, 0, cut - 1));
        msg = llGetSubString(msg, cut + 1, -1);
    }
    llOwnerSay(msg);
}

// ============================================================
// HUD EXTRAS: power button color + wearer-only ping
// ============================================================

integer findLinkByName(string name)
{
    // Find a prim by name so relinking the HUD never breaks the
    // buttons. Returns -1 when no prim has that name.
    integer n = llGetNumberOfPrims();
    integer i;
    for (i = 1; i <= n; i++)
    {
        if (llGetLinkName(i) == name)
            return i;
    }
    return -1;
}

updateButton()
{
    // Status is shown on the prim itself: the power button turns
    // green while monitoring runs, red while paused. HUD prims are
    // always full-bright, so a plain color change reads clearly.
    if (gEnabled)
        llSetLinkPrimitiveParamsFast(gLinkPower,
            [PRIM_COLOR, ALL_SIDES, COLOR_ON, 1.0]);
    else
        llSetLinkPrimitiveParamsFast(gLinkPower,
            [PRIM_COLOR, ALL_SIDES, COLOR_OFF, 1.0]);
}

updateSoundButton()
{
    if (gLinkSound == -1)
        return;
    // Same color language as the power button: GREEN while the
    // ping is on, RED while it is off.
    if (gPing)
        llSetLinkPrimitiveParamsFast(gLinkSound,
            [PRIM_COLOR, ALL_SIDES, COLOR_ON, 1.0]);
    else
        llSetLinkPrimitiveParamsFast(gLinkSound,
            [PRIM_COLOR, ALL_SIDES, COLOR_OFF, 1.0]);
}

playPing()
{
    // llPlaySound on a HUD is heard by the wearer only.
    if (gPing && llGetInventoryType(PING_SOUND) == INVENTORY_SOUND)
        llPlaySound(PING_SOUND, 1.0);
}

setBusy(integer delta)
{
    // BUSY|1 / BUSY|0 from the Data Script (a scan or the
    // census started/ended): the power button blinks while any
    // fetch runs. A counter, not a flag - fetches can overlap
    // (a scan during the census).
    integer was = gBusy;
    gBusy = gBusy + delta;
    if (gBusy < 0)
        gBusy = 0;
    if (gBusy > 0)
    {
        if (was <= 0)
        {
            gBusyStart = llGetUnixTime(); // new blink session
            // (Round 80: the blink trace narration is cut with
            // the trace mode everywhere - the debug rings won
            // the diagnosis war.)
        }
        llSetTimerEvent(0.5); // start blinking
    }
    else
    {
        llSetTimerEvent(5);   // fetch finished: back to steady -
                              // heartbeat cadence; the timer is
                              // never fully off anymore (round 56)
        gBlinkOn = FALSE;
        updateButton();
    }
}

// ============================================================
// ANNOUNCING (all text lives in the Companion Script; Core only
// serializes the facts - this is the big memory offload)
// ============================================================

integer entryFlags(key id, integer age, string pay)
{
    integer f = 0;
    if (llGetAgentInfo(id) & AGENT_AUTOMATED)
        f += 1;
    if (age >= 0 && age < 7)
        f += 2;
    if (pay == "0")
        f += 4;
    // Round 80 type-trap fix: gWatchList is a STRING mirror
    // (llParseString2List of the saved CSV) - llListFindList
    // matches types strictly, so the old KEY needle never
    // matched and the [WATCHED] bit never rendered here.
    if (llListFindList(gWatchList, [(string)id]) != -1)
        f += 8;
    return f;
}

annSend(string payload, key id)
{
    // Hand the facts to the Companion Script for formatting. If
    // the companion is missing the raw payload is printed anyway,
    // so announcements degrade instead of vanishing.
    if (gHaveLang)
        llMessageLinked(LINK_SET, LM_SAY, payload, id);
    else
        notifyOwner(payload);
}

announceArrival(key id, string name, integer age, string pay, string lang)
{
    // Called with the Data Script's finished lookup result.
    integer flags = entryFlags(id, age, pay);
    if (flags)
        playPing();
    // Distance from the wearer when the announcement is ready.
    // Positions are a snapshot (they may move right after); -1
    // means the position could not be read (avatar already gone),
    // and the Companion omits the field for negative values.
    integer dist = -1;
    vector p = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
    if (p != ZERO_VECTOR)
        dist = (integer)llVecDist(llGetPos(), p);
    annSend("A|" + scopeLabel() + "|" + name + "|" +
        (string)age + "|" + pay + "|" + lang + "|" + (string)flags + "|" +
        (string)dist, id);
}

// ============================================================
// SWEEP / SCAN CONTROL (the work itself lives in the Data Script)
// ============================================================

rebase()
{
    // Tell the Data Script to silently adopt the current population
    // (after scope changes, power-on, Wipe) so none of those spam
    // "arrived" messages for the people already present.
    llMessageLinked(LINK_SET, LM_SWEEP_ASK, "REBASE", "");
}

setScope(integer r)
{
    // Scope -> Radius/Region picks from the Companion's menu.
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
    // Shared by the power button (touch) and the menu's Turn On/Off.
    gEnabled = on;
    savePref("enabled", (string)gEnabled);
    if (on)
        rebase(); // resume: adopt the current population silently
    updateButton();
    pushState();
    if (on)
        notifyOwner("Detector ON.");
    else
        notifyOwner("Detector OFF. Click the power button to turn it back on.");
}

setPing()
{
    // Shared by the Sound Button (touch) and the menu's Ping toggle.
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

// ============================================================
// WATCH LIST MANAGEMENT
// ============================================================

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

addWatch(string s)
{
    if (!validUUID(s))
    {
        notifyOwner("That does not look like a UUID.");
        return;
    }
    key k = (key)s;
    // Round 80 type-trap fix: cast the needle to string - the
    // gWatchList mirror is STRING-typed, so the old KEY needle
    // always returned -1 and the "Already watching" dedupe
    // NEVER fired (a double-add silently made a duplicate
    // entry).
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
    // The watch-list push below also tells the Data Script; it
    // seeds already-present avatars silently there (no phantom
    // "entered" message), so Core needs no presence check here.
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

// ============================================================
// STATUS / HELP / WIPE (the dialog menus live in the Companion)
// ============================================================

string memPct(integer freeBytes)
{
    // Mono scripts get a 65536-byte budget; show the percentage
    // USED next to the free number wherever memory is listed.
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
    // Script health: a script halted by a run-time error (e.g.
    // Stack-Heap Collision) reports as NOT running. Quiet when
    // all is well, loud when the Data Script died. The
    // llGetInventoryType guard prevents DEBUG_CHANNEL error
    // shouts for a missing or misnamed script. NOTE (round 56):
    // LSL && does NOT short-circuit, so the state read must sit
    // in a nested if - never behind a && - or the guard is no
    // guard at all.
    string health = "";
    if (llGetInventoryType(DATA_SCRIPT_NAME) == INVENTORY_SCRIPT)
    {
        if (!llGetScriptState(DATA_SCRIPT_NAME))
            health = " | DATA SCRIPT STOPPED - reset it or re-wear the HUD";
    }
    // Round 63: label the scope ("Area: Parcel" - the bare
    // word read as noise). Capitalize so the value reads as a
    // labeled setting. (Radius capitalizes nothing - "Area:
    // 25m radius" - which is fine.)
    string area = scopeLabel();
    area = llGetSubString(llToUpper(area), 0, 0) + llDeleteSubString(area, 0, 0);
    return onoff + " | Area: " + area +
        " | Watch:" + (string)llGetListLength(gWatchList) +
        " | Build:" + BUILD_NUM + health;
}


sendHelp()
{
    // The help guide is a NOTECARD inside the HUD: zero script
    // memory, and the wearer keeps a copy to re-read any time.
    // llGiveInventory from a HUD shows the wearer the usual
    // "you received a notecard" notice; clicking it opens it.
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
    // Round 75: Core's 8-slot debug-log ring (SMH.cdbg0..7 +
    // SMH.cdbgNext) - the Core-side twin of the Data Script's
    // dbgLog. SMH.dlog (the Companion's Debug menu toggle)
    // gates every entry, so with the flag off the only cost is
    // one linkset read and a return. Entries use the same
    // "ts|Core|tag|fields" shape as the Data ring, so the
    // Companion's Dump Log prints both with one loop. Keep
    // CDBG_SLOTS in sync with the Companion's copy.
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

doWipe()
{
    // LSL has NO llLinksetDataDeleteByPrefix - reintroducing it
    // is a compile error ("name not defined within scope"). The
    // keys are few and known, so delete them plainly.
    llLinksetDataDelete(P + "owner");
    llLinksetDataDelete(P + "scope");
    llLinksetDataDelete(P + "range");
    llLinksetDataDelete(P + "enabled");
    llLinksetDataDelete(P + "watch");
    llLinksetDataDelete(P + "ping");
    llLinksetDataDelete(P + "lastpt");
    llLinksetDataDelete(P + "setup"); // so the Companion's welcome re-runs
    // Known-error log (the Data Script writes SMH.err0..9; the
    // Companion's Debug option prints them). Wipe = fresh log.
    // (10 = ERR_LOG_SLOTS in the Data/Companion scripts.)
    integer ei;
    for (ei = 0; ei < 10; ei++)
        llLinksetDataDelete(P + "err" + (string)ei);
    llLinksetDataDelete(P + "errNext");
    // Round 63: the freeze diagnostics are reported history
    // too - Wipe clears them as well (the field log showed a
    // stale "starved the HUD" tally and a stale coregap
    // surviving a Wipe). SMH.gap is belt-and-braces here (the
    // Data Script's own reset clears it).
    llLinksetDataDelete(P + "gap");
    llLinksetDataDelete(P + "coregap");
    llLinksetDataDelete(P + "starve");
    // Round 80: SMH.cap is saved state too - the Data Script's
    // tracking-cap publish must not outlive a Wipe (a handed-
    // over HUD would show a stale busy-context cap on its
    // first Summary). (The trace key's Wipe entry is cut with
    // the trace mode everywhere this round; the key itself may
    // still linger from an older build and is harmless - no
    // code reads it anymore.)
    llLinksetDataDelete(P + "cap");
    // Round 75: the debug-log rings and their toggle - Wipe
    // clears the story too, and dlog OFF matches Trace OFF
    // (a wiped HUD must not keep recording). (24 = DBG_SLOTS
    // and 8 = CDBG_SLOTS in the Data/Companion scripts.)
    integer di;
    for (di = 0; di < 24; di++)
        llLinksetDataDelete(P + "dbg" + (string)di);
    llLinksetDataDelete(P + "dbgNext");
    for (di = 0; di < 8; di++)
        llLinksetDataDelete(P + "cdbg" + (string)di);
    llLinksetDataDelete(P + "cdbgNext");
    // Round 78 amendment: the Registrar Script's ring clears
    // with the others (8 = its DBG_SLOTS; Core reads it on
    // Status Check while Debug Log is on).
    for (di = 0; di < 8; di++)
        llLinksetDataDelete(P + "rdbg" + (string)di);
    llLinksetDataDelete(P + "rdbgNext");
    // The WIPE entry itself is written AFTER the ring deletes
    // (into the now-empty ring) but while the dlog flag still
    // reads "1" - so a wipe leaves "WIPE, then BOOT, CBOOT"
    // as the start of the fresh story when the log was on.
    cDbg("WIPE", "fresh");
    llLinksetDataDelete(P + "dlog");
    // Round 45: the encounter ring is personal history - Wipe
    // clears it and the keep-days preference (default 30 back).
    for (ei = 0; ei < 50; ei++)
        llLinksetDataDelete(P + "enc" + (string)ei);
    llLinksetDataDelete(P + "encNext");
    llLinksetDataDelete(P + "encdays");
    // Reset the siblings so their mirrors, caches and any
    // half-finished fetch are as fresh as the datastore.
    // llResetOtherScript (wiki): reaches only scripts in THIS
    // prim; has NO effect on a script halted by a run-time
    // error (re-wear the HUD for that); a missing name would
    // shout on DEBUG_CHANNEL - hence the guards.
    if (llGetInventoryType(COMPANION_SCRIPT_NAME) == INVENTORY_SCRIPT)
        llResetOtherScript(COMPANION_SCRIPT_NAME);
    if (llGetInventoryType(DATA_SCRIPT_NAME) == INVENTORY_SCRIPT)
        llResetOtherScript(DATA_SCRIPT_NAME);
    if (llGetInventoryType(REGISTRAR_SCRIPT_NAME) == INVENTORY_SCRIPT)
        llResetOtherScript(REGISTRAR_SCRIPT_NAME); // round 78: the
        // listing script resets too; absent = skipped silently,
        // so a pre-r78 HUD still wipes clean.
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
    // Fresh boot on the defaults - the boot lines and one
    // arrival summary follow. MUST be the last call: the
    // current event exits immediately when this runs.
    llResetScript();
}

handleCmd(string cmd)
{
    // Menu commands from the Companion Script, plus SYNC requests
    // from either sibling. Parameterized commands are "head|arg".
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
            // The menu's Summary button: the Data Script prints
            // the one-line population census on demand.
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

// ============================================================
// DEFAULT STATE
// ============================================================
default
{
    state_entry()
    {
        // First line on purpose: separates "the compiled script
        // does not fit" (nothing prints at all) from a runtime
        // death during startup (this prints, then silence).
        llOwnerSay("Core boot (Build " + BUILD_NUM +
            "), memory: " + memPct(llGetFreeMemory()));
        // Round 75: the boot reading belongs in the debug ring
        // next to the Data Script's BOOT entry - the pair is
        // the baseline a Dump Log tells every later reading
        // against.
        cDbg("CBOOT", "free=" + (string)llGetFreeMemory());
        gOwner = llGetOwner();

        // Round 63: a reset is a deliberate fresh start - the
        // liveness gap record belongs to the PREVIOUS
        // incarnation (the same rule the Data Script applies
        // to SMH.gap and SMH.starve). A freeze that wakes
        // later never runs state_entry, so the record
        // survives exactly in the cases it is evidence for.
        llLinksetDataDelete(P + "coregap");

        // Publish the language map (round 58) before anything
        // else might need it: the Data Script reads it lazily,
        // once per unknown language code, and caches the result.
        // state_entry also runs on a fresh re-rez, where the
        // linkset datastore starts EMPTY - this write is what
        // restores the map there.
        llLinksetDataWrite(P + "langmap", LANG_MAP);
        loadSettings();
        gLinkPower = findLinkByName(BUTTON_POWER);
        if (gLinkPower == -1)
            gLinkPower = LINK_ROOT; // legacy fallback: assume root = power button
        gLinkHelp = findLinkByName(BUTTON_HELP);
        gLinkSound = findLinkByName(BUTTON_SOUND);
        gLinkMenu = findLinkByName(BUTTON_MENU);
        // Covers the fresh-script case (script starts while already
        // worn); attach() handles re-wears. Placement is
        // self-guarding (same point = no move), and it ignores
        // ground rezzes. Round 80: the reseat listener goes with
        // the placement call - the fixed owner-key-derived
        // channel, owner-filtered; the listen event itself
        // checks the word (an empty msg filter here lets the
        // event accept both typed forms; see the listen event).
        applyDefaultPlacement(FALSE);
        llListen(reseatChannel(), "", llGetOwner(), "");
        // Startup handshakes: the Companion answers with
        // "ping=ok" (text formatting available or not), the Data
        // Script likewise (detection available or not).
        llMessageLinked(LINK_SET, LM_LANG_ASK, "ping", "");
        llMessageLinked(LINK_SET, LM_DATA_ASK, "ping", "");
        // Round 56: the timer is also the liveness heartbeat -
        // always ticking, fast only while blinking. The grace
        // gives the Data Script time to boot after us and write
        // its first heartbeat.
        llSetTimerEvent(5);
        gStallGrace = llGetUnixTime() + 30;

        // The Data Script adopts the starting population silently
        // on its own first sweep - Core no longer holds baselines.
        updateButton();
        updateSoundButton();
        pushState();

        llOwnerSay("Opossum Labs Awareness HUD v" + HUD_VERSION + " ready. " + statusLine());
        // Round 80: the reseat command belongs in the boot log
        // once - the channel is owner-derived (stable across
        // sessions), so a wearer who needs it later can find
        // the number here or in the help notecard.
        llOwnerSay("If the HUD ever sits off-screen: type /" +
            (string)reseatChannel() + " reseat to bring it back.");
    }

    on_rez(integer start_param)
    {
        // Handles sale/transfer while running: reload everything for the
        // new owner (loadSettings clears the old owner's watch list).
        if (llGetOwner() != gOwner)
            llResetScript();
    }

    attach(key avatar)
    {
        // Placement is self-guarding: switching to a DIFFERENT HUD
        // point re-seats the panel, re-wearing the same point
        // keeps the wearer's position. The Data Script handles its
        // own re-baseline on re-attach (its attach event fires too).
        if (avatar != NULL_KEY)
            applyDefaultPlacement(FALSE);
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
        // Region/teleport re-baselining is handled by the Data
        // Script's own changed() event - it fires in every script
        // of the attachment, and the population lists live there.
    }

    timer()
    {
        integer now = llGetUnixTime();
        // Liveness heartbeat - the same recorder the Data Script
        // runs (round 55), now in Core too. The timer NEVER stops
        // (0.5 s while blinking, 5 s otherwise), so a 5+ minute
        // gap between ticks means the script engine was not
        // running THIS script: the region-crossing attachment
        // failure, a freeze, or a logout/detach. Recorded for
        // the Debug report, next to the Data Script's own gap:
        // EQUAL gaps = the sim stopped scheduling the prim (the
        // SL failure class); only one script's gap = a
        // single-script problem.
        if (gHbCore != 0 && now - gHbCore > 300)
        {
            llLinksetDataWrite(P + "coregap",
                (string)(now - gHbCore) + "|" + (string)now);
            // Round 75: the gap seconds go to the debug ring
            // too - next to the Data Script's GAP entry, the
            // pair tells "the prim froze" from "one script
            // froze" without a Status Check at the right
            // second.
            cDbg("CGAP", "dead=" + (string)(now - gHbCore) + "s");
        }
        // After our own wake (boot, or a gap: we were dead or
        // detached too), give the Data Script 30 s before its
        // heartbeat is trusted - its first pass may not have
        // fired yet.
        if (gHbCore == 0 || now - gHbCore > 300)
            gStallGrace = now + 30;
        gHbCore = now;

        // Data-stall detector. llGetScriptState cannot see a HUNG
        // script (one stuck inside an event still reports as
        // running); a stale published heartbeat can. NOTE: LSL
        // && does NOT short-circuit, so the inventory guard must
        // be a nested if, never a && in front of llGetScriptState
        // (a missing script name would shout on DEBUG_CHANNEL).
        // Armed only past the grace, and only while the script
        // claims to run - a halted one already warns on Status.
        // One warn per stall, one recovery line.
        if (now > gStallGrace &&
            llGetInventoryType(DATA_SCRIPT_NAME) == INVENTORY_SCRIPT)
        {
            if (llGetScriptState(DATA_SCRIPT_NAME))
            {
                integer hb = (integer)llLinksetDataRead(P + "hb");
                if (hb != 0 && now - hb > 120 && !gStalled)
                {
                    gStalled = TRUE;
                    notifyOwner("The Data Script looks stuck - it has not run a pass in over 2 minutes. Detection is paused; re-wear the HUD to fix it now.");
                    cDbg("STALL", "stale=" + (string)(now - hb) + "s");
                }
                else if (gStalled && (hb == 0 || now - hb <= 120))
                {
                    gStalled = FALSE;
                    notifyOwner("The Data Script is running again.");
                    cDbg("STALLOK", "hb=" + (string)hb);
                }
            }
        }

        // Blink the power button while the Data Script is fetching
        // account data (List All or the arrival census). The fetch
        // itself reports BUSY|1/BUSY|0 via LM_EVENT.
        if (gBusy <= 0)
            return; // nothing to blink; the heartbeat keeps the
                    // timer alive by design now
        // Never blink FOREVER: if the Data Script halts mid-fetch,
        // BUSY|0 never arrives. Stop after BUSY_TIMEOUT seconds (a
        // normal scan finishes well inside that window) and restore
        // the steady color.
        if (now - gBusyStart > BUSY_TIMEOUT)
        {
            gBusy = 0;
            llSetTimerEvent(5); // heartbeat cadence; never fully off
            gBlinkOn = FALSE;
            updateButton();
            return;
        }
        gBlinkOn = !gBlinkOn;
        if (gBlinkOn)
            llSetLinkPrimitiveParamsFast(gLinkPower,
                [PRIM_COLOR, ALL_SIDES, COLOR_BUSY, 1.0]);
        else
            llSetLinkPrimitiveParamsFast(gLinkPower,
                [PRIM_COLOR, ALL_SIDES, COLOR_ON, 1.0]);
    }

    listen(integer channel, string name, key id, string msg)
    {
        // Round 80: the "reseat" recovery command. The listener
        // was registered with the owner id as the filter, so
        // this only ever fires for the OWNER on the private
        // channel. The command is typed "/<channel> reseat"
        // (channel, space, word - the documented viewer form;
        // a colon after the channel number would be delivered
        // as part of the message, so the event also accepts
        // ":reseat" to cover that typing style too) - the one
        // way back when the panel sits somewhere the screen
        // no longer shows (LSL cannot detect a window resize;
        // there is no event and no dimension API).
        // FORCE = TRUE applies the seat even at the same
        // attach point - the lastpt guard is exactly what
        // must be bypassed here.
        if (msg != "reseat" && msg != ":reseat")
            return;
        applyDefaultPlacement(TRUE);
        llOwnerSay("HUD re-seated to its default screen position. " +
            "Nudge it in the viewer if you want it elsewhere.");
    }

    touch_start(integer total_number)
    {
        // HUDs can only be clicked by their wearer, but check anyway.
        if (llDetectedKey(0) != gOwner)
            return;
        // Buttons are matched by prim name (links resolved at
        // startup); this works because the script sits in the
        // root prim and child prims without their own touch
        // handler pass touches up to the root.
        integer btn = llDetectedLinkNumber(0);
        // (Round 80: the touch trace narration is cut with the
        // trace mode everywhere.)
        if (btn == gLinkPower)
            setPower(!gEnabled);
        else if (btn == gLinkHelp)
            sendHelp();
        else if (btn == gLinkSound)
            setPing();
        else if (btn == gLinkMenu)
            llMessageLinked(LINK_SET, LM_MENU_OPEN, "", ""); // only the named Menu Button; menus live in the Companion
        // Any other prim (the panel body etc.) is deliberately inert.
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        // Status Check: report this script's free memory; the
        // Companion formats and prints the labeled lines.
        if (num == LM_MEM_ASK)
        {
            // Round 80 (pre-field amendment): the reply carries
            // this script's build number, like its siblings' -
            // the Status Check memory lines then show WHICH
            // build each script runs.
            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Core Script|" + (string)llGetFreeMemory() + "|" +
                BUILD_NUM, "");
            // Round 78: the Registrar Script's 8-slot ring
            // (SMH.rdbg0..7) is read HERE, not by the
            // Companion - its Dump Log prints only the Data
            // and Core rings and the Companion stays frozen
            // (94% used), and a HALTED writer's story must
            // survive the halt (the r75 doctrine): with Debug
            // Log on, Status Check appends the Registrar's
            // recorded events oldest-first, and a dead
            // Registrar is itself diagnosed by its missing
            // memory line in this same report. Same loop shape
            // as the Companion's Dump Log.
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

        // Menu commands from the Companion Script (and SYNC from
        // either sibling).
        if (num == LM_UI_CMD)
        {
            handleCmd(str);
            return;
        }

        // Finished arrival lookup from the Data Script.
        if (num == LM_DATA_TELL)
        {
            if (str == "ping=ok")
            {
                gHaveData = TRUE;
                return;
            }
            // KeepNulls: an empty name field must survive the split.
            // (Field 0 was the mode; the Data Script only sends
            // finished arrivals now, so it is simply skipped.)
            list f = llParseStringKeepNulls(str, ["|"], []);
            key a = (key)llList2String(f, 1);
            string name = llList2String(f, 2);
            integer age = (integer)llList2String(f, 3);
            string pay = llList2String(f, 4);
            string lang = llList2String(f, 5);
            announceArrival(a, name, age, pay, lang);
            return;
        }

        // Detection events from the Data Script's sweep.
        if (num == LM_EVENT)
        {
            list f = llParseStringKeepNulls(str, ["|"], []);
            string kind = llList2String(f, 0);
            if (kind == "OUT")
            {
                // Left scope; the name is a viewer link composed
                // from the key (Data Script), the watch flag is
                // Core's to add.
                key a = (key)llList2String(f, 1);
                // Round 80 type-trap fix: (string) needle - see
                // addWatch above; the LEFT line's [WATCHED] tag
                // never rendered with the old key needle.
                annSend("L|" + scopeLabel() + "|" + llList2String(f, 2) + "|" +
                    (string)(llListFindList(gWatchList, [(string)a]) != -1), a);
            }
            else if (kind == "WIN")
            {
                playPing();
                // The 3rd field is the avatar key (encounter log).
                annSend("W|" + llList2String(f, 1) + "|1|" + llList2String(f, 2), "");
            }
            else if (kind == "WFOUND")
            {
                // Watched avatar already in the region when we
                // arrived (the Data Script's arrival seed).
                playPing();
                annSend("W|" + llList2String(f, 1) + "|2|" + llList2String(f, 2), "");
            }
            else if (kind == "BUSY")
            {
                // Data Script: a scan or the census started/ended.
                if (llList2String(f, 1) == "1")
                    setBusy(1);
                else
                    setBusy(-1);
            }
            else if (kind == "WOUT")
                annSend("W|" + llList2String(f, 1) + "|0", "");
            return;
        }

        // Handshake answer from the Companion Script.
        if (num != LM_LANG_TELL)
            return;
        if (str == "ping=ok")
            gHaveLang = TRUE;
    }
}
