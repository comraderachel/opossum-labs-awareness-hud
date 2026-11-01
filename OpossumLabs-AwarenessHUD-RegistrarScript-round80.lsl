
// ROUND 80 (2026-11-01) - paste the whole script over the old
// one. PAIRED with the round-80 Data, Companion AND Core
// Scripts (all four change this round) and the round-80 help
// notecard. This round: the watch-count type-trap fix (both
// llListFindList casts), the scan guard REPRICED population-
// style (boot-1500 refused EMPTY regions - the r79 boot is
// 10.8K, below its own old guard at rest), the census fit-cap
// ("and N more (low memory)" instead of silent truncation),
// OFF = true standby (Summary / List All / Watch+ refuse while
// the power is off; Status, Debug, watch-list edits and
// Export/Import stay available), the busy-context lines built
// from the new SMH.cap publish, the memory-aware arrival-ask
// cap, watch-list Export/Import two-unit radio transfer, the
// trace mode cut, and the build stamp.
// ============================================================
// OPOSSUM LABS AWARENESS HUD - Registrar Script (any prim)
// ------------------------------------------------------------
// The fourth script, born in round 78 of the 4th-script
// split: the LISTING side moves out of the Data Script into
// a fresh 64 KB Mono budget. The Data Script's compiled
// footprint kept growing (11,958 free at r68, 4.4-4.7 K at
// r74, 1476 at r76 - under the minimum pass price, so
// detection tripped in EVERY region), and the listing side
// is the worst memory citizen on that budget: List All
// holds a region fetch plus wave queues plus a born/pay/
// language pipeline, and Watch+ holds the fetch again for
// its top-10 sort. Moved here, the SAME code runs against a
// nearly-empty 64 KB: the region fetch (~10 KB at the
// wiki's 100-agent cap), the scan waves and the request
// rows all live in THIS script's heap, and a Stack-Heap
// Collision here (which the honest guards below should
// still prevent) can no longer take detection down with
// it - the r15 doctrine with its mirror image: the work
// goes where the memory is, AND the crash cannot kill the
// core function.
//
// WHAT THIS SCRIPT OWNS (round 79):
//   - List All: fetch the region list, apply the CURRENT
//     scope filter (mirrored live from Core's LM_UI_STATE
//     broadcasts), and list the first 20 people in scope
//     with age / payment / language / flags / distance,
//     resolved through its OWN dataserver pipeline. Since
//     round 79 the listing relay lives HERE too: the lines
//     are formatted and printed from THIS script's budget
//     (the Companion no longer accumulates a running
//     listing - its 22:46 relay collision on a 15-row list
//     in a 66-avatar region is r79 item 2's evidence).
//   - Watch+ (nearest): the incremental top-10 ranking AND
//     the pick dialog, Manual Add and Back - the whole flow
//     runs on this script's own random channel since round
//     79 (the Companion's pick build collided twice at
//     ~3.3 K, above its own 3422 boot canary, so no safe
//     floor exists there - r79 item 3).
//   - The ARRIVAL LOOKUPS, handed over by the Data Script's
//     sweep as "LOOK|key" (r79 item 1's second half): born
//     date + payment + language for every new face, one
//     LM_DATA_TELL to Core per arrival - the same wire the
//     Data Script used, so Core is unchanged. The Data
//     Script now runs NO dataserver requests at all.
//   - The CENSUS (r79 item 1): the arrival summary on
//     region adopt and the menu's Summary button both fetch
//     the current scope in THIS budget. Semantic change,
//     disclosed: the summary counts the CURRENT scope (up
//     to 60, the old POP_CAP honesty rule) instead of the
//     tracked pad, and works in ANY region - including
//     regions where detection is honestly paused, exactly
//     like List All since round 78. "New accounts: not
//     counted" (the "?" line) now means THIS script's
//     priced budget said so, not the Data Script's.
//   - Its own honest memory guards (round 80 repricing): the
//     scan guard refuses below (live population x 102) +
//     3500 - POPULATION-priced, the same arithmetic as the
//     nearest guard, because a listing's real cost scales
//     with agents, not with boot distance (the round-79
//     boot-1500 form refused even EMPTY regions once this
//     script's boot fell to 10.8 K and its rest sat below
//     its own guard) - both guards NUDGE Mono's lazy
//     collector first since round 79 (item 4): the field
//     ring holds two RREFUSE entries at 27072 and 24598 free
//     against a pinned pre-collection reading, the same lie
//     the Data Script's r74/r76 probe learned to nudge
//     through. Round 80 also: OFF is a true standby (the
//     Summary / List All / Watch+ entries refuse with a
//     reminder while the power is off), and the watch list
//     migrates between units by the Export / Import radio
//     (owner-key-derived channel, 60-second import window).
//
// WHAT STAYS IN THE DATA SCRIPT (its r79 end state): the 2 s
// detection sweep, the tracked-key pad, the valve / ladder /
// probe, the watch pad and the WFOUND/WIN/WOUT/WATCHED
// announce bookkeeping, the dilation watch and the liveness
// recorders. The ARRIVED / OUT / WIN / WOUT lines are still
// Data's to detect - but the account data behind every
// ARRIVED line is looked up HERE now.
//
// SEMANTIC CHANGE, deliberate and disclosed: List All used
// to list the sweep's TRACKED population (narrowed to as
// few as 10 in a tight region, and only as fresh as one
// sweep). It now lists the CURRENT SCOPE - up to 20 people
// who are in scope RIGHT NOW - independent of the memory
// state that narrows tracking. The listing button answers
// the question "who is here" instead of "who is the sweep
// currently tracking", and it works in any region,
// including regions where detection is honestly paused.
//
// ROUND 78 AMENDMENT (same round, before any field paste) -
// THE DEBUGGING SUITE. Trace: this script fully honors
// SMH.trace now (live narration of listing starts, refusals
// with the numbers, aborts and drops). Debug Log: this script
// keeps its own 8-slot ring (SMH.rdbg0..7 + SMH.rdbgNext) on
// the r77 diet - five short, diagnosable sites (RBOOT /
// RREFUSE / RABORT / RPURGE / RTIMEOUT), each string build
// priced, gated by the same SMH.dlog flag. The ring's READER
// is the CORE SCRIPT: it prints the Registrar's story on
// Status Check while Debug Log is on, because the
// Companion's Dump Log prints only the Data and Core rings
// and the Companion stays frozen at 94% (zero changes there
// is a round-78 design rule) - and a HALTED writer's story
// must survive the halt (the r75 doctrine): a dead Registrar
// shows up as its MISSING memory line in the same report
// while its recorded story still prints. Errors: logErr
// writes the SHARED error ring with this script's own
// "|Registrar|" source label, so Status Check's error list
// tells whose error it was. Liveness: no heartbeat - this
// script is event-driven (menu presses), an idle interval is
// normal, and the missing Status Check memory line IS the
// halt diagnosis.
// A third catch, found by the first paste attempt itself:
// the 15 s flush line called llGetListInteger - NOT an LSL
// function (llList2Integer is the real name; the stale
// purge loop two lines up had it right). The balance
// checker counts delimiters, not names, so the typo passed
// - every round's check now ends with a full ll-name audit
// against the real API.
//
// Protocol (numbers MUST match Core/Companion/Data):
//   Core -> here  : LM_SWEEP_ASK ("SCAN" / "REBASE" /
//                   "CENSUS" - the Summary button, answered
//                   HERE since round 79), via LINK_SET
//                   broadcast.
//   Data -> here  : LM_SWEEP_ASK ("LOOK|key" once per new
//                   arrival - the r79 arrival-lookup
//                   handoff; "CENSUS|A" when its sweep
//                   adopts a region; "RESET" on travel -
//                   rows from the region we just left must
//                   never flush after the warp)
//   Companion -> here : LM_SWEEP_ASK ("NEAR" - Watch+)
//   Core -> here  : LM_UI_STATE ("enabled|scope|range"),
//                   LM_WATCH_LIST (comma-separated keys)
//   here -> Companion : LM_SAY ("C|scope|total|new|bots|
//                   watched|src" the census line, "AE|name|
//                   key" once per census-counted scripted
//                   agent, "N|code|params" system notes
//                   (SCANBUSY / SCANMEM / SCANEMPTY /
//                   SUMSTOCK), and "NR|ok" - the one-byte
//                   Watch+ handshake that stands the
//                   Companion's missing-Registrar safety
//                   net down). The LISTING LINES themselves
//                   never leave this script anymore (they
//                   print straight to owner chat from this
//                   budget - the relay move, r79 item 2).
//   here -> Core  : LM_DATA_TELL ("0|key|name|age|pay|lang"
//                   once per finished ARRIVAL lookup - the
//                   exact wire the Data Script used, so
//                   Core announces unchanged), LM_UI_CMD
//                   ("ADD|key" from the Watch+ picker and
//                   Manual Add), LM_EVENT ("BUSY|1"/
//                   "BUSY|0" -> blink), LM_MENU_OPEN
//                   ("Back" from the picker re-opens the
//                   Companion's main menu)
//   any -> all   : LM_MEM_ASK / LM_MEM_TELL (Status Check)
//   own listen   : a random deep-negative per-boot channel
//                   (the round-25 pattern) carries this
//                   script's own pick-dialog buttons and
//                   Manual Add's text box.
//
// Drop into the HUD linkset (any prim). OPTIONAL but
// recommended: without it List All and Watch+ fall back to
// the Data Script's memory guards, which refuse in tight
// regions; detection itself works without it.
//
// VERSION: round 80 (2026-11-01): EIGHT ITEMS, ALL
// FIELD-DRIVEN. (1) WATCH-COUNT FIX: the gWatch mirror is
// STRINGS (llParseString2List of Core's CSV) but both use
// sites passed a KEY needle - llListFindList matches types
// strictly, so the [WATCHED] listing tag and the census
// "On watch list" count ALWAYS read zero. Both needles are
// cast to (string) now. (2) SCAN GUARD REPRICED: the old
// boot-1500 guard (floored 2500) was calibrated on the 29 K
// r78 boot; the r79 boot is ~10.8 K and the in-session rest
// sits BELOW it, so even EMPTY regions were refused (four
// field RREFUSEs at 8.4-9 K free). A listing's real cost
// scales with POPULATION, not boot distance: the guard is
// now live-population x 102 + 3500, the same arithmetic as
// the nearest guard - an empty region needs ~3.5 K (never
// refused at rest), a 50-avatar listing refuses honestly
// when it genuinely does not fit, and the refusal wording
// points at Summary (the busy-region context tool, which
// survives any listing refusal). gBootFree stays as the
// boot canary only. (3) CENSUS FIT-CAP: startCensus counts
// at most (free - 2500) / 156 people (never past the 60
// cap), and the summary honestly says "and N more (low
// memory)" when it trimmed - graceful, not a refusal; the
// "C" payload grows two fields (more, cap) for it and for
// the busy context. (4) OFF = STANDBY (Rachel's rule,
// supersedes r79's paused-region semantics for the POWER
// state): while the detector is off, Summary / List All /
// Watch+ refuse with a one-line reminder; Status, Debug,
// Manual Add, Watch- removals, the Watch List view and
// Export/Import keep working. The adopt census cannot fire
// while OFF anyway (the Data Script only sweeps when ON).
// (5) BUSY CONTEXT ON DEMAND: the Data Script publishes
// SMH.cap on cap change; the List All preamble and the
// Summary line append "detection tracking the first N" so
// the busy-region context appears where it is asked for
// instead of on a repeating timer. (6) ARRIVAL-ASK CAP:
// the fixed 36-element (6-row) queue bound is now
// memory-aware - clamp((free - 4500) / 160, 8, 36) rows -
// so a busy arrival flood stacks at most what the heap can
// pay, and the overflow still sends the partial-data line
// the timeout flush always produced. (7) EXPORT / IMPORT:
// the watch list migrates between two HUDs by radio -
// Export prints the keys to owner chat AND announces the
// CSV on an owner-key-derived deep-negative channel;
// Import arms a 60-second listener on the same channel and
// feeds each key to Core's existing "ADD|key" handler
// (dedupe / cap-at-20 / save included; ZERO Core changes).
// Both units must share an owner (the channel derives from
// llGetOwner, and the import listener only accepts objects
// whose llGetOwnerKey matches). PLUS: the trace mode is
// cut everywhere (the debug rings won), and every boot
// line, Core's Status line and the Status Check memory
// line gain the Build:NNNNNNNNN stamp (pre-field
// amendment: the LM_MEM_TELL reply carries this script's
// OWN build as a third field - the Companion prints it on
// the labeled line, so a mixed-round unit shows different
// builds on its lines). SECOND PRE-FIELD AMENDMENT (found
// by Rachel's paste - the first COMPILE-BLOCKING bug the
// audit battery ever missed): the timer's import-window
// check used "now" ABOVE its declaration ("name not
// defined"); "integer now = llGetUnixTime()" now opens the
// timer event and the later duplicate declaration is gone.
// The balance and ll-name audits cannot see undeclared
// variables - a use-before-declaration linter joins them as
// a standing round step. THIRD PRE-FIELD AMENDMENT (found
// decoding Rachel's first fit-cap field line - "1 avatars |
// ... and 39 more" in a ~40-avatar region): the census's
// bot and watch counting loop ran over the TRIMMED list,
// so a heavy trim made "Scripted agents" and "On watch
// list" see only the first fit people - a watched resident
// among the uncounted read as 0, a false negative for the
// round's own type-trap headline test. The count now scans
// the FULL list before the trim (it retains nothing - two
// counters - so it costs no census rows); the born-date
// asks stay trimmed to the fit. Watch DETECTION was never
// capped - the Data script's WATCHED lines still cover the
// whole region.
//
// VERSION: round 79 (2026-10-31): THE 4TH-SCRIPT SPLIT,
// PART 2 - THE ARCHITECTURAL FINISH. The five planned items,
// all landed in one paste-paired round: (1) the census
// cluster (startCensus / sendCensus / purgeCensusRows / the
// counters and deadline flush) and the ARRIVAL-LOOKUP
// pipeline move in from the Data Script - its 22:44 SHC at
// free=2420 in a 64-avatar region (the deepest reading ever
// observed; the valve paused honestly and the residual
// census/straggler churn still collided) is the crash
// evidence; (2) the LISTING RELAY moves in from the
// Companion - its 22:46 SHC during a 15-row listing relay
// in a 66-avatar region is the second evidence line, and a
// halted Companion can no longer take a running listing
// with it; (3) the WATCH+ PICK DIALOG builds here (the
// Companion's build collided twice above its own boot
// canary - no safe floor existed there), on this script's
// own listen channel, Manual Add included, and the
// Companion keeps only its 10-second missing-Registrar
// safety net plus the gMode 1 Manual Add that net offers;
// (4) BOTH MEMORY GUARDS nudge Mono's lazy collector before
// they read the heap (two field RREFUSE entries at pinned
// readings, 27072 and 24598 against the 27582 guard); (5)
// the canary before/after discipline - this script grows
// (record the new boot number; the r78 one was 29082), the
// Data Script shrinks (r78 boot 12304 - the number that
// sized this round; the census + pipeline bytecode leaving
// should lift it past the 13,220 crossover the ledger
// priced). THE ABORT WART is fixed the same round: the
// eighth field follow-up's post-abort stragglers (a second
// "listing complete", late rows printing in the next
// region) existed because an aborted listing left its rows
// in the pipeline for the 15 s flush - every abort path
// now purges the pipeline wholesale (clearPipeline, the
// old Data Script's own travel rule moved here with the
// rows), and the dataserver replies arrive as ignorable
// strays. THE ONE-WAY UPGRADE RULE: a scan may claim an
// in-flight arrival row (the r12 semantic - the S line
// covers them), but an arrival NEVER downgrades a scan
// row - the scan's completion is already owed, and a
// downgraded row would leak gScanCount and wedge the
// "already running" guard forever. Also this round: the
// boot gains a random pick channel + listener, a SYNC ask
// (its mirrors used to stay empty until Core's next push
// after a mid-session reset), a CHANGED_OWNER reset (every
// sibling script's rule - in-flight rows die with the old
// owner) and the orphaned-BUSY rebalance the Data Script
// always had. ZERO changes to Core this round - the
// arrival TELL rides the wire Core already handles.
//
// VERSION: round 78 (2026-10-31): BIRTH. The scan cluster
// (startScan / pumpScan / resetScan / the scan half of
// sendEntry / entryFlags), the dataserver pipeline copy
// (askAgent / dataserver / the timeout flush), the scope
// filter and label (mirrored from the Data Script), and
// sendNearest all move here, adapted to a scan-only
// pipeline: stride-5 rows [key, age, pay, lang, added]
// with no mode field, no arrival branch, no census rows.
// Data sheds the same code in the same round (paired
// edits - nothing answers SCAN or NEAR twice). Core gains
// only the Wipe reset for this script; the Companion needs
// ZERO changes (this script speaks the exact LM_SAY
// protocol Data used to speak). The census and the
// arrival-lookup handoff are round 79.

