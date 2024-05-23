#hittable_component.gd
## A component for nodes that can be affected by projectiles, explosions, and falling OOBs.
#class_name HittableComponent
extends Node

## Called when entity is hit with a damaging projectile
signal hurt()

## Called when entity is hit with a heart projectile
signal loved()

## Called when entity leaves the level boundaries
signal out_of_bounds()

## Called when entity shuffles off the mortal coil
signal killed()

## The health that this entity has. Generally, most things will die in a single hit.
@export var max_health = 1.0 as float

var _health = max_health

func hit(damage: float = 1):
	if (damage > 0):
		_health -= damage
		if (_health > 0):
			hurt.emit()
		else:
			killed.emit()
		
func hit_with_love(healing: float = 1):
	if (healing > 0):
		_health = min(_health + healing, max_health)
		loved.emit()
	
