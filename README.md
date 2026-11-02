# Opossum Labs Awareness HUD

A Second Life LSL heads-up display that keeps an eye on who is around you:
it announces arrivals with account age, payment status and viewer language,
watches for scripted agents region-wide, and alerts the moment a watched
avatar appears. Everything runs inside the HUD - linkset data and script
memory only. No external services, no backend, nothing leaves the object.

## Files

| File | Role | Round |
|---|---|---|
| `OpossumLabs-AwarenessHUD-CoreScript-round82.lsl` | Settings, watch list, panel buttons, power-light vocabulary, failure sweep, persistence, reseat recovery | 82 |
| `OpossumLabs-AwarenessHUD-DataScript-round81.lsl` | Detection engine - arrivals, sweeps, watch alerts, arrival pre-line, parcel-scope arrival summary | 81 |
| `OpossumLabs-AwarenessHUD-RegistrarScript-round82.lsl` | Census, List All, Watch+ ranking, memory-guarded fetching, liveness heartbeat | 82 |
| `OpossumLabs-AwarenessHUD-CompanionScript-round82.lsl` | Menus, dialogs, owner chat output, liveness heartbeat, Core watchdog | 82 |
| `OpossumLabs-AwarenessHUD-HelpNotecard-round82.txt` | In-world help notecard | 82 |

The scripts are paired as a set: update all changed scripts together,
following the ROUND header at the top of each file. Round 82 is the
current release: the power button learns a vocabulary - solid YELLOW when
detection is narrowed (busy region or low memory; the watch list stays
fully covered either way), a BLINKING YELLOW when a fetch runs past 30
seconds, and a BLINKING RED plus a chat line when a script has stopped or
is not responding. Core runs a 5-second failure sweep over all three
worker scripts (missing, halted, or hung - the Registrar and Companion
now publish liveness heartbeats for it), and the Companion runs a
watchdog that blinks the light red if Core itself ever goes silent. The
Data script is unchanged from round 81 (arrival pre-line and
parcel-scope arrival summary).

Private repository - retail product source. Do not redistribute.