string P = "SMH.";        // linkset-data key prefix (shared)
string BUILD_NUM = "110126080"; // round 80: the build stamp
                                // (MMDDYY 110126 + zero-padded round
                                // 080) - printed on every boot line
                                // and on Core's Status line (kept
                                // identical in all four scripts;
                                // bump the round digits every round)

// ---------- protocol (mirrors Core/Data exactly) ----------
integer LM_SAY = 19027;
integer LM_MENU_OPEN = 19028; // round 79: "Back" from the pick
                              // dialog re-opens the Companion's
                              // main menu through the same
                              // message the Menu Button uses
integer LM_UI_STATE = 19029;
integer LM_UI_CMD = 19030;   // round 79: this script's picker
                             // sends "ADD|key" to Core, the same
                             // command the Companion's Manual Add
                             // sends
integer LM_WATCH_LIST = 19031; // AMENDMENT CATCH: the first r78
                               // draft used this constant in
                               // link_message but never declared
                               // it - a COMPILE BLOCKER caught
                               // while adding the debug suite;
                               // 19031 matches Core exactly
integer LM_DATA_TELL = 19033; // round 79: finished ARRIVAL
                              // lookups tell Core on the exact
                              // wire the Data Script used ("0|"
                              // key|name|age|pay|lang) - Core
                              // announces unchanged
