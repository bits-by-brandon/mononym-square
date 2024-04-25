@tool
extends Control

@export var font: FontVariation
@export var text: String = "MONONY"
# Knobs
var font_size := 16
var letter_offset := 3
var grid_size_x := 20.0
var grid_size_y := 20.0
var noise_speed := 30.0
var colors: Gradient = Gradient.new()
var zoom_x := 1.0
var zoom_y := 1.0
var velocity_x := 0.0
var velocity_y := 0.0

# Non exported
var text_server = TextServerManager.get_primary_interface()
var WEIGHT_KEY = text_server.name_to_tag("wght")
var WIDTH_KEY = text_server.name_to_tag("wdth")

var beat_bpm := 120
var beat_curves: Dictionary = {}
var beat_lengths: Dictionary = {}

var noise: Noise
var elapsed_time: float = 0.0
var noise_time: float = 0.0
var s_per_beat: float = 60.0 / beat_bpm
var beat_offset: float = 0.0
var beat_ratio: float = 0.0
var offset := Vector2(0, 0)

func _get_property_list():
	var properties = []
	export_range(properties, &"font_size", 1, 100, 1)
	export_range(properties, &"letter_offset", 0, 10, 1)
	export_range(properties, &"grid_size_x", 10.0, 300.0, 0.01, true)
	export_range(properties, &"grid_size_y", 10.0, 300.0, 0.01, true)
	export_colors(properties)
	export_range(properties, &"zoom_x", 0.01, 10.0, 0.01, true)
	export_range(properties, &"zoom_y", 0.01, 10.0, 0.01, true)
	export_range(properties, &"noise_speed", 1.0, 200.0, .01)
	export_range(properties, &"velocity_x", -100.0, 100.0, 0.01)
	export_range(properties, &"velocity_y", -100.0, 100.0, 0.01)

	properties.append({
		"name": "font_width",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "100, 300, 1"
	})
	properties.append({
		"name": "font_weight",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "50, 900, 1"
	})
	return properties

func _set(property: StringName, value: Variant):
	if property.ends_with("_beat_curve"):
		beat_curves[property] = value
		return true

	if property.ends_with("_beat_length"):
		beat_lengths[property] = value
		return true

	if property == "font_width":
		font.variation_opentype = {
			WIDTH_KEY: value,
			WEIGHT_KEY: font.variation_opentype[WEIGHT_KEY]
		}
		return true

	if property == "font_weight":
		font.variation_opentype = {
			WIDTH_KEY: font.variation_opentype[WIDTH_KEY],
			WEIGHT_KEY: value,
		}
		return true

	return false

func _get(property: StringName):
	if property.ends_with("_beat_curve"):
		return beat_curves.get(property)
	if property.ends_with("_beat_length"):
		return beat_lengths.get(property)
	if property == &"font_width":
		return font.variation_opentype[WIDTH_KEY]
	if property == &"font_weight":
		return font.variation_opentype[WEIGHT_KEY]

func synced_value(prop: StringName):
	var curve = beat_curves.get(prop + "_beat_curve")
	if curve == null:
		return self[prop]
	else:
		return curve.sample_baked(beat_ratio) * self[prop]

func export_range(properties: Array, prop_name: String, prop_min: float, prop_max: float, step: float=0.01, exp: bool=false):
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
		"hint_string": "%.2f, %.2f, %.2f" % [prop_min, prop_max, step] + (", exp" if exp else "")
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

	properties.append({
		"name": prop_name + "_beat_length",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
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
	if font == null:
		return

	elapsed_time += delta
	noise_time += delta * noise_speed
	beat_offset += delta
	if beat_offset >= s_per_beat:
		beat_offset -= s_per_beat
	beat_ratio = beat_offset / s_per_beat

	offset.x += synced_value(&"velocity_x") * delta
	offset.y += synced_value(&"velocity_y") * delta
	queue_redraw()

func _draw():
	var letter_index = 0
	var letter_index_2 = 0
	var y := 0.0
	var x := 0.0

	while y < size.y:
		x = 0.0
		while x < size.x:
			var noise_val = noise.get_noise_3d(
				x * synced_value(&"zoom_x") + offset.x,
				y * synced_value(&"zoom_y") + offset.y, noise_time
			)
			var i := int(letter_index % text.length())
			var letter := text[i]
			var unicode := text.unicode_at(i)
			var synced_font_size := synced_value(&"font_size") as int
			var char_size := font.get_char_size(unicode, synced_font_size)
			draw_char(
				font,
				Vector2(x - char_size.x / 2, y + char_size.y / 2),
				letter,
				synced_font_size,
				colors.sample(remap(noise_val, -1, 1, 0, 1))
			)

			letter_index += 1
			x += grid_size_x

		letter_index_2 += letter_offset
		letter_index = letter_index_2
		y += grid_size_y
