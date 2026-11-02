# Opossum Labs Awareness HUD

A Second Life LSL heads-up display that keeps an eye on who is around you:
it announces arrivals with account age, payment status and viewer language,
watches for scripted agents region-wide, and alerts the moment a watched
avatar appears. Everything runs inside the HUD - linkset data and script
memory only. No external services, no backend, nothing leaves the object.

## Files

| File | Role | Round |
|---|---|---|
| `OpossumLabs-AwarenessHUD-CoreScript-round80.lsl` | Settings, watch list, panel buttons, persistence, reseat recovery | 80 |
| `OpossumLabs-AwarenessHUD-DataScript-round81.lsl` | Detection engine - arrivals, sweeps, watch alerts, arrival pre-line, parcel-scope arrival summary | 81 |
| `OpossumLabs-AwarenessHUD-RegistrarScript-round80.lsl` | Census, List All, Watch+ ranking, memory-guarded fetching | 80 |
| `OpossumLabs-AwarenessHUD-CompanionScript-round80.lsl` | Menus, dialogs, owner chat output | 80 |
| `OpossumLabs-AwarenessHUD-HelpNotecard-round81.txt` | In-world help notecard | 81 |

The scripts are paired as a set: update all changed scripts together,
following the ROUND header at the top of each file. Round 81 is the
current release (the Data script and the help notecard carry the
arrival pre-line - "New region detected / New parcel detected" before
the arrival summary - and the Parcel-scope parcel-change summary;
Core, Registrar and Companion are unchanged from round 80).

Private repository - retail product source. Do not redistribute.