integer LM_SWEEP_ASK = 19034;
integer LM_EVENT = 19035;
integer LM_MEM_ASK = 19036;
integer LM_MEM_TELL = 19037; // "name|freeBytes|build" (the Companion
                             // prints the debug lines)

integer SCAN_LIST_CAP = 20;     // scan listing cap (the old
                                // MAX_TRACKED_AGENTS; keep in
                                // sync with the Data Script's
                                // tracked-side semantics only
                                // in spirit - this is a LISTING
                                // cap, independent of tracking)
integer SCAN_BATCH = 3;         // scan wave size (round 65
                                // sizing, unchanged)
integer MAX_PENDING_REQUESTS = 30; // in-flight llRequestAgentData
                                // ROW cap (stride-3 rows). The r65
                                // sizing carried intact: census 24
                                // X-rows + one 3-agent scan wave =
                                // 30, plus arrival rows in the
                                // slack a census leaves
integer PENDING_TIMEOUT = 15;   // give up waiting for dataserver
integer STALE_DROP = 120;      // a queued row this old predates
                                // the session - drop, never announce
integer CENSUS_ASK_MAX = 24;   // born-date lookups per census cap
                                // (moved from the Data Script with
                                // the census in round 79; each X
                                // row ~260 B)
integer CENSUS_LIST_CAP = 60;  // the census counts at most this
                                // many in-scope people - the old
                                // POP_CAP honesty rule, moved here
                                // with the census (summary totals
                                // truncate past it, same as ever)
integer ERR_LOG_SLOTS = 10;    // known-error ring size (SMH.err0..9)
                                // - keep in sync with the copies in
                                // Data and the Companion
integer DBG_SLOTS = 8;          // this script's debug-log ring size
                                // (SMH.rdbg0..7, Core-sized). The
                                // reader is the CORE Script (Status
                                // Check while Debug Log is on); keep
                                // in sync with Core's reader copy
integer SCOPE_FETCH_CAP = 100; // llGetAgentList's own wiki cap -
                                // the filter may walk the whole
                                // fetch; this budget can afford it
string NUDGE_CSV = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
string NUDGE_MINI = "1,1,1,1,1,1,1,1,1,1";
                                // round 79 (item 4): the GC nudge
                                // constants, copied from the Data
                                // Script's r74/r76 probe - three
                                // short-lived parses force Mono's
                                // lazy collector to run before a
                                // guard reads the heap

// ---------- mirrored state (broadcasts from Core) ----------
integer gScope;    // 0 region / 1 radius / 2 parcel (LM_UI_STATE)
integer gRange;    // radius scope meters (LM_UI_STATE)
integer gEnabled;  // power state mirror (LM_UI_STATE)
integer gHaveState; // FALSE until the first LM_UI_STATE arrives
list gWatch;       // watch-list key mirror (LM_WATCH_LIST)

// ---------- pipeline state (this script's own) ----------
list gPending;     // stride 6: key, age, pay, lang, kind, added
                   // ("S" scan rows for List All, "A" arrival
                   // rows handed over by the Data Script's sweep
                   // since round 79 - the mode-field stride the
                   // pipeline had back when it lived in Data)
list gRequests;    // stride 3: reqid, agent, "B" born / "P" pay /
                   // "X" census born (the census moved in with
                   // its own row kind, round 79)
list gLangCache;   // stride 2: code -> full name, once resolved
list gScanQueue;    // keys still to scan (keys only: cheap)
integer gScanNext;  // index of the next queue key to start
integer gScanLeft;  // completions owed by the current wave
integer gScanCount; // completions owed overall (0 = done)
integer gPumping;   // pumpScan re-entrancy guard (round 71)
integer gBootFree;  // state_entry free-memory reading; the
                    // scan guard below derives from it (the
                    // round-74 self-calibration doctrine)

// ---------- listing relay state (moved from the Companion,
// round 79 item 2 - a halted Companion must not take a
// running listing with it, and the relay churn was the 22:46
// crash) ----------
string gScanOut = "";   // accumulating listing text
integer gScanLines = 0; // lines accumulated since last flush

// ---------- census state (moved from the Data Script, round
// 79 item 1 - the born asks that drove its deepest crash) --
integer gCensusTotal;  // people in scope when the census started
integer gCensusLeft;   // born replies still owed (0 = none)
integer gCensusNew;    // accounts under 7 days (-1 = skipped)
integer gCensusBots;   // scripted agents in scope
integer gCensusWatched;// watch-list members in scope
integer gCensusDeadline; // give up and summarize at this time
integer gCensusMore;   // round 80: people the fit-cap trimmed off
                       // the count ("and N more (low memory)")
string gCensusSrc = "A"; // "A" arrival adopt / "M" Summary button

// ---------- Watch+ picker state (round 79 item 3: the whole
// flow runs here now) ----------
list gPickKeys;      // the keys behind the pick dialog's
                     // numbered buttons, in rank order
