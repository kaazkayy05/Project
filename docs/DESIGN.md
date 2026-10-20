# Graveyard Shift — design context

This document records planned design, not implemented functionality.

Two players work a cemetery night shift from 12 AM to 6 AM.
Players receive randomized jobs: digging graves, replacing flowers,
fixing lights, returning tools, sweeping grave sites, and security patrol.

Players share a work quota. Complete enough jobs and return to the gate
together before 6 AM to win. Missing the deadline buries both players.

Small jobs can be completed alone. Digging requires one player digging
and another holding a lantern; players can swap roles. Grave assignments
specify coffin size, funeral time, and designated digging area.

Both players begin with a flashlight and shovel. Other equipment becomes
available according to assigned jobs.

A creature copies either player's appearance and performs believable
actions to lure someone away. Its tool is an outdated copy of that
player's equipment, providing an identification clue.

Creatures have different threat levels. Players observe an encounter
and judge whether the creature will chase. Encounters do not
automatically become chases.

The cemetery bell repels the creature and has three shared uses.

Captured players are buried in a coffin. Their teammate initially has
45 seconds to locate the correct grave and dig them out. Buried players
hear sounds above ground and can provide clues.

The finished game includes proximity voice chat and instructions that
teach the rules without the developer explaining them.

## Unresolved decisions

- Threat-level count, names, clues, triggers, speeds, and behaviors.
- Whether levels change during a shift or represent variants or states.
- Any explicit threat-level display requires separate approval.
- Coffin-size mechanics and funeral-time consequences.
- Lantern access and cooperative digging details.
- Buried-player voice range and clue mechanics.
- Final voice architecture and browser/native compatibility.
- Public hosting provider, domain, TLS and delivery configuration.

Do not invent or implement these decisions without approval.

## Competition requirements

At least two players connect from separate devices.
Players learn the rules inside the game.
The finished game has a public URL or publicly reachable host.

Local clients do not prove internet multiplayer.
Native clients do not prove browser compatibility.
