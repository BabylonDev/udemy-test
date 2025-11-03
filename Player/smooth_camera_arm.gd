extends SpringArm3D

# Smooth camera arm helper
#
# This SpringArm3D node smoothly follows a target Node3D by interpolating
# its global transform toward the target's global transform each physics frame.
#
# Exports:
# - target: the Node3D to follow. If null, the arm does nothing.
# - decay: smoothing factor (higher = faster following). Typical values ~ 5-15.

@export var target: Node3D
@export var decay: float = 10.0

func _physics_process(delta: float) -> void:
	# Safety: if no target is assigned, skip to avoid null dereference.
	if target == null:
		return

	# Interpolate this SpringArm's global transform toward the target's.
	# We compute an interpolation alpha as: 1 - exp(-decay * delta)
	# This produces smooth, frame-rate-independent easing controlled by `decay`.
	global_transform = global_transform.interpolate_with(
		target.global_transform,
		1.0 - exp(-decay * delta)
	)
