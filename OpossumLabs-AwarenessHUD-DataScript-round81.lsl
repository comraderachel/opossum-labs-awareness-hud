
// ROUND 81 (2026-11-02) - paste the whole script over the old
// one. ONLY THIS SCRIPT changes this round (plus the help
// notecard); keep the round-80 Registrar, Companion and Core
// Scripts exactly as they are. This round: the ARRIVAL
// PRE-LINE (when the HUD adopts a new region the wearer just
// entered, it first says "New region detected - counting who
// is here now", so a summary that is still seconds away is
// never mistaken for a dead HUD) and the PARCEL TRIGGER
// (Parcel scope now treats walking into a new parcel exactly
// like a region change: "New parcel detected" plus the
// one-line arrival summary, lifting the round-79 parcel
// silence; Region and Radius scopes stay region-change-only,
// so their routine parcel crossings stay quiet). The
// power-button blink already covered the census fetch window
// and routine detection sweeps already never blink - both
// stay exactly as they were.
// ============================================================
// OPOSSUM LABS AWARENESS HUD - Data Script (any prim)
// ------------------------------------------------------------
// The two memory-heavy jobs used to live here because this
// script has a nearly empty 64KB Mono budget (Core boots with
// ~10KB free; in Core the same key lists - 102 B/key in Mono -
// were a guaranteed Stack-Heap Collision in busy regions).
// Round 78 moved the LISTING side out; round 79 moves the
// LOOKUP side out (census cluster + arrival pipeline). What
// remains here is pure DETECTION - and every byte the moves
// freed is why this script can be expected to clear the
// 13,220-byte crossover at last:
//
// 1. THE DETECTION SWEEP: fetch the region agent list, apply
//    the scope filter (parcel / region / radius), diff
//    arrivals and departures, track watch-list presence, and
//    after a region jump / teleport / fresh wear ASK THE
//    REGISTRAR for the one-line arrival summary (the census
//    itself is the Registrar's now). Guards degrade
//    gracefully instead of crashing:
//      - the scope snapshot is KEYS-ONLY (names in chat lines
//        are viewer links composed from the key at announce
//        time, so no capture exists and nothing can fail);
//      - populations beyond the tracking cap are truncated
//        with an honest note. Watched avatars are still
//        checked against the FULL region list first, so the
//        watch list stays reliable when the valve trips. The
//        cap is DYNAMIC: 60 normally, stepping DOWN to 35 / 20
//        on region population (>40 / >70 agents, before the
//        first adopt) or on low free memory, silently
//        re-baselining as it goes; restored to 60 only on
//        region change, re-wear, or settings re-base - never
//        mid-session, so it cannot flap;
//      - below a DYNAMIC memory floor the sweep pass is
//        skipped with a one-time note: 6000 free, or the
//        known cost of the pass itself - (live population +
//        live scope) x ~102 B - when the region is big
//        enough that the region fetch alone (the wiki caps
//        llGetAgentList at 100 and offers no way to limit
//        it) would not fit (round 68).
// 2. THE MEMORY VALVE / LADDER / PROBE: self-calibrating from
//    the boot canary (gBootFree), the honest rung pricing of
//    round 72, the two-tier GC nudge of round 76 - all kept,
//    because detection itself still has to fit in this
//    budget. An arrival is now HANDED to the Registrar the
//    moment the sweep sees it ("LOOK|key" on the LM_SWEEP_ASK
//    wire): the Registrar does the born/pay/lang lookup in
//    ITS budget and tells Core the finished arrival line -
//    so the arrival pipeline's queue, its timeout flush,
//    its stale purge and its dataserver event no longer
//    exist HERE at all.
//
// Drop into the HUD linkset (any prim). REQUIRED: without it
// the HUD detects nothing.
//
// Protocol (numbers MUST match Core/Companion/Registrar):
//   Core/Companion -> here : LM_DATA_ASK ("ping" handshake
//                   only - all lookups are the REGISTRAR's
//                   now), LM_UI_STATE, LM_WATCH_LIST
//   Core   -> all  : LM_SWEEP_ASK ("REBASE" - this script
//                   answers it; round 79: "SCAN", "NEAR"
//                   and "CENSUS" are the REGISTRAR's to
//                   answer - it hears the same wire)
//   here  -> Registrar : LM_SWEEP_ASK, the round-79 handoff
//                   payloads: "LOOK|key" (one arrival to
//                   look up and tell Core), "CENSUS|A" (we
//                   just adopted a new region: print the
//                   arrival summary), "RESET" (we just
//                   traveled: purge your pipeline - in-
//                   flight rows from the old region must
//                   not land as post-abort stragglers)
//   here  -> Core : LM_DATA_TELL ("ping=ok" ONLY now - the
//                   finished-arrival tell is the REGISTRAR's),
//                   LM_EVENT ("OUT|key|name" left scope,
//                   "WIN|name|key" / "WOUT|name" watched
//                   entered / left (r48: WIN fires only for
//                   entries from OUTSIDE the tracked scope -
//                   an in-scope entry is covered by its
//                   ARRIVED [WATCHED] line), "WFOUND|name|
//                   key" watched already present on arrival,
//                   "BUSY|0" the boot-only counter rebalance)
//   here  -> Companion : LM_SAY ("D|low|pct" / "D|ok|pct"
//                   slowdown / recovery, "N|code|params"
//                   system note - the FULL TEXT of every
//                   note lives in the Companion's budget
//                   (the designated text valve; only the
//                   boot line stays here) ) - the Companion
//                   formats and prints them. (Round 79: the
//                   census "C|" line and the "AE|" encounter
//                   line are the REGISTRAR's to say now.)
//   any -> all : LM_MEM_ASK / LM_MEM_TELL (Debug)
// "name" fields everywhere are viewer display-name links
// composed from the agent key.
//
// VERSION: round 81 (2026-11-02): THE ARRIVAL PRE-LINE AND
// THE PARCEL TRIGGER (field-driven). (1) THE PRE-LINE: a
// region change ends in the one-line ARRIVAL SUMMARY, but
// until it lands (one sweep to adopt, then the census fetch -
// born-date asks can take seconds in a busy region) the HUD
// said NOTHING, so a wearer who just teleported could not
// tell "working" from "dead". Every region adoption now says
// "New region detected - counting who is here now." first.
// travelReset() gains a WHY parameter ("region" / "rewear")
// and a new gAdoptWhy global carries it to the adopt block;
// boot ("") and re-wear stay silent (their own blocks
// already speak), and the login wake keeps its resume line.
// The sweep's region-identity guard gains a gBaselined
// gate: at boot the empty gBaseRegion made it call
// travelReset on every pass before the first adopt -
// harmless before, but it would now stamp a REGION cause on
// the boot census. (2) THE PARCEL TRIGGER: in Parcel scope a
// parcel change used to rebase silently (round 79 chose
// silence; the field verdict is that silence reads as dead).
// The parcel check now arms the adopt census too, so
// crossing a parcel boundary prints "New parcel detected" and
// the summary of the NEW parcel's population (the
// Registrar's census already counts by the CURRENT scope -
// no Registrar change needed). rebaseData() clears
// gAdoptWhy with the flag, so a settings re-base still
// cancels a pending arrival line. Region and Radius scopes
// keep region-change-only summaries; routine sweeps still
// never blink (the blink wraps only census / listing fetch
// windows, like a disk activity light).
// VERSION: round 80 (2026-11-01): FIVE FIXES, ALL
// FIELD-DRIVEN. (1) THE BUSY-NOTE FLAP: the hour-long club
// soak printed "Very busy region (59 avatars) - tracking the
// first 35 only" every ~30 s. Root cause: in the club this
// script sat at 31 K+ free, so the round-72 sustained-
// recovery block (15 passes above the full-width price)
// restored POP_CAP, the population trigger (>40 -> 35)
// re-narrowed it the same pass, the BUSY note re-armed, and
// the loop repeated forever - each "recovery" manufactured
// the next note. FIX: the recovery block now skips
// POPULATION-cause caps (gCapCrowd == TRUE) - a population
// cap is the honest width for THIS region and only the
// region emptying (or a travel reset) widens it. The
// episode-end restore needs no gate: gMemNoted is only set
// by a valve trip, a trip always resets gCapCrowd to FALSE
// (memory cause), and the population trigger cannot re-set
// it while a trip holds the cap at the floor - so crowd can
// never be TRUE on that path. The spontaneous note now
// prints ONCE per arrival (the trigger's first narrowing),
// which is exactly what it was for. (2) SMH.cap PUBLISH:
// this script writes the CURRENT tracking cap to linkset
// data on cap CHANGE only (gCapPub mirror; the wipe list
// gains SMH.cap) - the Registrar reads it to append
// "detection tracking the first N" context to the Summary
// line and the List All preamble, so the busy-region
// context is available on demand instead of on a timer.
// (3) LOGIN WAKE: a relog fires no LSL event, but the gap
// recorder already detects the dead stretch - the first
// sweep pass after a 5+ minute gap now prints "Detection
// resumed after ..." with the Area label and watch count
// and fires the adopt census ("CENSUS|A"), so a login ends
// in the same arrival summary a region change does. Gated
// on gEnabled + gHaveState: a wake while OFF stays quiet
// (OFF is a true standby since this round). (4) TRACE CUT:
// the trace mode is deleted everywhere (gates, branches,
// the gHbChecked one-shot) - the debug rings won the
// diagnosis war; the Companion's toggle and Core's wipe
// entry go the same round. (5) TYPE-TRAP FIX: the
// watchedIn presence-row drop passed a KEY needle against
// the STRING gWatch mirror - llListFindList matches types
// strictly, so it ALWAYS returned -1 and a removed watch
// entry's presence row survived to fire a phantom
// "watched avatar left" later. Needle cast to (string),
// same fix as the Registrar's two census/flags sites this
// round. The type-trap audit is now a standing round step.
// (6) STATUS CHECK BUILD LINE (pre-field amendment,
// Rachel's request): the LM_MEM_TELL reply grows a third
// field - this script's OWN build number - so the Status
// Check memory line reads "Data Script - N free (P% used)
// | Build:NNNNNNNNN" and a mixed-round unit shows
// different builds on its lines.
//
// VERSION: round 79 (2026-10-31): THE 4TH-SCRIPT SPLIT,
// PART 2 - THE LOOKUP SIDE MOVES OUT. Round 78 moved the
// listing (scan / List All / Watch+); this round moves the
// CENSUS CLUSTER and the whole ARRIVAL-LOOKUP PIPELINE to
// the Registrar, completing the architecture: Data is now
// pure detection - sweep, valve/ladder/probe, tracked pad,
// watch pad, WFOUND/WIN/WOUT, dilation watch, liveness - and
// hands every dataserver question to the Registrar on the
// LM_SWEEP_ASK wire: "LOOK|key" per arrival, "CENSUS|A" on
// adopt (the one-line arrival summary), "RESET" on travel
// (the r78 field follow-up #8's straggler wart: in-flight
// rows from the old region used to flush as a late
// "listing complete" in the NEW region - the Registrar now
// purges its pipeline on every abort path). DELETED here:
// askAgent / sendEntry / checkPending / findAgentIndex /
// findRequestIndex / calculateAgeFromBornDate / clearPipeline
// / purgeCensusRows / startCensus / sendCensus /
// startCensusNow / knownKeys, the gPending / gRequests /
// gLangCache / census-counter globals, the whole
// dataserver event, the timer's stale-purge and timeout-
// flush and census-deadline blocks, the sweep's census-skip
// early return, and the trip block's clearPipeline() call
// (the Registrar's rows complete or purge on their own -
// a detection pause must not reach into another script's
// budget). KEPT: the valve, the ladder, the two-tier probe,
// the GC nudge constants (the probe still uses them), the
// boot canary, the watch/census-on-adopt flags (the FLAG
// stays; the WORK it triggers is the Registrar's "CENSUS|A"
// broadcast now), and every liveness feature. Core is
// UNTOUCHED this round (its LM_DATA_TELL handler already
// parses the Registrar's arrival TELLs - same payload
// shape as the old Data ones). CANARY EXPECTATION: boot
// free should clear the 13,220-byte crossover at last
// (12304 + the deleted pipeline bytecode and globals - the
// r78 sizing note called ~916 B short; the deletion list
// above is several times that). The Registrar's canary
// DROPS correspondingly (~29 K, huge headroom for the
// census + picker it took on); the Companion's RISES (the
// pick build and its buffers leave). SUCCESS BAR for the
// field soak: zero Stack-Heap Collisions from NEW causes.
//
// VERSION: round 78 (2026-10-31): THE 4TH-SCRIPT SPLIT,
// PART 1 - THE LISTING SIDE MOVES OUT. The r77 bridge was
// sized to make this round possible; the canary after the
// r78 paste sizes the rest of the plan. The scan cluster
// (startScan / pumpScan / resetScan / entryFlags / the scan
// half of sendEntry), the region-fetch half of the pipeline
// bookkeeping (gScanQueue / gScanNext / gScanLeft /
// gScanCount / gPumping, the scan wave and its stale-purge
// branch) and sendNearest all MOVE to the new Registrar
// Script, which answers "SCAN" and "NEAR" on the same
// LM_SWEEP_ASK wire with the same LM_SAY reply protocol -
// the Companion needs ZERO changes. SEMANTIC CHANGE,
// deliberate and disclosed: List All used to list the
// sweep's TRACKED population (narrowed to as few as 10 by
// the valve, and refused entirely while paused); the
// Registrar lists the CURRENT SCOPE - up to 20 people in
// scope right now - in ANY region, including regions where
// this script has honestly paused detection. The listing
// button now answers "who is here" instead of "who is the
// sweep currently tracking". What stays here: the 2s
// detection sweep, the tracked pad, the valve/ladder/probe,
// the arrival pipeline and the census (the census and the
// arrival-lookup handoff move in round 79 - MAX_PENDING_
// REQUESTS keeps its census-era sizing until then). What
// this script GAINS: a smaller, calmer heap - the scan
// waves and the fetch were the worst per-press spikes this
// budget ever took, and a collision in the Registrar can
// no longer take detection down with it (the r15 doctrine
// with its mirror image: the work goes where the memory
// is, AND the crash cannot kill the core function).
//
// VERSION: round 77 (2026-10-31): THE CANARY VERDICT - THE
// DEBUG LOG SLIMS TO ITS DIAGNOSTIC CORE. The r76 field
// canaries (two pastes, a Wipe, four regions) read 1476
// free at boot - the round-75 debug ring cost ~3 K of
// BYTECODE (3-4x the ~1 K estimate the round was approved
// on), pushing Data under the minimum pass price (2204 at
// one avatar): detection tripped instantly in EVERY region,
// empty home included (sweeps 1454, pause pinned 1086;
// at 29 people, pinned 928). The r75 ring sites are cut
// back to the four that carry a diagnosis - BOOT (the
// budget datum), GAP, TRIP (free/pop/need at the moment of
// pausing) and PROBE (the pre=/post= GC-nudge pair) - and
// SNAP / NARROW / RESTORE / WIDEN / CENSUS / SCANGUARD /
// NEARGUARD are deleted (their stories are re-derivable
// from Status Check + the four kept entries, and each
// site's string build costs bytecode this script no longer
// has). Core's ring is untouched (15480 free). This is the
// BRIDGE round of the agreed plan: detection returns in
// quiet regions now (~3.5-4 K boot expected - the canary
// after paste is the truth, not this estimate), and the
// 4th-script split (scan / census / nearest out of Data)
// is the next rounds; a sweep() diet only after the
// split, if the post-split canary still says so.
//
// VERSION: round 76 (2026-10-31): "TOO BUSY" IN AN EMPTY
// REGION - the r75 field log (teleport to a quiet platform,
// valve trip at 1362, then free PINNED at 912 for many
// minutes while every List All answered "Still taking stock
// of this region") exposed two stacked r69/r74-era bugs:
// (1) THE SCANSTOCK FOSSIL: startScan refused whenever
// !gBaselined && free <= 20000 - a flat 20000 sized against
// the r69-era 12 K boot, unconditionally true at today's
// ~3-4 K boot, and a trip ALWAYS clears gBaselined (for the
// silent re-adopt), so after ANY pause every List All was
// refused with a "busy"-sounding line - in an EMPTY region -
// and while paused no pass ever re-adopts, so it never
// cleared. The honest guard (gBootFree - 1500) sits right
// below it; the fossil is DELETED. (2) THE NUDEGE'S OWN
// FLOOR EXCLUDED THE PINNED CASE: the r74 GC nudge was
// gated free > 2600 "to keep the parse safe" - but a pause
// pinned at 912 by uncollected garbage never reaches 2600,
// so the nudge never ran and the pause could not self-end in
// even an empty region (probe price at 1-3 avatars is only
// ~2.2-2.6 K). The nudge is now TWO-TIER: the full 40-element
// parse above 2600, and a 10-element mini parse above 500 -
// the ~350 B transient is safe at a pinned-low reading, and
// any allocation pressure on a garbage-pinned heap is the
// collection trigger the nudge exists to pull. The r75 PROBE
// entry (pre=/post=) measures whether it works, directly.
//
// VERSION: round 75 (2026-10-31): THE DEBUG LOG. A memory
// episode can no longer be reconstructed after the fact -
// a Status Check reads the moment, not the story, and the
// r73/r74 field sessions needed the BOOT number, the trip
// readings, and the probe's pre/post-nudge values to tell
// "the region is honestly too big" apart from "Mono's lazy
// collector is lying about free memory". Every important
// moment now lands in a rotating linkset-data ring
// (SMH.dbg0..23, 24 slots) as "ts|Data|TAG|fields": BOOT
// (the gBootFree number the r74 valve derives everything
// from), SNAP (a ~60 s snapshot of free/pop/cap/pending/
// requests), GAP (a dead pipeline, with the exact seconds),
// TRIP, PROBE (pre- and post-nudge readings - the direct
// GC-nudge theory test), NARROW, RESTORE, WIDEN, CENSUS,
// SCANGUARD, NEARGUARD. The Core Script keeps its own 8-slot
// ring (CBOOT/STALL/STALLOK/WIPE/CGAP); the Companion's
// Debug menu gains "Debug Log" (toggle, SMH.dlog - the exact
// Trace pattern: flag off = one linkset read per event) and
// "Dump Log" (prints both rings oldest-first). Off by
// default; Wipe deletes the ring and the flag.
//
// VERSION: round 74 (2026-10-31): THE VALVE STOPPED TELLING
// THE TRUTH - the r73 field session (fresh Wipe, an 11-12
// avatar region) tripped the valve at 3570 free and Status
// Check read the SAME 4364 free an hour later with the
// pipeline empty (the trip purges every list and the pad),
// which pins the BOOT number: the compiled script alone now
// leaves only ~4.4-4.7 K free, down from 11958 at r68 - the
// growth of rounds 70-73 was never re-measured, and every
// absolute threshold in the memory design went dead at
// once. The census floor (8000) made "New accounts: not
// counted" permanent (the budget formula can never be
// positive); the episode-end restore (>9000) is
// unreachable in ANY region, so after one trip the cap
// stays floored for the whole session (the wideTick
// recovery is gated on !gMemNoted and can never fire); the
// scan guard (<9000) refuses List All everywhere; and the
// r33/36 free-based cap steps (free<10000 -> 35,
// free<6000 -> 20) fired on EVERY pass, forcing the cap to
// 20 before the honest ladder even voted. Round 74 makes
// the valve SELF-CALIBRATING - no absolute memory constant
// survives: (1) gBootFree is captured at state_entry and
// the boot canary prints it; (2) the census ask floor is
// now PRICED (a full-width pass at the census-time
// population, the same (pop + min(pop, POP_CAP)) x 102 +
// 2000 arithmetic the ladder uses) - a quiet region counts
// new accounts again, a tight region honestly prints "?";
// (3) the episode-end restore is PRICE-BASED too (full
// width fits again), so it can actually fire and hand the
// cap back; (4) the scan guard derives from gBootFree
// (refuse below boot-1500, floored at 2500 - the scan
// costs roughly a pass, not a fixed 9000); (5) the
// free-based cap steps are DELETED - the r70-72 ladder
// subsumes them with honest pricing, and at a 4.5 K boot
// they were unconditionally true dead weight; (6) the
// recovery probe NUDGES MONO'S LAZY COLLECTOR before it
// judges: three short-lived CSV parses (fixed ~1 K each,
// guarded by a 2600 floor) put allocation pressure on the
// heap so the collector reclaims the pause's own churn
// garbage BEFORE the fit test - llGetFreeMemory
// under-reports until a collection runs, and a paused
// script allocates almost nothing, so the 16:27 wipe sat
// pinned at 3570 for 80+ minutes on garbage the probe
// could not see past. HONEST LIMIT, unchanged by this
// round: at a ~4.5 K boot the pass price at 11 avatars
// (~4.1-4.4 K) leaves no room for the steady pipeline, so
// detection in an 11-12 avatar region will still pause
// honestly (and resume when the region quiets) - the
// capability envelope is now ~8-10 avatars, down from the
// r68-era ~88; restoring it needs a real footprint diet
// (round 75 candidates: measured function profile has
// sweep() at 517 lines / 47 ll-calls as the mass, with
// scan/census/nearest at 45-78 lines each).
// VERSION: round 73 (2026-10-30): the Watch+ nearest-ranking
// guard was DEAD - it refused in every region. The flat
// 13000-free threshold was set in round 54 against that
// era's ~16.5 K boot; boot fell under 13000 around round
// 68, and every Watch+ press since has answered "too busy
// to rank nearby people safely" regardless of population
// (the r72 field session hit it in a quiet 11-avatar
// region - the wording made a stale constant sound like a
// crowd judgment; the r65 lesson again: constants sized
// against a boot budget nobody re-reads). The guard is now
// DYNAMIC, the r68 valve's own arithmetic: the ranking is
// priced at (live population x 102) + 3500 - the fetch
// costs ~102 B per PRESENT avatar (llGetAgentList's own
// 100-agent cap means the 10.2 K worst case is priced by
// the live count, never assumed), and the ~3.5 K covers
// the 20-entry top-10 strided list, its insertion churn,
// the keys list and the reply string. A quiet region ranks
// comfortably (11 avatars need ~4.6 K against ~11 K free);
// a genuinely packed one (80+) still refuses honestly;
// Manual Add always works without a fetch. The menu's
// display limit is UNCHANGED: the ten nearest people as
// numbered buttons plus Manual Add and Back (12 = the
// llDialog cap) - the refusal was never about the menu.
// VERSION: round 72 (2026-10-30): the first r71 field report -
// "tracking the first 10 only" in a QUIET 11-avatar region,
// seconds after a teleport, no valve trip. The wired ladder was
// OVER-PRICING the pass: it demanded (population + rung) x 102
// even when the population could never FILL the rung - at 11
// avatars, rung 60 priced 60 tracked slots while the scope
// copy is bounded by the population and can only ever hold
// 11 keys, an overcharge of ~5 KB. Any transient dip below
// that inflated price (the post-travel churn while garbage is
// uncollected - free memory under-reports between collections
// - or a burst of arrivals) floored the cap at 10, and the
// one-way rule kept it there for the whole session: the only
// memory-based cap restore was the >9000 episode-end one,
// which fires after a full valve TRIP, and no trip happened.
// Fixes (Data + the Companion's note wording):
//   (1) HONEST RUNG PRICING: the pass is priced at
//       (population + min(rung, population)) x 102 + 2000 -
//       what the pass actually spends. A region smaller than
//       its rung can no longer narrow AT ALL (stepping the
//       cap down frees nothing the pass spends, so the ladder
//       correctly declines); the ladder now narrows only when
//       the population genuinely exceeds the rung, and the
//       trip below it stays honest. The paused-state probe
//       prices the same way (a wide paused cap in a mid-size
//       region was overcharged and could stay paused past
//       recovery).
//   (2) SUSTAINED RECOVERY: 15 consecutive passes (about
//       30 s) with free memory above the FULL-width price
//       restore a ladder-narrowed cap to POP_CAP silently -
//       one re-adopt, no note unless the population really
//       truncates it again. Any tight pass resets the count,
//       so the width cannot flap; the mid-population scar
//       (a burst narrows, the dip heals but the cap never
//       climbs back) is gone.
//   (3) THE BUSY NOTE GAINS A CAUSE FIELD (N|BUSY|n|cap|crowd)
//       so the Companion can attribute honestly: the
//       population trigger sets crowd=1 ("very busy region"),
//       the ladder / free steps / trip set crowd=0 (low
//       script memory). The old note blamed "very busy
//       region" even when memory, not population, narrowed
//       the cap. Older Companions ignore the extra field
//       (mixed versions keep working).
// VERSION: round 71 (2026-10-30): external-review fixes - the
// r70 LADDER SHIPPED INERT. An independent review of the
// scripts was adjudicated line by line before this round
// (every claim verified against the source; the refuted
// claims were NOT applied). The headline finding: round 70
// computed the ladder rung but never assigned it to gCap -
// the trip test priced the pass at the narrowed rung while
// the pass itself still ran at the population-trigger cap,
// so "detection narrows instead of pausing" never actually
// happened: a pass the ladder had just sized for rung 10
// could still run at cap 35 (Stack-Heap Collision risk, and
// the 68-70-avatar dead zone was NOT closed). Fixes, ALL in
// this script (Core stays 67, Companion stays 69):
//   (1) LADDER WIRING: after the ladder loop, rung < gCap
//       assigns gCap = rung and re-arms the BUSY note - cap,
//       trip test and pass width are now the same number;
//       the existing gCap != gPrevCap guard re-adopts
//       silently at the narrower width. The adopt TRACE line
//       prints rung= too, so the field test can see the
//       ladder working.
//   (2) REQUEST CAP IN ROWS: the in-flight check counted
//       list ELEMENTS against stride-3 rows, so "30" was
//       really ~10 rows (5 agents), and the census (up to 24
//       X rows, budget-priced, bypasses the cap by design)
//       throttled EVERY arrival lookup while it ran - 15 s
//       partial lines, no [NEW ACCOUNT] / [NO PAYMENT INFO]
//       flags. The check now counts ROWS (30 rows = 15
//       agents, above the queue's realistic maximum of the
//       6-row arrival pipeline x 2 + one SCAN_BATCH wave x
//       2); during a census there is room for 3 more agents
//       instead of none.
//   (3) askAgent OVERFLOW PATH deletes its row BY KEY after
//       sendEntry: the old tail delete ran after sendEntry,
//       which for scan rows can re-enter askAgent via
//       pumpScan and append rows before the delete - so the
//       delete removed a DIFFERENT agent's row (one
//       duplicate line + one lost announcement, and the
//       overflow row survived to be flushed twice).
//   (4) pumpScan RE-ENTRANCY: a gPumping guard turns the
//       nested pumpScan call into a no-op, and gScanLeft is
//       accumulated per row instead of assigned after the
//       loop (the old assignment overwrote the decrements of
//       synchronously completed rows and could stall the
//       wave forever - a stuck scan, SCANBUSY until the
//       blink timeout). Second edge, same fix: the per-row
//       +1 now lands BEFORE askAgent and the loop stops the
//       moment gScanCount hits 0 - a row that completes
//       synchronously AND finishes the whole scan runs
//       resetScan inside askAgent, and with the increments
//       after the call the +1 arrived after the zeroing,
//       leaving a phantom gScanLeft = 1 that hung the NEXT
//       scan mid-wave (and the stale queue snapshot could
//       hand a NULL_KEY row to askAgent).
//   (5) SAME-REGION TELEPORT in Radius scope now re-adopts
//       silently (gBaselined = FALSE): the wearer moved the
//       CENTER, so the old baseline would flood OUT + ARRIVED
//       for everyone who stayed put. Region and Parcel scope
//       keep the no-op (still valid; a same-parcel jump is
//       handled by the sweep's parcel check).
//   (6) ZERO_VECTOR GUARD in scopeAgentsFrom's radius and
//       parcel branches: an unreadable position (the avatar
//       left between the fetch and the query) reads as
//       <0,0,0> - the region's SW corner - and counted as
//       in-radius / same-parcel whenever the wearer stood
//       near that corner. sendNearest already sorted such
//       rows last; the scope filters now match.
//   (7) CENSUS BOOKKEEPING: every census end path purges
//       leftover X rows from gRequests (unanswered rows used
//       to linger until the NEXT census, silently eating the
//       row cap), and Summary gained an in-flight guard
//       (gCensusLeft > 0 -> the existing SUMSTOCK note; a
//       double press used to purge and re-request the whole
//       book and print two summaries).
//   (8) ONE-TIME hb TRACE: with Trace on, the first pass
//       prints the hb datastore write's return code (0 = OK)
//       - the cheapest in-world health check for the linkset
//       datastore, recorded for the r69 post-mortem.
// VERSION: round 70 (2026-10-30): EMERGENCY round - the r69
// field test failed. Symptom: the same arrival line repeated
// every cycle (14 identical ARRIVED lines for one agent in a
// 1-avatar region) and the valve tripped at 4580 free in a
// 3-avatar region, with the pipeline saturated at its caps
// (~7.3K held: the re-asks every pass kept gPending and
// gRequests full). Root cause: r69 stored the tracked
// population in the linkset datastore and WROTE it at the
// end of every sweep pass - built on the delay-table note
// "all llLinksetData* have no forced delay", but the saved
// wiki page for llLinksetDataWrite (the authoritative
// upload) shows a 10.0 forced-delay entry, so each pass
// could stall ten seconds and the CSV never reliably
// survived pass-to-pass (every diff then saw an empty
// tracked set and re-announced + re-asked everyone, every
// cycle). The two references contradict each other; rather
// than patch an unreliable mechanism, r70 removes it: the
// tracked population returns to the HEAP as a comma-wrapped
// CSV STRING global (gKnownPad) - ~38 B/key instead of the
// old list's ~102 B/key, so most of r69's memory win is
// kept with ZERO datastore writes in the sweep (keys are
// exactly 36 chars, so the string iterates by fixed 37-char
// stride for the departure diff and membership stays the
// knownHas string search). And the rung LADDER ships: when
// the pass does not fit at the preferred rung, the cap
// steps DOWN (35 -> 20 -> 10) until it fits and the pass
// RUNS (one silent re-adopt per step; the BUSY note prints
// the honest "tracking the first N") - detection slows
// instead of pausing, exactly the wearer's standing request.
// The valve now trips only when even CAP_FLOOR cannot fit,
// which closes the 68-70 avatar dead zone (rung 35 forced
// there priced over boot free while rung 20 fit). Margin
// 1500 -> 2000 (the string rides the heap readings now).
// A stale "SMH.known" pair may linger in upgraders'
// datastores from the r69 copy - harmless (~1-2 KiB of the
// 128 KiB store, plain-written), cleaned whenever a future
// Core round takes a Wipe-key list update.
//
// VERSION: round 69 (2026-10-30): the tracked population moves
// to the LINKSET DATASTORE ("SMH.known": a comma-wrapped key
// CSV, ~38 B per key of the 128 KiB shared store - never the
// script heap). This is the "linkmemory" lever. The field log
// from a 54-avatar club showed the adopt of 35 keys (~3.6 KiB
// of heap) crash free memory 11524 -> 2294 and pin the valve
// paused for the whole visit; with the keys in the datastore
// the resting footprint is flat at any population, so
// detection keeps running at the 2 s cadence up to ~63-67
// avatars (tracking 35) and ~78-82 (tracking 20), per the
// boot free ceiling of 11958 against the floor formula
// ((pop+rung)x102+1500: 67 at rung 35, 82 at rung 20; a few
// less at in-session free readings). The pause remains only
// where the region fetch itself cannot fit - the wiki offers no
// way to limit llGetAgentList, so a 100-avatar fetch needs
// ~10.2 KiB no matter where the keys live. Also this round:
// the valve floor prices the pass at the rung the population
// trigger is about to set (fixes the spurious entry trip that
// paused at 11524 free in a 54-avatar region one tick before
// the same pass fit at cap 35); a census in flight no longer
// trips the valve (its rows drain within 15 s by the deadline
// flush - passes skip quietly instead, the trip purged the
// very rows finishing the summary); the census budget floor
// drops 10000 -> 8000 ("New accounts: not counted" printed in
// every region of the field log - the free reading sat just
// under the old floor at boot); startScan and the menu Summary
// parse the CSV transiently instead of reading a heap list.
//
// VERSION: round 68 (2026-10-30): "we used to process larger
// populations" - yes: the memory floor never changed, the
// BUDGET under it did. Data booted ~50K free in the early
// rounds; it boots ~12.4K now (every feature since - name
// links, census, starve/trace, error log, the resume notice
// - lives in the same 64KB), so the round-50 valve floor
// that once bit at 50+ avatars now bites at ~20 in a busy
// region. Field log: 22 avatars, REGION scope, evening
// arrival churn -> trip at 5504 free (12.4K boot - ~2.2K
// tracked keys - an in-flight arrival stack on the old
// 12-row queue cap, up to ~8.6K = the trip). The round-66
// recovery WORKED - the "tracking the first 10" note one
// minute later is a full pass running again - but the
// episode left the cap floored for the whole session and
// the churn kept Data hovering at the floor. Three fixes,
// all here: (1) the valve floor is now DYNAMIC - the fetch
// allocates the FULL region list (~102 B per avatar), so
// the static 6000 (sized for the churn) never actually
// protected an 80-avatar fetch; the floor is now "6000, or
// (live population + live scope) x 102 + 1500, whichever is
// larger", read via llGetRegionAgentCount (an integer, no
// allocation), so big regions pause honestly instead of
// walking into a Stack-Heap Collision; (2) the episode END
// restores the tracking budget: when the note clears above
// 9000 free the cap returns to POP_CAP and the population
// trigger re-rungs it for the current region in the same
// pass (one silent re-adopt), so "tracking the first 10
// only" no longer outlives the pause that caused it;
// (3) the arrival queue cap drops 12 -> 6 rows: the burst
// stack cost halves (~4.3K max), and overflow announces
// immediately with partial data (the timeout flush's own
// honest shape) instead of spending the memory that trips
// the valve. The structural NEXT LEVER - the tracked keys
// into linkset data (~2.2K of resting relief at 22
// avatars, more at bigger caps) - is identified but
// deliberately NOT shipped this round: it rewires the
// sweep's diff core and deserves its own field-tested
// round. Round 67 remains below. (Full history in the
// project notes.)
//
// VERSION: round 67 (2026-10-30): the full-script audit round
// (all three scripts read end to end: efficiency, outlying
// bugs, dead code). NO functional change here - after round
// 66 this script audited clean (gLastPop, removed then, was
// the last dead global; every declared message number,
// helper and state variable is live; the sweep's O(n^2)
// diffs are bounded by the dynamic cap; the heartbeat write
// has no delay cost per the saved linkset-data reference).
// Two accepted-as-is items, for the record: (1) the
// LM_WATCH_LIST presence-seed fetch in link_message has no
// free-memory guard - but it runs ALONE in its event at the
// same resting level the sweep's own identical fetch
// survives every pass, so a guard would buy nothing; (2)
// the arrival payload's leading mode field is dead in
// effect (Core skips field 0; only finished arrivals are
// sent) but kept - removing it would touch a three-script
// protocol for zero gain. This round's stamp: a ROUND line
// as the first comment of every script, so a pasted copy
// always shows its version. Round 66 remains below. (Full
// history in the project notes.)
//
// VERSION: round 66 (2026-10-30): "it will come back but never
// does" - the recovery side of the round-50 valve could never
// work in a 15+ avatar region. Field log: region scope, ~17
// avatars, arrival/left lines still printing, then the pause
// note - and detection never resumed (the line quoted back was
// the Summary button's refusal, which is what a paused HUD
// answers). Two compounding flaws in the trip/probe block:
// (1) the probe's fit test demanded MORE free memory than the
// valve floor: free > (gLastPop + gCap) * 102 + 3500, where
// gLastPop was the LAST FETCH's population - stale from the
// moment the pause starts, because only a fetch updates it and
// the fetch is exactly what the pause refuses - and the 3500
// margin double-counted the scope copy (the gCap term already
// pays it). At 17 avatars + CAP_FLOOR 10 that demanded 6254
// free while the valve is by definition tripped BELOW 6000:
// the probe could never fire in any region of 15+ avatars, so
// the pause ended only on teleport / re-wear / re-base.
// (2) the trip held gKnownScope hostage: the tracked keys (up
// to cap x 102 B) were already doomed to a silent re-adopt at
// CAP_FLOOR, but the pause kept them allocated - pinning free
// memory below the floor with nothing left to purge. Fixes,
// both here: the fit test reads the LIVE population via
// llGetRegionAgentCount (an integer, no list allocation - the
// probe costs nothing and the estimate now tracks the region
// actually quieting down) with the margin corrected to 1500;
// and the trip RELEASES gKnownScope (gBaselined is forced
// FALSE with it - MANDATORY, since diffing the next scope
// against an emptied gKnownScope would announce the whole
// population), freeing up to cap x 102 B so the typical pause
// ends one tick (~2 s) after it starts. gLastPop deleted
// (dead). The MEMPAUSE promise ("they come back on their own
// as the region quiets down") is true for the first time.
// Round 65 remains below. (Full history in the project
// notes.)
//
// VERSION: round 65 (2026-10-30): the 17-avatar valve trip
// closed a sizing era. Field log: region scope, 17 avatars,
// List All running -> "memory valve: detection paused at
// 4594 free" (92% used) - the arithmetic: boot ~12.4K free,
// minus ~1.8K of tracked keys, minus the scan queue, minus
// a 6-agent wave (~4.3K of pending+request rows - the
// pipeline costs ~720B per agent, the round-20 figure) =
// 4594. Not a leak: SCAN_BATCH = 6 and MAX_PENDING_REQUESTS
// = 50 were sized in round 7/16 against a ~50KB boot budget
// that no longer exists (the name links, census, starve and
// trace code since then boot at ~12KB free). Fixes, all
// sizing: (1) SCAN_BATCH 6 -> 3 (a 17-avatar scan now
// oscillates ~6.4-8.6K free and never reaches the 6000
// valve floor); (2) MAX_PENDING_REQUESTS 50 -> 30 back to
// the original (the census 24 + one 3-agent wave = 30
// exactly - the raise to 50 bought scan latency protection
// that cost 8KB of budget this script no longer has);
// (3) the scan entry guard 6000 -> 9000: the scan needs its
// queue (~2K) plus a wave (~2.2K) plus sweep churn ABOVE
// the 6000 floor, so an entry below 9000 meant "starts,
// then trips the valve and pauses DETECTION" - now it
// refuses honestly up front and detection keeps running;
// (4) LATENT WEDGE BUG the trip exposed: the valve's
// clearPipeline purges the scan's rows too - with its
// completions gone, gScanCount stayed above 0 forever
// ("a scan is already running", queue held, blink until
// Core's 180s timeout). The valve now calls resetScan(),
// which sends SE| + BUSY|0 so the Companion closes the
// partial list cleanly and the scan state is released.
// Round 63 remains below. (Full history in the project
// notes.)
//
// VERSION: round 63 (2026-10-30): the starve tally now
// clears on this script's own reset and on Wipe (fresh
// start = fresh evidence, the same rule the gap record
// already followed) - the field log showed a stale
// "starved the HUD 1 time(s)" surviving a Wipe because
// nothing deleted SMH.starve (Core's doWipe deletes it too
// now, belt-and-braces). No other change here. Round 60
// remains below. (Full history in the project notes.)
//
// VERSION: round 60 (2026-10-30): the freeze mystery
// CLOSED. Rachel's simulator release-notes uploads plus her
// field walk pinned it: since server 2026-09-22 (#2693,
// present on every channel she hops between), scripts
// ATTACHED FROM AGENT INVENTORY follow the parcel "run
// scripts" rule - so a parcel with scripts disabled (the
// Ahern Welcome Area) stops the WHOLE HUD: no output, a
// reset does nothing (the script never runs to process it),
// and it revives the moment the wearer crosses into a
// parcel that allows scripts (which is why flying between
// parcels "fixed" it and re-entering froze it again). While
// stopped NOTHING can run, so the HUD can never warn at the
// door; the honest fix is the RESUME NOTICE: the first tick
// after a 60 s+ gap while worn (gWearT guard, same family
// as the starve record) sends "N|PAUSE|<seconds>" and the
// Companion's text valve explains the causes. The 60 s
// floor sits above busy-region jitter (~13 s at the 2 s
// rung) and the 15 s starve tally, so the line means
// "scanning was down", not "one late tick". Round 59
// remains below. (Full history in the project notes.)
//
// VERSION: round 59 (2026-10-30): the round-58 field test
// validated the linkset-data map (10368 free with 16 avatars
// tracked vs 7464 in round 57, no valve trip, census running
// again) and exposed one mechanical fact: llSetTimerEvent is
// SCHEDULE-anchored - a late delivery is followed by an
// on-schedule catch-up tick (field trace: dt 13 s then 7 s at
// the 10 s rung), so busy-region delivery jitter reaches ~13 s
// at the 2 s rung. The adaptive ENGAGE keeps the 3x rule
// (widening the sweep in a crowd is correct), but the SMH.starve
// RECORD now has a 15 s floor with its own condition
// (independent of gSweepSec), so the Debug freeze tally counts
// real 15 s+ freezes, not every busy-region late tick.
// Round 58 remains below. (Full history in the project notes.)
//
// VERSION: round 58 (2026-10-30): the round-57 trace CONFIRMED
// event starvation (a 48 s tick; a Menu touch queued during
// the freeze, processed only when the jam released - no
// boundary crossing involved at all), and it exposed a worse
// problem: the language map's Mono LIST form cost this script
// ~4.5 KB, boot free fell to 9518 (85%), and in a 16-avatar
// region "List All" drove it to 4254 free (93%) - the memory
// valve PAUSED DETECTION in a modest crowd. Fixes: (1) the
// map now lives in LINKSET DATA as a flat pipe-delimited
// string (Core writes it at boot; this script reads it ONCE
// per unknown code and caches the full name - zero cost at
// rest, no script's heap holds the table); (2) short
// starvation events are now RECORDED to SMH.starve
// (count|longest|last) so Debug shows them with Trace off;
// (3) gWearT: a re-wear's first tick no longer misreads the
// whole detach window as one starved tick (the gap recorder
// stays unguarded on purpose - "detached" is honest there).
// Round 57 remains below. (Full history in the project notes.)
//
// VERSION: round 57 (2026-10-30): three answers to the
// field report. (1) The freeze is EVENT STARVATION, not
// death: a click's dialog appeared only at the next
// crossing, a ping fired with no text - the events were
// QUEUED (the 64-slot queue drops overflow silently), the
// scripts alive but starved. New adaptive sweep interval:
// a tick that fires more than 3x late means the sim cannot
// keep up, so the sweep widens 2 s -> 10 s (timer events
// were evicting the wearer's clicks and the announcements
// from the queue) and narrows back after 10 clean ticks.
// (2) Trace mode (Settings > Debug > Trace): SMH.trace in linkset
// data; when on, each script prints its steps to owner
// chat (Data: sweep dt/free/adopts, Core: touches/blink,
// Companion: owner actions). Off = zero output, so it
// ships permanently - nothing to remove later. (3) The
// language map moved here from the Companion (90% used at
// rest, the new tightest by far): resolution is local now -
// the "?code" pending pipeline, the LM_LANG_TELL walk and
// the errLang flush are GONE, and one link-message
// round-trip per unknown language code never happens at
// all. Round 56 remains below. (Full history in the
// project notes.)
//
// VERSION: round 56 (2026-10-30): the heartbeat is now PUBLISHED
// ("SMH.hb", every pass) for the Core Script's new stall
// detector - a hung-but-not-halted script still reports as
// running to llGetScriptState, so the stale heartbeat is the
// only in-world signal for "scheduled but stuck". The Data
// Script stays unsimplified otherwise. Round 55 remains
// below. (Full history in the project notes.)
//
// VERSION: round 55 (2026-10-30): freeze liveness recorder.
// The alt's freeze recurred, population-correlated (empty
// destination survives; a populated one prints the summary,
// then dies) - a second full audit of every handler found no
// possible hang (all loops bounded, resting memory matches
// boot), so the leading theory stays the SL attachment
// script-engine failure, which tracks sim LOAD, not our
// code. New evidence machine: the timer stamps a heartbeat
// (gHb), a 5+ minute pass gap is recorded in linkset data,
// and Debug reports it right after Data's memory line
// ("N|GAP"). A freeze that wakes on the next crossing now
// self-documents its exact dead time. Round 54 remains
// below. (Full history in the project notes.)
//
// VERSION: round 54 (2026-10-30): the Watch+ nearest-people
// ranking moved HERE from the Companion (new "NEAR" request /
// "NR" reply). The Companion's boot line read 8148 free (87%
// used) in the alt-account field test - the tightest of the
// three scripts now - and its old ranking code (a full
// llGetAgentList fetch plus one padded distance string per
// avatar plus a sort copy) was a Stack-Heap Collision waiting
// for a busy region; a halted Companion takes every menu and
// every line of text with it. sendNearest() keeps the fetch
// (unavoidable ~102 B/agent) but drops the per-agent strings
// and the sort: an insertion-sorted ten-entry strided list.
// Refusal below 13000 free (the 100-agent fetch alone is
// ~10.2 KB). Round 53 remains the last change below. (Full
// history in the project notes.)
//
// VERSION: round 53 (2026-10-30): owner-change hardening. The
// boot now sends one "BUSY|0" to Core: a reset landing
// mid-census or mid-scan (an owner change, a Wipe) orphans
// the fetch's earlier "BUSY|1" - the partner "BUSY|0" died
// with the old state, and the power button kept blinking
// until the 180 s timeout (field: transferred HUD, census
// killed by the owner-change reset). Core clamps the counter
// at 0, so the rebalance is free at a clean boot. Round 51
// remains the last change below. (Full history in the project
// notes.)
//
// VERSION: round 51 (2026-10-28): scan PEAK trimmed. (1) The
// raw region list is released right after the watch check
// (its last reader): the diffs, adopt and census stack on the
// capped scope copy alone, so the pass's one uncapped
// allocation (~102 B per region avatar) no longer overlaps
// them - in a busy region that is several KB off the
// collision moment, and the census budget is read after the
// release so the headroom becomes real born asks. (2) Data's
// user-facing note strings (valve/busy-region/scan/summary
// lines) moved to the Companion via the new "N|code|..."
// LM_SAY kind - the Companion is the designated text valve
// and the menu-triggered refusals cannot fire without it
// anyway; the boot line stays here because the canary must
// print with no Companion. Recent rounds (full history in
// the project notes):
//   50 - the low-memory valve recovers instead of parking
//        forever (pipeline purge + CAP_FLOOR=10 + a ~30 s
//        probe pass once the last-known population fits);
//        census budget floor 12000 -> 10000; new "CENSUS"
//        command for the menu's Summary button ("C" gained
//        the src field).
//   49 - comment cleanup + dead-code removal only (Core also
//        lost the orphan PING/HELP command branches).
//   48 - watched-arrival de-dup (symmetric to the r45
//        departure fix): the watch check moved AFTER the scope
//        snapshot; WIN is suppressed when the ARRIVED
//        [WATCHED] line from the diff covers the entry (the
//        diff runs, the key is in this pass's scope snapshot,
//        and the key is new to the tracked population).
//   47 - the census emits "AE|name|key" per scripted agent
//        in scope (the Companion logs encounters silently).
//   40 - sweep's region-identity guard catches teleports
//        that race the changed() event (travelReset is
//        shared by changed/attach/sweep; whichever fires
//        first wins, the others no-op).
//   37 - STALE_DROP purge: pipeline rows that survived a
//        logout are dropped silently, never announced.
//   39 - llGetDate() parse offsets must match the born-date
//        parse (both "YYYY-MM-DD" WITH dashes).
//   36/34/33 - dynamic caps, budgeted census, scan reuses
//        the tracked population (no second region fetch),
//        12-row arrival queue cap, readiness guard, NULL_KEY
//        ghost filtering.
//   30 - names are viewer links composed from the key; the
//        tracking lists are keys-only.
// ============================================================
// ============================================================

