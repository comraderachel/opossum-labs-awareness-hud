
// ROUND 84 (2026-11-06) - paste the whole script over the old
// one. The Companion AND the Registrar Script BOTH move this
// round (the Data and Core Scripts are UNCHANGED from rounds
// 81/82 - do not touch them); the help notecard is unchanged
// from round 82. ONE ITEM, TRIGGERED BY THE FIELD ALARM:
// three days of normal wear took this script from 6954 free
// at boot to 376 free - the round-80 club soak read the same
// ratchet (1170 free), and the low-water line fired exactly
// as designed. The cause is Mono heap fragmentation from
// ordinary string churn, NOT a data leak (the only list is
// the bounded watch mirror; the rings and encounters live in
// linkset data). No code reclaims fragmentation; only a reset
// does, and all durable state lives in linkset data - so this
// script now SELF-HEALS: below 2000 free, at a quiescent
// moment (no typed-input mode, no pending Watch+ pick, no
// welcome flow or scheduled one, no live Core watchdog), it
// writes a "selfheal" forensics line to the error ring and
// resets itself. Boot restores full memory; Core's 120 s
// failure bar never sees the gap (the first tick republishes
// SMH.chb seconds later).
// ============================================================
// OPOSSUM LABS AWARENESS HUD - Companion Script (any prim)
// ------------------------------------------------------------
// VERSION HISTORY (newest first):
//   round 84: SELF-HEAL RESET (the low-water alarm's answer).
//     Field: boot 6954 -> 376 free in three days of normal
//     wear; the r80 club soak read the same ratchet. Frag-
//     mentation, not a leak. Below 2000 free at a QUIESCENT
//     moment - gates: gMode == 0, gPickDue == 0, no welcome
//     flow active or scheduled (!gWelcome, gSetupDue == 0),
//     no live watchdog (!gCoreWatch) - the timer writes
//     "selfheal: reset at N free" to the error ring and calls
//     llResetScript. state_entry re-reads everything from
//     linkset data; the boot "Companion ready" line is the
//     visible trace.
//   round 82: THE CORE WATCHDOG + HEARTBEAT (field-designed
//     with Rachel as part of the light vocabulary). (1) The
//     tick publishes SMH.chb every pass - Core's new failure
//     sweep needs it to tell a hung Companion from a healthy
//     one. (2) The WATCHDOG: Core drives the power light, so
//     a dead Core freezes it at whatever color it last
//     wrote - invisible. This script reads Core's published
//     SMH.corehb on the same 5 s tick; staler than 120 s
//     means Core is gone, so this script takes the light:
//     red/dark blink at the busy cadence (the timer drops
//     to 0.5 s while it lasts), one chat line ("The Core
//     Script is not responding - take the HUD off and wear
//     it again"), one error-ring entry per transition
//     (corewatch / corewatchok - Status Check still works
//     with Core dead, since the menus live here). IMMUNITY:
//     a 30-second grace at boot (a stale pre-reboot corehb
//     must not read as a dead Core before it ticks once),
//     and if OUR OWN tick was 60+ seconds late the whole
//     linkset froze together - skip the evaluation that
//     pass and re-grace, so logouts and no-script parcels
//     never false-alarm. HAND-BACK: none needed - Core's
//     round-82 lightTick re-writes its color every pass, so
//     the moment it runs again our paint heals away. The
//     power prim is found by name ("Power Button") with the
//     root fallback, exactly like Core's own lookup.
//   round 80: SIX UI CHANGES, ALL FIELD-DRIVEN. (1) WATCH-
//     REWORK: the remove dialog's BUTTONS were pickName live
//     lookups - llDialog button text cannot carry viewer
//     links, and the lookups return "" for anyone not in the
//     region, so every absent avatar showed as "Unknown
//     Avatar" (the removal chat line was fine: it uses the
//     viewer-link safeName). The dialog BODY now carries the
//     numbered viewer-link names (the viewer resolves them
//     there for offline and never-seen avatars alike - the
//     same mechanism as chat), and the buttons are plain
//     numbers. llDialog caps the BODY at 512 bytes and each
//     link is ~73, so the page is 6 entries (pickName is
//     deleted - this was its last use). (2) ENCOUNTERS
//     RETENTION CUT: the 7/14/30/60/90-day picker and the
//     encdays preference are gone - encounters keep a fixed
//     30 days (the constant), the Settings menu is Area /
//     Debug / Wipe / Back (the Export / Import buttons that
//     shipped here are removed mid-field - see (7)), and
//     gMenu level 8 dies with showEncKeepMenu. (3) TRACE CUT: the toggle
//     and the click narration are deleted everywhere (the
//     debug rings won the diagnosis war - the r79 field
//     follow-ups ran entirely on rings). (4) THE "C" LINE
//     grows two optional fields from the Registrar's census
//     fit-cap and the Data Script's SMH.cap publish: "and N
//     more (low memory)" and "detection tracking the first
//     N" - the busy-region context appears on Summary and
//     List All, not on a repeating timer (the club soak
//     printed the BUSY note every 30 s; the Data-side flap
//     fix and this on-demand wording close it together). The
//     SCANMEM refusal wording points at Summary. (5) LOW-
//     WATER SELF-REPORT: this script is the only one without
//     its own memory telemetry, and the club soak read 1170
//     free (98%) with no story; the 5-second tick now writes
//     the shared error ring ("Companion|low: N free") when
//     free < 2500, at most once per 10 minutes - zero new
//     reader code, the ring prints on every Status Check.
//     (6) STATUS CHECK BUILD LINES (Rachel's request, pre-
//     field amendment): every LM_MEM_TELL reply grows a third
//     field - the answering script's OWN build number - and
//     the printed line becomes "Debug: N Script - N free
//     (P% used) | Build:NNNNNNNNN", so each Status Check
//     shows WHICH build EACH script runs (a mixed-round unit
//     shows different builds on its lines - the support
//     rationale behind per-script builds). This script's own
//     reply carries its build too, and an old-shape reply
//     prints cleanly without the suffix. (7) MID-FIELD
//     AMENDMENT - EXPORT / IMPORT REMOVED (Rachel's report:
//     "the import and export options in the settings menu do
//     not seem to work" - they never did): this script sent
//     the button labels verbatim ("Export" / "Import") while
//     the Registrar's sweep-ask handler matched UPPERCASE,
//     and LSL comparison is case-sensitive - the buttons
//     were dead on arrival and did nothing. Removed rather
//     than fixed, per Rachel's call; the Settings menu drops
//     the two buttons and this dispatch branch dies with
//     them. Backup abilities return in a later round,
//     planned as sync with a web management page. LESSON:
//     cross-script wire strings must be checked sender-vs-
//     receiver - the audit battery is blind to case
//     mismatches across scripts.
//   round 79: THE PICK BUILD LEAVES, AND THE TEXT VALVE
//     LIGHTENS. Two Companion Stack-Heap Collisions in one
//     field evening (both in the Watch+ pick build - the
//     second WITH the guard live) put that build's peak at
//     >= 3.3 K against a 3422 boot canary: no safe floor
//     exists in THIS budget, and round 79 moves the build to
//     the Registrar (29 K free, owns the ranked keys and the
//     list all along). What moves OUT of this script: the
//     listing relay (gScanOut / gScanLines and handleSay's
//     SB / S / SE branches - the Registrar now formats and
//     batches its own listing lines), the pick-dialog build
//     itself (gPickKeys and the numbered-name button branch
//     - the Registrar's own dialog on its own channel), and
//     the guard era's constants (PICK_FLOOR and the
//     amendment-2 refuse branches). The "NR" reply keeps
//     exactly ONE job: the handshake clear - the Registrar
//     answers Watch+ with "NR|ok" at the top of its own
//     dialog build, and this script's gPickDue safety net
//     stands down the moment it arrives (if the Registrar is
//     missing or halted, the 10-second timer still offers
//     Manual Add honestly). Also deleted: the SUMPAUSE and
//     SCANSTOCK note branches (SUMPAUSE has no sender since
//     the Summary moved; SCANSTOCK has been dead since r76).
//     What STAYS: the entire menu system, all announcement
//     formatting (A / L / W / AE / C / D / N), the encounter
//     log, Debug, Manual Add, Watch-, and the byte-trim
//     helpers those need (pickName for Watch-, strBytes for
//     the batching guards). Net: this script becomes the
//     honest text valve again - menus and text, nothing
//     that allocates by region population.
//   round 78 (field amendment 2): the SECOND Watch+
//     collision, 2026-10-31 20:44 - WITH THE GUARD LIVE:
//     Status Check read 3292 free (above the 2500 floor, so
//     the guard passed the build through) and the build
//     still collided. Two crashes at ~3.3 K available put
//     the build's TRUE peak at >= 3.3 K: the 1.5-2 K
//     estimate missed the parse tokens, pickName's
//     per-entry llGetDisplayName plus its byte-trim loop
//     (a substring PER ITERATION), the label + 24-char
//     substring DOUBLE allocation, and the COW append
//     churn - and every pick-click re-enters showAddMenu()
//     for another full build. That peak exceeds the
//     script's own boot canary (3422) - NO SAFE FLOOR
//     EXISTS: one that protects (>= 3.5 K) refuses
//     forever, one that ever passes (<= 3.3 K) is the
//     crash zone. PICK_FLOOR is now 4000 - above any
//     reading this script can produce - and the
//     keys-arrived case answers its OWN honest dialog
//     (picker unavailable on this build; Manual Add
//     works), keeping "region too busy" reserved for the
//     Registrar's "NR|-1" guard refusal, which it truly
//     describes. The feature is UNAVAILABLE, not
//     half-alive - a menu that dies takes every other
//     feature with it. Round 79 moves the build to the
//     Registrar (29 K free, owns the ranked keys) and
//     deletes this branch; the empty-region reply and
//     Manual Add keep working meanwhile.
//   round 78 (field amendment): the FIRST Companion
//     Stack-Heap Collision, caught in the field 2026-10-31 -
//     Watch+ right after a 20-line List All: the pick-dialog
//     build (10 keys + 10 labels + llDialog, ~1.5-2 K) ran on
//     a heap still carrying the listing relay's uncollected
//     churn garbage (Mono collects lazily; Status read 3338
//     free BEFORE the listing). The build is now GUARDED:
//     below PICK_FLOOR it NUDGES the collector first (the
//     r74 mini-nudge pattern - a short-lived 10-element parse
//     is the collection trigger, with the r74 500-byte safe
//     floor), then refuses honestly into the existing "too
//     busy" dialog if the post-nudge reading still does not
//     fit (Manual Add always works). A halted Companion takes
//     every menu and every line of text with it; this script
//     is the text valve and must never collide. Round 79
//     (planned) moves the listing relay itself to the
//     Registrar, which owns the data and has 29 K free - the
//     churn source this guard defends against then goes away.
//   round 72: the BUSY note ("tracking the first N only")
//     now words itself by CAUSE - the Data Script sends a
//     5th field: 1 = the population trigger narrowed the
//     cap (the original "Very busy region" line), 0 = memory
//     did (new line: "Low script memory - tracking the first
//     M of N avatars for now. Tracking widens again on its
//     own as memory recovers." - true since the Data Script's
//     round-72 sustained recovery). The r71 field report had
//     the old line blaming "very busy region" in a quiet
//     11-avatar region. No field 4 = treated as memory
//     (an older Data Script narrowed only on population or
//     memory steps; this degrades safely either way).
//   round 58: Debug now also prints the Data Script's
//     starvation record (SMH.starve: short 10-60 s freezes
//     while worn, invisible to the 5-minute gap recorders).
//     The language map moved on again - linkset data now, so
//     NO script's heap holds it (round 57's move to Data cost
//     it ~4.5KB and tripped the memory valve in a 16-avatar
//     region). This script is unchanged otherwise.
//   round 57: language map moved to the Data Script (this one
//     hit 90% used in-session; the map is a lookup table, not
//     prose). LM_LANG_ASK/TELL now carry only the alive ping.
//     New "Trace" button in Settings toggles SMH.trace so every
//     script prints its steps while hunting the freeze bug.
// ------------------------------------------------------------
// The designated place to take work off the Core Script: ALL
// user-facing text lives in THIS script's own 64KB Mono
// budget (a notecard would not help - Core would have to read
// it back into its own heap). Current duty: language-code ->
// full-name lookups, ALL ANNOUNCEMENT formatting (round 79:
// the listing lines are the Registrar's own now), and the
// entire dialog menu system; Core only forwards menu
// commands and finished facts. If this script is missing,
// Core notices via the handshake, prints raw payloads and
// raw language codes - detection keeps working, but the
// Menu Button does nothing and the encounter log does not
// record.
//
// Protocol (message numbers MUST match Core/Data exactly):
//   Core  -> here : LM_LANG_ASK (str = "ping" only, alive check)
//   here  -> Core : LM_LANG_TELL ("ping=ok")
//   Core/Data/Registrar -> here : LM_SAY (str = "kind|fields" -
//                   see handleSay: A arrival, L left, W watched,
//                   AE census bot, C summary, D slowdown, N the
//                   Data/Registrar system notes, and "NR|ok" -
//                   the Registrar's Watch+ handshake that stands
//                   the pick-flow safety net down. Round 79: the
//                   SB/S/SE listing kinds are GONE - the
//                   Registrar formats and batches its own
//                   listing lines, and this script never touches
//                   a pick build again)
//   Core  -> here : LM_MENU_OPEN (Menu Button clicked),
//                   LM_UI_STATE ("enabled|scope|range"),
//                   LM_WATCH_LIST (CSV of keys)
//   here  -> Registrar : LM_SWEEP_ASK ("NEAR" - Watch+ asks the
//                   Registrar for its own nearest-people dialog;
//                   the ranking, the build and the channel all
//                   live in the Registrar's budget now)
//   here  -> Core : LM_UI_CMD ("SCAN" / "STATUS" / "WIPE" /
//                   "SYNC", or "POWER|0/1", "SCOPE|0/1/2",
//                   "RANGE|m", "ADD|uuid", "REM|n")
//   Debug: LM_MEM_ASK broadcast - every script answers with
//   LM_MEM_TELL ("name|freeBytes|build"); THIS script prints
//   them.
// Unknown language codes are returned unchanged (Core shows
// the raw code as a fallback).
//
// VERSION: round 75 (2026-10-31): THE DEBUG LOG, UI SIDE.
// Diagnostics gains two buttons: "Debug Log" toggles SMH.dlog
// (the exact Trace pattern - the Data Script's dbgLog and
// Core's cDbg check the flag live before every entry, so off
// costs one linkset read per event) and "Dump Log" prints
// both rings oldest-first straight from linkset data (Data's
// SMH.dbg0..23: boot number, ~60 s snapshots, pipeline gaps,
// valve trips / probes / narrows / restores, census and
// guard refusals; Core's SMH.cdbg0..7: boot, gaps, the stall
// detector, wipe). A memory episode finally leaves behind a
// story a Status Check cannot reconstruct after the fact.
// Wipe clears both rings and the flag.
//
// VERSION: round 69 (2026-10-30): the Watch+ pick keys stop
// leaking. The field log showed this script fall 6624 -> 4830
// free across one Watch+ visit: the pick dialog's key list
// (up to 10 keys, ~1 KiB) was built on every "NR|" reply and
// never released after the flow ended - in the tightest
// script of the three. The list is now cleared when the flow
// exits: any Back/Cancel (which climbs out of every menu
// level) and the typed Manual Add both drop it. The Watch+
// flow itself re-populates the list on demand, so nothing
// user-visible changes except the memory no longer ratchets
// down per visit. Data also changed this round (tracked
// population to the linkset datastore); this script needed no
// protocol change for that - the notes and lines it formats
// are identical.
//
// VERSION: round 67 (2026-10-30): the full-script audit round.
// One real find: Back from Settings > Encounters (the keep-
// days picker) jumped to MAIN instead of climbing one level
// to Settings - the keep dialog reused gMenu level 1, so the
// Back handler's "one level up" rule sent it past its parent.
// The keep picker gets its own level 8, and Back now returns
// to Settings from all three of its subdialogs (2/7/8). The
// rest of this script audited clean: no dead globals, no
// unused message numbers, every dialog label inside the
// 24-byte cap via pickName, the encounter calendar math and
// the scan-line batching all verified. Also this round (all
// three scripts): a ROUND stamp as the first line of every
// script, and the LM_UI_STATE payload lost its dead 4th
// field (Core's free memory - nothing read it; Status Check
// asks each script live). Round 64 remains below. (Full
// history in the project notes.)
//
// VERSION: round 64 (2026-10-30): the bracketed tags close
// the line. The field order used to strand them between
// Lang: and the distance ("Lang:Polish [NEW ACCOUNT] | 22m
// away" - Rachel called it a random place); the documented
// design always said "tags at the end of the line", and the
// distance (round 10) has been landing after them ever
// since. entryText now composes the distance itself (new
// dist parameter), so the tags sit at the true end:
// "MayaFour | Age:1d | Pay:None | Lang:Polish | 22m away
// [NEW ACCOUNT]". The A and S branches pass dist in; the
// LEFT line (no distance) already ends in its [WATCHED] tag.
// Round 63 remains the last change below. (Full history in
// the project notes.)
//
// VERSION: round 63 (2026-10-30): the status line labels
// its scope - "ON | Area: Parcel | Watch:0" instead of the
// bare "parcel" (Core's statusLine matches; Rachel's
// request), shown in every dialog header and the Status
// Check header. Also this round (no code here): the Debug
// menu's freeze lines (starve tally, both gap records)
// are now cleared by Wipe and by each script's own reset,
// so Status Check stops reprinting stale history after a
// Wipe. Round 62 remains the last change below. (Full
// history in the project notes.)
//
// VERSION: round 62 (2026-10-30): Settings > Debug is now a
// MENU (Rachel's request): the one-shot diagnostic report
// became "Status Check" inside it - the name states its
// purpose - and the Trace toggle (round 57) moved in from
// the Settings grid, where it never really belonged. The
// debug dialog shows Trace's current state, both actions
// re-open it, and Back climbs to Settings (new gMenu level
// 7; the welcome keeps 6). Three user-facing strings gained
// the new path ("Settings > Debug > Status Check" /
// "> Trace"). Round 60 remains the last change below.
// (Full history in the project notes.)
//
// VERSION: round 60 (2026-10-30): new "PAUSE" note. The
// freeze mystery closed (see the Data Script's round-60
// block): since server 2026-09-22 (#2693) scripts attached
// from agent inventory follow the parcel "run scripts"
// rule, so a parcel with scripts disabled stops the whole
// HUD until the wearer crosses into one that allows
// scripts. Nothing can run while stopped, so the HUD cannot
// warn at the door - instead Data's first tick back after a
// 60 s+ worn gap sends "N|PAUSE|<secs>" and THIS script
// prints the explanation (causes named, resume confirmed).
// Round 56 remains the last change below. (Full history in
// the project notes.)
//
// VERSION: round 56 (2026-10-30): Debug now also prints the
// Core Script's liveness gap right after its memory line
// (shared gapText helper) - the two scripts' gaps together
// tell a server-side outage (equal) from a single-script
// problem (unequal). Round 55 remains the last change
// below. (Full history in the project notes.)
//
// VERSION: round 55 (2026-10-30): new "GAP" note for Debug -
// the Data Script's liveness recorder reports its most
// recent scheduling gap ("no pass for Xm, ending T SLT -
// the HUD was frozen or logged out"), printed right after
// Data's memory line. Round 54 remains the last change
// below. (Full history in the project notes.)
//
// VERSION: round 54 (2026-10-30): Watch+ offload to the Data
// Script. This script boots at only ~8 KB free, and the old
// Watch+ ranked people with a full llGetAgentList fetch
// (~10 KB past 80 avatars) plus one padded distance string
// per avatar - a guaranteed collision in any busy region.
// showAddMenu now just asks the Data Script ("NEAR"); its
// "NR|keys" reply builds the same nearest-first dialog
// (handleSay), with Manual Add kept in every failure path
// (refusal, empty region, or a 10-second timer expiry).
// Round 53 remains the last change below.
// (Full history in the project notes.)
//
// VERSION: round 53 (2026-10-30): transferred-HUD welcome fix.
// The welcome timer now checks the stored owner before
// showing the dialog: a HUD passed to a new avatar inside
// the 8-second window resumes with the previous owner's
// PENDING welcome, which fired on the old session's channel
// (its click lost when the owner-change reset
// re-randomized the channel) while the reset's own welcome
// then asked a second time. Only the matching owner fires
// the welcome. Round 51 remains the last change below.
// (Full history in the project notes.)
//
// VERSION: round 51 (2026-10-28): new "N|code|..." note kind -
// the Data Script's user-facing notes (valve/busy/scan/
// summary lines) moved into THIS budget as a code->text
// table (the designated text valve; Data's static strings
// shrank by the full text of all eight). Recent rounds
// (full history in the project notes):
//   50 - new "Summary" main-menu button (on-demand census
//        line, next to List All); the "C" census message
//        gained a 7th source field ("A" arrival / "M" menu)
//        that picks the ARRIVAL SUMMARY / SUMMARY label, and
//        the new-account skip reads "not counted (low script
//        memory)".
//   49 - comment cleanup + dead gListen global removed; no
//        behavior change.
//   48 - watched arrivals are logged as encounters from the
//        "A" branch (Data suppresses their in-scope WIN in
//        favor of the ARRIVED [WATCHED] line); out-of-scope
//        entries log from the "W" branch as before.
//   47 - encounter log covers automated agents too ("AE"
//        census events and arrival flags bit 1; entries are
//        tagged "[AUTOMATED AGENT]" - 5th "|A" field, so old
//        4-field entries still read fine).
//   46 - LSL has no ?: operator (round 45 broke compilation
//        with one; rewritten as an if - keep this in mind for
//        any new code).
//   45 - encounter log: 50-slot ring in the linkset store,
//        SLT display, Settings > Encounters keep-days
//        (7/14/30/60/90, default 30), 24h dedupe.
//   31/30/28 - chat-length guards (llOwnerSay truncates at
//        1024 bytes; name links cost ~71 B); names in chat
//        pass through VERBATIM as viewer links (pickName is
//        for dialog BUTTONS only); buttons byte-trim to the
//        24-byte llDialog cap.
//   25/23 - dialog channel is RANDOM PER BOOT; the menus do
//        not duplicate the panel buttons.
// ============================================================
// ============================================================

