extends CharacterBody3D

# Player controller for 3D character with movement, camera control, and combat.
#
# This script handles all player interactions including movement, jumping, camera
# control via mouse input, and combat actions. It works with an animation rig
# to provide smooth character movement and attack animations.
#
# Required nodes (must be set in scene):
# - HorizontalPivot: Node3D for yaw rotation
# - HorizontalPivot/VerticalPivot: Node3D for pitch rotation
# - RigPivot: Node3D for character model rotation
# - RigPivot/Rig: Character model with animation tree support
# - SmoothCameraArm: SpringArm3D for camera following
#
# Required input actions:
# - move_forward, move_back, move_left, move_right: Character movement
# - ui_accept: Jump action
# - ui_cancel: Toggle mouse capture
# - click: Trigger attack
#
# @desc Controls player character movement, camera, and combat actions
class_name Player

## Walking speed in units per second
const SPEED = 5.0

## Initial upward velocity when jumping
const JUMP_VELOCITY = 4.5

## Mouse look sensitivity (lower = less sensitive)
var mouse_sensitivity := 0.003

## Current attack direction, used during slash animation
var _attack_direction: Vector3 = Vector3.ZERO

## Minimum vertical camera angle in degrees (looking down)
const min_boundary: float = -60

## Maximum vertical camera angle in degrees (looking up)
const max_boundary: float = 10

## Movement speed during attack animation
const attack_move_speed: float = 2.0

## Node reference for horizontal (yaw) camera control
@onready var horizontal_pivot: Node3D = $HorizontalPivot

## Node reference for vertical (pitch) camera control
@onready var vertical_pivot: Node3D = $HorizontalPivot/VerticalPivot

## Node reference for character model rotation
@onready var rig_pivot: Node3D = $RigPivot

## Node reference to character model and animation controller
@onready var rig: Node3D = $RigPivot/Rig
@onready var attack_cast : RayCast3D = %AttackCast

## Initializes mouse capture for gameplay
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Handles physics-based movement, jumping, and combat state updates
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_mouse_mode()

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var direction := get_movement_direction()
	rig.update_animation_tree(direction)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_toward_direction(direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	handle_idle_physics_frame(delta, direction)
	handle_slashing_physics_frame(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

## Handles input events for mouse look and combat actions
## @param event: The input event to process
func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_process_mouse_motion(event)

	if rig.is_idle() and Input.is_action_just_pressed("click"):
		slash_attack()

## Updates camera rotation based on mouse movement
## @param event: The mouse motion event to process
func _process_mouse_motion(event: InputEventMouseMotion) -> void:
	horizontal_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
	vertical_pivot.rotate_x(-event.relative.y * mouse_sensitivity)

	vertical_pivot.rotation.x = clampf(
		vertical_pivot.rotation.x,
		deg_to_rad(min_boundary),
		deg_to_rad(max_boundary)
	)

## Toggles between visible and captured mouse modes
## Snaps the camera smoothly when toggling to prevent jarring transitions
func toggle_mouse_mode() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	$SmoothCameraArm.global_transform = vertical_pivot.global_transform

## Calculates movement direction based on input and camera orientation
## @return Vector3: Normalized direction vector in world space
func get_movement_direction() -> Vector3:
	var direction := Vector3.ZERO
	var forward := -horizontal_pivot.transform.basis.z.normalized()
	var right := horizontal_pivot.transform.basis.x.normalized()

	if Input.is_action_pressed("move_forward"):
		direction += forward
	if Input.is_action_pressed("move_back"):
		direction -= forward
	if Input.is_action_pressed("move_right"):
		direction += right
	if Input.is_action_pressed("move_left"):
		direction -= right
	return direction.normalized()

## Smoothly rotates the character model to face the movement direction
## @param direction: The target direction to face
## @param delta: Time elapsed since last frame
func look_toward_direction(direction: Vector3, delta: float) -> void:
	var target_transform := rig_pivot.global_transform.looking_at(
		rig_pivot.global_position + direction,
		Vector3.UP, true
	)
	rig_pivot.global_transform = rig_pivot.global_transform.interpolate_with(
		target_transform,
		1.0 - exp(-10.0 * delta)
	)

## Initiates a slash attack animation and sets up attack direction
func slash_attack() -> void:
	rig.travel("Slash")
	_attack_direction = get_movement_direction()
	if _attack_direction.is_zero_approx():
		_attack_direction = rig_pivot.transform.basis.z.normalized()
	attack_cast.clear_exceptions()

## Updates character state during slash attack animation
## Handles movement and damage dealing during attack
## @param delta: Time elapsed since last frame
func handle_slashing_physics_frame(delta: float) -> void:
	if not rig.is_slashing():
		return
	velocity.x = _attack_direction.x * attack_move_speed
	velocity.z = _attack_direction.z * attack_move_speed
	look_toward_direction(_attack_direction, delta)
	attack_cast.deal_damage()

## Updates character state during idle animation
## Handles smooth rotation to face movement direction
## @param delta: Time elapsed since last frame
## @param direction: Current movement direction
func handle_idle_physics_frame(delta: float, direction: Vector3) -> void:
	if not rig.is_idle():
		return
	if direction:
		look_toward_direction(direction, delta)