integer LM_SAY = 19027;
integer LM_UI_STATE = 19029;
integer LM_UI_CMD = 19030;
integer LM_WATCH_LIST = 19031;
integer LM_DATA_ASK = 19032;
integer LM_DATA_TELL = 19033;
integer LM_SWEEP_ASK = 19034;
integer LM_EVENT = 19035;
integer LM_MEM_ASK = 19036;  // -> LINK_SET (Status Check): every
                             // script answers with LM_MEM_TELL
integer LM_MEM_TELL = 19037; // <- any script: "name|freeBytes|build"
                             // (the Companion prints the debug lines)

string P = "SMH.";        // linkset-data key prefix (shared with the
string BUILD_NUM = "110226081"; // round 81: the build stamp
                                // (MMDDYY 110126 + zero-padded round
                                // 080) - printed on every boot line
                                // and on Core's Status line, so a
                                // field log always shows WHICH
                                // build ran (identical constant in
                                // all four scripts; bump the round
                                // digits every round)
                         // Core Script - see its header). Used here
                         // only for the known-error log below.
integer ERR_LOG_SLOTS = 10; // known-error ring size (SMH.err0..9);
                           // keep in sync with the Companion's copy
integer DBG_SLOTS = 24; // round 75: debug-log ring size
                        // (SMH.dbg0..23); keep in sync with the
                        // Companion's Dump Log reader