integer LM_LANG_ASK = 19024;
integer LM_LANG_TELL = 19025;
// (19026 was LM_HELP_ASK - retired: help is now a notecard the
// Core Script gives with llGiveInventory. Gap kept reserved.)
integer LM_SAY = 19027;
integer LM_MENU_OPEN = 19028;
integer LM_UI_STATE = 19029;
integer LM_UI_CMD = 19030;
integer LM_WATCH_LIST = 19031;
integer LM_SWEEP_ASK = 19034; // -> the Registrar Script: "NEAR"
                              // (Watch+ wants the nearest-people
                              // keys; the ranking moved to the
                              // Registrar's memory budget,
                              // round 78)
integer LM_MEM_ASK = 19036;  // -> LINK_SET (Status Check): every
                             // script answers with LM_MEM_TELL
integer LM_MEM_TELL = 19037; // <- any script: "name|freeBytes|build" -
                             // THIS script prints the debug lines

integer MENU_TIMEOUT = 60; // seconds for typed menu input

string P = "SMH.";        // linkset-data key prefix (shared with
                         // the Core Script; see its header). The
                         // Companion touches the store only for
                         // the one-time setup flag below, the
                         // debug rings it prints, and the
                         // round-80 error-ring self-report.
string BUILD_NUM = "110626084"; // round 84: the build stamp
                                // (MMDDYY 110126 + zero-padded round
                                // 080) - printed on every boot line
                                // and on Core's Status line (kept
                                // identical in all four scripts;
                                // bump the round digits every round)

