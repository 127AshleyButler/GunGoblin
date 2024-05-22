#hittable_component.gd
## A component for nodes that can be affected by projectiles, explosions, and falling OOBs.
class_name HittableComponent
extends Node

## Called when entity is hit with a damaging projectile
signal hit(damage: float)

## Called when entity is hit with a heart projectile
signal loved()

## Called when entity leaves the level boundaries
signal out_of_bounds()

## Called when entity shuffles off the mortal coil
signal destroyed()

## The health that this entity has. Generally, most things will die in a single hit.
@export var max_health = 1.0 as float

var _health = max_health

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