integer SWEEP_INTERVAL = 2;       // seconds between sweeps = max
                                  // arrival detection delay
integer POP_CAP = 60;             // huge-region safety valve
integer CAP_FLOOR = 10;           // lowest dynamic-cap rung, taken
                                  // when the memory valve trips: a
                                  // smaller scope copy means the
                                  // probe pass fits sooner; restored
                                  // to POP_CAP on region change /
                                  // re-wear / settings re-base like
                                  // every cap step

string memPct(integer freeBytes)
{
    // Mono scripts get a 65536-byte budget; show the percentage
    // USED next to the free number wherever memory is listed.
    return (string)freeBytes + " free (" +
        (string)((100 * (65536 - freeBytes)) / 65536) + "% used)";
}

logErr(string text)
{
    // Rotating known-error log kept in the SHARED linkset-data
    // store (SMH.err0..9 + SMH.errNext cursor) instead of script
    // memory: it survives a script reset and even a HALTED
    // script, so the errors that led up to a crash are still on
    // the Debug report. Entries are "YYYY-MM-DD HH:MM:SS|Data|"
    // + text; the Companion's Debug option prints them oldest
    // first, and Wipe deletes the keys. Keep ERR_LOG_SLOTS in
    // sync with the Companion's copy.
    integer i = (integer)llLinksetDataRead(P + "errNext");
    if (i < 0 || i >= ERR_LOG_SLOTS)
        i = 0;
    string ts = llGetSubString(llGetTimestamp(), 0, 18);
    // llGetTimestamp is "YYYY-MM-DDTHH:MM:SS..." - swap the T
    // for a space so the Debug line reads cleanly.
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
    // Round 75: the Debug Log ring (SMH.dbg0..23 + SMH.dbgNext
    // cursor). SMH.dlog gates EVERY entry at the top - the
    // same live-read pattern as SMH.trace, so with the flag
    // off the only cost is one linkset read and a return, and
    // with it on each event writes one short string. Entries
    // use logErr's exact "ts|Data|" shape (plus a tag) so the
    // Companion's Dump Log prints both rings with one loop.
    // Keep DBG_SLOTS in sync with the Companion's copy.
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
    // Names in chat lines are VIEWER-RESOLVED LINKS composed
    // from the key: the viewer renders the URI as a clickable
    // CURRENT display name and opens the profile - immune to
    // every failure mode of script-side lookups (llGetDisplayName
    // can return "" for a present avatar, per the wiki). This
    // is why the tracking lists below are KEYS-ONLY.
    return "secondlife:///app/agent/" + (string)id + "/displayname";
}

