# Opossum Labs Awareness HUD - Script Architecture

Four scripts, one logical object. Each script lives in the LSL `default` state only, so the "states" below are conceptual: each script is a set of event handlers (timer, listen, touch, link_message, dataserver) sharing globals, plus a shared memory bus. Everything durable lives in linkset data under the `SMH.*` prefix, so any script can reset without losing settings, the watch list, logs, or encounters.

Current rounds: Core 87 (build 111126087), Data 81 (110226081), Registrar 85 (110626085), Companion 86 (110626086).

## The Big Picture

The Core holds configuration and drives the power light. The Data Script is the detection engine. The Registrar does every account-data fetch (the memory-heavy work) and all listings. The Companion is the only script that talks to the wearer: menus, dialogs, and every chat line.

```mermaid
flowchart TB
  wearer["Wearer: touch, menus, typed text, chat"]
  region["Region: agent list, dilation"]
  ds["Dataserver: born dates, payment status"]
  core["Core r87: settings, watch list, persistence, power light, failure sweep"]
  data["Data r81: detection engine, sweeps, watch alerts"]
  reg["Registrar r85: arrival lookups, List All, census, Watch+"]
  comp["Companion r86: menus, dialogs, every chat line, encounters"]
  subgraph lsd["Linkset data bus, SMH. prefix"]
    prefs["settings: owner, enabled, scope, range, ping, lastpt, cap"]
    watch["watch list CSV"]
    beats["heartbeats: corehb, hb, rhb, chb"]
    rings["rings: dlog, err, enc, gap, starve"]
  end
  wearer -->|"panel button touches"| core
  wearer -->|"menu clicks, typed UUID or radius"| comp
  comp -->|"UI_CMD: power, scope, watch edits, SCAN, CENSUS, WIPE, SYNC"| core
  core -->|"UI_STATE broadcast: enabled, scope, range"| data
  core -->|"UI_STATE + watch CSV"| reg
  core -->|"UI_STATE"| comp
  region -->|"llGetAgentList every 2 s"| data
  data -->|"LOOK key for each new arrival"| reg
  data -->|"CENSUS A on region adopt"| reg
  core -->|"SCAN and CENSUS relay"| reg
  comp -->|"NEAR, the Watch+ ask"| reg
  reg -->|"born and pay queries"| ds
  reg <-->|"language ask and answer"| comp
  reg -->|"finished arrival row"| core
  core -->|"A: the arrival line"| comp
  reg -->|"C census, D slowdown, AE encounter, NR handshake"| comp
  data -->|"N notes, D slowdown"| comp
  data -->|"BUSY blink, OUT, WIN, WOUT, WFOUND"| core
  core --> prefs
  core --> watch
  data -->|"hb"| beats
  reg -->|"rhb"| beats
  comp -->|"chb"| beats
  core -->|"corehb"| beats
  core -->|"failure sweep reads hb, rhb, chb"| beats
  comp -->|"Core watchdog reads corehb"| beats
  data -->|"gap, err"| rings
  reg -->|"rdbg, err"| rings
  comp -->|"enc encounters, cdbg"| rings
  comp -->|"chat lines"| wearer
  reg -->|"List All lines direct"| wearer
```

The two safety loops worth calling out:

- Core sweeps the three worker heartbeats (`hb`, `rhb`, `chb`); a stale one fails the power light to a red blink and writes a failure ring entry.
- The Companion watches Core the same way (`corehb`, stale after 120 seconds) because a dead Core cannot report itself. Whoever notices, the wearer sees the light.

## Core Script (r87) - settings, watch list, power light

The Core owns every preference and the watch list, persists all of it to linkset data, and relays menu commands to the right worker. It never talks to the dataserver.

```mermaid
flowchart TD
  boot["state_entry: load settings from linkset, place panel prims, broadcast UI_STATE, ask workers for SYNC"] --> idle["Idle: timer every 5 s, or 0.5 s while the light blinks"]
  idle -->|"touch: power button"| power["setPower: save pref, broadcast UI_STATE"]
  idle -->|"touch: other panel prims"| panel["scope, ping sound, reseat hint"]
  idle -->|"owner chat command"| chatcmd["handleCmd: reseat and friends"]
  idle -->|"UI_CMD from Companion"| uicmd["SYNC: push watch and settings mirrors, SCAN or CENSUS relay, ADD or REMOVE watch, WIPE, STATUS"]
  uicmd --> watchedit["addWatch or removeWatchByIndex: save CSV to SMH.watch, broadcast LM_WATCH_LIST"]
  idle -->|"every pass"| hb["publish corehb heartbeat"]
  idle -->|"every pass"| sweep["checkFailures: hb, rhb, chb freshness"]
  sweep -->|"one stale"| fail["red failure blink, ring entry naming the script"]
  idle -->|"every pass"| light["lightTick: the power light vocabulary"]
  wipe["doWipe: delete every SMH key"] --> fresh["all scripts reboot into a clean HUD, welcome flow re-runs"]
```

