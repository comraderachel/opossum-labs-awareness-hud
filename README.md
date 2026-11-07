# Opossum Labs Awareness HUD

A Second Life LSL heads-up display that keeps an eye on who is around you:
it announces arrivals with account age, payment status and viewer language,
watches for scripted agents region-wide, and alerts the moment a watched
avatar appears. Everything runs inside the HUD - linkset data and script
memory only. No external services, no backend, nothing leaves the object.

## Files

| File | Role | Current version |
|---|---|---|
| `OpossumLabs-AwarenessHUD-CoreScript.lsl` | Settings, watch list, panel buttons, power-light vocabulary, failure sweep, persistence, reseat recovery | 82 |
| `OpossumLabs-AwarenessHUD-DataScript.lsl` | Detection engine - arrivals, sweeps, watch alerts, arrival pre-line, parcel-scope arrival summary | 81 |
| `OpossumLabs-AwarenessHUD-RegistrarScript.lsl` | Census, List All, Watch+ ranking, memory-guarded fetching, liveness heartbeat, self-heal reset, pick-dialog expiry | 85 |
| `OpossumLabs-AwarenessHUD-CompanionScript.lsl` | Menus, dialogs, owner chat output, liveness heartbeat, Core watchdog, self-heal reset | 86 |
| `OpossumLabs-AwarenessHUD-HelpNotecard.txt` | In-world help notecard | 84 |

The scripts are paired as a set: update all changed scripts together,
following the ROUND header at the top of each file.

## Tracking changes

Each file keeps its name across releases: a new round lands as a commit
that UPDATES the existing files, so the commit history shows exactly what
was added or removed from round to round. The ROUND header at the top of
each script (and the per-script Build number on the HUD's Status Check)
identify which round a running copy is. Current release: round 86 (the
REGION SLOWDOWN line lost its speculation clause - it now states the sim
speed and the recovery promise, nothing else; the Data, Core and
Registrar scripts and the help notecard are unchanged from rounds
81/82/85/84).

Private repository - retail product source. Do not redistribute.
