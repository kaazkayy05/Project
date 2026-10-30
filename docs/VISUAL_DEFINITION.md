# Visual definition

## Intent

Make the first-person view resemble worn VHS / 1980s security-camera footage.
Retain the existing softness and combine it with restrained scanlines,
fine moving grain/static, occasional tracking bands, slight image instability
and subtle horizontal color separation in one pass before the HUD and map.

Apply consistently to environment, characters and first-person tools.
Preserve palette, lighting, camera position, scale and gameplay.

Keep navigation, equipment recognition and task work readable.
Avoid heavy constant distortion, rapid flashing and view-blocking interference.
Do not add audio, camera shake or rotation, timestamps, REC labels,
camera borders or other recording overlays. Instability affects image sampling
only; the camera remains at its existing 1.6-metre eye height.
Preserve world lighting and environment settings; this treatment adds no fog.
Preserve the established palette: #080c17, #5a4937, #475c7d, #11345e,
and very rare #786458. No overall color tint is added.

## Settings

Select Main/VisualDefinition in scenes/main.tscn:

- Effect Enabled: enables or bypasses the treatment.
- Radius At 720p: sample radius, scaled with image height. Default 0.9.
- Strength: blend with the softened image. Default 0.65.
- Scanline Strength: horizontal line shading, 0 disables. Default 0.10.
- Scanline Spacing: line period in reference pixels. Default 3.0.
- Grain Strength: fine monochrome static refreshed at 24 Hz, 0 disables.
  Default 0.025; reduced in near-black areas.
- Tracking Frequency: events per second, 0 disables. Default 0.12
  (about one event every 8.3 seconds, lasting about one second).
- Tracking Strength: narrow band shading, noise and displacement,
  0 disables the band. Default 0.12.
- Instability: slight horizontal drift/waviness in reference pixels,
  0 disables. Default 0.35.
- Color Separation: horizontal red/blue sample offsets in reference pixels,
  blended at half strength; most visible at high-contrast edges.
  0 disables. Default 0.65.

Reference pixels scale with image height relative to 720p. Grain remains
fine at actual screen-pixel resolution. Scanlines fade at very small sizes
to reduce aliasing. Set Strength or Radius At 720p to 0 to disable softness
without disabling other effects. Set all new effect strengths to 0 for
the previous softness-only appearance. Effect Enabled bypasses everything.

Defaults are starting settings requiring visual review.
Changing geometry, materials, lighting or assets requires separate approval.

## Comparison

Run from Godot to use the Remote Inspector for live tuning.
While controlling the player with the mouse captured, press V to toggle
original/full recorded-footage treatment, including softness.
The console reports which appearance is active.

Stand still and stop mouse movement before toggling.
Keep the same equipped tool, flashlight state and window size.
Do not sweep during the comparison; its animation changes the image.

Compare:
- Nearby grave-marker edges and shed surfaces.
- Distant graves and teammate silhouette.
- Flashlight-lit ground and object boundaries.
- Flashlight, shovel and complete broom shape.
- Small sweeping debris and task readability.
- HUD, prompts, progress and map text remaining sharp.

Test at 1280x720, 1920x1080 and while resizing the window.
Observe for at least 20 seconds to see multiple tracking events.
Check dark areas and flashlight-lit surfaces as well as nearby/distant objects.
Check collection, sweeping, progress, clock, menus and map with two clients.

For live tuning, run from the Godot editor, release the mouse with Esc,
switch the Scene dock to Remote and select Main/VisualDefinition.
Adjust the exported controls in the Inspector, then Resume gameplay.
Change one control at a time. Start with scanlines and grain; keep tracking,
instability and color separation restrained. Compare frame time/FPS with V
at the same position with one client and then two clients running.
Remote Inspector changes last only for that run. To retain chosen values,
stop the game, select VisualDefinition in the Local scene tree, set the same
values and save scenes/main.tscn yourself.

## Limits

Current assets are untextured primitive geometry.
The filter reduces image definition; it does not redesign silhouettes
or add realistic surface detail.

The effect uses Compatibility-compatible canvas screen sampling.
It retains one screen copy and the nine-sample softness filter, adding two
texture samples when color separation is enabled. Other effects use arithmetic.
The existing headless-server bypass is preserved.
Browser appearance and performance require an actual web-export test.

## Validation status

Implemented the approved recorded-footage treatment and controls on 2026-10-29.
Godot 4.7.2 headless editor initialization/parse completed successfully on an
unsandboxed rerun. The initial sandboxed run reported certificate-store access
and editor-settings save errors; the rerun did not report those errors.
Two graphical clients started with Compatibility rendering on Intel Iris Xe
at requested sizes 1280x720 and 1920x1080. Startup logs reported no shader
compilation errors. A local server started with the unchanged 720-second shift.

Computer-use access to the Godot game window was rejected by automatic approval
review. The captured image did not show the game, so no visual result is claimed.
Logs collected at shutdown showed two admitted players, a started shift,
a broom borrowed and returned with shared count 1, and original/enabled toggle
messages. These are log observations, not automated interaction or visual tests.
Visual V comparison, individual settings, tracking motion, different-size
appearance, readability and frame-time/FPS comparisons remain untested and
require in-game review. Browser rendering/performance and internet
multiplayer also remain untested. Headless checks do not establish visual quality.
