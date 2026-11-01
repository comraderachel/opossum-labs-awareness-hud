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
| `OpossumLabs-AwarenessHUD-DataScript-round80.lsl` | Detection engine - arrivals, sweeps, watch alerts | 80 |
| `OpossumLabs-AwarenessHUD-RegistrarScript-round80.lsl` | Census, List All, Watch+ ranking, memory-guarded fetching | 80 |
| `OpossumLabs-AwarenessHUD-CompanionScript-round80.lsl` | Menus, dialogs, owner chat output | 80 |
| `OpossumLabs-AwarenessHUD-HelpNotecard-round80.txt` | In-world help notecard | 80 |

The scripts are paired as a set: update all changed scripts together,
following the ROUND header at the top of each file. Round 80 is the
current release (Data and Core are unchanged from the earlier round-80
paste; Registrar, Companion and the notecard carry the mid-field
export/import removal).

Private repository - retail product source. Do not redistribute.
