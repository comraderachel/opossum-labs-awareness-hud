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
| `OpossumLabs-AwarenessHUD-RegistrarScript.lsl` | Census, List All, Watch+ ranking, memory-guarded fetching, liveness heartbeat, self-heal reset | 84 |
| `OpossumLabs-AwarenessHUD-CompanionScript.lsl` | Menus, dialogs, owner chat output, liveness heartbeat, Core watchdog, self-heal reset | 84 |
| `OpossumLabs-AwarenessHUD-HelpNotecard.txt` | In-world help notecard | 84 |

The scripts are paired as a set: update all changed scripts together,
following the ROUND header at the top of each file.

## Tracking changes

Each file keeps its name across releases: a new round lands as a commit
that UPDATES the existing files, so the commit history shows exactly what
was added or removed from round to round. The ROUND header at the top of
each script (and the per-script Build number on the HUD's Status Check)
identify which round a running copy is. Current release: round 84 (the
self-heal resets in the Companion and Registrar - field wear ratchets
free memory down via Mono heap fragmentation, so both scripts now reset
themselves at a quiescent moment to restore boot memory; the Core and
Data scripts are unchanged from rounds 82/81. The help notecard was
refreshed to match: the Status line now reflects the any-stopped-script
health wording, the self-heal behavior is explained, and the removed
backup-feature promise is no longer promised).

Private repository - retail product source. Do not redistribute.
