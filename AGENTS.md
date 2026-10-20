# Graveyard Shift — Codex CLI Rules

Graveyard Shift is the working title for my Handshake competition game. This is a Godot project developed using Codex CLI, VS Code, and GitHub. Do not assume it belongs to a class team or reuse ownership assignments from another project.

## 1. Permission Required for All Changes

- NEVER edit, create, delete, rename, move, overwrite, or replace any file without asking for my explicit permission first.
- Before making changes, identify the exact file paths, explain what will change, and explain why.
- Show the proposed edits or diff and wait for my approval before changing anything.
- Approval applies ONLY to the specific files and changes I authorize.
- Do not interpret permission for one change as permission for additional changes.
- Reading and inspecting relevant files is allowed without editing them.
- Never bypass these rules, even for seemingly minor fixes.

## 2. Protect My Work

- Do not modify my existing scripts, scenes, assets, audio, or configurations unless the specific modification is approved.
- Preserve all existing functionality unless I explicitly authorize changing it.
- Do not replace entire scripts when a small targeted edit would work.
- Do not change unrelated code, even within an approved file.
- Never delete functionality because it appears duplicated or unnecessary. Explain the issue and ask first.
- Do not overwrite manual edits or changes from another Codex session.
- If collaborators join, ask me to establish ownership boundaries. Never invent assignments or modify their work without my explicit approval.

## 3. Strict Task Scope

- ONLY work on the exact task I request.
- Do not add extra features, dependencies, assets, UI elements, tests, or systems without permission.
- Do not make unrelated fixes or improvements.
- If you discover another problem, report it without changing it.
- Before proposing a new system, inspect the relevant existing project files for similar functionality. Prefer reusing existing functionality.
- Do not change the startup scene, Autoloads, input mappings, rendering settings, plugins, export presets, or other shared settings without explaining the consequences and obtaining approval.
- Do not install software, run commands that generate or modify project files, or launch tools that rewrite project metadata without approval.
- The game design below is context, not permission to implement every feature.

## 4. Game Design Boundaries

### Core Concept

- A 3D first-person cooperative horror game for two players working a normal cemetery night shift.
- Each player receives randomized tasks from a list: digging graves, replacing flowers, fixing lights, returning tools, sweeping grave sites, and security patrol.
- A creature copies either player's appearance and performs believable work-related actions before trying to lure someone away from their teammate.
- Players decide whether to split up to finish faster or stay together for safety.
- Creatures have different threat levels. Players must assess an encounter and decide whether the creature will run after them.

### Rules and Equipment

- Players share a work quota. Complete enough jobs and return to the gate together to win.
- The shift runs from 12 AM to 6 AM. If the players have not finished and escaped by 6 AM, both are buried and lose.
- Small jobs can be completed alone. Digging requires teamwork: one player digs while the other holds a lantern. Players can swap roles.
- Grave-digging assignments specify coffin size, funeral time, and the designated digging area.
- Each player starts with a flashlight and shovel.
- Other equipment, such as brooms and flowers, becomes available to pick up according to the player's assigned tasks.
- The creature carries an outdated version of the copied player's equipment, providing a clue to its identity.
- The cemetery bell repels the creature and has three shared uses.
- Captured players are buried in a coffin. Their teammate must locate the correct grave and dig them out within an initial rescue window of 45 seconds.
- A buried player can hear sounds above ground and provide location clues.
- Proximity voice chat lets teammates communicate based on distance.
- Players must be able to learn the controls, objectives, and rules from inside the game.

### Creature Threat Levels

- The creature system includes different threat levels that affect whether a creature will chase a player.
- Not every creature encounter should automatically result in a chase.
- Players must observe the creature and judge whether it is likely to run after them.
- Threat assessment should affect the player's decision to continue working, retreat, regroup with their teammate, or use the bell.
- Threat levels must have consistent rules and learnable clues so players can make informed decisions.
- Do not assume threat levels are displayed as labels, numbers, colors, or a HUD meter. Ask before adding any explicit threat indicator.
- The number of levels, their names, identifying clues, chase triggers, movement speeds, and behavior differences have not been finalized.
- Whether a creature can change levels during a shift has not been finalized.
- Whether levels represent different creature variants or different states of the same creature has not been finalized.
- Propose these details and obtain my approval before implementing them.
- Preserve the equipment-copying clue, bell mechanic, and coffin-rescue mechanic unless I explicitly approve changes.
- Do not add additional creature species or simultaneous creatures merely to implement threat levels.

