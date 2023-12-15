@tool
extends Node3D

@export var line_radius = 0.1
@export var line_resolution = 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var circle = PackedVector2Array()
	for degree in line_resolution:
		var x = line_radius * sin(PI * 2 * degree / line_resolution)
		var y = line_radius * cos(PI * 2 * degree / line_resolution)
		var coords = Vector2(x, y)
		circle.append(coords)
	$CSGPolygon3D.polygon = circle
