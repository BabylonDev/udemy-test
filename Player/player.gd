extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var mouse_sensitivity := 0.003
var _attack_direction: Vector3 = Vector3.ZERO
const min_boundary: float = -60
const max_boundary: float = 10
const attack_move_speed: float = 8.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

@onready var horizontal_pivot: Node3D = $HorizontalPivot
@onready var vertical_pivot: Node3D = $HorizontalPivot/VerticalPivot
@onready var rig_pivot: Node3D = $RigPivot
@onready var rig: Node3D = $RigPivot/Rig

func _physics_process(delta: float) -> void:
	# Pressing the escape key toggles mouse mode.
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_mouse_mode()

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle movement.
	var direction := get_movement_direction()
	rig.update_animation_tree(direction)

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_toward_direction(direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	handle_slashing_physics_frame(delta)
	move_and_slide()

func _input(event: InputEvent) -> void:
	# Process mouse motion only when mouse is captured (gameplay camera control).
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_process_mouse_motion(event)
	if rig.is_idle():
		if Input.is_action_just_pressed("click"):
			slash_attack()

func _process_mouse_motion(event: InputEventMouseMotion) -> void:
	# Apply raw rotation from mouse relative movement and clamp vertical rotation.
	horizontal_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
	vertical_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
	vertical_pivot.rotation.x = clampf(vertical_pivot.rotation.x,
		deg_to_rad(min_boundary),
		deg_to_rad(max_boundary))

### Toggle Mouse Captured/Visible ###
func toggle_mouse_mode() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	$SmoothCameraArm.global_transform = vertical_pivot.global_transform
	
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

func look_toward_direction(direction: Vector3, delta: float) -> void:
	var target_transform := rig_pivot.global_transform.looking_at(
		rig_pivot.global_position + direction,
		Vector3.UP, true
	)
	rig_pivot.global_transform = rig_pivot.global_transform.interpolate_with(
		target_transform,
		1.0 - exp(-10.0 * delta)
	)

func slash_attack() -> void:
	rig.travel("Slash")
	_attack_direction = get_movement_direction()
	if _attack_direction.is_zero_approx():
		_attack_direction = -rig_pivot.transform.basis.z.normalized()

func handle_slashing_physics_frame(delta: float) -> void:
	print(rig.is_slashing())
	if not rig.is_slashing():
		return
	velocity.x = _attack_direction.x * attack_move_speed
	velocity.z = _attack_direction.z * attack_move_speed
	look_toward_direction(_attack_direction, delta)