The power light is a genuine state machine with a fixed priority: failure beats OFF, OFF beats busy.

```mermaid
stateDiagram-v2
  [*] --> On
  On --> Off : power off
  Off --> On : power on
  On --> Busy : a fetch starts, dim green blink
  Busy --> On : fetch done or 180 s safety stop
  Busy --> Slow : fetch over 30 s, yellow blink
  Slow --> On : fetch done
  On --> Fail : a heartbeat went stale, red with dark phase
  Off --> Fail : a heartbeat went stale
  Fail --> On : all heartbeats healthy again
```

Reseat recovery: `lastpt` records the panel position; a Status Check compares it and prints the reseat hint when prims drifted, and the reseat command rebuilds the default placement.

## Data Script (r81) - the detection engine

One timer, one sweep loop, no dataserver. Every 2 seconds it fetches the region agent list, filters it to scope, and diffs it against what it already knows. It degrades honestly: a memory-guard ladder narrows the tracking cap in busy regions instead of crashing.

```mermaid
flowchart TD
  boot["state_entry: ask SYNC, rebase, start 2 s timer"] --> loop["Timer every 2 s"]
  loop --> agents["llGetAgentList region-wide"]
  agents --> scope["scope filter: parcel, radius, or region, plus tracking-cap ladder"]
  scope --> tight["memory tight: cap ladder narrows, N MEMPAUSE note, timer drops to 10 s"]
  tight --> loop
  scope --> wd["watch diff against watch mirror"]
  wd -->|"watched person enters"| win["WIN or WFOUND event"]
  wd -->|"watched person leaves"| wout["WOUT event"]
  scope --> diff["arrival diff against the known pad"]
  diff -->|"new in scope"| look["LOOK key to the Registrar"]
  diff -->|"gone"| out["OUT event to Core"]
  diff -->|"first pass in a new region"| census["CENSUS A to the Registrar, silent adopt"]
  loop --> dilate["dilation watch: D low or D ok note"]
  loop --> hbpass["publish hb heartbeat, record gap diagnostics"]
  agents --> corrupt["corrupt or empty list: drop the pass, ring entry"]
```

Everything above flows out as events and notes; the Registrar does the actual account lookups, so a slow dataserver never stalls detection.

## Registrar Script (r85) - lookups, listings, census, Watch+

The fourth script exists for one reason: listing memory. Every dataserver pipeline lives here against a nearly empty 64 KB Mono budget, so a listing collision can no longer kill detection. All four of its request kinds share one row pipeline with memory guards priced against live population.

```mermaid
flowchart TD
  req["Requests: LOOK from Data, SCAN from Core, CENSUS from Core, NEAR from Companion"]
  req --> guard{"memory guards: population x 102 + 3500, fit-cap, ask budget"}
  guard -->|"refused"| refuse["honest refusal: too-busy dialog or trimmed count, RREFUSE in ring"]
  guard -->|"passes"| ask["askAgent rows: born and pay queries to the dataserver"]
  ask --> pend["gPending rows, each with an expiry"]
  pend --> reply["dataserver replies"]
  reply --> entry["sendEntry by row kind"]
  entry --> kindA["A: finished arrival row to Core"]
  entry --> kindS["S: List All buffer, flushed to chat every 10 lines or 900 bytes"]
  entry --> kindX["X: census counters, then one C summary to the Companion"]
```

List All runs in capped waves so the heap never holds the whole region at once. The census counts new accounts, scripted agents, and watched people in one summary line, with born-date asks budgeted against free memory.

The Watch+ picker got the round-85 fix: its state is the one thing that could wedge the self-heal, so it now expires.

```mermaid
stateDiagram-v2
  [*] --> NoPick
  NoPick --> PickOpen : NEAR accepted, top-10 nearest, dialog on its own channel, gPickDue set
  PickOpen --> PickOpen : pick made, ADD sent, dialog re-shown, deadline refreshed
  PickOpen --> ManualAdd : Manual Add box opens, deadline refreshed
  ManualAdd --> PickOpen : UUID submitted
  PickOpen --> NoPick : Back, or 120 s with no response
  ManualAdd --> NoPick : Back, or 120 s with no response
  NoPick --> SelfHeal : free memory under 6000 and all gates quiet
  SelfHeal : gcNudge, re-read, logErr selfheal, llResetScript
  SelfHeal --> NoPick : boot re-asks SYNC, mirrors back within one pass
```

Self-heal gates: no scan wave (`gScanCount`), no census (`gCensusLeft`), no buffered listing lines (`gScanLines`), no pick dialog (`gPickKeys`), no pending rows (`gPending`). The pick expiry is what reopens the last gate after a dismissed dialog.

## Companion Script (r86) - menus, dialogs, the text valve