integer gChannel = -1; // random per-boot dialog channel (the
                     // round-25 pattern: a listener must
                     // register the exact number, so no
                     // precomputation is possible)
integer gImpHandle; // round 80: the IMPORT listener's handle
integer gImpDeadline; // round 80: unix time the import window
                     // ends (0 = not armed)

integer ownerChannel()
{
    // Round 80: the watch-list TRANSFER channel - deterministic
    // and derived from the OWNER KEY, so both HUD units compute
    // the same deep-negative number while nobody else lands on
    // it. Avatars cannot type on negative channels at all, so
    // only scripts ever speak here, and the import listener
    // only accepts objects whose llGetOwnerKey matches.
    return -1000000000 -
        (integer)("0x" + llGetSubString((string)llGetOwner(), 0, 6));
}

doExport()
{
    // Round 80: watch-list migration, SENDING side. The keys
    // print to owner chat (copyable by hand into Manual Add)
    // AND announce as a CSV on the transfer channel - a second
    // HUD with the SAME owner catches them with Import armed.
    // Works while the detector is off: it is configuration,
    // not detection.
    integer n = llGetListLength(gWatch);
    if (n == 0)
    {
        llOwnerSay("The watch list is empty - nothing to export.");
        return;
    }
    string csv = llDumpList2String(gWatch, ",");
    // 20 keys x 37 bytes = ~759 - one owner-chat line, well
    // under llOwnerSay's 1024-byte cap.
    llOwnerSay("Watch list export (" + (string)n + " keys): " + csv);
    llRegionSay(ownerChannel(), "SMHEXPORT|" + csv);
    llOwnerSay("Export sent - press Import on the other HUD (same owner) within 60 seconds.");
}

doImport()
{
    // Round 80: watch-list migration, RECEIVING side. Arms a
    // 60-second listener on the transfer channel; a same-owner
    // HUD's "SMHEXPORT|" CSV feeds each key to Core's EXISTING
    // "ADD|key" handler - dedupe, the cap of 20 and the save
    // are all Core's, so this needs ZERO Core changes. Re-
    // pressing Import restarts the window. Works while the
    // detector is off (configuration, not detection).
    if (gImpDeadline != 0)
        llListenRemove(gImpHandle);
    gImpHandle = llListen(ownerChannel(), "", NULL_KEY, "");
    gImpDeadline = llGetUnixTime() + 60;
    llOwnerSay("Import listening for 60 seconds - press Export on the other HUD now. Both HUDs must have the same owner.");
}

string memPct(integer freeBytes)
{
    // Mono scripts get a 65536-byte budget; show the percentage
    // USED next to the free number wherever memory is listed.
    return (string)freeBytes + " free (" +
        (string)((100 * (65536 - freeBytes)) / 65536) + "% used)";
}

logErr(string text)
{
    // The known-error ring, shared through linkset data with
    // the Data Script (same SMH.err0..9 slots, same cursor).
    // The source label differs so the Debug report can tell
    // which script hit the error. Keep ERR_LOG_SLOTS in sync
    // with the other scripts' copies.
    integer i = (integer)llLinksetDataRead(P + "errNext");
    if (i < 0 || i >= ERR_LOG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);
    // llGetTimestamp is "YYYY-MM-DDTHH:MM:SS..." - swap the T
    // for a space so the Debug line reads cleanly.
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
    // Round 78 amendment: this script's 8-slot debug-log ring
    // (SMH.rdbg0..7 + SMH.rdbgNext), the r75 pattern on the
    // r77 diet (five short, diagnosable sites - every string
    // build costs bytecode). SMH.dlog gates EVERY entry at the
    // top, the same live-read pattern as SMH.trace: with the
    // flag off the only cost is one linkset read and a return.
    // Entries use logErr's exact "ts|Registrar|" shape plus a
    // tag. The READER is the Core Script (Status Check while
    // Debug Log is on) - a HALTED writer's story must survive
    // the halt, so the reader must live in ANOTHER script;
    // the Companion's Dump Log prints only the Data and Core
    // rings and the Companion stays frozen. Wipe clears these
    // keys with the other rings.
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
    // Names in chat lines are VIEWER-RESOLVED LINKS composed
    // from the key: the viewer renders the URI as a clickable
    // CURRENT display name and opens the profile - immune to
    // every failure mode of script-side lookups. Copied from
    // the Data Script; the tracking lists stay KEYS-ONLY here
    // for the same reason.
    return "secondlife:///app/agent/" + (string)id + "/displayname";
}

integer strBytes(string s)
{
    // LSL strings are byte strings, and display names can contain
    // multi-byte UTF-8 - llDialog buttons cap at 24 BYTES, and the
    // listing flush caps at 900, so a plain llStringLength check
    // is not enough. base64 encodes 3 bytes per 4 characters; the
    // trailing "=" padding rounds up, so subtract it. (Moved from
    // the Companion with the relay in round 79.)
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
    // Short forms: the field already says "Pay:", so repeating
    // "Payment" was redundant. The raw numeric pay value (not
    // this text) is what the flag logic checks. (The
    // Companion's own copy stays there for ARRIVED lines; the
    // listing lines render here since the relay moved.)
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
    // Bit 1 (automated) is rendered at the START of the line as
    // "AUTOMATED AGENT:" (entryText) instead of a trailing tag.
    // Bit 4 (no payment info) is not rendered either: the Pay:
    // field in entryText already says it.
    string s = "";
    if (f & 2)
        s += " [NEW ACCOUNT]";
    if (f & 8)
        s += " [WATCHED]";
    return s;
}

string ageText(string age)
{
    // Age in days -> readable: past the first year "2y 34d",
    // within it "123d", unknown "?" (the Companion's helper,
    // duplicated here for the listing lines - LSL cannot share
    // code between scripts).
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
    // One listing line, composed exactly as the Companion
    // composed it (the wearer sees no difference in the
    // listing's shape) - but on THIS script's budget since the
    // relay moved in round 79. The name arrives as a viewer
    // display-name link - pass it through VERBATIM.
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
    // DIALOG BUTTON label ONLY (the Watch+ pick, round 79).
    // llDialog buttons cap at 24 BYTES, so use the DISPLAY name
    // trimmed to 20 bytes + "~" - the leading number is the
    // selector, so truncation is safe. NEVER feed this a name
    // STRING: it is a key-based lookup, and chat lines pass
    // their name field (a viewer link) through VERBATIM. (The
    // Companion's copy stays there for the Watch- remove
    // dialog.)
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

gcNudge()
{
    // Round 79 (item 4): three short-lived parses of a fixed
    // CSV constant - ~1 K of allocation pressure each when the
    // heap can afford it, a ~350 B mini tier when it cannot.
    // An allocation is what forces Mono's lazy collector to
    // run, and llGetFreeMemory under-reports until it does -
    // the r74/r76 Data Script probe pattern, now applied
    // before BOTH of this script's memory guards (the field
    // ring holds two false RREFUSE refusals at pinned
    // readings). Constant-size, population-independent.
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
    // Approximate age in days (30-day months; good enough for
    // flags). NOTE: llGetDate() is "YYYY-MM-DD" WITH dash
    // separators, exactly like the born date - the parse offsets
    // below MUST match (copied verbatim from the Data Script,
    // where a mismatch once understated every age by ~357 days).
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
        // A "future" born date can only be the DATA_BORN vs UTC
        // clock edge on a day-old account, or a corrupt reply.
        // Clamp to 0 and log it so anomalies stay visible.
        logErr("born date " + bornDate + " parsed as a negative age (" +
            (string)age + "d) - clamped to 0d");
        return 0;
    }
    return age;
}

