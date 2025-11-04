extends Node3D
class_name CharacterRig

## Animation controller for the character model
##
## Manages the character's animation state machine, providing a clean API
## for transitioning between animations and blending movement states.
## Uses an AnimationTree for state management and smooth blending.
##
## Required nodes:
## - AnimationTree: Must have a state machine with "MoveSpace" and "Slash" states
##
## Example Usage:
## ```gdscript
## # Update movement state
## rig.update_animation_tree(movement_direction)
## 
## # Trigger attack
## if rig.is_idle():
##     rig.travel("Slash")
## ```

## Reference to the AnimationTree node controlling character animations
@onready var animation_tree: AnimationTree = $AnimationTree

## State machine playback controller for managing animation states
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var skeleton_3d: Skeleton3D = $CharacterRig/GameRig/Skeleton3D
@onready var villager_01: MeshInstance3D = $CharacterRig/GameRig/Skeleton3D/Villager_01
@onready var villager_02: MeshInstance3D = $CharacterRig/GameRig/Skeleton3D/Villager_02
@onready var villager_meshes: Array[MeshInstance3D] = [villager_01, villager_02]

## Speed at which animations blend between states
const animation_speed: float = 10.0

## AnimationTree parameter path for movement blend position
const run_path: String = "parameters/MoveSpace/blend_position"

## Current target weight for run/idle blending (-1.0 = idle, 1.0 = running)
var run_weight_target: float = -1.0

## Updates animation blending weights each physics frame
## @param delta: Time elapsed since last frame
func _physics_process(delta: float) -> void:
	animation_tree[run_path] = move_toward(
		animation_tree[run_path],
		run_weight_target,
		animation_speed * delta
	)

## Updates the animation state based on movement direction
## @param direction: Current movement direction vector
func update_animation_tree(direction: Vector3) -> void:
	run_weight_target = -1.0 if direction.is_zero_approx() else 1.0

## Requests a transition to a specific animation state
## @param animation_name: Name of the state to transition to (e.g. "Slash")
func travel(animation_name: String) -> void:
	playback.travel(animation_name)

## Checks if the character is in the idle/movement state
## @return bool: True if in "MoveSpace" state, false otherwise
func is_idle() -> bool:
	return playback.get_current_node() == "MoveSpace"

## Checks if the character is currently performing a slash attack
## @return bool: True if in "Slash" state, false otherwise
func is_slashing() -> bool:
	return playback.get_current_node() == "Slash"

func set_active_mesh(active_mesh: MeshInstance3D) -> void:
	for mesh in skeleton_3d.get_children():
		mesh.visible = false
	active_mesh.visible = true