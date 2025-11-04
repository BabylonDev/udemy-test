extends SpringArm3D
class_name SmoothCameraArm

## A camera arm that smoothly follows a target with frame-rate independent easing
##
## This specialized SpringArm3D provides smooth camera following by interpolating
## its transform toward a target node each physics frame. Uses exponential
## interpolation for frame-rate independent smoothing.
##
## Example Usage:
## ```gdscript
## @onready var camera_arm = $SmoothCameraArm
## camera_arm.target = $PlayerPivot
## camera_arm.decay = 12.0  # Faster following
## ```

## The Node3D to follow. Camera arm stays still if null.
@export var target: Node3D

## Smoothing decay rate. Higher values = faster camera following.
## Typical values range from 5 (very smooth) to 15 (responsive).
@export var decay: float = 10.0

## Updates the camera arm position and rotation
## @param delta: Time elapsed since last frame
func _physics_process(delta: float) -> void:
	if target == null:
		return
		
	# Use exponential interpolation for smooth, frame-rate independent following
	global_transform = global_transform.interpolate_with(
		target.global_transform,
		1.0 - exp(-decay * delta)
	)
