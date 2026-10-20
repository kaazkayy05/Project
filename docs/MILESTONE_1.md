# Milestone 1 — multiplayer foundation

## Scope

Original primitive cemetery: ground, paths, graves, gate, shed and bell.
Relevant solid geometry has collision. All landmarks are scenery.

First-person walking, mouse look, gravity and collision.
Flashlight and shovel at spawn; switching and flashlight toggling.
Visible teammate body and tools; local body hidden from local camera.

Dedicated WebSocket server with two admitted players.
Both players explicitly ready before server starts the shift.
Server simulates movement and owns session state and shared clock.
Clients submit only their own input; server identifies the RPC sender.

Clock begins at 12 AM and reaches 6 AM after 720 real seconds by default.
Server argument --shift-seconds configures testing duration.
At 6 AM movement stops and both players receive the loss state.
No quota, victory, burial animation or jumpscare.

HUD includes time, player count, tool, controls and prototype limitations.
There is no task log because tasks are not implemented.

## Controls

WASD: walk. Mouse: look.
1: flashlight. 2: shovel.
F: toggle equipped flashlight.
Esc: release mouse. Resume button: capture mouse.
Leave session: disconnect and return to the connection menu.

Switching to the shovel hides the beam and preserves its toggle setting.
Movement is disabled while the mouse is released or the window lacks focus.

## Session rules

Two clients connect to a separate server; neither client is the host.
Both click Ready; either can cancel readiness before the second is ready.
Third connections and joins outside the lobby receive rejection messages.

A disconnect during play cancels the shift and resets remaining players
to the lobby with readiness cleared. It is not a gameplay loss.
After the 6 AM loss, both players leave before the server resets.
There is no reconnect, account system, matchmaking or session browser.

Movement snapshots are sent approximately 20 times per second.
There is no client prediction or interpolation in this milestone.
WebSocket reliability can cause visible delays on poor connections.

## Local setup

Use Godot 4.7.2 with GDScript and Compatibility rendering.
Import project.godot through Godot's project manager.

PowerShell, from the project directory:

    $godotExe = 'C:\Users\blueb\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'

Terminal 1, server:

    & $godotExe --headless --path . -- --server --port=9080

Terminal 2, client A:

    & $godotExe --path .

Terminal 3, client B:

    & $godotExe --path .

Each client enters ws://127.0.0.1:9080, connects and clicks Ready.
After the shift starts, click Resume to capture the mouse.
The headless server does not count as a player.

For an explicitly approved short test, restart the empty server with:

    & $godotExe --headless --path . -- --server --port=9080 --shift-seconds=30

Normal duration remains 720 seconds.

## Eventual delivery

A web export serves the client only. A separate publicly reachable Godot
server process is required. An HTTPS deployment should use a wss://
endpoint with a valid certificate, normally through a TLS reverse proxy.
Local ws:// connections do not establish deployed browser compatibility.

No export presets, deployment files, hosting, certificates or dependencies
are included in this milestone. Export templates remain unverified.

Future proximity voice requires separate design and approval.
Do not add microphone permissions or send voice over this gameplay
connection as part of Milestone 1.

## Proposed validation

- Godot import and parse; headless startup.
- Graphical startup and connection error messages.
- One server and two clients: lobby, ready cancellation, shared start.
- Walking, collision, gravity, mouse release and focus behavior.
- Teammate body, facing, equipped tool and flashlight visibility.
- Clock waits in lobby and advances consistently after both are ready.
- Approved 30-second duration: synchronized loss and frozen movement.
- Third-player rejection, mid-shift join rejection and disconnect reset.
- Both players leaving the loss screen resets the server.

Native local tests cannot prove browser or internet multiplayer.
Separate-device and separate-network tests remain required.

## Progress

Initial source proposal only. No implementation or gameplay validation
has been performed. Godot --version reported 4.7.2.stable.official.ed1daf0bf.
Update this section only with approved implementation and actual results.