// ---------- settings mirror (from Core's pushes) ----------
integer gHaveState;  // FALSE until the first LM_UI_STATE arrives
integer gEnabled = TRUE;
integer gScope = 2;  // 0 = region, 1 = radius, 2 = parcel
integer gRange = 25;
list gWatch;         // watch-list key mirror

// ---------- detection sweep state ----------
// Round 70: the tracked population (in-scope keys, keys-only)
// lives in the HEAP as gKnownPad - a comma-WRAPPED CSV string
// (~38 B per key vs the old list's ~102 B). Round 69 tried
// the linkset datastore and the field test broke: the saved
// wiki page for llLinksetDataWrite shows a 10.0 forced-delay
// entry (the delay-table note claiming no delay for all
// llLinksetData* is wrong), so the per-pass CSV write made
// the pass unreliable and the diff re-announced everyone
// every cycle. The string keeps most of r69's memory win
// with zero datastore traffic; see knownCsv / knownHas
// (round 79: knownKeys moved to the Registrar with the census
// - the sweep's diff loops never parsed the string). Names
// stay viewer links composed from the key
// at announce time, so nothing but the keys is ever stored.
string gKnownPad;    // wrapped CSV: "," + key + "," + ...;
                     // "" = empty population
integer gBaselined; // FALSE => adopt the population silently
key gParcelId;      // current parcel (parcel-scope rebase check)
string gBaseRegion; // region NAME the baseline was adopted in
                    // (region names are unique grid-wide; the
                    // sweep compares against it every pass so a
                    // teleport is caught even when the changed()
                    // event is still queued)
