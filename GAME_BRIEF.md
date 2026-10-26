# Wasteland Arcade: Game Brief (working title)

A post-apocalyptic 3D hub world. The player explores a ruined city square, and each "zone" is a ruined, remixed version of a classic casual game mechanic. Built in Summer Engine (Godot 4 compatible) and driven through the Summer Engine MCP tools.

## Rules for the agent
- Use the Summer Engine MCP tools to create scenes, attach scripts, and run the game to check your own work after every meaningful change.
- GDScript only. Keep each system in its own scene and script so zones can be built and tested in isolation.
- Use placeholder primitives (boxes, capsules, cylinders) with simple materials first. Art comes later. Never block gameplay work on art.
- Original names, characters and art only. Do not use names, logos, characters or signature art from existing games (Subway Surfers, Temple Run, Snake/Nokia, Angry Birds, Flappy Bird, etc.). We remix mechanics, not brands.
- Target renderer: Forward+ for desktop. Aim for 60 fps at 1080p.

## Hardware target
Dev machine: laptop with NVIDIA GTX 1650 Ti Max-Q (4 GB VRAM), Intel i7-10750H, 16 GB RAM. Build for this machine:
- Do not use SDFGI or VoxelGI. Use baked lighting (LightmapGI) plus one directional light for dusk.
- Shadows: directional shadows only, medium quality, limited distance. Keep omni and spot lights few and mostly shadowless.
- Fog: use basic depth fog. Volumetric fog only in small, contained areas if at all.
- Get the toxic glow from emissive materials and Glow in the WorldEnvironment, not from many real lights.
- Keep textures at 1K or 2K max, and total VRAM use well under 4 GB.
- Use object pooling for spawned obstacles and pickups, and LOD or visibility ranges for distant props.
- If fps drops below 60, profile first and report the cause before adding new features.
- After finishing a task, summarise what changed and what to test, then stop and wait.

## Visual direction
Gritty but stylised realism: rust, broken concrete, overgrown vines, toxic green glow, dust and fog. Moody dusk lighting. Readable silhouettes over photoreal detail.

## Project structure
- `scenes/hub/` hub world
- `scenes/zones/<zone_name>/` one folder per zone
- `scenes/player/` hub player controller
- `scripts/autoload/GameState.gd` global state (scrap currency, zone unlocks, high scores)
- `scenes/ui/` HUD, pause menu, zone results screen

## Phase 1 scope (build this now)

### 1. Hub: "The Junction"
- Small ruined city square, about 60 x 60 m, walled in by wrecked buses and rubble so the player cannot leave.
- Third-person player controller: walk, sprint, jump, mouse orbit camera.
- Two zone portals: rusted doorways with a glowing sign and a prompt "Press E to enter".
- Entering a portal loads the zone scene. Finishing or quitting a zone returns the player to the hub in front of that portal.
- GameState autoload stores scrap (currency) and best score per zone, saved to `user://save.json`.

### 2. Zone A: "The Toxic Coil" (snake mechanic, ridden in 3D)
- Setting: a ruined playground at dusk (rusted slides, broken swings, a cracked play court, toxic puddles), about 60 x 60 m, walled in by fences and rubble. The player arrives on foot and walks around freely with the same third-person controller as the hub.
- The grid arena is the cracked play court in the middle: 18 x 18 cells, 2 m per cell. Rocks and low maze walls (fence panels, rubble) sit on grid cells as fixed obstacles.
- A giant mutant sludge serpent lies coiled and breathing at the edge of the court. Walk up to its head to get the prompt "Press E to ride".
- Riding: the player climbs onto the serpent's head, and the serpent moves on the grid like the classic game. The camera chases the head from above and behind, always facing map north, so the arrow keys and WASD steer in absolute map directions.
- A classic top-down 2D grid map of the court is shown in a panel at the side of the screen while riding: walls, rocks, canisters and the serpent's body.
- Eating canisters grows the serpent by one segment and adds score. Speed increases every 5 canisters.
- Death on hitting the court edge, rocks, maze walls or its own body. The serpent collapses and the rider is thrown off onto the ground.
- Results screen: score, best score, scrap earned (score / 10), Retry (remount at the start), Walk Around (close the results and explore on foot), Return to Hub.
- Esc while riding opens the pause menu (Resume, Return to Hub). On foot, Esc frees the cursor as in the hub.

### 3. Zone B: "Derailed Metro" (3-lane endless runner)
- Abandoned flooded subway tunnel, behind-the-player camera.
- 3 lanes. Swipe or arrow keys: left, right, jump, slide.
- Obstacles: derailed train cars (switch lane), fallen beams (slide), debris piles (jump).
- Track chunks spawn ahead and despawn behind (object pooling). Speed ramps up over time.
- Collect scrap bolts along the lanes. Same results screen flow as Zone A.

### Definition of done for Phase 1
- Walk around the hub, enter both zones, play, die, see results, return to hub.
- Scrap and best scores persist after closing and reopening the game.
- Steady 60 fps in all three scenes on the dev machine.

## Later phases (do not build yet)
- Phase 2: "Smokestack Glide" (flappy mechanic), "Bunker Breaker" (brick breaker), "Fossil Run" (2D side runner).
- Phase 3: "Scrapshot" (slingshot physics), "Highway Crossing" (lane crossing), "Overgrown Ruins Path" (turning-path runner).
- Phase 4: real art pass, audio, hub unlock progression, export.
