extends RayCast3D
class_name AttackRayCast

## A specialized RayCast3D for handling melee attack collision detection
##
## This raycast is used to detect hits during melee attacks and manages
## a list of already-hit targets to prevent multiple hits in one swing.
## Must be properly positioned and oriented in the scene to match the
## weapon's strike arc.

## Processes a hit attempt during an attack animation
## Automatically manages hit exceptions to prevent multiple hits on the same target
## Prints the collider for debugging (TODO: implement actual damage system)
func deal_damage() -> void:
	if not is_colliding():
		return
	var collider = get_collider()
	print(collider)  # Debug print, replace with actual damage system
	add_exception(collider)  # Prevent multiple hits on the same target