list gWatchedIn;    // watched keys present in region (keys-only)
integer gWatchBase; // FALSE => seed gWatchedIn silently on next sweep
integer gWatchAnnounce; // TRUE => the next silent watch re-seed
                        // announces watched people found ALREADY
                        // present (region jump / teleport / wear /
                        // boot); cleared by config re-bases
integer gCapNoted;  // one-time note when the cap truncates
integer gCapCrowd;  // round 72: the narrowed cap's CAUSE, sent
                    // as the BUSY note's 5th field so the
                    // Companion can word it honestly: TRUE =
                    // the population trigger (a genuinely busy
                    // region), FALSE = memory (the ladder, the
                    // free steps, or the valve trip). Any
                    // POP_CAP restore clears it; the LAST
                    // narrowing that moved the cap wins.
integer gWideTick;  // round 72: consecutive passes with free
                    // memory above the FULL-width pass price -
                    // 15 of them (about 30 s) restore a
                    // ladder-narrowed cap to POP_CAP silently;
                    // any tight pass resets the count, so the
                    // tracked width cannot flap
integer gBootFree;  // round 74: the state_entry free-memory
                    // reading - the ONE true budget datum.
                    // Every absolute memory threshold from the
                    // r68-era 11.9 K boot (census floor,
                    // episode-end restore, scan guard) is
                    // derived from THIS number now, so the
                    // valve re-calibrates itself as the
                    // compiled script grows or shrinks
                    // instead of silently going dead.
string NUDGE_CSV = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
string NUDGE_MINI = "1,1,1,1,1,1,1,1,1,1";
                    // round 74: the paused probe's garbage-
                    // collection nudge - three short-lived
                    // parses of this fixed ~40-element list
                    // put ~1 K of allocation pressure on the
                    // heap so Mono's lazy collector reclaims
                    // the pause's own churn garbage before
                    // the probe's fit test reads.
                    // Round 76: the 2600 entry floor excluded
                    // exactly the pinned case the nudge exists
                    // for (the r75 log: paused at 912 free,
                    // nudge never ran, pause could not end in
                    // an EMPTY region). The mini tier (10
                    // elements, a ~350 B transient, entry
                    // floor 500) puts allocation pressure on
                    // a garbage-pinned heap even at a reading
                    // the full parse could never safely touch
                    // - any pressure is the collection
                    // trigger; the r75 PROBE entry's pre=/post=
                    // pair measures whether it fired.
                    // round 74: the paused probe's garbage-
                    // collection nudge - three short-lived
                    // parses of this fixed ~40-element list
                    // put ~3 K of allocation pressure on the
                    // heap so Mono's lazy collector reclaims
                    // the pause's own churn garbage before
                    // the probe's fit test reads.
integer gMemNoted;  // one-time note for the low-memory sweep
                    // valve: below the dynamic floor (round 70:
                    // the pass's own cost at the rung the
                    // ladder cannot get under - it already
                    // tried 35 -> 20 -> 10) the pass is
                    // skipped; on the trip the pipeline is
                    // purged, the cap drops to CAP_FLOOR, the
                    // tracked-key CSV string is cleared (the
                    // round-66 heap release is REAL again -
                    // clearing frees ~0.4-1.3 K at once), and
                    // a probe pass retries every ~30 s once
                    // the LIVE population
                    // (llGetRegionAgentCount) is known to fit;
                    // when the episode ends above
                    // 9000 free the cap is RESTORED to the
                    // population trigger's rung for this region
                    // (round 68) - the pause always ends by
                    // itself as the region quiets down, and the
                    // session comes back at full tracking
integer gMemProbe;  // skipped-pass counter for the probe above
integer gHb = 0;   // liveness heartbeat: unix time of the last
                    // timer pass. A gap of 5+ minutes between
                    // passes means the script engine was not
                    // running this script at all - the
                    // region-crossing attachment failure, a
                    // freeze, or the wearer was logged out. The
                    // most recent such gap is recorded in
                    // linkset data and shown on the Debug report
                    // (a logout is not an error, so it never
                    // touches the error ring).
integer gSweepSec;  // the CURRENT sweep interval: SWEEP_INTERVAL
                    // normally, 10 s under sim starvation (the
                    // adaptive backpressure in timer())
integer gSweepTick; // clean-tick counter for the return to
                    // SWEEP_INTERVAL (10 in a row required)
integer gWearT;     // unix time of the most recent attach. A
                    // re-wear (no script reset) leaves gHb at
                    // its detach-time value, so the first tick
                    // would read the WHOLE detach as a late,
                    // starved tick: a false "slowed to 10s" and,
                    // since round 58, a false starvation record.
                    // Only ticks whose predecessor ran AFTER the
                    // latest attach count as starved (round 58).
                    // The gap recorder above stays unguarded on
                    // purpose: a 5+ minute DETACH is honest gap
                    // evidence ("frozen, detached or logged out").
integer gCap;      // dynamic version of POP_CAP: in a busy
                   // region the key lists alone eat tens of KB,
                   // so the cap steps DOWN as free memory drops
                   // (60 -> 35 -> 20) and only returns to POP_CAP
                   // on a region change, re-wear, or settings
                   // re-base - never mid-session, so it cannot
                   // flap up and down
integer gPrevCap;  // the cap the population was last ADOPTED at;
                   // a change means a silent re-baseline (people
                   // crossing the cutoff must not produce a
                   // flood of LEFT or ARRIVED lines)
integer gCapPub = -1; // round 80: the cap value last written to
                   // SMH.cap (-1 = never published). The
                   // Registrar reads SMH.cap to word the Summary
                   // and List All busy-context lines; written
                   // on cap CHANGE only, so the sweep's cost is
                   // one integer compare per pass.

// ---------- region slowdown watch ----------
float DILATION_LOW = 0.50;  // alert when the sim slows below this
float DILATION_OK  = 0.90;  // ...and announce recovery at/above;
                            // the wide band between them stops a
                            // borderline sim from flapping
integer gDilLow;   // TRUE while the slowdown alert is active

// ---------- census (arrival summary) ----------
integer gCensusOnAdopt;  // TRUE => after the next silent adopt
                         // (region change / teleport / attach /
                         // boot) ask the REGISTRAR for the
                         // population summary (round 79: the
                         // census itself lives there now - the
                         // flag just picks WHO broadcasts
                         // "CENSUS|A"; the sweep's adopt block
                         // is the only reader)
string gAdoptWhy = "";    // round 81: WHY the next adopt is an
                          // arrival. "region" / "parcel" get
                          // the pre-line, "rewear" and "" (the
                          // boot) stay silent; cleared wherever
                          // the flag is cleared

// ============================================================
// DETECTION SWEEP HELPERS
// ============================================================
// (Round 79: scopeLabel() moved to the Registrar with the
// census "C|" line that was its only caller here.)