string HUD_VERSION = "1.0"; // user-facing HUD version, shown in the
                            // welcome dialog and the Debug report
                            // (keep in sync with Core's copy)

integer ERR_LOG_SLOTS = 10; // known-error ring size (SMH.err0..9);
                            // the Data Script writes the entries -
                            // keep in sync with its copy
integer DBG_SLOTS = 24;     // round 75: Data's debug-log ring size
                            // (SMH.dbg0..23) - keep in sync with
                            // the Data Script's copy
integer CDBG_SLOTS = 8;     // round 75: Core's debug-log ring size
                            // (SMH.cdbg0..7) - keep in sync with
                            // the Core Script's copy
integer ENC_MAX = 50;        // encounter ring size (SMH.enc0..49);
                            // written and read by this script only
integer ENC_DAYS_DEFAULT = 30; // round 80: encounter keep-days
                            // - now a FIXED 30 days (the 7/14/30/
                            // 60/90 picker is cut; the old
                            // SMH.encdays preference is no longer
                            // read - Wipe still deletes it)

// Menu system state (moved out of Core with the menus).
// (Round 79: the listing relay globals gScanOut / gScanLines
// and the pick-flow globals PICK_FLOOR / gPickKeys are GONE -
// the Registrar owns the listing relay and the pick build now,
// and this script holds only the gPickDue safety-net stamp.)
integer gChannel = -1;  // random per-boot dialog channel
integer gMode = 0;      // 0 = dialog mode, 1 = Manual Add UUID,
                        // 2 = radius (both via pop-up text box)
