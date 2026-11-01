# Opossum Labs Awareness HUD

Opossum Labs' first retail product for Second Life: a 4-script Awareness HUD
(arrival/scan pipeline, census, watch list, per-attachment-point placement).

## Scripts (round 79 snapshot)

| File | Role | Round |
|---|---|---|
| OpossumLabs-AwarenessHUD-CoreScript-round78.lsl | Core Script (root prim) | 78 |
| OpossumLabs-AwarenessHUD-DataScript-round79.lsl | Data Script - pure detection (sweep, valve/ladder/probe, tracked pad, watch pad) | 79 |
| OpossumLabs-AwarenessHUD-RegistrarScript-round79.lsl | Registrar - listing relay, census, arrival lookups, Watch+ pick dialog | 79 |
| OpossumLabs-AwarenessHUD-CompanionScript-round79.lsl | Companion - menus and chat UI | 79 |
| OpossumLabs-AwarenessHUD-HelpNotecard-round79.txt | Help notecard text (paste into the in-world notecard) | 79 |

## Paste rule

Data, Registrar AND Companion must be pasted together in-world (all three first
lines read ROUND 79); Core stays its round-78 copy. Mixed old/new among the
three movers breaks arrivals, Summary and Watch+.

The first comment line of every script is its ROUND stamp - read it before any
paste. Boot canary expectations for round 79: Data clears the 13,220
hundred-agent crossover (r78 reading: 12304); Registrar drops from 29082;
Companion rises from 2910; Core unchanged at 14402.

## Conventions

- ROUND stamp as the first comment line of every script
- VERSION blocks newest-first
- Comment/string-aware brace/paren balance check after every edit
- Full ll-name audit of changed scripts every round
- No expressions in global initializers; no ternary/break/continue
