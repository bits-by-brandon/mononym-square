@tool
extends Control

@export var font: Font
@export var text: String = "MONONY"

# Knobs
var font_size := 16
var letter_offset := 3
var grid_size_x := 20.0:
	set(value):
		grid_size_x = value
		grid_size.x = value
var grid_size_y := 20.0:
	set(value):
		grid_size_y = value
		grid_size.y = value
var noise_speed := 30.0
var colors: Gradient = Gradient.new()
@export var start_color := Color(0, 0, 0)
@export var end_color := Color(1, 1, 1)
var start_color_threshold := - 1.0
var end_color_threshold := 1.0
var zoom_x := 1.0:
	set(value):
		zoom.x = value
		zoom_x = value
var zoom_y := 1.0:
	set(value):
		zoom.y = value
		zoom_y = value
var velocity_x := 0.0
var velocity_y := 0.0

# Non exported
var beat_bpm := 120
var beat_curves: Dictionary = {}

var grid_size: Vector2 = Vector2(grid_size_x, grid_size_y)
var zoom := Vector2(zoom_x, zoom_y)
var noise: Noise
var elapsed_time: float = 0.0
var noise_time: float = 0.0
var s_per_beat: float = 60.0 / beat_bpm
var beat_offset: float = 0.0
var offset := Vector2(0, 0)

func _get_property_list():
	var beat_matchable_knobs = [
		&"font_size",
		&"letter_offset",
		&"grid_size_x", &"grid_size_y",
		&"noise_speed",
		# &"start_color", &"end_color",
		&"start_color_threshold", &"end_color_threshold",
		&"zoom_x", &"zoom_y",
		&"velocity_x", &"velocity_y"
	]

	var properties = []
	export_range(properties, &"font_size", 1, 100, 1)
	export_range(properties, &"letter_offset", 1, 100, 1)
	export_range(properties, &"grid_size_x", 1.0, 100.0, 0.01)
	export_range(properties, &"grid_size_y", 1.0, 100.0, 0.01)
	export_range(properties, &"start_color_threshold", -1.0, 1.0, 0.001)
	export_range(properties, &"end_color_threshold", -1.0, 1.0, 0.001)
	export_range(properties, &"font_size", 1, 100, 1)
	export_range(properties, &"zoom_x", 1.0, 100.0, 0.01)
	export_range(properties, &"zoom_y", 1.0, 100.0, 0.01)
	export_range(properties, &"noise_speed", 1, 100, 0.01)
	return properties

func _set(property: StringName, value: Variant):
	if property.ends_with("_beat_curve"):
		beat_curves[property] = value
		return true

	return false

func _get(property: StringName):
	if property.ends_with("_beat_curve"):
		return beat_curves.get(property)

func export_range(properties: Array, prop_name: String, prop_min: float, prop_max: float, step: float=0.01):
	properties.append({
		"name": prop_name.capitalize(),
		"type": TYPE_NIL,
		"hint_string": prop_name,
		"usage": PROPERTY_USAGE_GROUP
	})

	properties.append({
		"name": prop_name,
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "%.2f, %.2f, %.2f" % [prop_min, prop_max, step]
	})

	properties.append({
		"name": "Beat Settings",
		"type": TYPE_NIL,
		"hint_string": prop_name + "_beat",
		"usage": PROPERTY_USAGE_SUBGROUP
	})

	properties.append({
		"name": prop_name + "_beat_curve",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Curve"
	})

func export_color(properties: Array, prop_name: String):
	properties.append({
		"name": prop_name.capitalize(),
		"type": TYPE_NIL,
		"hint_string": prop_name,
		"usage": PROPERTY_USAGE_GROUP
	})

	properties.append({
		"name": prop_name,
		"type": TYPE_COLOR,
		"usage": PROPERTY_USAGE_DEFAULT,
	})

	properties.append({
		"name": "Beat Settings",
		"type": TYPE_NIL,
		"hint_string": prop_name + "_beat",
		"usage": PROPERTY_USAGE_SUBGROUP
	})

	properties.append({
		"name": prop_name + "_beat_curve",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Curve"
	})

func export_colors(properties: Array):
	properties.append({
		"name": "Colors",
		"type": TYPE_NIL,
		"hint_string": "colors_",
		"usage": PROPERTY_USAGE_GROUP
	})

	properties.append({
		"name": "colors",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Gradient"
	})

func _ready():
	noise = FastNoiseLite.new()
	noise.seed = 1

func _process(delta):
	elapsed_time += delta
	noise_time += delta * noise_speed
	beat_offset += delta
	if beat_offset >= s_per_beat:
		beat_offset -= s_per_beat

	offset.x += velocity_x * delta
	offset.y += velocity_y * delta
	queue_redraw()

func _draw():
	var letter_index = 0
	var letter_index_2 = 0
	for y in range(0, size.y, grid_size.y):
		for x in range(0, size.x, grid_size.x):
			var noise_val = noise.get_noise_3d(x * zoom.x + offset.x, y * zoom.y + offset.y, noise_time)
			draw_string(
				font,
				Vector2(x, y),
				text[letter_index % text.length()],
				HORIZONTAL_ALIGNMENT_LEFT,
				- 1,
				font_size,
				start_color.lerp(end_color, remap(noise_val, start_color_threshold, end_color_threshold, 0, 1)),
			)

			letter_index += 1
		letter_index_2 += letter_offset
		letter_index = letter_index_2
