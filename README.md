# Opossum Labs Awareness HUD

A Second Life LSL heads-up display that keeps an eye on who is around you:
it announces arrivals with account age, payment status and viewer language,
watches for scripted agents region-wide, and alerts the moment a watched
avatar appears. Everything runs inside the HUD - linkset data and script
memory only. No external services, no backend, nothing leaves the object.

## Files

| File | Role | Round |
|---|---|---|
| `OpossumLabs-AwarenessHUD-CoreScript-round78.lsl` | Settings, watch list, panel buttons, persistence | 78 |
| `OpossumLabs-AwarenessHUD-DataScript-round79.lsl` | Detection engine - arrivals, sweeps, watch alerts | 79 |
| `OpossumLabs-AwarenessHUD-RegistrarScript-round79.lsl` | Census, List All, Watch+ ranking, memory-guarded fetching | 79 |
| `OpossumLabs-AwarenessHUD-CompanionScript-round79.lsl` | Menus, dialogs, owner chat output | 79 |
| `OpossumLabs-AwarenessHUD-HelpNotecard-round79.txt` | In-world help notecard | 79 |

The scripts are paired as a set: update all changed scripts together,
following the ROUND header at the top of each file. Round 79 is the
field-tested current release; the Core Script is stable at round 78.

Private repository - retail product source. Do not redistribute.