integer entryFlags(key id, integer age, string pay)
{
    // Same flag bits the Data Script's scan lines used: the
    // [AUTOMATED], [NEW] and no-payment bits from the live
    // agent, plus the watch bit from this script's gWatch
    // mirror (kept current by Core's LM_WATCH_LIST broadcasts).
    integer f = 0;
    if (llGetAgentInfo(id) & AGENT_AUTOMATED)
        f += 1;
    if (age >= 0 && age < 7)
        f += 2;
    if (pay == "0")
        f += 4;
    // Round 80 type-trap fix: gWatch is a STRING mirror
    // (llParseString2List of Core's CSV) - llListFindList
    // matches types strictly, so the old KEY needle never
    // matched and the [WATCHED] tag never rendered.
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
    // The scope filter, copied from the Data Script (round 71
    // ZERO_VECTOR guards included). The wearer and NULL_KEY
    // ghosts are dropped; the caller passes the cutoff. The
    // Data Script stops the walk early at its narrowed cap -
    // THIS script passes the fetch's own 100-key cap, because
    // a full-region walk is exactly what this budget is for.
    integer n = llGetListLength(agents);
    if (n > max)
        n = max;
    integer i;

    if (gScope == 1)
    {
        // Radius scope: llGetPos() in an attachment is the
        // wearer's position, so this is centered on the avatar.
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

    // Parcel scope: everyone standing on the wearer's parcel.
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

    // Region scope: everyone but the wearer.
    list out;
    for (i = 0; i < n; i++)
    {
        key a = llList2Key(agents, i);
        if (a != llGetOwner() && a != NULL_KEY)
            out += [a];
    }
    return out;
}

askAgent(key agent, string kind)
{
    // Queue ONE lookup: born date + payment info, with language
    // resolved through the shared linkset-data map (Core writes
    // SMH.langmap at boot; cache first, then one linkset read
    // per unknown code). Round 79: the pipeline carries TWO
    // kinds of row - "S" scan rows (List All) and "A" arrival
    // rows the Data Script's sweep hands over as "LOOK|key" -
    // exactly the mode-field stride the pipeline had back when
    // it lived in the Data Script.
    integer idx = findAgentIndex(gPending, agent);
    if (idx != -1)
    {
        // Already in flight: one reply still comes. The ONE-WAY
        // upgrade rule (round 79): a scan may CLAIM an in-flight
        // arrival (the r12 semantic - the S line covers them,
        // the ARRIVED line is skipped), but an arrival NEVER
        // downgrades a scan row: the scan's completion is
        // already owed in gScanCount, a downgraded row would
        // never decrement it, and the "already running" guard
        // would wedge until a region change.
        if (kind == "S" && llList2String(gPending, idx + 4) == "A")
            gPending = llListReplaceList(gPending, ["S"], idx + 4, idx + 4);
        return;
    }

    // Round 80: the queue bound is MEMORY-AWARE - rows =
    // clamp((free - 4500) / 160, 8, 36), checked per arrival
    // (each stride-6 row is ~160 B of list overhead; the old
    // fixed 36-ELEMENT bound was the Data Script's round-68
    // sizing carried over). At a healthy boot the full 36 rows
    // fit; a tight heap drops the bound toward the 8-row floor,
    // so an arrival flood can never outstack the pipeline's
    // own 15 s flush. Past the cap the entry is sent right
    // away with whatever is known - the same partial-data
    // shape the timeout flush produces.
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

    // Language: raw code from the viewer, resolved via the
    // linkset-data map (pipe-delimited with a LEADING pipe so
    // "|code|" can only match a real pair boundary; the
    // 30-char window is safe - the longest full name is 20).
    string lang = llGetAgentLanguage(agent);
    if (lang != "")
    {
        integer ci = llListFindList(gLangCache, [lang]);
        if (ci != -1)
            lang = llList2String(gLangCache, ci + 1); // known: use it now
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
                        gLangCache = []; // safety cap
                    gLangCache += [lang, full];
                    lang = full;
                }
            }
            // not found / map missing: keep the raw code
        }
    }
    gPending += [agent, -1, "", lang, kind, llGetUnixTime()];

    if (llGetListLength(gRequests) >= MAX_PENDING_REQUESTS * 3)
        return; // throttled: entry stays pending, the timer flushes it

    gRequests += [llRequestAgentData(agent, DATA_BORN), agent, "B"];
    gRequests += [llRequestAgentData(agent, DATA_PAYINFO), agent, "P"];
}

sendEntry(integer idx)
{
    // Complete ONE pipeline row, whichever way the data arrived.
    // The name is a viewer link composed from the key. Round 79
    // branches on the row's kind: "S" scan rows append to the
    // listing buffer (the relay lives HERE now - flushed in
    // 10-line / 900-byte batches straight to owner chat, the
    // exact batching the Companion used); "A" arrival rows tell
    // Core, which announces through the Companion exactly as it
    // did when the Data Script owned the pipeline.
    key agent = llList2Key(gPending, idx);
    string kind = llList2String(gPending, idx + 4);
    integer age = llList2Integer(gPending, idx + 1);
    string pay = llList2String(gPending, idx + 2);
    string lang = llList2String(gPending, idx + 3);

    if (kind == "S")
    {
        // Field 7 of the old payload was the distance snapshot
        // from the wearer when the line was composed (-1 =
        // position unreadable, the avatar probably left);
        // llGetPos() in an attachment returns the AVATAR's
        // position.
        integer dist = -1;
        vector pos = llList2Vector(llGetObjectDetails(agent, [OBJECT_POS]), 0);
        if (pos != ZERO_VECTOR)
            dist = (integer)llVecDist(llGetPos(), pos);
        // llOwnerSay truncates at 1024 bytes and every line
        // carries a ~71-byte name link, so flush at ~900 bytes
        // OR every 10 lines, whichever comes first (the r31
        // rule, moved here with the relay).
        gScanOut += entryText(nameUri(agent), (string)age, pay, lang,
            (string)entryFlags(agent, age, pay), dist) + "\n";
        gScanLines = gScanLines + 1;
        if (gScanLines % 10 == 0 || strBytes(gScanOut) > 900)
        {
            llOwnerSay(gScanOut);
            gScanOut = "";
        }
        gScanLeft = gScanLeft - 1;
        gScanCount = gScanCount - 1;
        if (gScanLeft <= 0 && gScanNext < llGetListLength(gScanQueue))
            pumpScan(); // wave finished: start the next one
        if (gScanCount <= 0)
        {
            if (gScanOut != "")
            {
                llOwnerSay(gScanOut);
                gScanOut = "";
            }
            gScanLines = 0;
            llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
            resetScan(); // bookkeeping only: the pipeline purge
                         // is NOT wanted here - in-flight
                         // arrival rows must survive a listing
                         // completing
        }
        return;
    }

    // Arrival row: the finished facts to Core, the exact wire
    // the Data Script used ("0" was the old mode field - Core
    // skips it).
    llMessageLinked(LINK_SET, LM_DATA_TELL,
        "0|" + (string)agent + "|" + nameUri(agent) + "|" +
        (string)age + "|" + pay + "|" + lang, "");
}

checkPending(integer idx)
{
    if (llList2Integer(gPending, idx + 1) == -1 ||
        llList2String(gPending, idx + 2) == "")
        return; // still waiting: born date or payment info
    sendEntry(idx);
    gPending = llDeleteSubList(gPending, idx, idx + 5);
}

