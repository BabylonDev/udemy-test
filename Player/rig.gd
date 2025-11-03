extends Node3D

# Animation rig helper
#
# Responsible for controlling the project's AnimationTree and providing a
# small API used by the player controller to update movement blending and
# trigger state machine transitions (e.g. attack animations).
#
# Public API:
# - update_animation_tree(direction: Vector3): set the desired run/idle target
# - travel(animation_name: String): request a state machine transition
# - is_idle() / is_slashing(): convenience checks for current state

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

const animation_speed: float = 10.0
const run_path: String = "parameters/MoveSpace/blend_position"
var run_weight_target: float = -1.0

func _physics_process(delta: float) -> void:
	# Smoothly animate the 'MoveSpace' blend_position toward run_weight_target.
	# This creates a smoothed transition between idle and running states.
	animation_tree[run_path] = move_toward(
		animation_tree[run_path],
		run_weight_target,
		animation_speed * delta
	)

func update_animation_tree(direction: Vector3) -> void:
	# Called by the player each frame with a movement direction vector.
	# If there's no meaningful input, target idle (-1.0). Otherwise, target run (1.0).
	if direction.is_zero_approx():
		run_weight_target = -1.0
	else:
		run_weight_target = 1.0

func travel(animation_name: String) -> void:
	# Trigger a state machine transition by name (e.g. "Slash").
	playback.travel(animation_name)

func is_idle() -> bool:
	# True when the state machine is in the MoveSpace node (default locomotion).
	return playback.get_current_node() == "MoveSpace"

func is_slashing() -> bool:
	# True when the state machine is in the Slash node (attack animation).
	return playback.get_current_node() == "Slash"