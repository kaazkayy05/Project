# Sweeping milestone

## Scope

One sweeping assignment per player per shift.
Two existing graves are assigned; their positions are shown on the map.
Gravestones have no assignment-number labels.
No automatic replacement assignments.

Each player sees their own broom pickup at the same location inside the shed.
Collecting it hides it only on that player's client.
The other player's pickup remains available and visible to them.
The server validates collection and owns each player's broom availability.
Equipped brooms remain visible to teammates.
Existing flashlight and shovel remain available.

Controls:
- E: collect broom while looking at the supply.
- 3: equip collected broom.
- Hold E: sweep the assigned ground patch.
- M: toggle the live cemetery map.
- Esc: close the map and release the mouse.
- Movement and the shift clock continue while the map is open.
- Existing movement, mouse, equipment and mouse-release controls remain.

Interaction reach is 3 metres from camera to first ray intersection.
Sweeping requires 8 accumulated seconds.
Release, invalid aim, distance, equipment, focus or input expiry stops work.
Earned work remains until session reset.

Eight debris pieces disappear progressively.
A simple broom animation follows server-confirmed valid sweeping.
It is visible locally and to the teammate. No sound is included.
Only the assigned player advances the job.

The server owns assignments, broom ownership, progress and completion.
Each sweeping assignment adds exactly one shared completed job only
after its borrowed broom is returned to the shed.
The test target is two; it does not trigger victory or a gate interaction.
The existing clock and 6 AM loss remain.

Disconnect cancellation uses the existing lobby reset behavior.
Each new shift clears tasks, broom ownership and shared completed jobs.

## Borrowed broom return

The broom is borrowed. The starting flashlight and shovel are personal.

After eight accumulated seconds of sweeping, return to the shed.
Look at the return tray within 3 metres and press E.
Any available tool may be equipped during return.

The server validates ownership, finished sweeping and the return location.
Returning removes the broom. If equipped, the flashlight is selected.
Returning earns the assignment's single completed job, never an extra job.

The player's private pickup remains hidden until the next shift.
Disconnect cancellation and new-shift reset clear borrowed equipment,
return status, assignments and the shared count.

### Return checks

- Both players borrow, sweep and return independently.
- Sweeping alone does not increase the shared count.
- Early and wrong-location returns do not complete the assignment.
- Return with broom, flashlight and shovel equipped.
- Repeated E presses do not award duplicate jobs or another broom.
- No return is accepted after the deadline.
- A new shift restores both private pickups and resets the count.

## Visual boundaries

New geometry uses the user's palette:
#5a4937 for broom handle and debris; #786458 for bristles.
The popup map shows graves, paths, shed, gate, both players and assignment.
Map colors use #080c17, #11345e, #475c7d and #786458.
There are no world-space navigation markers or gravestone labels.
No audio or unrelated polish is included.

The broader art-direction changes discussed previously are not
implemented by this milestone.

## Validation checklist

- Two clients receive different site identifiers.
- Both independently collect brooms from the same supply.
- Broom selection appears locally and on the teammate.
- Only the owner can sweep their assigned site.
- Wrong tool, wrong site, obstructed view and excess distance reject work.
- Releasing E, looking away, walking away, changing tools, releasing
  the mouse and losing focus stop progress.
- Resuming preserves earned work.
- Each job increments the shared count exactly once.
- Both clients agree on progress, clean sites and shared count.
- Reaching 2/2 does not end the shift.
- Deadline and disconnect stop work.
- New shift resets assignments, brooms, debris, progress and count.
- M opens/closes the map; Esc closes it and restores the cursor.
- Both player markers move and turn correctly on each client's map.
- The assigned grave ring matches the real sweepable patch.
- A collected pickup disappears only for its player.
- Each player can collect only their own broom once per shift.
- Each player's pickup reappears on a new shift.
- Broom bristles are visible in first person.
- Sweeping animation runs only during valid work and stops on release,
  invalid aim, tool change, completion, deadline or disconnect.

## Validation status

Pending approved implementation and validation.
Local native testing does not establish browser or internet compatibility.