list scopeAgentsFrom(list agents, integer max)
{
    // Filter the region list down to the current scope, dropping
    // the wearer: tracking, listing, and counting yourself is
    // pure overhead (llGetAgentList includes the owner).
    // NULL_KEY entries are dropped too - the wiki caveats say
    // ghosts / corrupted presences / God Mode agents can come
    // back as NULL_KEY; a flickering ghost must never produce
    // ARRIVED/LEFT lines for a broken link.
    // ONE pass (no "everyone except me" intermediate list: two
    // full key lists alive at once in a busy region is exactly
    // the memory we cannot spare). The caller passes the cutoff
    // (max) so the loops simply stop there - no llList2List
    // truncation copy of the region list.
    integer n = llGetListLength(agents);
    if (n > max)
        n = max;
    integer i;

    if (gScope == 1)
    {
        // Radius scope. For attachments llGetPos() is the wearer's
        // position, so this is automatically centered on the
        // avatar.
        vector here = llGetPos();
        list rad;
        for (i = 0; i < n; i++)
        {
            key a = llList2Key(agents, i);
            if (a != llGetOwner() && a != NULL_KEY)
            {
                vector p = llList2Vector(llGetObjectDetails(a, [OBJECT_POS]), 0);
                // Round 71: an unreadable position (the avatar
                // left between the fetch and this query) reads
                // as ZERO_VECTOR - the region's SW corner -
                // and without the guard counted as in-radius
                // whenever the wearer stood near that corner.
                // (The Registrar's ranking sorts such rows
                // last, the same rule.)
                if (p != ZERO_VECTOR && llVecDist(here, p) <= (float)gRange)
                    rad += [a];
            }
        }
        return rad;
    }

    // Parcel scope: everyone standing on the SAME parcel as the
    // wearer. Needs no land ownership - only the ban workflow did.
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
                // Round 71: same ZERO_VECTOR guard as the
                // radius branch - an unreadable position is
                // the SW corner, not "same parcel".
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

list watchedInRegion(list regionAgents)
{
    // Keys of watched avatars present in the region (keys-only:
    // announce time composes a viewer link from the key).
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

// ============================================================
// TRACKED POPULATION (heap CSV string, rounds 69-70)
// ============================================================

string knownCsv(list agents)
{
    // Round 70: build the wrapped CSV form of the tracked
    // population. The heap STRING carries most of r69's
    // datastore win (~38 B/key vs the list's ~102 B) with
    // zero linkset-datastore writes - the r69 field test
    // showed the per-pass write was unreliable (see the
    // gKnownPad declaration and the round-70 VERSION block).
    // An empty population is the empty string.
    if (llGetListLength(agents) == 0)
        return "";
    return "," + llDumpList2String(agents, ",") + ",";
}

integer knownHas(string pad, key a)
{
    // Membership test WITHOUT parsing: keys are fixed 36 chars
    // and never contain commas, and the stored CSV is comma-
    // wrapped on both sides, so a "," + key + "," hit can only
    // land on a real key boundary - never across two neighbor
    // keys. One string search, no list allocated.
    if (pad == "")
        return FALSE;
    return (llSubStringIndex(pad, "," + (string)a + ",") != -1);
}

// ============================================================
// CENSUS (the one-line arrival summary)
// ============================================================
// Round 79: this whole section MOVED to the Registrar Script
// (startCensus / sendCensus / startCensusNow). Data keeps only
// the gCensusOnAdopt flag above: the sweep's adopt block
// broadcasts "CENSUS|A" on the LM_SWEEP_ASK wire and the
// Registrar counts the region it now owns. Nothing here uses
// the tracked pad for a census anymore, so knownKeys() moved
// with it (the sweep keeps knownCsv / knownHas - the diff
// loops and membership tests never parsed the string).

travelReset(string why)
{
    // The one shared travel rebase, called from changed()
    // (CHANGED_REGION | CHANGED_TELEPORT), attach() and the
    // sweep's region-identity guard - whichever runs first
    // handles the jump; the others no-op, because the guard
    // adopts under the CURRENT region name.
    gKnownPad = ""; // round 70: the tracked keys are a heap
                    // CSV string now - empty it for the new
                    // region (an old region's baseline must
                    // never diff against a new region's
                    // population)
    gBaselined = FALSE;
    gCap = POP_CAP; // new region: full tracking budget again
    gCapCrowd = FALSE;
    gWatchedIn = [];
    gWatchBase = FALSE;
    gCensusOnAdopt = TRUE;
    gAdoptWhy = why;
    gWatchAnnounce = TRUE;
    gDilLow = FALSE; // silently forget the old region's slowdown
                     // state - no recovery line for a sim we left
    gMemNoted = FALSE; // a new region is a new valve episode: if
                       // memory is still low there, the note must
                       // print again (silence would read as the
                       // HUD being dead)
    gMemProbe = 0;
    // Round 79: this script no longer owns a pipeline to clear -
    // it BROADCASTS the travel instead, and the Registrar purges
    // its own (in-flight lookups and listing rows from the old
    // region must never land as post-abort stragglers here,
    // exactly the wart the r78 field follow-up #8 caught). The
    // Registrar hears the same CHANGED_REGION / CHANGED_TELEPORT
    // event too; this broadcast covers the race where the timer's
    // region-identity guard (below) fires first.
    llMessageLinked(LINK_SET, LM_SWEEP_ASK, "RESET", "");
    gBaseRegion = llGetRegionName(); // the guard compares against
                                     // THIS now; the adopt that
                                     // follows is already "home"
}

sweep()
{
    // One detection pass. Skipped until Core's first state push
    // arrives (gHaveState) and while monitoring is paused; the
    // power-on REBASE re-adopts the population silently.
    if (!gHaveState || !gEnabled)
        return;

    // Region-identity guard: at a teleport the timer can run in
    // the NEW region while the changed() event is still queued,
    // and diffing the OLD baseline against the new region's
    // list would announce the whole population on entry.
    // Region names are unique grid-wide - if this is not the
    // region the baseline was adopted in, rebase HERE; this
    // sweep adopts silently and changed() no-ops when it
    // finally delivers. Round 81: the gBaselined gate - at
    // boot the empty gBaseRegion made this fire travelReset
    // on every pass before the first adopt, which would now
    // stamp a REGION cause on the boot census; before an
    // adopt there is no stale baseline to reset anyway.
    if (gBaselined && llGetRegionName() != gBaseRegion)
        travelReset("region");

    // Critical-memory valve: the region fetch alone can need
    // ~10KB (100 keys at ~102 B each), so with free memory this
    // low even READING the population could collide. Field
    // report (round 50): the pause used to be PERMANENT in a
    // region whose resting free memory sat below the line, with
    // a note that promised recovery "in a moment" - and the
    // valve blocking the adopting pass meant the next region
    // printed no summary at all. So the trip now ACTS instead
    // of waiting: purge the pipeline (the in-flight rows were
    // doomed to partial lines anyway) and drop the cap to
    // CAP_FLOOR with a silent re-adopt, so a pass costs less.
    // Recovery probe: every ~30 s, attempt one pass as soon as
    // the LIVE population is known to fit in free memory -
    // llGetRegionAgentCount (round 66; the old test read the
    // LAST FETCH's count, which was stale from the moment the
    // pause started because only a fetch updates it and the
    // fetch is what the pause refuses). The margin covers diff
    // churn and a couple of arrival rows (the scope copy is
    // already paid by the gCap term). gMemNoted stays TRUE
    // through a probe pass so the note cannot re-fire every
    // ~30 s; the episode ends above 9000 free. travelReset
    // re-arms the note so each new region gets its own episode.
    // One note per episode (llGetFreeMemory under-reports
    // between garbage collections, so the trip fires early =
    // safe).
    // Round 68: the floor is DYNAMIC. The static 6000 guarded
    // the pass's churn, but the fetch allocates the FULL
    // region list (~102 B per avatar; the wiki caps
    // llGetAgentList at 100 and offers no limiting option) -
    // an 80-avatar region needs ~8.2KB for the fetch alone,
    // and a 6000-floor pass there walked straight toward a
    // Stack-Heap Collision. llGetRegionAgentCount is an
    // integer (no allocation): reading the LIVE count first
    // costs nothing, and the floor becomes "6000, or the
    // pass's own known cost - fetch plus the scope copy the
    // cap will allow - plus margin, whichever is larger".
    // The trip, note, purge, CSV delete and probe below all
    // work unchanged; the entry check re-reads the count
    // every pass, so the pause still tracks the region
    // quieting down (faster than the ~30 s probe can).
    integer livePop = llGetRegionAgentCount();
    // Round 69/70: price the pass at the rung the population
    // trigger below is ABOUT to set, not the stale post-travel
    // gCap (the r69 fix for the spurious entry trip - a
    // 54-avatar arrival once paused at 11524 free one tick
    // before the same pass fit at cap 35). Round 70 adds the
    // LADDER: if the pass still does not fit at that rung,
    // step the rung DOWN (35 -> 20 -> 10) until it fits and
    // RUN the pass - one silent re-adopt per step, the BUSY
    // note prints the honest "tracking the first N". Detection
    // slows instead of pausing (the wearer's standing
    // request); the trip below now fires only when even
    // CAP_FLOOR cannot fit, which also closes the 68-70
    // avatar dead zone (rung 35 forced there priced over
    // boot free while rung 20 fit comfortably). The ladder is
    // one-way per session (steps down freely; the full width
    // returns on travel / re-wear / settings re-base / the
    // episode-end restore) so the tracked width cannot flap
    // pass-to-pass.
    integer rung = gCap;
    if (livePop > 70 && rung > 20)
        rung = 20;
    else if (livePop > 40 && rung > 35)
        rung = 35;
    // Round 79: the census-skip early return is GONE - the
    // census rows live in the REGISTRAR's budget now, so a
    // mid-census dip in THIS script's free memory is a real
    // reading again, priced by the ladder below like any
    // other pass.
    integer freeNow = llGetFreeMemory();
    // Round 72: the rung is priced at min(rung, livePop) -
    // the field fix for the r71 report ("tracking the first
    // 10 only" in a QUIET 11-avatar region, right after a
    // teleport, no valve trip). The old pricing demanded
    // (pop + rung) x 102 even when the population could never
    // FILL the rung: at 11 avatars, rung 60 priced memory for
    // 60 tracked slots while the scope copy is bounded by the
    // population and can only ever hold 11 keys - the pass
    // was overcharged by (rung - pop) x 102 (~5 KB at rung
    // 60), so any transient dip (a burst of arrivals, the
    // post-travel churn while garbage is uncollected -
    // llGetFreeMemory under-reports between collections)
    // could floor the cap in a region that never needed it.
    // Priced honestly, the demand at 11 avatars is ~4.2 KB
    // at EVERY rung down to 10 - the ladder can no longer
    // narrow a region smaller than its rung at all (stepping
    // the cap down could not free what the pass does not
    // spend), and the trip below stays honest: it fires only
    // when the pass genuinely does not fit.
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
    // Round 71: WIRE the ladder to the cap. Round 70 computed
    // the rung but never assigned it - the trip decision used
    // the narrowed rung while the pass itself still ran at the
    // population-trigger cap (20/35), so a pass the ladder had
    // just decided only fits at rung 10 ran at 35 and walked
    // straight toward a Stack-Heap Collision, and "detection
    // narrows instead of pausing" never actually happened.
    // Assigning here keeps the trip test and the pass width
    // IDENTICAL; the gCap != gPrevCap guard below re-adopts
    // silently at the narrower width, gCapNoted re-arms the
    // honest "tracking the first N" note, and the one-way
    // property is preserved (rung starts from gCap and only
    // steps down; the episode-end restore gives POP_CAP back).
    if (rung < gCap)
    {
        gCap = rung;
        gCapNoted = FALSE;
        gCapCrowd = FALSE; // round 72: the ladder narrows on
                           // MEMORY, never on population - the
                           // population trigger above set the
                           // rung's starting point already
    }
    if (passNeed > freeNow)
    {
        if (!gMemNoted)
        {
            gMemNoted = TRUE;
            gMemProbe = 0;
            logErr("memory valve: detection paused at " +
                (string)llGetFreeMemory() + " free");
            // Round 75: the trip's own numbers - free at the
            // moment of the trip, the population, and the
            // price that did not fit - so the dump answers
            // "was this an honest pause?" without a Status
            // Check at the right second.
            dbgLog("TRIP", "free=" + (string)freeNow +
                "|pop=" + (string)livePop +
                "|need=" + (string)passNeed);
            llMessageLinked(LINK_SET, LM_SAY, "N|MEMPAUSE", "");
            // Round 79: no pipeline to purge HERE anymore - the
            // arrival lookups live in the Registrar's budget and
            // complete or time out on their own; a detection
            // pause must never reach into another script's
            // memory. (The Registrar's own guard handles its
            // side; the census it drops mid-flight was honest
            // before and stays honest.)
            gCap = CAP_FLOOR;
            gCapNoted = FALSE; // re-note: the tracked count
                               // changed
            gCapCrowd = FALSE; // round 72: a trip is a memory
                               // cause by definition
            gBaselined = FALSE; // re-adopt silently at the floor
                                // once passes resume - MANDATORY
                                // now that the line below empties
                                // the old baseline: diffing the
                                // next scope against an emptied
                                // baseline would announce the
                                // whole population as arrivals
            // Round 66 released the tracked keys here because
            // holding them in the heap pinned the pause forever
            // (the field bug: "it will come back but never
            // does"). Round 70 puts the keys back in the heap
            // as one compact CSV string (~38 B/key instead of
            // the list's ~102), so the release is REAL again:
            // clearing it frees ~0.4-1.3 K at once and the
            // pause can no longer be pinned by the baseline.
            // Recovery still adopts a FRESH population, never
            // diffs against a stale baseline.
            gKnownPad = "";
            return;
        }
        gMemProbe = gMemProbe + 1;
        if (gMemProbe < 15)
            return; // ~30 s between probe attempts
        gMemProbe = 0;
        // Round 72: the probe prices the pass the same honest
        // way the ladder does - the scope copy is bounded by
        // the population, so a paused 11-avatar region at cap
        // 10 needs ~4.1 KB of fit, not the old (11+10)-full
        // arithmetic... which was right here by luck (cap 10
        // < pop 11); a paused MID-pop region at a wide cap was
        // overcharged and could stay paused past recovery.
        // Round 74: NUDGE MONO'S LAZY COLLECTOR FIRST.
        // llGetFreeMemory under-reports until an allocation
        // forces a collection, and a PAUSED script allocates
        // almost nothing - so the wipe-minute churn garbage
        // (adopt, census, welcome flow, scope rebase, all in
        // the first 60 s) sat uncollected for 80+ minutes in
        // the r73 field log while the probe read the lie
        // (3570 pinned; the same state read 4364 later). The
        // nudge is three short-lived parses of a fixed
        // ~40-element CSV (~1 K of allocation pressure each,
        // dropped immediately - constant size, independent of
        // the region population, unlike a list fetch). The
        // 2600 floor keeps the transient parse safe even on
        // the tightest honest reading; if garbage exists, a
        // collection fires mid-nudge and the fit test below
        // reads the post-collection truth instead.
        // Round 75: capture the PRE-nudge reading. The probe's
        // dump entry then carries both readings, so the GC-
        // nudge theory is directly testable from a dump: a
        // post reading well above pre means the nudge freed
        // garbage; identical readings mean the memory was
        // never there (an honest pause after all).
        integer nfPre = llGetFreeMemory();
        if (nfPre > 2600)
        {
            list junk = llCSV2List(NUDGE_CSV);
            junk = llCSV2List(NUDGE_CSV);
            junk = llCSV2List(NUDGE_CSV);
        }
        else if (nfPre > 500)
        {
            // Round 76: the pinned-low tier. The full parse is
            // unsafe here (it needs ~1.2 K the reading does not
            // have), but a ~350 B transient is not - and on a
            // garbage-pinned heap ANY allocation pressure is
            // the collection trigger the nudge exists to
            // pull. Three mini parses, then the same fit test
            // below; the PROBE entry's post= reading is the
            // verdict on whether collection fired.
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
            return; // still does not fit: stay paused
        }
        dbgLog("PROBE", "pre=" + (string)nfPre +
            "|post=" + (string)llGetFreeMemory() +
            "|pop=" + (string)pn +
            "|need=" + (string)pfit + "|resumed");
        // Fits per the live population: fall through and run
        // this one pass (the note above stays armed).
    }
    if (gMemNoted)
    {
        // Round 74: the episode-end restore is PRICE-BASED,
        // not the old absolute >9000 (set in round 68 when
        // boot read ~11.9 K - after boot fell to ~4.5 K the
        // threshold was unreachable in ANY region, so one
        // trip floored the cap for the whole session and the
        // wideTick recovery, gated on !gMemNoted, could never
        // fire). The episode is over when a FULL-WIDTH pass
        // honestly fits again - the same (pop + min(pop,
        // POP_CAP)) x 102 + 2000 arithmetic the ladder and
        // the probe use. A quiet region fires it and hands
        // the cap back to POP_CAP; a region that is still
        // genuinely too tight keeps the floor honestly.
        integer rn = llGetRegionAgentCount();
        integer rw = POP_CAP;
        if (rw > rn)
            rw = rn;
        if (llGetFreeMemory() > (rn + rw) * 102 + 2000)
        {
        gMemNoted = FALSE;
        // Round 68: the episode is over - give the tracking
        // budget back. The trip floored the cap to protect
        // the pause; with detection healthy again the cap
        // returns to POP_CAP and the population trigger
        // below re-rungs it for THIS region in the same pass
        // (one silent re-adopt), so "tracking the first 10
        // only" no longer outlives the low-memory episode
        // that caused it.
        gCap = POP_CAP;
        gBaselined = FALSE;
        gCapNoted = FALSE;
        gCapCrowd = FALSE;
        }
    }

    // Round 72: SUSTAINED RECOVERY for a ladder-narrowed cap.
    // Round 80 flap fix: POPULATION-cause caps are EXEMPT - in
    // the club soak this block kept restoring POP_CAP on the
    // 31 K free reading, the population trigger re-narrowed it
    // the same pass, and the BUSY note re-armed every ~30 s. A
    // population cap is the honest width for THIS region; only
    // the region emptying or a travel reset widens it.
    if (!gMemNoted && !gCapCrowd && gCap < POP_CAP)
    {
        // The r71 field report this block was born from: a
        // quiet 11-avatar region printed "tracking the first
        // 10 only" right after a teleport - the ladder had
        // floored the cap on ONE transient below-price
        // reading, and the one-way rule kept it there for the
        // whole session. This block heals the case it was for
        // (a MEMORY-cause narrowing): 15 consecutive passes -
        // about 30 s - with free memory above the FULL-width
        // price restore POP_CAP with one silent re-adopt. Any
        // tight pass resets the count, so the width cannot
        // flap. Population-cause caps never reach here now
        // (the round-80 gate above).
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

    // Readiness guard: while the HUD is WORN the wearer is
    // always in the region list, so an EMPTY result means the
    // data was not ready yet (fresh wear, just teleported in).
    // Adopting that "nobody" would baseline on empty and the
    // next good sweep would announce the whole population as
    // new arrivals. Adopt nothing; the next pass does it.
    if (llGetAttached() != 0 && llGetListLength(regionAgents) == 0)
        return;

    // ---------- huge-region safety valve ----------
    // Watched avatars are checked against the FULL list below;
    // only the scope diff is capped, so the watch list stays
    // reliable even when the valve trips. The cap is DYNAMIC:
    // it steps down when free memory runs low (the thresholds
    // are deliberately conservative - llGetFreeMemory
    // under-reports a little between garbage collections), and
    // every step silently re-baselines so nobody crossing the
    // cutoff is announced.
    integer n = llGetListLength(regionAgents);
    // The population trigger sizes the cap from the region
    // population DIRECTLY (>70 -> track 20, >40 -> track 35):
    // it runs before any allocations land, so the first adopt
    // in a busy region is already sized. The note below prints
    // the honest number. (Round 74: the r33/36 FREE-memory
    // steps that used to live here (free<10000 -> 35,
    // free<6000 -> 20) are DELETED - the r70-72 ladder already
    // narrows on genuine non-fit with honest pricing, which
    // SUBSUMES them; and after boot fell to ~4.5 K both steps
    // were unconditionally true on every pass, forcing the cap
    // to 20 in quiet regions where the ladder (correctly)
    // would have narrowed nothing.)
    if (n > 70 && gCap > 20)
    {
        gCap = 20;
        gCapNoted = FALSE;
        gCapCrowd = TRUE; // round 72: population cause
    }
    else if (n > 40 && gCap > 35)
    {
        gCap = 35;
        gCapNoted = FALSE;
        gCapCrowd = TRUE; // round 72: population cause
    }
    if (gCap != gPrevCap && gBaselined)
        gBaselined = FALSE; // cutoff moved: re-adopt silently
    if (n > gCap && !gCapNoted)
    {
        // No truncation copy: scopeAgentsFrom caps internally via
        // its max parameter, so the full region list is used by
        // the watch check above and nothing is duplicated.
        gCapNoted = TRUE;
        // Round 72: the 5th field is the CAUSE - TRUE when the
        // population trigger narrowed the cap (a genuinely
        // busy region), FALSE when memory did (the ladder or
        // a trip - the r33/36 free steps were deleted in
        // round 74, subsumed by the honest ladder). An older
        // Companion ignores the extra field and prints the
        // old line, so mixed
        // versions keep working.
        llMessageLinked(LINK_SET, LM_SAY,
            "N|BUSY|" + (string)n + "|" + (string)gCap + "|" +
            (string)gCapCrowd, "");
    }

    // Round 80: publish the cap to linkset data on CHANGE only
    // (the Registrar reads it for the Summary / List All
    // busy-context lines). travelReset's re-widening is caught
    // here too - the next sweep after a region change sees the
    // new value and writes it.
    if (gCap != gCapPub)
    {
        gCapPub = gCap;
        llLinksetDataWrite(P + "cap", (string)gCap);
    }

    // ---------- parcel-change rebase (parcel scope) ----------
    // Walking into a different parcel within the same region
    // fires no event: check here. Round 81 lifts the old
    // silence: crossing a parcel boundary is an ARRIVAL now -
    // the adopt block below prints "New parcel detected" and
    // asks the Registrar for the new parcel's summary (the
    // census already counts by the CURRENT scope, so it sees
    // the new parcel's people and labels the line "parcel").
    // Region and Radius scopes never reach this check, so
    // their parcel crossings stay quiet.
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

    // ---------- scope population diff ----------
    // The scope snapshot is taken BEFORE the watch check (the
    // watch block runs below): the WIN guard needs to know
    // whether an arriving watched person is inside the tracked
    // scope - if they are, the ARRIVED [WATCHED] line from the
    // diff is the single notice and the "entered the region"
    // line is suppressed.
    list scopeAgents = scopeAgentsFrom(regionAgents, gCap);

    // Round 70: the tracked population lives in the HEAP again,
    // as one comma-wrapped CSV string (gKnownPad, ~38 B/key -
    // the r68 heap list cost ~102 B/key and pinned the pause;
    // the r69 datastore move broke in the field because the
    // per-pass write could not keep up). The watch block tests
    // membership against the string directly; the diff loops
    // below walk it by fixed 37-char stride (keys are exactly
    // 36 chars in a comma-wrapped pad). No parse, no datastore.

    // ---------- watch list (region-wide, full population) ----------
    if (!gWatchBase)
    {
        gWatchedIn = watchedInRegion(regionAgents);
        gWatchBase = TRUE;
        if (gWatchAnnounce)
        {
            // We just arrived (region jump / teleport / wear /
            // boot): the people found already present were seeded
            // silently so far - name them now, instead of waiting
            // for their next border crossing. Config re-bases
            // (rebaseData) clear the flag, so scope changes and
            // power-on never produce these.
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
                // Suppress WIN when the ARRIVED [WATCHED] line
                // from the diff below covers this entry
                // (symmetric to the WOUT fix): the diff actually
                // runs this pass (gBaselined - a silent adopt
                // must still fire WIN as the only notice), the
                // key is in THIS pass's scope snapshot, and the
                // key is new to the tracked population (if they
                // were already tracked, no ARRIVED would come
                // and WIN must fire). Entering from OUTSIDE the
                // scope keeps WIN: it is the only notice there.
                // The ping is not lost (the ARRIVED line's
                // [WATCHED] flag triggers it), and the encounter
                // log is covered by the Companion's "A" branch.
                if (!gBaselined ||
                    llListFindList(scopeAgents, [w]) == -1 ||
                    knownHas(gKnownPad, w))
                    llMessageLinked(LINK_SET, LM_EVENT,
                        "WIN|" + nameUri(w) + "|" + (string)w, "");
            }
            else if (!inNow && wasIn)
            {
                gWatchedIn = llDeleteSubList(gWatchedIn, wi, wi);
                // When the person is in the tracked population,
                // the LEFT [WATCHED] line from the diff below
                // covers the departure, so WOUT is suppressed;
                // leaving from OUTSIDE the scope still gets
                // WOUT (it is the only notice there).
                if (!knownHas(gKnownPad, w))
                    llMessageLinked(LINK_SET, LM_EVENT,
                        "WOUT|" + nameUri(w), "");
            }
        }
    }

    // Release the raw region list: the watch block above was
    // its LAST reader (the diffs and census below work on the
    // capped scopeAgents and the gKnownPad string only), so
    // the pass's one UNCAPPED allocation - ~102 B per region
    // avatar, alive from the fetch until now - can go BEFORE
    // the remaining passes stack their allocations. The PEAK,
    // not the resting level, is what collides. LSL has no
    // free(): overwriting the local drops the reference and
    // Mono's collector reuses the space. The census budget is
    // read AFTER this line, so in busy regions the freed
    // headroom becomes real born-lookup asks instead of a
    // "not counted" line.
    regionAgents = [];

    if (!gBaselined)
    {
        gKnownPad = knownCsv(scopeAgents); // keys only
        gBaselined = TRUE;
        gBaseRegion = llGetRegionName(); // this baseline belongs
                                         // to THIS region
        gPrevCap = gCap; // the population was adopted at this cap
        if (gCensusOnAdopt)
        {
            // We just adopted a new region: the REGISTRAR prints
            // the summary now (round 79) - it fetches the region
            // list it owns, counts bots / watched / new accounts
            // in its own budget, and its "C|" line reaches the
            // Companion exactly as Data's used to. This script
            // keeps only the FLAG (travel / boot / re-wear all
            // set it; config re-bases clear it).
            gCensusOnAdopt = FALSE;
            // Round 81 pre-line: a region or parcel arrival
            // announces itself BEFORE the summary, so the
            // wearer knows the HUD noticed the move and is
            // fetching - the summary is seconds away (a sweep
            // to adopt, then the born-date asks). Boot ("")
            // and re-wear stay silent: their own blocks
            // already speak.
            if (gAdoptWhy == "region" || gAdoptWhy == "parcel")
                llOwnerSay("New " + gAdoptWhy +
                    " detected - counting who is here now. The power button " +
                    "blinks while the HUD fetches account data; a summary follows.");
            gAdoptWhy = "";
            llMessageLinked(LINK_SET, LM_SWEEP_ASK, "CENSUS|A", "");
        }
        return;
    }

    // Arrivals: each scope key not in the tracked string is a
    // NEW face since the last pass. The string search costs no
    // parse; the tracked pad rides heap readings as one
    // global, never a second list.
    integer k;
    for (k = 0; k < llGetListLength(scopeAgents); k++)
    {
        key a = llList2Key(scopeAgents, k);
        if (!knownHas(gKnownPad, a))
            // Round 79: hand the arrival to the REGISTRAR - it
            // does the born/pay/lang lookup in its own budget
            // and tells Core the finished line ("LOOK|key" on
            // this same wire; the Registrar ignores its own
            // broadcasts, so there is no loop).
            llMessageLinked(LINK_SET, LM_SWEEP_ASK,
                "LOOK|" + (string)a, "");
    }

    // Departures: walk the tracked string by fixed stride -
    // every record is exactly 36 key chars plus its wrapping
    // comma, so record i spans [1+37i, 36+37i]. A tracked key
    // missing from this pass's scope has left between passes.
    integer tlen = llStringLength(gKnownPad);
    for (k = 1; k + 35 < tlen; k += 37)
    {
        key a = (key)llGetSubString(gKnownPad, k, k + 35);
        if (llListFindList(scopeAgents, [a]) == -1)
        {
            // The avatar has already left, so a name lookup
            // would fail - the viewer link still shows their
            // current display name. The WATCHED tag is added
            // by the Companion.
            llMessageLinked(LINK_SET, LM_EVENT, "OUT|" + (string)a + "|" +
                nameUri(a), "");
        }
    }
    gKnownPad = knownCsv(scopeAgents);
}

// ============================================================
// SCAN (uses the queue/wave functions defined above)
// ============================================================

rebaseData()
{
    // Silent re-adopt after scope changes, power-on, Wipe. This
    // is a CONFIG change, not an arrival, so it cancels any
    // pending summary (those belong to region jumps only) and
    // the "already present" watch announcements.
    gCensusOnAdopt = FALSE;
    gAdoptWhy = "";
    gWatchAnnounce = FALSE;
    gCap = POP_CAP; // settings re-base: full tracking budget again
    gCapCrowd = FALSE;
    // Round 79: no clearPipeline() here - nothing of ours needs
    // purging, and the Registrar hears the SAME "REBASE"
    // broadcast this function answers and purges its own.
    list regionAgents = llGetAgentList(AGENT_LIST_REGION, []);
    if (llGetAttached() != 0 && llGetListLength(regionAgents) == 0)
    {
        // Readiness guard: the region data is not ready -
        // adopting an empty population would announce everyone
        // on the next good sweep. Leave it un-baselined; the
        // next sweep adopts silently (config re-bases carry
        // no census).
        gBaselined = FALSE;
        return;
    }
    gKnownPad = knownCsv(scopeAgentsFrom(regionAgents, gCap));
    gBaselined = TRUE;
    gBaseRegion = llGetRegionName();
    gPrevCap = gCap;
}

default
{
    state_entry()
    {
        gSweepSec = SWEEP_INTERVAL;
        llSetTimerEvent(gSweepSec); // sweep + dataserver flush
                                    // (gSweepSec: adaptive - see
                                    // timer)
        // Fresh boot: the first sweep adopts the population
        // silently - with a summary, since this counts as
        // "arriving" wherever the HUD is worn.
        gCap = POP_CAP;   // fresh session: full tracking budget
        gCapCrowd = FALSE;
        gPrevCap = POP_CAP;
        gCensusOnAdopt = TRUE;
        gWatchAnnounce = TRUE;
        // A script reset is a deliberate fresh start (boot,
        // owner change, Wipe): the liveness gap record belongs
        // to the PREVIOUS incarnation, so clear it here. A
        // freeze that wakes later never runs state_entry (the
        // timer just resumes), so the record survives exactly
        // in the cases it is evidence for.
        llLinksetDataDelete(P + "gap");
        // Round 63: the starve tally follows the same
        // fresh-start rule (boot / owner change / Wipe clear
        // it; a freeze that wakes never runs state_entry).
        llLinksetDataDelete(P + "starve");
        // Round 70: the tracked CSV string follows the same
        // fresh-start rule (it is a heap global, so a script
        // reset empties it anyway - this comment marks the
        // intent): a fresh start re-adopts silently.
        gKnownPad = "";
        // Announce ourselves to Core so its gHaveData is set
        // whatever order the scripts boot in (saving a script
        // only resets THAT script). (Rounds 57/58: no Companion
        // language handshake anymore - the map lives in linkset
        // data, written by Core at ITS boot.)
        llMessageLinked(LINK_SET, LM_DATA_TELL, "ping=ok", "");
        // Ask Core for the settings/watch mirror in case we
        // (re)started after it did (SYNC -> LM_UI_STATE +
        // LM_WATCH_LIST pushes).
        llMessageLinked(LINK_SET, LM_UI_CMD, "SYNC", "");
        // Rebalance Core's busy counter: a reset landing
        // mid-census or mid-scan (an owner change, a Wipe)
        // orphans the fetch's earlier "BUSY|1" - its "BUSY|0"
        // died with the old state, leaving the power button
        // blinking until the 180 s timeout. Harmless at a
        // clean boot: Core clamps the counter at 0.
        llMessageLinked(LINK_SET, LM_EVENT, "BUSY|0", "");
        // Boot line stays a direct llOwnerSay (every other note
    // moved to the Companion's budget in round 51): it is the
    // canary proving THIS script compiled and booted, so it
    // must print even with no Companion in the linkset.
    // (Round 74: the reading is captured into gBootFree first
    // - the number every memory threshold now derives from -
    // and the canary prints THAT, so the field log and the
    // script's own arithmetic can never disagree.)
    gBootFree = llGetFreeMemory();
    llOwnerSay("Data Script ready (Build " + BUILD_NUM +
        "). Memory: " + memPct(gBootFree));
    // Round 75: the boot reading IS the datum every r74
    // threshold derives from - record it in the debug ring
    // so a field log always carries it even when the boot
    // line scrolled away.
    dbgLog("BOOT", "free=" + (string)gBootFree);
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
        if (change & (CHANGED_REGION | CHANGED_TELEPORT))
        {
            // Traveling: adopt the new region's population
            // silently on the next sweep - travelers only hear
            // about NEW people - plus the one-line arrival
            // summary. The sweep's region-identity guard may
            // have ALREADY handled this jump (at a teleport the
            // timer can run in the new region before this event
            // is delivered); if the current region is the
            // adopted one, do nothing - re-clearing would kill
            // the census that adopt just started. Same-region
            // teleports used to no-op unconditionally - round
            // 71 narrows that to REGION and PARCEL scope, where
            // the tracked population really is still valid
            // (and a same-parcel jump is handled by the sweep's
            // parcel check). RADIUS scope is the exception: the
            // wearer just moved the CENTER, so the old baseline
            // is stale - diffing it would flood OUT + ARRIVED
            // for everyone who stayed put. Re-adopt silently at
            // the new position; the watch list is region-wide
            // and keeps its presence book untouched.
            if (gBaselined && llGetRegionName() == gBaseRegion)
            {
                if (gScope == 1 && (change & CHANGED_TELEPORT))
                    gBaselined = FALSE;
                return;
            }
            travelReset("region");
        }
    }

    attach(key avatar)
    {
        // Re-baseline when the HUD is worn again (shares the
        // travel rebase body). Also stamp gWearT (round 58): the
        // first tick after a re-wear must not misread the whole
        // detach window as one giant starved tick.
        if (avatar != NULL_KEY)
        {
            gWearT = llGetUnixTime();
            travelReset("rewear");
        }
    }

    timer()
    {
        // Dataserver timeout flush: whatever arrived gets sent -
        // this also completes stuck scans and keeps the "one
        // result per lookup" guarantee.
        integer now = llGetUnixTime();
        integer prevHb = gHb; // this tick's lateness, for the
                              // adaptive interval + trace below
        // Liveness heartbeat (see gHb). Checked at the TOP of
        // the timer: the timer firing at all is the proof this
        // script is being scheduled, so the check must not sit
        // behind any early return. On the wake-up pass after a
        // gap, now - gHb is the exact time the pipeline was
        // dead - hard evidence for the freeze diagnosis, and
        // it survives the gap itself (nothing runs while the
        // script is unscheduled; the record is written by the
        // FIRST pass that does run).
        if (gHb != 0 && now - gHb > 300)
        {
            llLinksetDataWrite(P + "gap", (string)(now - gHb) + "|" + (string)now);
            // Round 75: the gap seconds belong in the debug
            // ring too - "how long was the pipeline dead" is
            // the freeze diagnosis, and the gap write alone is
            // only readable via a Status Check AFTER the fact.
            dbgLog("GAP", "dead=" + (string)(now - gHb) + "s");
            // Round 80: the LOGIN WAKE. A relog fires no LSL
            // event, but the gap is right here - the first
            // pass after 5+ minutes of downtime announces the
            // resume and fires the adopt census, so a login
            // ends in the same arrival summary a region change
            // does. Gated on the power state: OFF is a true
            // standby since this round, and a wake while OFF
            // stays quiet (the gap record above still logs it
            // for Debug).
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
        // Published heartbeat for the Core Script's stall
        // detector (round 56): a hung-but-not-halted script
        // still reports as running to llGetScriptState, so a
        // stale SMH.hb is the only in-world signal for
        // "scheduled but stuck". No write throttle to worry
        // about (saved wiki reference: the only limit is the
        // 131072-byte datastore total). (Round 80: the trace
        // one-shot that reported the write's return code is
        // deleted with the trace mode; the r69 mystery it
        // probed is long closed.)
        llLinksetDataWrite(P + "hb", (string)now);

        // Adaptive sweep interval (round 57, the freeze
        // mitigation): in a script-starved sim the timer events
        // pile up in the 64-slot event queue and EVICT the
        // wearer's clicks and the announcements - the "frozen
        // HUD" shape (field reports: a dialog from an earlier
        // click appearing only at the next crossing; a ping
        // with no text; buttons that do nothing - then a late
        // burst of everything at once). A tick that fires more
        // than 3x late means we cannot keep up: widen the sweep
        // to 10 s so the queue gets headroom. Ten clean ticks in
        // a row narrow it back. The gap recorder above handles
        // 5+ minute outages; THIS handles the 10-60 s starvation
        // that reads as "frozen" without actually dying. The
        // gWearT guard (rounds 58/59) keeps a re-wear's first
        // tick from misreading the detach window as starvation;
        // the gap recorder is deliberately NOT guarded that way.
        // Round 59: the starve RECORD got its own floor. Field
        // data (16-avatar region) shows llSetTimerEvent is
        // SCHEDULE-anchored: a late delivery is followed by an
        // on-schedule catch-up tick, so per-tick dt alternates
        // around the interval (13 s then 7 s at a 10 s setting),
        // and busy-region delivery jitter reached 13 s at the 2
        // s rung. The ENGAGE below still uses the 3x rule
        // (widening in a crowd is correct - the slower drum is
        // what stops queued clicks being evicted), but only gaps
        // of 15 s or more are COUNTED as freezes, so the Debug
        // line stays a freeze tally, not a busy-region tally.
        // The floor is independent of gSweepSec, so a 15-29 s jam
        // still records even while already at the 10 s rung.
        if (prevHb != 0 && prevHb >= gWearT && now - prevHb >= 15)
        {
            // count|longest|last to SMH.starve; the Debug report
            // prints it (Trace not needed). The 5-minute gap
            // recorder above is blind to these short freezes.
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
        // Round 60: the long-pause RESUME NOTICE. Field
        // evidence closed the freeze mystery: since server
        // 2026-09-22 (#2693) scripts attached from agent
        // inventory follow the parcel "run scripts" rule, so
        // a parcel with scripts disabled stops the WHOLE HUD
        // (no output, reset does nothing) until the wearer
        // crosses into a parcel that allows scripts. Nothing
        // runs while stopped, so warning AT THE DOOR is
        // impossible - but the first tick back knows exactly
        // how long scanning was down, and the Companion's
        // text valve turns "N|PAUSE|<secs>" into the
        // explanation. 60 s floor: above busy-region jitter
        // and the 15 s starve tally, so this means "scanning
        // was down", not "one late tick". Same gWearT guard
        // as the starve record, so a re-wear or a logout
        // (attach() re-stamps gWearT) can never masquerade
        // as a pause - only gaps while continuously worn
        // count, which is precisely the no-script-parcel
        // shape. (Round 80: gaps of 5+ minutes are the LOGIN
        // WAKE's business now - its announcement plus the adopt
        // census - so this note keeps the short-pause window.)
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
        // Round 79: the dataserver flush blocks (stale purge,
        // timeout flush, census deadline) are GONE from this
        // timer - the pipeline they drained lives in the
        // Registrar now, and its own timer flushes it. What is
        // left here is pure detection cadence: the heartbeat,
        // the liveness records, the adaptive interval, the
        // dilation watch and the sweep call below.

        // Region slowdown watch: llGetRegionTimeDilation()
        // reads 1.0 at full sim speed. Checked only while
        // monitoring is ON, edge-triggered with a wide recovery
        // band so a borderline sim cannot flap a line every
        // sweep: ONE line on the drop, ONE on the recovery. The
        // percent is sent instead of the raw float so the line
        // reads clean.
        if (gHaveState && gEnabled)
        {
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

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == LM_DATA_ASK)
        {
            // Handshake only: lookups originate here now.
            if (str == "ping")
                llMessageLinked(LINK_SET, LM_DATA_TELL, "ping=ok", "");
            return;
        }

        if (num == LM_MEM_ASK)
        {
            // Debug: report this script's free memory (the
            // Companion formats and prints the labeled line).
            // Round 80 (pre-field amendment): the reply also
            // carries THIS script's build number, so the
            // Status Check memory lines show WHICH build each
            // script runs - a mixed-round unit shows different
            // builds on its lines.
            llMessageLinked(LINK_SET, LM_MEM_TELL,
                "Data Script|" + (string)llGetFreeMemory() + "|" +
                BUILD_NUM, "");
            // If a liveness gap was recorded since the last
            // Wipe, report it right after the memory line - it
            // is the after-the-fact timing of any freeze.
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
            // Round 79: "SCAN", "NEAR" and "CENSUS" are the
            // REGISTRAR's to answer on this wire. So are this
            // script's OWN handoff broadcasts ("LOOK|key",
            // "CENSUS|A", "RESET" - link messages reach every
            // script including the sender), which this branch
            // ignores by design: it matches "REBASE" only.
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
            // Drop presence rows for keys no longer watched.
            integer i;
            for (i = llGetListLength(gWatchedIn) - 1; i >= 0; i--)
            {
                // Round 80 type-trap fix: gWatch is a STRING
                // mirror (llParseString2List) - a KEY needle
                // never matches a string element in
                // llListFindList, so this check always
                // returned -1 and a removed entry's presence
                // row survived to fire a phantom "left" line.
                // Cast the needle to string (same fix as the
                // Registrar's two census/flags sites).
                if (llListFindList(gWatch,
                    [llList2String(gWatchedIn, i)]) == -1)
                    gWatchedIn = llDeleteSubList(gWatchedIn, i, i);
            }
            // Newly watched avatars who are ALREADY present are
            // seeded silently (no phantom "entered" message), like
            // Core's old addWatch presence check.
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