Every word the wearer reads comes from here, including the system notes whose full text is far too big to keep in the workers. It owns the menu tree, the welcome flow, the encounter log, and the self-heals.

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> Welcome : first boot or after Wipe, setup key gone
  Welcome --> Idle : setup finished, setup key written
  Idle --> Main : menu button touched
  Main --> Settings
  Settings --> Area
  Area --> Radius
  Radius --> Area : Back
  Area --> Settings : Back
  Settings --> Diagnostics
  Diagnostics --> Settings : Back
  Settings --> ConfirmWipe : Wipe
  ConfirmWipe --> Settings : Cancel or confirm
  Settings --> Main : Back
  Main --> WatchWait : Watch+, NEAR sent, 10 s safety net armed
  WatchWait --> Main : Registrar dialog takes over, NR ok stands the net down
  Main --> Remove : Watch-, pages of six names
  Remove --> Main : Back
  Main --> Typing : Manual Add UUID or custom radius, gMode set
  Typing --> Idle : submitted or expired
  Main --> ChatOut : Summary, List All, Watch List, Encounters, Status fire their requests and print
```

Alongside the menu tree, the timer runs three standing jobs:

- Core watchdog: `corehb` over 120 seconds stale means Core is dead or hung, so the Companion takes the power light and blinks red itself, with a `corewatch` ring entry.
- Low-water self-report: under a free-memory threshold it says so, throttled to once per 10 minutes.
- Self-heal: under 2,000 free at a quiescent moment (no typed-input mode, no pending Watch+ safety net, no welcome flow active or scheduled, no live Core watchdog) it writes a `selfheal` ring entry and resets itself.

The text valve decodes worker codes into owner chat: `A` arrivals, `L` departures, `W` watch in/out, `AE` scripted-agent encounters, `C` census summaries, `D` region slowdown, `N` system notes, `NR` the Watch+ handshake.

## One Arrival, End To End

The busiest path in the HUD: a stranger walks into scope.

```mermaid
sequenceDiagram
  participant R as Region
  participant D as Data
  participant G as Registrar
  participant S as Dataserver
  participant C as Core
  participant M as Companion
  participant W as Wearer
  R ->> D: avatar appears, seen on the 2 s sweep
  D ->> D: scope filter, watch diff, arrival diff
  D ->> G: LOOK key
  G ->> S: born date and payment queries
  S -->> G: answers
  G ->> M: language ask if not cached in langmap
  M -->> G: language name
  G ->> C: finished arrival row
  C ->> C: flags, ping sound if flagged, distance snapshot
  C ->> M: A, scope, name, age, pay, language, flags, distance
  M ->> W: the arrival line in chat
  M ->> M: encounter logged to SMH enc
```

Variations on this path: a watched arrival also fires a `WFOUND` or `WIN` event with the alert ping; the first arrival in a new region also triggers the adopt census, which comes back as the one-line ARRIVAL SUMMARY; a scripted agent is named in an `AE` encounter; and a sim running slow adds the short `D` slowdown line.

## Reference: The Bus

Link messages (all scripts, `LINK_SET` broadcast, each script matches only its own literals):

| Channel | Who sends | Carries |
|---|---|---|
| LM_UI_CMD 19030 | Companion to Core | menu actions: SYNC, SCAN, CENSUS, ADD, REMOVE, WIPE, STATUS |
| LM_UI_STATE 19029 | Core to all | enabled, scope, range mirror |
| LM_WATCH_LIST 19031 | Core to all | watch list CSV mirror |
| LM_SWEEP_ASK 19034 | mixed | NEAR from Companion, SCAN and CENSUS relay from Core, LOOK and CENSUS A from Data; Data itself answers REBASE only |
| LM_SAY 19027 | workers to Companion | text-valve codes: A, L, W, AE, C, D, N, NR |
| LM_EVENT 19035 | Data to Core, Companion | OUT, BUSY, WIN, WOUT, WFOUND |
| LM_LANG_ASK / TELL 19024 / 19025 | Registrar to Companion and back | viewer language code to display name |
| LM_DATA_ASK / TELL 19032 / 19033 | Core to Data and back | ping handshake |
| LM_MEM_ASK / TELL 19036 / 19037 | any script | Debug line: name, free bytes, build |

Linkset data keys (`SMH.*`), the only durable state:

| Key | Owner | Holds |
|---|---|---|
| owner, enabled, scope, range, ping | Core | settings, written on every change |
| watch | Core | watch list CSV |
| lastpt | Core | panel position for the reseat hint |
| setup | Companion | welcome done marker, deleted by Wipe |
| cap | Data | tracking cap, read for busy-context lines |
| corehb, hb, rhb, chb | each script | liveness heartbeats, the failure sweep and watchdog read them |
| gap, coregap, starve | Core, Data | freeze and starvation diagnostics |
| dlog, cdbg, rdbg, dbg | each script | debug ring entries |
| err0 to err9, errNext | Data and Registrar | error ring, ten slots |
| enc, encdays | Companion | encounter log and retention |
| langmap | Registrar | cached viewer language codes |

<!-- ARCHITECTURE.md mirrors the awareness-hud-architecture canvas. Update this file when script rounds or flows change. -->
