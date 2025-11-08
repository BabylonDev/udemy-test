extends Node

class_name HealthComponent

signal defeat()
signal health_changed()

var max_health: float
var current_health: float:
    set(value):
        current_health = clamp(value, 0, max_health)
        health_changed.emit()
        if current_health <= 0:
            defeat.emit()
        print("Current Health: %s / %s" % [current_health, max_health])

func update_max_health(new_max_health: float) -> void:
    max_health = new_max_health
    current_health = max_health
    health_changed.emit()

func take_damage(damage: float) -> void:
    current_health -= damage
    current_health = clamp(current_health, 0, max_health)
    health_changed.emit()
    if current_health <= 0:
        defeat.emit()