@tool
extends Control

@export var font: Font
@export var text: String = "MONONY"

@export_group("Knobs")
@export var font_size := 16
@export_range(0, 10, 1.0) var letter_offset := 3
@export_range(1.0, 1500.0, 0.01) var grid_size_x := 20.0:
	set(value):
		grid_size_x = value
		grid_size.x = value
@export_range(1.0, 1000.0, 0.01) var grid_size_y := 20.0:
	set(value):
		grid_size_y = value
		grid_size.y = value
@export_range(1.0, 200.0, .01) var noise_speed := 30.0
@export var start_color := Color(0, 0, 0)
@export var end_color := Color(1, 1, 1)
@export_range(-1.0, 1.0, 0.01) var start_color_threshold := - 1.0
@export_range(-1.0, 1.0, 0.01) var end_color_threshold := 1.0
@export_range(0.01, 10.0, 0.01) var zoom_x := 1.0:
	set(value):
		zoom.x = value
		zoom_x = value
@export_range(0.01, 10.0, 0.01) var zoom_y := 1.0:
	set(value):
		zoom.y = value
		zoom_y = value
@export_range(-1000.0, 1000.0, 0.01) var velocity_x := 0.0
@export_range(-1000.0, 1000.0, 0.01) var velocity_y := 0.0

@export_group("Beat", "beat_")
@export var beat_bpm := 120

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
		&"start_color", &"end_color",
		&"start_color_threshold", &"end_color_threshold",
		&"zoom_x", &"zoom_y",
		&"velocity_x", &"velocity_y"
	]

	var properties = []
	for knob in beat_matchable_knobs:
		properties.append({
			"name": knob,
			"type": TYPE_NIL,
			"hint_string": "beat_" + knob,
			"usage": PROPERTY_USAGE_SUBGROUP

		})

		properties.append({
			"name": "beat_" + knob + "_curve",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Curve"
		})

	return properties

func _set(property: StringName, value: Variant):
	if property.begins_with("beat_")&&property != &"beat_bpm":
		beat_curves[property] = value
		return true

	return false

func _get(property: StringName):
	if property.begins_with("beat_")&&property != &"beat_bpm":
		return beat_curves.get(property)

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

func get_start_color():
	return start_color

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