integer gModeExpiry = 0;
integer gMenu = 0;      // which dialog is on screen right now:
                        // 0 = main, 1 = settings, 2 = area,
                        // 3 = Watch+ (WAITING on the Registrar's
                        //        own dialog - the state still
                        //        matters to the safety net and
                        //        the Back climb),
                        // 4 = Watch- remove,
                        // 5 = radius size (under Area),
                        // 6 = first-time welcome,
                        // 7 = diagnostics (under Settings),
                        // 8 = encounter keep-days (under
                        // Settings; round 67 - its own level
                        // so Back climbs to Settings, not
                        // past it to Main).
                        // Lets "Back" climb one level (Radius ->
                        // Area -> Settings -> Main) instead of
                        // jumping straight back to Main.
integer gPickDue = 0;   // Watch+: unix time the NEAR request
                        // expires (0 = none pending). The
                        // Registrar clears it with its "NR|ok"
                        // handshake; if none comes (missing or
                        // halted script), the timer offers
                        // Manual Add - Watch+ must never leave
                        // the wearer stuck.
integer gRemPage;       // Watch- dialog page (6 names per page,
                          // round 80: viewer-link body entries)
integer gLowLast = 0;   // round 80: unix time of the last
                          // low-water self-report (throttle 10
                          // minutes; 0 = never reported)
integer gCoreWatch;  // round 82: we declared Core unresponsive
                     // and own the power light (red blink)
integer gWatchBlink; // round 82: the watchdog blink toggle
integer gLinkPowerC; // round 82: the power prim's link number
                     // (0 = not looked up yet)
integer gWatchGrace; // round 82: no watchdog evaluation before
                     // this unix time (boot + any shared freeze)
integer gTickLast;   // round 82: our own last tick time (the
                     // shared-freeze immunity)
integer gWelcome = FALSE; // one-time welcome flow is active
                          // (first wear / new owner / after Wipe)
integer gSetupDue = 0;    // unix time to show the welcome dialog
                          // (0 = none pending; fired from timer)

// Settings mirror (kept current via LM_UI_STATE pushes).
integer gEnabled = TRUE;
integer gScope = 0;     // 0 = region, 1 = radius, 2 = parcel
integer gRange = 25;
list gWatch = [];       // key mirror for Roster / Watch-

// The language-code -> full-name map lived here until round 57
// (90% used in-session), then in the Data Script for one round,
// and since round 58 in LINKSET DATA - a flat string Core
// writes at boot, which no script's 64KB heap has to hold.
// Language resolution is entirely the Data Script's business.

// ---------- announcement formatting (moved out of Core) ----------

integer strBytes(string s)
{
    // LSL strings are byte strings, and display names can contain
    // multi-byte UTF-8 - llDialog buttons cap at 24 BYTES, so a
    // plain llStringLength check is not enough. base64 encodes 3
    // bytes per 4 characters; the trailing "=" padding rounds up,
    // so subtract it.
    string b = llStringToBase64(s);
    integer n = llStringLength(b) * 3 / 4;
    if (llGetSubString(b, -1, -1) == "=")
        n = n - 1;
    if (llGetSubString(b, -2, -2) == "=")
        n = n - 1;
    return n;
}

// (Round 80: pickName is DELETED - the Watch- remove dialog
// was its last user, and the rework put viewer-link names in
// the dialog BODY instead; the Registrar keeps its own copy
// for the Watch+ pick buttons, whose candidates are always
// present.)

string nameUri(key k)
{
    // Viewer-resolved display-name link (clickable, opens the
    // profile) - works even for OFFLINE watch-list entries,
    // unlike script-side name lookups.
    return "secondlife:///app/agent/" + (string)k + "/displayname";
}

string payText(string pay)
{
    // Short forms: the field already says "Pay:", so repeating
    // "Payment" was redundant. The raw numeric pay value (not
    // this text) is what the flag logic checks, so shortening is
    // display-only.
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
    // "AUTOMATED AGENT:" (entryText) instead of a trailing tag, so
    // bots stand out immediately. Bit 4 (no payment info) is not
    // rendered either: the Pay: field in entryText already says it.
    string s = "";
    if (f & 2)
        s += " [NEW ACCOUNT]";
    if (f & 8)
        s += " [WATCHED]";
    return s;
}

// Age in days -> readable: past the first year it becomes
// "2y 34d" (years + leftover days); within the year it stays
// "123d"; unknown stays "?". A 365-day year is the convention -
// leap days just fold into the leftover.
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
    // The name arrives as a viewer display-name link from the
    // Data Script - pass it through VERBATIM (never a pickName
    // call: that is a key-based lookup, and a name string would
    // fail both lookups).
    // Round 64: the distance is composed HERE now (new dist
    // parameter), so the bracketed tags can close the line -
    // they used to sit between Lang: and the distance, which
    // read as a random spot. The documented design and the
    // LEFT line's shape both put tags at the very end.
    string s = lead + name + " | Age:" + ageText(age) + " | Pay:" + payText(pay) +
        " | Lang:" + lang;
    if (dist >= 0)
        s += " | " + (string)dist + "m away";
    return s + flagText(f);
}

// ============================================================
// ENCOUNTER LOG - where and when you met watched people
// (region-wide, like their alerts) and automated agents
// (within the Area, like their ARRIVED lines). Both directions
// count: they enter, or you arrive where they already are.
// Storage: 50-slot ring in the linkset store (SMH.enc0..49 +
// SMH.encNext, written and read by THIS script only), entries
// "unix|uri|region|parcel" + "|A" on automated ones, ~150 B
// each - a full ring is ~5% of the 128 KiB store, so it cannot
// overflow by construction. Entries past the keep-days
// (user-settable, default 30) are purged at boot and on every
// view; a repeat meeting with the same person in the same
// region within 24 hours is not logged twice (relogs cannot
// flood the log). The uri is a viewer link, so log lines show
// each person's CURRENT name.
// ============================================================

// (Round 80: encDays() is DELETED - the 7/14/30/60/90-day
// picker is cut and encounters keep a FIXED 30 days (the
// ENC_DAYS_DEFAULT constant below); the retention math uses
// the constant directly.)