resetScan()
{
    if (gScanCount > 0)
    {
        // Abandoning a scan that is still running (region
        // change, scope re-base): print whatever the buffer
        // holds (those lines DID complete - the old SE| made
        // the Companion flush its copy; the relay lives here
        // now, so the flush does too) and switch the busy
        // blink off, or both would hang.
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
    // The old Data Script's travel rule, moved here with the
    // rows in round 79: abandon EVERY in-flight lookup on
    // region change / re-wear / re-base - arrival and scan rows
    // from the OLD region must never flush AFTER the warp.
    // Dataserver replies for the dropped request rows arrive as
    // strays and are ignored (findRequestIndex returns -1).
    // This is also THE ABORT-WART FIX: the eighth field
    // follow-up's stragglers (a second "listing complete",
    // late rows printing in the next region) existed because
    // an aborted listing left its rows in the pipeline for the
    // 15 s flush - every abort path now purges wholesale. The
    // census counters are zeroed so a stray census reply cannot
    // decrement or print a summary for a region we just left;
    // a census that was mid-fetch stops the busy blink.
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
    // Drop every census ("X") request row from gRequests (moved
    // from the Data Script with the census, round 79). Rows
    // whose born replies never arrived (avatar left
    // mid-census, or the reply was eaten by a script-freeze)
    // would linger until the NEXT census purged them -
    // silently eating the request cap. Called at census start
    // (drop the previous census's strays), at sendCensus
    // (every census end path) and from the timer's stale-drop
    // branch (the one path that does not reach sendCensus).
    // Walks from the tail so deletes never shift unvisited
    // rows.
    integer r;
    for (r = llGetListLength(gRequests) - 3; r >= 0; r -= 3)
    {
        if (llList2String(gRequests, r + 2) == "X")
            gRequests = llDeleteSubList(gRequests, r, r + 2);
    }
}

pumpScan()
{
    // Start the next wave: at most SCAN_BATCH agents in flight.
    // The round-71 re-entrancy fixes from the Data Script,
    // carried over intact because the hazards are structural:
    // (1) gPumping guards against a synchronous completion
    // inside askAgent re-entering pumpScan mid-wave; (2) the
    // counters advance BEFORE askAgent so a synchronous
    // completion nets its own row to zero.
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

startScan()
{
    // Round 80: OFF IS STANDBY - the power state mirrors here
    // (LM_UI_STATE), and a listing is detection work, so it
    // refuses with the reminder while the detector is off.
    // (Status, Debug, watch-list edits and Export/Import stay
    // available - they are configuration, not detection.)
    if (gHaveState && !gEnabled)
    {
        llOwnerSay("The detector is off - click the power button to turn it back on.");
        return;
    }
    if (gScanCount > 0)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SCANBUSY", "");
        return;
    }
    // Memory guard, round-80 REPRICING: a listing's real cost
    // scales with POPULATION, not with boot distance - the
    // round-79 boot-1500 form (calibrated on the 29 K r78
    // boot) refused even EMPTY regions once this script's
    // boot fell to 10.8 K and its in-session rest sat below
    // its own guard (four field RREFUSEs at 8.4-9 K free in
    // 0-2 avatar regions). The guard is now the nearest
    // guard's arithmetic: live population x 102 + 3500 - an
    // empty region needs ~3.5 K (never refused at rest), a
    // 50-avatar listing refuses honestly when it genuinely
    // does not fit. Round 79 (item 4) keeps the GC nudge
    // FIRST: llGetFreeMemory under-reports until an
    // allocation forces a collection, and the field ring
    // holds two false refusals at pinned readings while the
    // real memory was fine.
    gcNudge();
    integer sfl = llGetRegionAgentCount() * 102 + 3500;
    if (llGetFreeMemory() < sfl)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SCANMEM", "");
        dbgLog("RREFUSE", "scan|free=" + (string)llGetFreeMemory() +
            "|guard=" + (string)sfl);
        return;
    }
    // The listing shows the CURRENT SCOPE - not the sweep's
    // narrowed tracked population (the r78 semantic change,
    // disclosed in the header). The fetch is the whole point
    // of this script: it lives where the memory is.
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
    // The header goes straight to owner chat now (the relay
    // lives here since round 79) and the blink tells the wearer
    // the list is still fetching. Round 80: the busy context
    // rides the listing ON DEMAND - if detection is tracking a
    // narrowed cap (SMH.cap, published by the Data Script on
    // cap change), the preamble says so once, here, instead of
    // on a repeating timer.
    integer capCtx = (integer)llLinksetDataRead(P + "cap");
    if (capCtx > 0 && n > capCtx)
        llOwnerSay("(" + (string)llGetRegionAgentCount() +
            " avatars in the region - detection is tracking the first " +
            (string)capCtx + " for alerts.)");
    llOwnerSay("=== AVATARS IN " + llToUpper(scopeLabel()) +
        " (" + (string)n + ") ===");
    llOwnerSay("Fetching account data - the power button blinks until the list is ready.");
    llMessageLinked(LINK_SET, LM_EVENT, "BUSY|1", ""); // blink the power light
    gScanQueue = agents;
    gScanNext = 0;
    gScanCount = n;
    pumpScan();
}

startCensus(list agents, string src)
{
    // The census, moved from the Data Script in round 79 with
    // the whole pipeline (the born-date asks that stacked into
    // its deepest crash). After adopting a new region ("A"):
    // report ONE summary line instead of either silence or
    // per-avatar spam; on demand from the menu's Summary
    // button ("M") the same line, same numbers. Scripted agents
    // and watched people are counted instantly (llGetAgentInfo
    // / the watch mirror); new accounts need born dates, so one
    // dataserver request per avatar goes out - results only
    // bump counters, no announcements, no language lookups.
    llMessageLinked(LINK_SET, LM_EVENT, "BUSY|1", ""); // blink while fetching
    // A previous census can still have born replies in flight
    // (a teleport mid-census). Drop its request rows so those
    // replies arrive as unknown ids and are ignored.
    purgeCensusRows();
    // Round 80 FIT-CAP: count at most (free - 2500) / 156
    // people (never past the caller's own cap) - each counted
    // row costs ~156 B of list overhead, and in a tight heap
    // the COUNT is what must shrink. Graceful, not a refusal:
    // the summary still prints, with an honest "and N more
    // (low memory)" line (gCensusMore rides the "C" payload).
    gCensusMore = 0;
    integer fit = (llGetFreeMemory() - 2500) / 156;
    if (fit < 1)
        fit = 1; // count at least one - the line costs nothing
    integer tot = llGetListLength(agents);
    // PRE-FIELD AMENDMENT 3: count bots and watched people
    // over the FULL list, BEFORE the trim. The r80 fit-cap
    // clipped the list first, so a heavy trim made "Scripted
    // agents" and "On watch list" see only the first few
    // people - a watched resident among the uncounted read
    // as 0, a false negative for the round's own watch-count
    // fix. This scan retains nothing (two counters), so it
    // costs no census rows; only the born-date asks stay
    // trimmed to the fit. Watch DETECTION was never capped -
    // the Data script's "WATCHED: entered/left" lines still
    // cover the whole region.
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
            // Name each scripted agent in scope so the
            // Companion can log the encounter silently (she
            // just arrived where it already is; no chat line
            // here - the summary's bot count covers them).
            llMessageLinked(LINK_SET, LM_SAY,
                "AE|" + nameUri(a) + "|" + (string)a, "");
        }
        // Round 80 type-trap fix: cast to string (gWatch is a
        // string mirror; a key needle never matched, so the
        // census watch count always read zero).
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
        sendCensus(); // empty region: the summary is the message
        return;
    }
    // Cap the born-date requests: each row costs ~260B and
    // lives up to PENDING_TIMEOUT seconds. The ask count is
    // BUDGETED against free memory and shrinks (to "?" at
    // zero) instead of spending headroom the script may need;
    // the count then covers the first people in scope - the
    // same honesty rule as the listing cap. The r74 PRICED
    // floor came along with the census: keep (n + min(n,
    // CENSUS_LIST_CAP)) x 102 + 2000 of heap - the census's
    // own list plus a concurrent listing wave plus margin -
    // and spend only the surplus on born-date asks.
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
        gCensusNew = -1; // the Companion prints "?" for -1
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
    // "C|scope|total|new|bots|watched|src|more|cap" - formatted
    // by the Companion like every other one-line note; src
    // picks the ARRIVAL SUMMARY / SUMMARY label. Round 80 adds
    // the last two fields: "more" = fit-cap trimmed people
    // ("and N more (low memory)"), "cap" = the Data Script's
    // published tracking cap (the busy-context line "detection
    // tracking the first N"). An older Companion ignores both
    // extra fields; a newer one tolerates their absence
    // (missing fields parse to "" -> 0).
    integer capCtx = (integer)llLinksetDataRead(P + "cap");
    if (capCtx < 0)
        capCtx = 0;
    llMessageLinked(LINK_SET, LM_SAY, "C|" + scopeLabel() + "|" +
        (string)gCensusTotal + "|" + (string)gCensusNew + "|" +
        (string)gCensusBots + "|" + (string)gCensusWatched + "|" +
        gCensusSrc + "|" + (string)gCensusMore + "|" + (string)capCtx, "");
    llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", ""); // blink off
    // Every census end path lands here, so this is the single
    // point that guarantees no X row outlives its census -
    // even when born replies never came back.
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
    // Round 80: OFF IS STANDBY - the Summary button is detection
    // work, so it refuses with the reminder while the power is
    // off (the arrival census cannot fire while OFF either: the
    // Data Script only sweeps when ON).
    if (gHaveState && !gEnabled)
    {
        llOwnerSay("The detector is off - click the power button to turn it back on.");
        return;
    }
    // The menu's Summary button (Core relays "CENSUS"): the
    // one-line census for the CURRENT scope, on demand. Round
    // 79 semantic change, disclosed: it fetches the current
    // scope fresh in THIS budget (the r78 List All doctrine)
    // instead of reusing the Data Script's tracked pad - so it
    // works in ANY region now, including regions where
    // detection is honestly paused (SUMPAUSE is gone), and
    // counts up to CENSUS_LIST_CAP people. A census already in
    // flight must not be re-requested - the second press used
    // to purge and re-ask every born row (two summaries,
    // double the dataserver load); SUMSTOCK says "still
    // counting, try again in a few seconds".
    if (gCensusLeft > 0)
    {
        llMessageLinked(LINK_SET, LM_SAY, "N|SUMSTOCK", "");
        return;
    }
    startCensus(scopeAgentsFrom(llGetAgentList(AGENT_LIST_REGION, []),
        CENSUS_LIST_CAP), "M");
}

