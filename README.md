# Opossum Labs Awareness HUD

A Second Life heads-up display that keeps an eye on who is around you: it
announces arrivals with account age, payment status and viewer language,
watches for scripted agents region-wide, and alerts the moment a watched
avatar appears. Everything runs inside the HUD - linkset data and script
memory only. No external services, no backend, nothing leaves the object.

- Arrival announcements with age, payment status, language and flags
- Watch list with region-wide enter/leave alerts and a sound ping
- Scripted-agent detection and encounter logging
- List All, nearest-first Watch+ picker, region census summary
- Parcel / radius / region scope, power button, in-world help notecard
- Self-monitoring: heartbeats, failure sweep, self-healing memory resets

## The four scripts

| File | Role | Build |
|---|---|---|
| `OpossumLabs-AwarenessHUD-CoreScript.lsl` | Settings, watch list, panel buttons, power light, persistence, failure sweep | 110226082 |
| `OpossumLabs-AwarenessHUD-DataScript.lsl` | Detection engine: arrivals, sweeps, watch alerts, region slowdown watch | 110226081 |
| `OpossumLabs-AwarenessHUD-RegistrarScript.lsl` | Arrival lookups, List All, census, Watch+ picker, self-heal | 110626085 |
| `OpossumLabs-AwarenessHUD-CompanionScript.lsl` | Menus, dialogs, all chat output, encounters, Core watchdog, self-heal | 110626086 |
| `OpossumLabs-AwarenessHUD-HelpNotecard.txt` | In-world help notecard | v1.0 |

ARCHITECTURE.md has per-script state and data-flow diagrams (Mermaid
renders on GitHub).

## Quick start

1. Rez or wear the HUD object. The scripts may live in any prim of the
   linkset; the Core rebuilds its default panel placement on boot.
2. Create a new script in the object, paste one file into it, save, and
   repeat for all four scripts. The Status Check menu option prints each
   script's build number to confirm what is running.
3. Create a notecard, paste the help notecard text, and name it exactly
   `Awareness Hud Help` (the Core looks for this name).
4. Wear the HUD. The first-time welcome flow walks you through the rest.

Comments in these files are deliberately short: each header carries
the repository address, and the why behind each design lives here and
in ARCHITECTURE.md, not in the code. Someone reading a script inside
Second Life cannot open the markdown pages, so the code comments
stand on their own.

## Design guide: making your own HUD from this code

If you fork this, keep the architecture unless you have a reason not to.
It exists because of how Second Life's scripting runtime works.

One job, one script, one heap. Every LSL script gets its own ~64 KB Mono
heap, and a HUD that mixes detection, listings and menus in one script
will hit Stack-Heap Collisions under load. The split here is by
volatility: the detection loop (Data Script) must never share a heap
with burst-heavy listing work (Registrar), and neither may share one
with the UI (Companion). A crash in one script cannot take down the
core function.

All durable state lives in linkset data. The `SMH.*` keys hold every
setting, the watch list, the logs and the encounters, so any script can
be reset at any time without losing anything. This is what makes the
self-heal resets safe: a worn-down script resets itself at a quiet
moment and reads its state back from the bus on boot.

One script owns the user's eyes. The Companion prints every line and
builds every dialog. Workers send compact pipe-coded messages (see the
channel table in ARCHITECTURE.md); the full human-readable text exists
in exactly one heap. Full text strings are the most expensive thing in
LSL - never duplicate them across scripts.

Mirrors, not requests. Core broadcasts the settings and the watch list
as mirrors (LM_UI_STATE, LM_WATCH_LIST). Workers ask for a SYNC push at
boot instead of querying Core synchronously, so a restarting script is
fully functional within one timer pass.

Degrade honestly, never crash. Every memory-heavy path has a guard
priced against live population (a listing costs roughly 102 bytes per
avatar in the region), a fit-cap that trims counts instead of failing,
and an honest refusal line when the work genuinely does not fit.
`llGetFreeMemory()` under-reports until Mono's lazy collector runs, so
every guard nudges the collector before reading. Copy this pattern if
you copy nothing else.

Liveness is a design, not an afterthought. Every script publishes a
heartbeat to linkset data every timer pass. Core sweeps the three
workers; the Companion watches Core (a dead Core cannot report itself);
whoever notices, the power light tells the wearer. The Registrar and
Companion reset themselves when free memory drops below their floors and
all work is quiet - the quiescence gates matter, a reset mid-listing
would be worse than low memory.

Invariants to respect when editing:

- LSL compiles top-down: declare a global before any use of it.
- The watch mirror holds CSV strings, not keys - cast before matching.
- Fetches run in capped waves; never hold a whole region in one list.
- Flush listing output at 10 lines or 900 bytes (llOwnerSay caps at 1024).
- The four scripts are pasted as a matched set; keep build stamps in sync
  and read them back from Status Check after pasting.

## Documentation

- ARCHITECTURE.md - every script's states, flows and the message bus,
  with diagrams.
- The help notecard - end-user documentation (CC BY-SA 4.0), readable
  outside Second Life too.
- Each script header - a short license notice, what the script owns,
  and the repository address.

## Known issues and limitations

- The watch list holds at most 20 entries.
- In busy regions the memory guards trip on purpose: List All answers
  with a short memory note and Watch+ offers Manual Add only until the
  region quiets down. The HUD degrades; it never crashes.
- The Watch+ picker and its Manual Add box expire after 120 seconds
  with no response - just click Watch+ again.
- Under memory pressure the Data Script tracks fewer avatars and slows
  its sweep from 2 s to 10 s, and says so in chat.
- On parcels that disallow scripts the HUD is dormant - no detection,
  no menus - and wakes itself up when you leave. That is Second Life's
  rule, not a fault.
- Arrival details (account age, payment status) come from the
  dataserver and can lag a few seconds behind the arrival itself.
- Crossing a region border or teleporting aborts any listing in
  progress; the HUD re-adopts the new region silently on its first pass.
- Sim freezes are Second Life scheduling, not HUD faults: the HUD waits
  them out and catches up by itself, and Trace shows them.

## Compatibility

Second Life regions (LSL, Mono runtime). No external HTTP services, no
database, no listener ports. Works as an attachment in any linkset.

## License and branding

The code - the four .lsl scripts - is GPL-3.0-or-later. See LICENSE for
the full text. The scripts carry the standard per-file notice in their
headers. If you redistribute the HUD in-world, keep the license headers
intact and point recipients at this repository for the source - the
help notecard already does.

The help notecard text is documentation, not code, and is separately
licensed under Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA
4.0). You may share and adapt it, including commercially, as long as
you credit Opossum Labs and share adaptations under the same license.

The name "Opossum Labs" and this project's branding are not part of
either license and are not licensed for use in derived works. If you
build your own product from this code, give it your own name and your
own branding: do not sell or present it as an Opossum Labs product,
and do not present yourself as an authorized representative of Opossum
Labs. Stating truthfully that your work is based on or derived from
this project is fine and needs no permission.

(c) 2026 Opossum Labs - rachel.possum in-world.