integer daysFromCivil(integer y, integer m)
{
    // Days from 1970-01-01 to the FIRST of year y, month m
    // (Hinnant civil-calendar era math; the whole unix->SLT
    // chain was verified against 2000+ real timestamps incl.
    // both 2025-2027 DST switches and leap days).
    // LSL has no ?: operator - the mp step is an if statement.
    if (m <= 2)
        y -= 1;
    integer era = y / 400;
    integer yoe = y - era * 400;
    // mp = (m + 9) % 12 in Hinnant's formula; LSL has no ?:
    // conditional operator, so the adjustment is an if statement.
    integer mp = m + 9;
    if (m > 2) mp = m - 3;
    integer doy = (153 * mp + 2) / 5;
    integer doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

integer civilFromDays(integer z)
{
    // Inverse of daysFromCivil; returns the date packed as
    // YYYYMMDD. The Jan/Feb year bump is the classic trap of
    // this algorithm.
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
    // Two-digit zero pad for the SLT line.
    if (n < 10)
        return "0" + (string)n;
    return (string)n;
}

string sltFromUnix(integer u)
{
    // "YYYY-MM-DD HH:MM" in SLT (Pacific). US DST rule: from
    // the 2nd Sunday of March 02:00 local through the 1st
    // Sunday of November 02:00 local (10:00 / 09:00 UTC).
    // Logged events are always ~now, so u is far from any
    // negative-math edge.
    integer ymd = civilFromDays(u / 86400);
    integer y = ymd / 10000;
    integer march1 = daysFromCivil(y, 3);
    integer nov1 = daysFromCivil(y, 11);
    integer start = (march1 + (7 - (march1 + 4) % 7) % 7 + 7) * 86400 + 36000;
    integer end = (nov1 + (7 - (nov1 + 4) % 7) % 7) * 86400 + 32400;
    integer off = 28800; // PST
    if (u >= start && u < end)
        off = 25200; // PDT
    integer lu = u - off;
    ymd = civilFromDays(lu / 86400);
    integer ls = lu % 86400;
    return (string)(ymd / 10000) + "-" + encP2((ymd / 100) % 100) + "-" +
        encP2(ymd % 100) + " " + encP2(ls / 3600) + ":" +
        encP2((ls % 3600) / 60);
}

encPurge()
{
    // Remove entries past their keep-days (boot + every view).
    integer now = llGetUnixTime();
    integer limit = ENC_DAYS_DEFAULT * 86400; // round 80: fixed 30 days
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
    // Log one encounter. The parcel is where THEY were
    // (position -> parcel name, up to 63 chars; an unreadable
    // position just omits it). Dedupe first: same person +
    // same region within 24h is skipped. The write goes to the
    // ring's next slot, overwriting the oldest once all 50
    // are in use.
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
        entry += "|A"; // automated tag; 4-field entries read fine too
    llLinksetDataWrite(P + "enc" + (string)slot, entry);
    llLinksetDataWrite(P + "encNext", (string)slot);
}

encShow()
{
    // The Encounters view: purge, then print oldest -> newest.
    // Lines batch at ~750 bytes (llOwnerSay truncates at 1024;
    // a worst-case line with a 63-char parcel name is ~230
    // bytes, so a batch can never reach the cap).
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
    // A liveness-gap duration for the Debug report (rounds 55/56):
    // minutes = a freeze or a short logout/detach; hours = a
    // normal logout or a long time off.
    string dur = (string)(secs / 60) + "m";
    if (secs >= 3600)
        dur = (string)(secs / 3600) + "h " + (string)((secs % 3600) / 60) + "m";
    return dur;
}

handleSay(string str, key id)
{
    // The Data Script sends viewer display-name links for names -
    // pass them through VERBATIM. KeepNulls matters so an empty
    // field keeps the field positions stable.
    list f = llParseStringKeepNulls(str, ["|"], []);
    string kind = llList2String(f, 0);
    if (kind == "A")
    {
        // Field 7 = distance in meters from the wearer when the
        // announcement was composed; -1 means the position could
        // not be read (the avatar may have left already). The
        // distance and the flag tags are composed inside
        // entryText (round 64) - tags LAST, so they close the
        // line instead of landing mid-sentence.
        integer dist = (integer)llList2String(f, 7);
        llOwnerSay("ARRIVED (" + llList2String(f, 1) + "): " +
            entryText(llList2String(f, 2), llList2String(f, 3),
                      llList2String(f, 4), llList2String(f, 5), llList2String(f, 6),
                      dist));
        // Encounter hooks: an arrival flagged automated (flags
        // bit 1) or watched (bit 8) is logged right here - an
        // in-scope watched arrival produces no WIN (the Data
        // Script suppresses it in favor of this line), so the
        // ARRIVED line itself is the only hook that sees those
        // meetings. Out-of-scope watched entries keep their WIN
        // and log from the "W" branch; the 24h dedupe guards
        // the overlap. The key rides the link message.
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
        // "entered" / "already in" are logged as encounters
        // (field 4 = the avatar key, sent for exactly this;
        // absent on raw-fallback lines). "entered" now arrives
        // only for people entering OUTSIDE the scope.
        if (llGetListLength(f) > 3 &&
            (llList2String(f, 2) == "1" || llList2String(f, 2) == "2"))
            encLog((key)llList2String(f, 3), llList2String(f, 1), FALSE);
    }
    else if (kind == "AE")
    {
        // One per automated agent the census found in scope on
        // arrival - log the encounter silently (the ARRIVAL
        // SUMMARY's bot count already announces them).
        encLog((key)llList2String(f, 2), llList2String(f, 1), TRUE);
    }
    // (Round 79: the SB / S / SE listing branches are GONE -
    // the Registrar Script formats, batches and prints its
    // own listing lines from its own budget; this script's
    // relay buffers went with them.)
    else if (kind == "C")
    {
        // One-line population census: "C|scope|total|new|bots|
        // watched|src". On arrival (src "A") it replaces an
        // arrival line for everyone already present; src "M" is
        // the main menu's Summary button asking for the same
        // numbers on demand - the label says which.
        // New accounts "-1" = not counted (the Data Script
        // skipped the born lookups to protect memory) - say so
        // honestly.
        string label = "ARRIVAL SUMMARY";
        if (llList2String(f, 6) == "M")
            label = "SUMMARY";
        string newT = llList2String(f, 3);
        if (newT == "-1")
            newT = "not counted (low script memory)";
        // Round 80: two optional trailing fields from the
        // Registrar (absent fields parse to 0 - an older
        // Registrar keeps working): field 7 = the census
        // fit-cap's trimmed people, field 8 = the Data
        // Script's published tracking cap (SMH.cap) for the
        // busy-region context, shown only when the count
        // really exceeds it.
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
        // Region slowdown watch, edge-triggered by the Data
        // Script: ONE line when the sim slows down, ONE when it
        // recovers. Field 3 = sim speed as a percent of normal
        // (100 = full speed).
        if (llList2String(f, 1) == "low")
            llOwnerSay("REGION SLOWDOWN: the sim is running at " +
                llList2String(f, 2) + "% of normal speed - something heavy " +
                "is running in this region (script or particle spam, " +
                "physics, or sim trouble). You will hear when it recovers.");
        else
            llOwnerSay("Region speed recovered: " + llList2String(f, 2) +
                "% of normal.");
    }
    else if (kind == "NR")
    {
        // Round 79: this branch has exactly ONE job left - the
        // HANDSHAKE CLEAR. The Registrar answers Watch+ with
        // "NR|ok" at the top of its own dialog build, on its
        // own channel, from its own budget; the moment it
        // arrives this script's 10-second safety net stands
        // down (the picker is on screen - or its refusal is
        // already honestly worded BY the Registrar). If no
        // "NR|ok" ever comes (missing or halted Registrar),
        // the timer offers Manual Add. Everything this branch
        // used to do - the pick build, the guard, the floors -
        // moved to the Registrar with the collisions they
        // caused.
        gPickDue = 0;
    }
    else if (kind == "N")
    {
        // System notes from the Data Script: "N|code|params".
        // The FULL TEXT of every note lives in THIS budget -
        // the Companion is the designated text valve (round
        // 51), so Data's static strings shrank to a few short
        // codes. Unknown codes print nothing (a newer Data
        // with an older Companion degrades to silence, never
        // to a wrong line).
        string code = llList2String(f, 1);
        if (code == "MEMPAUSE")
            llOwnerSay("Low script memory in this region - arrival and watch alerts are paused so the HUD does not crash. They come back on their own as the region quiets down. Menus still work; Settings > Debug > Status Check shows the memory numbers.");
        else if (code == "BUSY")
        {
            // Round 72: the note words itself by CAUSE (the
            // Data Script's 5th field): 1 = the population
            // trigger narrowed the cap - a genuinely busy
            // region, the original wording; 0 or absent =
            // memory narrowed it (the ladder / free steps /
            // a valve trip) - and the r72 Data recovery makes
            // "widens again on its own" a true promise.
            if (llGetListLength(f) > 4 && llList2String(f, 4) == "1")
                llOwnerSay("Very busy region (" + llList2String(f, 2) + " avatars) - tracking the first " + llList2String(f, 3) + " only, to protect memory.");
            else
                llOwnerSay("Low script memory - tracking the first " + llList2String(f, 3) + " of " + llList2String(f, 2) + " avatars for now. Tracking widens again on its own as memory recovers.");
        }
        else if (code == "SCANBUSY")
            llOwnerSay("A scan is already running - please wait.");
        // (Round 79: SCANSTOCK deleted - no sender since r76.)
        else if (code == "SCANMEM")
            // Round 80: the guard is population-priced now, so
            // a refusal means a genuinely busy region - and
            // Summary is the busy-region context tool (it
            // survives any listing refusal).
            llOwnerSay("Too little free memory to list people safely here - Summary still works for a quick count.");
        else if (code == "SCANEMPTY")
            llOwnerSay("No avatars currently in " + llList2String(f, 2) + ".");
        // (Round 79: SUMPAUSE deleted - its only sender, the
        // Data Script's census refusal, went to the Registrar,
        // whose Summary works even while detection is paused.)
        else if (code == "SUMSTOCK")
            llOwnerSay("Still taking stock of this region - try Summary again in a few seconds.");
        else if (code == "PAUSE")
        {
            // Round 60: the long-pause resume notice (Data's
            // 60 s+ gap while continuously worn). While the
            // HUD cannot run there is no way to warn at the
            // door, so the first tick back explains the
            // silence instead.
            llOwnerSay("Scanning was paused for " +
                gapText((integer)llList2String(f, 2)) +
                " - usually a parcel with scripts disabled (the HUD cannot run there) or a sim too busy to run it. Scanning has resumed.");
        }
        else if (code == "GAP")
        {
            // The Data Script's liveness recorder (Debug only):
            // its most recent scheduling gap - how long the
            // pipeline made no pass at all. Minutes = a freeze
            // or a short logout; hours = a normal logout.
            llOwnerSay("Detection made no pass for " +
                gapText((integer)llList2String(f, 2)) +
                ", ending " + sltFromUnix((integer)llList2String(f, 3)) +
                " SLT - the HUD was frozen, detached or logged out.");
        }
    }
}

// ---------- menus (moved out of Core) ----------

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
    // Mono scripts get a 65536-byte budget; show the percentage
    // USED next to the free number wherever memory is listed.
    return (string)freeBytes + " free (" +
        (string)((100 * (65536 - freeBytes)) / 65536) + "% used)";
}

