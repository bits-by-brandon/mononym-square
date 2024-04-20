@tool
extends Control

@export var font: Font
@export var font_size := 16
@export var text: String = "MONONY"
@export_range(0, 10, 1.0) var letter_offset := 3
@export_range(1.0, 40.0, 1.0) var grid_size_x := 20.0:
	set(value):
		grid_size_x = value
		grid_size.x = value
@export_range(1.0, 40.0, 1.0) var grid_size_y := 20.0:
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

var grid_size: Vector2 = Vector2(grid_size_x, grid_size_y)
var zoom := Vector2(zoom_x, zoom_y)
var noise: Noise
var elapsed_time: float = 0.0
var offset := Vector2(0, 0)

func _ready():
	noise = FastNoiseLite.new()
	noise.seed = 1

func _process(delta):
	elapsed_time += delta * noise_speed
	offset.x += velocity_x * delta
	offset.y += velocity_y * delta
	queue_redraw()

func _draw():
	var letter_index = 0
	var letter_index_2 = 0
	for y in range(0, size.y, grid_size.y):
		for x in range(0, size.x, grid_size.x):
			var noise_val = noise.get_noise_3d(x * zoom.x + offset.x, y * zoom.y + offset.y, elapsed_time)
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
