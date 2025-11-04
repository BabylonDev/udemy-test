extends CharacterBody3D

# Player controller for 3D character
#
# Responsibilities:
# - Read player input and convert it to movement (walking/running) and jumping.
# - Control camera rotation via mouse when captured.
# - Trigger animation state changes and attack actions on the rig.
#
# Inputs / expected InputMap actions:
# - move_forward, move_back, move_left, move_right
# - ui_accept (jump), ui_cancel (toggle cursor), click (attack)
#
# Notes:
# - This script keeps logic separate: movement, camera, and animation calls.
# - The `rig` node is expected to provide `update_animation_tree`, `travel`,
#   `is_idle()` and `is_slashing()` methods (see `rig.gd`).

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var mouse_sensitivity := 0.003
var _attack_direction: Vector3 = Vector3.ZERO
const min_boundary: float = -60
const max_boundary: float = 10
const attack_move_speed: float = 2.0

func _ready():
	# Start with the mouse captured for gameplay camera control.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

@onready var horizontal_pivot: Node3D = $HorizontalPivot
@onready var vertical_pivot: Node3D = $HorizontalPivot/VerticalPivot
@onready var rig_pivot: Node3D = $RigPivot
@onready var rig: Node3D = $RigPivot/Rig
@onready var attack_cast : RayCast3D = %AttackCast

func _physics_process(delta: float) -> void:
	# Toggle mouse capture with the cancel action (usually Esc).
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_mouse_mode()

	# Handle jump input (only when on the floor).
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Movement: compute desired direction and update animations.
	var direction := get_movement_direction()
	rig.update_animation_tree(direction)

	if direction:
		# Apply movement speed along local world axes derived from pivots.
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_toward_direction(direction, delta)
	else:
		# Smoothly slow to a stop when no input.
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Allow the rig to process special behavior per-frame.
	handle_idle_physics_frame(delta, direction)
	handle_slashing_physics_frame(delta)

	# Apply gravity when in the air.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

func _input(event: InputEvent) -> void:
	# Only process mouse motion when the mouse is captured by the game.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_process_mouse_motion(event)

	# Allow attacking only when the rig is in the idle locomotion state.
	if rig.is_idle():
		if Input.is_action_just_pressed("click"):
			slash_attack()

func _process_mouse_motion(event: InputEventMouseMotion) -> void:
	# Rotate horizontal pivot around Y (yaw) and vertical pivot around X (pitch).
	horizontal_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
	vertical_pivot.rotate_x(-event.relative.y * mouse_sensitivity)

	# Clamp vertical rotation to avoid flipping the camera.
	vertical_pivot.rotation.x = clampf(
		vertical_pivot.rotation.x,
		deg_to_rad(min_boundary),
		deg_to_rad(max_boundary)
	)

### Toggle Mouse Captured/Visible ###
func toggle_mouse_mode() -> void:
	# Toggle between visible and captured mouse modes.
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Immediately snap the smooth camera arm to the current pivot transform
	# so the camera doesn't jump visibly when toggling capture.
	$SmoothCameraArm.global_transform = vertical_pivot.global_transform
	
func get_movement_direction() -> Vector3:
	# Compute movement direction relative to the horizontal pivot's orientation.
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

func look_toward_direction(direction: Vector3, delta: float) -> void:
	# Smoothly rotate the rig pivot to face the movement direction.
	var target_transform := rig_pivot.global_transform.looking_at(
		rig_pivot.global_position + direction,
		Vector3.UP, true
	)
	rig_pivot.global_transform = rig_pivot.global_transform.interpolate_with(
		target_transform,
		1.0 - exp(-10.0 * delta)
	)

func slash_attack() -> void:
	# Trigger the 'Slash' animation and compute an attack movement direction.
	rig.travel("Slash")
	_attack_direction = get_movement_direction()
	# If there's no input direction, use the rig pivot's forward direction.
	if _attack_direction.is_zero_approx():
		_attack_direction = rig_pivot.transform.basis.z.normalized()
	attack_cast.clear_exceptions()

func handle_slashing_physics_frame(delta: float) -> void:
	# When slashing, move the character slightly in the attack direction.
	if not rig.is_slashing():
		return
	velocity.x = _attack_direction.x * attack_move_speed
	velocity.z = _attack_direction.z * attack_move_speed
	look_toward_direction(_attack_direction, delta)
	attack_cast.deal_damage()

func handle_idle_physics_frame(delta: float, direction: Vector3) -> void:
	# When idle, ensure the character faces the movement direction center smoothly.
	if not rig.is_idle():
		return
	if direction:
		look_toward_direction(direction, delta)