string lsdPct(integer freeBytes)
{
    // The linkset-data store gets the same "% used" format as
    // the script-memory lines. Total is 131072 bytes (128 KiB)
    // per linkset - the llLinksetDataWrite wiki page.
    return (string)freeBytes + " free (" +
        (string)((100 * (131072 - freeBytes)) / 131072) + "% used)";
}

string uiStatus()
{
    string onoff = "OFF";
    if (gEnabled)
        onoff = "ON";
    // Round 63: label the scope ("Area: Parcel" - the bare
    // word read as noise). Matches Core's statusLine exactly.
    string area = scopeLabel();
    area = llGetSubString(llToUpper(area), 0, 0) + llDeleteSubString(area, 0, 0);
    return onoff + " | Area: " + area +
        " | Watch:" + (string)llGetListLength(gWatch);
}

showMainMenu()
{
    // Frequently used actions only. Anything the panel already
    // has a physical button for (Power, Help, Sound) is
    // deliberately NOT duplicated here anymore. llDialog lays
    // buttons out in rows of three: Summary/List All/Watch+,
    // then Watch-/Watch List/Encounters, then Status/Settings.
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
    // Configuration submenu, reached from the main menu. Round
    // 80: the Encounters retention picker is CUT (encounters
    // keep a fixed 30 days - the constant). Mid-field
    // amendment: the Export / Import buttons are REMOVED -
    // they never worked (this script sent the labels verbatim
    // while the Registrar matched UPPERCASE - LSL comparison
    // is case-sensitive, so the sweep-ask branches were dead
    // on arrival). Backup abilities return in a later round,
    // planned as sync with a web management page.
    gMode = 0;
    gMenu = 1;
    llDialog(llGetOwner(),
        "Settings\n" + uiStatus(),
        ["Area", "Debug", "Wipe", "Back"],
        gChannel);
}

showDebugMenu()
{
    // The diagnostics submenu (round 62, Rachel's request): the
    // Debug REPORT (header + per-script memory lines + error
    // ring) lives here as "Status Check". Round 80: the Trace
    // toggle is CUT with the trace mode everywhere - the
    // debug rings won the diagnosis war (the r79 field
    // follow-ups ran entirely on rings; every TRACE gate and
    // branch is deleted from all four scripts this round).
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
    // Round 75: print both debug rings oldest-first. The Data
    // Script keeps SMH.dbg0..23 and Core keeps SMH.cdbg0..7 in
    // the SHARED linkset-data store - the same trick as the
    // error ring (a HALTED writer's story survives the halt,
    // and this script never holds it in heap). Entries are
    // "ts|Data/Core|tag|fields"; the loop mirrors the Status
    // Check's error-ring print. Nothing recorded prints a
    // "none recorded" line per section. Worst case ~32 chat
    // lines, owner-only, on demand.
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
    // Step 1 of the area flow: WHERE to watch. Radius used to
    // cram the size buttons into this same dialog, but that
    // mixed two questions onto one screen; picking a size now
    // opens a second dialog (showRadiusMenu) instead, so the
    // scope switch only happens once a width is actually chosen.
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
    // Step 2 of the area flow: HOW WIDE the radius sphere is.
    // Picking a size here carries the scope switch with it, so
    // Backing out of this dialog leaves the settings untouched.
    gMode = 0;
    gMenu = 5;
    llDialog(llGetOwner(),
        "Radius size (sphere around you)\nCurrently: " + (string)gRange + "m" +
        "\n\nPick a size, or Custom for a pop-up box:",
        ["10m", "25m", "50m",
         "100m", "Custom", "Back"],
        gChannel);
}

showWelcomeMenu()
{
    // One-time greeting, fired ~8 seconds after the first boot of
    // a fresh / new-owner / wiped HUD (see state_entry). It asks
    // the first WHERE question; picking Radius continues into the
    // normal size dialog (gMenu 5), whose Back returns here.
    // Ignore = keep the defaults (Parcel, ON), never asked again.
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
    // Called once the welcome's area question is answered; the
    // SCOPE / RANGE command has already been sent to Core.
    gWelcome = FALSE;
    gMenu = 0;
    llOwnerSay("Setup complete. Click the Menu button for watch lists and settings; the Help button has the full guide.");
}

showAddMenu()
{
    // Watch+ made easy - and round 79 makes it ONE LINE: the
    // REGISTRAR owns the ranking, the pick-dialog build, the
    // refusal wording and the channel; THIS script only asks
    // (the "NEAR" request) and keeps the safety-net stamp so a
    // missing or halted Registrar still gets an honest answer
    // (the timer's Manual Add offer below). The Registrar's
    // "NR|ok" handshake stands the net down. The two field
    // collisions that ended the in-Companion build era both
    // happened inside what this function used to hold.
    gMenu = 3;
    gPickDue = llGetUnixTime() + 10; // Registrar missing/halted: expiry
    llMessageLinked(LINK_SET, LM_SWEEP_ASK, "NEAR", "");
}