### Unresolved Details

- The initial real-time shift duration is 12 minutes; the initial rescue duration is 45 seconds. Ask before changing either.
- Do not invent mechanics for coffin sizes, funeral deadlines, lantern access, buried-player voice range, creature threat levels, or other unspecified details.
- Propose options and get approval before implementation.
- Do not add combat, extra monsters, additional player roles, or new win/loss conditions without permission.

## 5. Multiplayer and Competition Requirements

- At least two players must be able to join from separate devices and play remotely.
- The finished game must be reachable through a public URL or publicly accessible host.
- Plan for a browser-playable client and dedicated server, using a transport compatible with Godot web exports.
- Check current official Godot documentation before proposing networking or browser voice implementations.
- Keep shared gameplay state server-authoritative, including:
  - Shift clock.
  - Work quota and task completion.
  - Bell charges.
  - Creature threat levels and behavior.
  - Chase targets and chase outcomes.
  - Captures and rescues.
  - Win/loss outcomes.
- Do not change networking architecture, RPC interfaces, authority rules, or synchronization behavior without approval.
- Explain any separate server hosting requirement before implementation or deployment.
- Do not claim localhost or LAN testing proves internet multiplayer works.
- Clearly distinguish implemented, tested, and untested behavior.
- Do not publish, deploy, purchase services, or change hosting configuration without explicit permission.

## 6. Milestone Boundaries

The initial planned milestone contains only:

1. A small placeholder cemetery with a gate, paths, grave markers, tool shed, and bell.
2. First-person movement, mouse look, collision, flashlight toggling, and switching between flashlight and shovel.
3. Visible player bodies and equipped tools without the local body obstructing its camera.
4. A host/join menu and two-player lobby.
5. Synchronized movement and equipped tools.
6. A server-controlled shared shift clock with configurable duration.
7. A HUD showing time, connected player count, controls, and a clickable task log that you can check.
8. A synchronized loss screen at 6 AM. Jumpscare.

- This list defines scope only; obtain approval for specific file changes before implementing it.
- Do not implement tasks, creature AI, creature threat levels, chases, coffin rescues, burial animations, or voice chat until I explicitly request and approve those changes.
- Use simple placeholder geometry and original placeholder visuals until other assets are approved.
- Keep code readable and organized. Do not overengineer the project.
- Read existing progress notes before continuing.
- Creating or updating design and progress documents also requires approval.

## 7. Git and Repository Safety

- Work only inside this game's repository. Do not modify the parent repository or another project.
- Verify the repository root and remote before proposing Git changes.
- Read-only inspection such as git status, git diff, git log, and git remote -v is allowed.
- NEVER create, switch, rename, or delete branches without permission.
- NEVER stage, commit, push, pull, fetch, merge, rebase, reset, restore, stash, or discard changes without permission.
- NEVER resolve merge conflicts automatically or overwrite existing work to resolve them.
- Never stage unrelated files.
- Never change Git remotes, GitHub workflows, deployment files, repository visibility, or repository settings without permission.
- Never use destructive Git commands or force-push without explicit authorization for that exact action.
- Do not place credentials, access tokens, or private keys in project files or commits.

## 8. Required Workflow

For every requested task:

1. Read the request and inspect only relevant files and applicable instructions.
2. Identify the exact files that need modifications, using paths relative to the game repository root.
3. Explain the smallest proposed change and why it is needed.
4. Show the proposed edits or diff, including proposed contents for new files.
5. Identify any commands, validation steps, or Git operations that require approval.
6. Ask for explicit permission and STOP until I respond.
7. Apply exactly the authorized changes after approval.
8. Perform only approved validation. If it reveals another required edit, explain it and ask before changing anything else.
9. Show the final diff and report what changed, what was tested, and what still needs manual testing.
10. Do not perform additional actions without permission.

If the task cannot be completed within the approved scope, STOP and ask before proceeding.

## 9. Final Rule

When uncertain whether something is allowed, DO NOT CHANGE IT. Ask me first.