doWatchPlus()
{
    // The ENTIRE Watch+ flow, round 79 item 3: the Companion's
    // pick-dialog build collided twice at ~3.3 K (above its
    // own 3422 boot canary - NO safe floor exists there), so
    // the ranking AND the dialog AND Manual Add all run on
    // THIS budget now, on this script's own channel. The
    // one-byte handshake stands the Companion's 10-second
    // missing-Registrar safety net down before anything else
    // happens. Round 80: OFF IS STANDBY - the pick build is
    // detection work and refuses with the reminder while the
    // power is off.
    if (gHaveState && !gEnabled)
    {
        llMessageLinked(LINK_SET, LM_SAY, "NR|ok", "");
        llOwnerSay("The detector is off - click the power button to turn it back on.");
        return;
    }
    llMessageLinked(LINK_SET, LM_SAY, "NR|ok", "");
    // Honest memory guard, r73's dynamic arithmetic (live
    // population x 102 + 3500), with the round-79 GC nudge
    // FIRST - the same pinned-reading lie the scan guard
    // learned to nudge through (item 4, applied to both).
    gcNudge();
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
    // Incremental top-10, no sort copy: [distance, key, ...]
    // ascending; the wearer and NULL_KEY ghosts are never
    // ranked (the round-36 ghost filter). j reaching 20 means
    // this agent is not one of the ten nearest.
    list top;
    integer i;
    for (i = 0; i < llGetListLength(regionAgents); i++)
    {
        key a = llList2Key(regionAgents, i);
        if (a != llGetOwner() && a != NULL_KEY)
        {
            vector p = llList2Vector(llGetObjectDetails(a, [OBJECT_POS]), 0);
            integer dist = 9999; // unreadable position: sort last
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
    // Keep the keys in rank order for the button clicks; no
    // keys = nobody else is in the region.
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
    // llDialog buttons cap at 24 BYTES: "12 " + the pickName
    // label (byte-trimmed to 20 + "~"); the leading number is
    // the selector, so truncation is safe.
    list buttons;
    for (i = 0; i < llGetListLength(gPickKeys); i++)
    {
        string label = (string)(i + 1) + " " + pickName(llList2Key(gPickKeys, i));
        buttons += [llGetSubString(label, 0, 23)];
    }
    buttons += ["Manual Add", "Back"];
    llDialog(llGetOwner(),
        "Add who to the watch list?\nNearest people first. Click a name to add.",
        buttons, gChannel);
}

default
{
    state_entry()
    {
        // The canary: this script's boot number, on the same
        // pattern as the others. Round 79 grew this script
        // (the relay, the census, the arrival pipeline and the
        // picker all landed at once) - RECORD the new number;
        // the r78 one was 29082, and the scan guard below
        // re-calibrates around whatever this reads.
        gBootFree = llGetFreeMemory();
        llOwnerSay("Registrar Script ready (Build " + BUILD_NUM +
            "). Memory: " + memPct(gBootFree));
        dbgLog("RBOOT", "free=" + (string)gBootFree);
        // Round 79: this script's own random deep-negative
        // dialog channel (the round-25 pattern) + its listener
        // - the Watch+ picker's buttons and Manual Add's text
        // box arrive here, never through the Companion.
        gChannel = -(integer)llFrand(1000000000) - 1000000000;
        llListen(gChannel, "", llGetOwner(), "");
        // Round 79: ask Core for the settings/watch mirror in
        // case THIS script (re)started after Core did (the
        // Data Script has always done this at boot; without
        // the ask, this script's mirrors sat empty until
        // Core's next push after a mid-session reset).
        llMessageLinked(LINK_SET, LM_UI_CMD, "SYNC", "");
        // Rebalance Core's busy counter: a reset landing mid-
        // listing or mid-census (an owner change, a Wipe)
        // orphans the fetch's earlier "BUSY|1" - its "BUSY|0"
        // died with the old state, leaving the power button
        // blinking until the 180 s timeout. Harmless at a
        // clean boot: Core clamps the counter at 0.
        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
        llSetTimerEvent(2); // the pipeline flush (no sweep lives here)
    }

    timer()
    {
        // Pre-field amendment fix: "now" is declared BEFORE the
        // import-window check - the first draft used it above
        // its declaration and LSL rejected the name (Rachel's
        // paste found it; the balance and ll-name audits cannot
        // see undeclared variables).
        integer now = llGetUnixTime();
        // Round 80: the 60-second IMPORT window closes quietly
        // when it times out (the reminder line only fires if
        // the wearer is still watching for it).
        if (gImpDeadline != 0 && now >= gImpDeadline)
        {
            llListenRemove(gImpHandle);
            gImpDeadline = 0;
            llOwnerSay("Import window closed - press Import, then Export on the other HUD, to try again.");
        }
        // Pipeline maintenance, mirrored from the old Data
        // Script's timer, now for BOTH row kinds: a stale purge
        // first (rows past STALE_DROP can only predate this
        // running session - drop them and keep the bookkeeping
        // honest), then the 15 s partial flush (exactly one
        // line per queued agent, whatever the dataserver
        // managed to answer), then the census deadline.
        integer i;
        integer errStale = 0;
        for (i = llGetListLength(gPending) - 6; i >= 0; i -= 6)
        {
            if (now - llList2Integer(gPending, i + 5) >= STALE_DROP)
            {
                key sa = llList2Key(gPending, i);
                // Kill the dead request rows too: their query
                // ids died with the old session.
                integer sri = llListFindList(gRequests, [sa]);
                while (sri != -1)
                {
                    integer row = sri - 1; // agent sits at stride +1
                    gRequests = llDeleteSubList(gRequests, row, row + 2);
                    sri = llListFindList(gRequests, [sa]);
                }
                // Round 79: only SCAN rows owe the listing a
                // completion - an arrival row must never
                // decrement the scan counters (the old
                // scan-only pipeline could assume every row;
                // the two-kind pipeline cannot).
                if (gScanCount > 0 && llList2String(gPending, i + 4) == "S")
                {
                    // Keep the scan bookkeeping honest, or a
                    // scan that died at logout would wedge "A
                    // scan is already running" forever.
                    // AMENDMENT FIX: close the listing HERE.
                    // resetScan's own guard (count > 0) cannot
                    // know a scan was running once the count
                    // has hit 0, so the first r78 draft called
                    // it there and LEAKED an open listing and a
                    // stuck busy blink on exactly this path -
                    // the logout-mid-scan case this branch
                    // exists for.
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
        integer errData = 0; // dataserver no-reply rows (this flush)
        for (i = llGetListLength(gPending) - 6; i >= 0; i -= 6)
        {
            if (now - llList2Integer(gPending, i + 5) >= PENDING_TIMEOUT)
            {
                key a = llList2Key(gPending, i);
                // If this row still has outstanding requests, the
                // dataserver never answered: count it for the
                // error ring AND purge the stale rows so they
                // cannot clog the MAX_PENDING_REQUESTS cap.
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

        // Census deadline (moved from the Data Script's timer
        // with the census in round 79): send the summary with
        // whatever the dataserver managed to answer - a stalled
        // reply must not swallow the summary line.
        if (gCensusLeft > 0 && now >= gCensusDeadline)
        {
            if (now - gCensusDeadline >= STALE_DROP)
            {
                // This census was mid-flight when the wearer
                // logged out; its summary belongs to a session
                // (maybe a region) already left. Drop it
                // silently instead of printing a stale line -
                // and purge the orphaned X rows here too: this
                // is the one census end path that never reaches
                // sendCensus.
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
    }

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
            // Census born reply (the census moved in with its own
            // row kind, round 79): count new accounts, nothing
            // else - and only while a census is actually
            // expecting replies (strays must not fire extra
            // summary lines).
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

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == LM_SWEEP_ASK)
        {
            if (str == "SCAN")
                startScan();
            else if (str == "REBASE")
            {
                // Scope just changed: a running listing is stale
                // by definition. Purge the pipeline too (round
                // 79) - pending name requests from the old
                // scope must not land as post-abort stragglers.
                resetScan();
                clearPipeline();
            }
            else if (str == "RESET")
            {
                // The Data Script's travelReset moved to this
                // broadcast (round 79): purge everything on
                // any region change it detects and we miss.
                resetScan();
                clearPipeline();
            }
            else if (str == "CENSUS")
                startCensusNow();
            else if (llGetSubString(str, 0, 5) == "CENSUS|")
            {
                // "CENSUS|A" - adopt-scope census: count the
                // agents the Data Script just swept up.
                startCensus(scopeAgentsFrom(llGetAgentList(
                    AGENT_LIST_REGION, []), CENSUS_LIST_CAP), "A");
            }
            else if (llGetSubString(str, 0, 4) == "LOOK|")
                askAgent((key)llGetSubString(str, 5, -1), "A");
            else if (str == "NEAR")
                doWatchPlus();
            else if (str == "EXPORT")
                doExport();
            else if (str == "IMPORT")
                doImport();
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
            // Mirror the watch list from Core's broadcast so the
            // scan lines' [WATCHED] bit is current (the Data
            // Script keeps its own mirror the same way).
            if (str == "")
                gWatch = [];
            else
                gWatch = llParseString2List(str, [","], []);
            return;
        }

        if (num == LM_MEM_ASK)
        {
            // Status Check: the labeled memory line, same shape
            // as the other scripts' replies. Round 80
            // (pre-field amendment): the reply carries this
            // script's build number too - the Status Check
            // lines then show WHICH build each script runs.
            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Registrar Script|" + (string)llGetFreeMemory() +
                "|" + BUILD_NUM, "");
            return;
        }
    }

    listen(integer channel, string name, key id, string msg)
    {
        // Round 80: the IMPORT receiver first - the transfer
        // channel is NOT the dialog channel. Only the owner's
        // OWN objects are accepted (llGetOwnerKey), and only
        // while a 60-second window is armed.
        if (gImpDeadline != 0 && channel == ownerChannel())
        {
            if (id != NULL_KEY && llGetOwnerKey(id) == llGetOwner() &&
                llGetSubString(msg, 0, 9) == "SMHEXPORT|")
            {
                list keys = llParseString2List(
                    llDeleteSubString(msg, 0, 9), [","], []);
                integer i;
                for (i = 0; i < llGetListLength(keys); i++)
                {
                    // Core's existing ADD handler validates,
                    // dedupes, caps at 20 and saves - the whole
                    // normal Manual Add path, unchanged.
                    llMessageLinked(LINK_SET, LM_UI_CMD,
                        "ADD|" + llList2String(keys, i), "");
                }
                llListenRemove(gImpHandle);
                gImpDeadline = 0;
                llOwnerSay("Import received " + (string)llGetListLength(keys) +
                    " key(s) - duplicates are skipped by the watch list itself; the cap is 20.");
            }
            return;
        }
        // Watch+ pick dialog (round 79): this script's own deep
        // random channel (round-25 pattern). Only the owner
        // speaks here, and only via the dialog we offered.
        if (channel != gChannel || id != llGetOwner())
            return;
        msg = llStringTrim(msg, STRING_TRIM);
        if (msg == "")
            return;

        if (msg == "Back")
        {
            llMessageLinked(LINK_SET, LM_MENU_OPEN, "", "");
            return;
        }

        if (msg == "Manual Add")
        {
            // Same flow as the main menu's Manual Add, but on
            // this channel: paste a raw UUID, Submit, done.
            llTextBox(id, "Paste the avatar key (UUID) you want " +
                "to watch, then click Submit:", gChannel);
            return;
        }

        // "N Name" - a numbered pick from the dialog list.
        integer sp = llSubStringIndex(msg, " ");
        if (sp > 0)
        {
            integer num = (integer)llGetSubString(msg, 0, sp - 1);
            if (num > 0 && num <= llGetListLength(gPickKeys))
            {
                llMessageLinked(LINK_SET, LM_UI_CMD,
                    "ADD|" + llList2String(gPickKeys, num - 1), "");
                doWatchPlus(); // re-show: multiple picks, one dialog
                return;
            }
        }

        // Otherwise: a raw 36-character UUID from the Manual
        // Add text box (or anything UUID-shaped the owner typed
        // at the dialog - llDialog only lets them pick what we
        // offered, so the TextBox is the only way here).
        if (llStringLength(msg) == 36)
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "ADD|" + msg, "");
            doWatchPlus();
        }
    }

    changed(integer change)
    {
        // New owner = new everything: the random channel, the
        // census state, the pipeline - restart clean (round 79).
        if (change & CHANGED_OWNER)
        {
            llResetScript();
            return;
        }

        // A region jump invalidates a running listing (its
        // rows belong to the region we just left) - abort it
        // exactly the way the Data Script's travelReset used
        // to, but from THIS script's own event. Purge the
        // pipeline too (round 79): in-flight name requests
        // from the old region must not land as stragglers.
        if (change & (CHANGED_REGION | CHANGED_TELEPORT))
        {
            resetScan();
            clearPipeline();
        }
    }
}