showRemoveMenu()
{
    // Watch- as a click dialog too: no more typed numbers on a
    // channel. Round 80 REWORK: the buttons were pickName LIVE
    // lookups, which return "" for anyone not in the region -
    // so absent avatars all showed as "Unknown Avatar" (the
    // removal chat line was always fine: it uses the viewer-
    // link safeName). The dialog BODY now carries the numbered
    // VIEWER-LINK names - the viewer resolves links in the
    // body for offline and never-seen avatars alike - and the
    // buttons are plain numbers. llDialog caps the BODY at 512
    // bytes and each link is ~73, so a page is 6 entries (a
    // 10-entry page would truncate mid-name). Entry numbers
    // are the GLOBAL watch-list numbers (the same ones the
    // Watch List text display shows).
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
    // 512-byte body budget: header + 6 x ~78-byte lines +
    // "Page N of M" footer ~= 490 - the tight header is on
    // purpose, a "Remove who from the watch list?" header
    // would ride the cap.
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

showRoster()
{
    integer n = llGetListLength(gWatch);
    if (n == 0)
    {
        llOwnerSay("The watch list is empty.");
        return;
    }
    // llOwnerSay truncates at 1024 bytes (wiki) and each entry is
    // a ~115-byte name-link + key line, so a full 20-entry list
    // would be cut mid-entry. Flush at ~900 bytes; the guard
    // skips the LAST entry so the final chunk always prints.
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

watchRing(string what)
{
    // Round 82: the watchdog's forensics, in the shared error
    // ring - same shape as the low-water entry below, so
    // Status Check prints it with zero new reader code. One
    // line per transition only (the watchdog declares and
    // clears once, never repeatedly).
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
    // Round 82: the watchdog needs the power prim. Buttons are
    // found BY NAME (relinking the HUD never breaks them);
    // the root fallback matches Core's own lookup.
    integer n = llGetNumberOfPrims();
    integer i;
    for (i = 1; i <= n; i++)
    {
        if (llGetLinkName(i) == "Power Button")
            return i;
    }
    return LINK_ROOT;
}

default
{
    state_entry()
    {
        // Dialog responses can only arrive via a listen, so a
        // channel is unavoidable. RANDOM PER BOOT, deep negative:
        // the old owner-key-derived channel was predictable, and
        // anyone who knew the algorithm could pre-open a listener
        // and eavesdrop on button presses within chat range. The
        // listen accepts ONLY the owner's messages (see listen),
        // so spoofing was never possible.
        gChannel = -(integer)llFrand(1000000000) - 1000000000;
        llListen(gChannel, "", llGetOwner(), "");
        // 5-second tick: typed-input mode expiry AND the delayed
        // first-run welcome below.
        llSetTimerEvent(5);
        // Round 82: no watchdog evaluation for the first 30 s -
        // a stale pre-reboot corehb in linkset data must not
        // read as a dead Core before it ticks once.
        gWatchGrace = llGetUnixTime() + 30;
        // Prune expired encounter entries at boot (the
        // Encounters view prunes them again on every open).
        encPurge();
        // One-time welcome: fresh HUD, new owner, or after a Wipe
        // (Core's Wipe deletes SMH.setup and its owner-change path
        // clears it; Core never writes it). Writing the flag NOW
        // means it greets exactly ONCE: clicking Ignore keeps the
        // defaults (Parcel, ON) and is never asked again. The
        // stored-owner check makes this safe no matter which
        // script boots first after a transfer.
        integer fresh = (llLinksetDataRead(P + "setup") != "1");
        string storedOwner = llLinksetDataRead(P + "owner");
        if (storedOwner != "" && (key)storedOwner != llGetOwner())
            fresh = TRUE;
        if (fresh)
        {
            gWelcome = TRUE;
            llLinksetDataWrite(P + "setup", "1");
            gSetupDue = llGetUnixTime() + 8; // let the boot lines land first
        }
        // Ask Core for the settings/watch mirror in case we
        // (re)started after it did.
        llMessageLinked(LINK_SET, LM_UI_CMD, "SYNC", "");
        // Announce ourselves to Core: its startup "ping" may
        // have been sent before we existed (saving a script
        // only resets THAT script), and Core's gHaveLang gate
        // would otherwise wait forever before formatting.
        llMessageLinked(LINK_SET, LM_LANG_TELL, "ping=ok", "");
        llOwnerSay("Companion ready (Build " + BUILD_NUM +
            "). Memory: " + memPct(llGetFreeMemory()));
    }

    changed(integer change)
    {
        // Sold/transferred: re-derive the channel for the new owner.
        if (change & CHANGED_OWNER)
            llResetScript();
    }

    timer()
    {
        // Round 82: OUR HEARTBEAT + THE CORE WATCHDOG first;
        // the round-80 low-water report follows unchanged.
        integer now = llGetUnixTime();
        // Our liveness heartbeat, published for the Core
        // Script's failure sweep - it checks all three worker
        // scripts every 5 s; ours proves this timer runs.
        llLinksetDataWrite(P + "chb", (string)now);
        // SHARED-FREEZE IMMUNITY: if OUR tick is late too, the
        // whole linkset froze together (a logout, a no-scripts
        // parcel, sim trouble) - stale heartbeats then mean
        // everyone froze, not a failure. Skip the evaluation
        // this pass and re-grace, exactly like Core's own wake
        // grace.
        if (gTickLast != 0 && now - gTickLast > 60)
            gWatchGrace = now + 30;
        gTickLast = now;
        if (now >= gWatchGrace)
        {
            integer cb = (integer)llLinksetDataRead(P + "corehb");
            if (!gCoreWatch && cb != 0 && now - cb > 120)
            {
                gCoreWatch = TRUE;
                llSetTimerEvent(0.5); // blink red at the busy cadence
                llOwnerSay("The Core Script is not responding - take the HUD off and wear it again to fix it.");
                watchRing("corewatch: corehb stale " +
                    (string)(now - cb) + "s");
            }
            else if (gCoreWatch && (cb == 0 || now - cb <= 120))
            {
                gCoreWatch = FALSE;
                llSetTimerEvent(5);   // back to the slow tick
                llOwnerSay("The Core Script is responding again.");
                watchRing("corewatchok: hb=" + (string)cb);
            }
        }
        if (gCoreWatch)
        {
            // We own the power light while Core is gone - a
            // dead Core cannot report itself. Blink red/dark
            // (the same pair Core's failure blink uses); Core
            // re-writes its color on every pass once it runs
            // again, so there is no hand-back to negotiate.
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
        // Round 80: LOW-WATER SELF-REPORT. This script is the
        // only one without its own memory telemetry, and the
        // club soak read 1170 free (98%) with no story to tell.
        // Below 2500 free, write the SHARED error ring
        // ("ts|Companion|low: N free") - the reader is Status
        // Check's existing error print, so there is zero new
        // reader code - at most once per 10 minutes, so a long
        // tight session cannot flood the ring.
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
        // Round 84: SELF-HEAL RESET - the low-water line's
        // answer. Boot 6954 fell to 376 free in three days of
        // normal wear (the r80 club soak read the same
        // ratchet): Mono heap fragmentation from ordinary
        // string churn, not a data leak, and only a reset
        // reclaims it. Durable state is all in linkset data,
        // so at a QUIESCENT moment - no typed-input mode, no
        // pending Watch+ pick, no welcome flow or scheduled
        // one, and no live Core watchdog (a dead Core needs
        // the watchdog ALIVE, not a reset) - write the
        // forensics line and reset. Boot restores full memory;
        // Core's 120 s failure bar never sees the gap (the
        // first tick republishes "chb" seconds later).
        if (cf < 2000 && gMode == 0 && gPickDue == 0 &&
            !gWelcome && gSetupDue == 0 && !gCoreWatch)
        {
            watchRing("selfheal: reset at " + (string)cf + " free");
            llResetScript();
        }
        // Expire typed-input modes.
        if (gMode != 0 && llGetUnixTime() > gModeExpiry)
            gMode = 0;
        // Fire the delayed first-run welcome (see state_entry).
        // OWNER GUARD: a transferred HUD can RESUME with a
        // welcome the previous owner's session scheduled (the
        // HUD was passed to a new avatar inside the 8-second
        // window). That stale welcome must never fire: it
        // speaks on the OLD session's dialog channel, and the
        // owner-change reset re-randomizes the channel, so the
        // click would be silently lost - and the new owner's
        // own state_entry then asks a second time (field
        // report: "it asks a second time"). Only the matching
        // owner may fire the welcome; the owner-change reset
        // always schedules the new owner's own one.
        if (gSetupDue != 0 && llGetUnixTime() >= gSetupDue)
        {
            gSetupDue = 0;
            string storedOwner = llLinksetDataRead(P + "owner");
            if (storedOwner == "" || (key)storedOwner == llGetOwner())
                showWelcomeMenu();
        }
        // Watch+ safety net: if the Data Script never answered
        // the NEAR request (missing, halted, or the message was
        // lost), the pending pick dialog would never appear -
        // the wearer clicks Watch+ and nothing happens. Offer
        // the honest explanation instead, with Manual Add kept
        // available (it needs no region fetch).
        if (gPickDue != 0 && llGetUnixTime() >= gPickDue)
        {
            gPickDue = 0;
            // Only speak up if the wearer is still waiting on
            // the pick menu; if they navigated elsewhere, let
            // the request die quietly instead of ambushing a
            // different dialog with this one.
            if (gMenu == 3)
                llDialog(llGetOwner(),
                    "The Registrar Script did not answer.\nManual Add still works with an avatar key.",
                    ["Manual Add", "Back"], gChannel);
        }
    }

    listen(integer channel, string name, key id, string msg)
    {
        if (channel != gChannel || id != llGetOwner())
            return;
        msg = llStringTrim(msg, STRING_TRIM);

        // (Round 80: the trace-mode click narration is cut with
        // the trace mode everywhere - the debug rings won the
        // diagnosis war.)

        // Typed input for the pending menu mode.
        if (gMode == 1)
        {
            gMode = 0;
            // (Round 79: the pick-key list clear is gone with
            // the list itself - the Registrar owns the keys
            // behind its own dialog buttons now.)
            llMessageLinked(LINK_SET, LM_UI_CMD, "ADD|" + msg, "");
            return;
        }
        if (gMode == 2)
        {
            gMode = 0;
            // A typed radius implies Radius scope (the size dialog
            // is only reachable via Area -> Radius or the one-time
            // welcome), so switch the scope along with the width.
            llMessageLinked(LINK_SET, LM_UI_CMD, "SCOPE|1", "");
            llMessageLinked(LINK_SET, LM_UI_CMD, "RANGE|" + msg, "");
            if (gWelcome)
                finishSetup();
            return;
        }

        // Dialog buttons: local navigation stays here; anything
        // that changes settings is forwarded to Core.
        if (msg == "Summary")
        {
            // On-demand population census (the same one-line
            // summary the HUD prints on entering a region).
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
            // Round 80: the Settings retention picker is cut -
            // this button only ever shows the log now (kept a
            // fixed 30 days).
            encShow();
            return;
        }
        if (msg == "Watch+")
        {
            showAddMenu(); // nearest people as buttons + Manual Add
            return;
        }
        if (msg == "Manual Add")
        {
            // Pop-up text box for a raw avatar key: the submitted
            // text arrives on gChannel from the owner, so the
            // gMode == 1 branch in listen above handles it. If the
            // user clicks Ignore no chat is generated, so the mode
            // simply expires via gModeExpiry.
            gMode = 1;
            gModeExpiry = llGetUnixTime() + MENU_TIMEOUT;
            llTextBox(llGetOwner(),
                "Paste the avatar key (UUID) you want to watch, then click Submit:",
                gChannel);
            return;
        }
        if (msg == "More")
        {
            // Watch- dialog pagination (10 names per page);
            // showRemoveMenu wraps past the last page.
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
        // (Ping, Help, Turn On and Turn Off are panel buttons,
        // not menu items.)
        if (msg == "Status")
        {
            llMessageLinked(LINK_SET, LM_UI_CMD, "STATUS", "");
            return;
        }
        if (msg == "Debug")
        {
            // Round 62: Settings > Debug opens the diagnostics
            // submenu (Status Check + Trace) instead of firing
            // the report directly.
            showDebugMenu();
            return;
        }
        if (msg == "Status Check")
        {
            // Header first, then every script answers the
            // LM_MEM_ASK broadcast with a labeled memory line
            // (a MISSING line = that script is not responding,
            // which is itself the diagnosis). Then the
            // known-error ring (SMH.err0..9, written by the
            // Data Script), oldest first.
            llOwnerSay("Opossum Labs Awareness HUD v" + HUD_VERSION +
                " | " + uiStatus() +
                " | Channel: " + (string)gChannel +
                " | LinksetData: " + lsdPct(llLinksetDataAvailable()));
            // Known-error ring (SMH.err0..9 in the shared store;
            // the Data Script writes them - e.g. dataserver
            // no-reply timeouts - and Wipe clears them). Print
            // oldest first; "none recorded" when the ring is empty.
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
        // (Round 80: the Trace button branch is cut with the
        // trace mode everywhere.)
        if (msg == "Debug Log")
        {
            // Round 75: flip SMH.dlog - the Data Script's
            // dbgLog and Core's cDbg gate every entry on this
            // flag (the exact Trace pattern: off = one linkset
            // read per event, on = one short ring write per
            // recorded event). The rings keep the latest 24 /
            // 8 entries; Dump Log prints them; Wipe clears the
            // rings and turns recording off.
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
            // Back climbs one level: Radius -> Area (or back to
            // the Welcome if that is where this flow started),
            // Area -> Settings, anything else -> Main. Cancel only
            // appears on the Wipe confirm (opened from Settings)
            // but the same "one level up" rule is safe for it too.
            // (Round 79: the pick-key list clear is gone with the
            // list - the Registrar owns the pick flow's keys now;
            // leaving a menu here just stands the safety net down
            // next tick, which is exactly right.)
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
            // No scope switch here anymore: picking Radius just
            // opens the size dialog, and the scope (plus width)
            // is sent only when a size is actually chosen there.
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
            // A size pick implies Radius scope, so carry the
            // scope switch together with the width.
            llMessageLinked(LINK_SET, LM_UI_CMD, "SCOPE|1", "");
            llMessageLinked(LINK_SET, LM_UI_CMD,
                "RANGE|" + llGetSubString(msg, 0, llStringLength(msg) - 2), "");
            if (gWelcome)
                finishSetup();
            return;
        }
        if (msg == "Custom")
        {
            // Pop-up text box, same flow as Manual Add: the
            // submitted text arrives on gChannel from the owner,
            // so the gMode == 2 branch above handles it (it now
            // sends SCOPE|1 before RANGE). Ignore just lets the
            // mode expire quietly.
            gMode = 2;
            gModeExpiry = llGetUnixTime() + MENU_TIMEOUT;
            llTextBox(llGetOwner(),
                "Type the radius in meters (5-256), then click Submit:",
                gChannel);
            return;
        }

        // Round 80: the Watch- remove dialog's buttons are
        // PLAIN NUMBERS now (the names live in the dialog body
        // as viewer links) - "3" removes entry 3. The number
        // matches the global watch-list index, so it can never
        // remove the wrong entry. (Round 79: the Watch+ PICK
        // branch is gone - the Registrar's own dialog answers
        // its own numbered buttons on its own channel.)
        integer num = (integer)msg;
        if (num > 0 && (string)num == msg && gMenu == 4 &&
            num <= llGetListLength(gWatch))
        {
            gMenu = 0;
            llMessageLinked(LINK_SET, LM_UI_CMD, "REM|" + (string)num, "");
            showRemoveMenu(); // re-show: the list just shrank
            return;
        }
    }

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
            // (Round 67: the payload is 3 fields now - the old
            // 4th field, Core's free memory, was dead; memory
            // is Status Check's business, which asks each
            // script live.)
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
            // Debug: answer the broadcast like the other
            // scripts. Round 80 (pre-field amendment): the
            // reply carries this script's build number, same
            // as its siblings' replies.
            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Companion Script|" + (string)llGetFreeMemory() +
                "|" + BUILD_NUM, "");
            return;
        }

        if (num == LM_MEM_TELL)
        {
            // One labeled memory line per answering script.
            // Round 80 (pre-field amendment): each reply now
            // carries the answering script's OWN build number
            // as a third field - printed as "Build:NNNNNNNNN"
            // on that script's line, so a mixed-round unit
            // shows different builds on its lines (the
            // support rationale behind per-script builds). An
            // old-shape reply (no third field) still prints
            // cleanly without the suffix.
            list f = llParseString2List(str, ["|"], []);
            string mline = "Debug: " + llList2String(f, 0) + " - " +
                memPct((integer)llList2String(f, 1));
            string bld = llList2String(f, 2);
            if (bld != "")
                mline = mline + " | Build:" + bld;
            llOwnerSay(mline);
            // The Core Script's liveness gap (its own freeze
            // record), right after its line (round 56): shown
            // together with the Data Script's GAP note, the two
            // gaps tell a server-side outage (both scripts
            // unscheduled for the SAME stretch) from a
            // single-script problem (only one gap).
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
            // The Data Script's starvation record (round 58):
            // short 10-60 s queue jams while WORN - too short
            // for the 5-minute gap recorders, and exactly the
            // "buttons dead, then everything at once" freeze.
            // Recorded since round 58 so Debug shows it with
            // Trace off. Not counted: detach/log out (gWearT).
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

        // Handshake only since round 57: language resolution
        // no longer involves this script at all (the map lives
        // in linkset data since round 58; the Data Script
        // resolves codes locally). Core still pings at boot to
        // confirm THIS script is alive and replying; anything
        // else is noise.
        if (str == "ping")
            llMessageLinked(LINK_SET, LM_LANG_TELL, "ping=ok", "");
    }
}
