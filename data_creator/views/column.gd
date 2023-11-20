##
## Brief description.
##
## Long description.
##
@tool
extends VBoxContainer

const MIN_CELL_HEIGHT := 34
const VECTOR_COMPONENT_LABELS = ["x", "y", "z", "w"]

@onready var header: Label = $Header
@onready var options_box: HBoxContainer = $Options/OptionsBox
@onready var configure_button: Button = $Options/OptionsBox/ConfigureButton

var _data_type: int
var _default_value
var _get_value_callback: Callable
var _get_cell_func: Callable
var _cell_props := {}


###############################################################
####======= Public Functions ==============================####

func set_property(property: Dictionary, data_script: Script) -> void:
	__clear()
	var prop_name: String = property.name
	header.text = prop_name.capitalize()
	header.tooltip_text = header.text
	_data_type = property.type
	_default_value = data_script.get_property_default_value(prop_name)
	var hint: int = property.hint
	var hint_string: String = property.hint_string
	configure_button.hide()	# The button will be shown depending on type and
							# hint.
	match _data_type:
		TYPE_INT, TYPE_FLOAT:
			__set_as_number(hint, hint_string)
			_get_value_callback = __get_number_value
		TYPE_VECTOR2I:
			__set_as_vector2i()
			_get_value_callback = __get_vector2i_value
	add_cell()


func add_cell() -> void:
	var cell: Control = _get_cell_func.call()
	add_child(cell)
	cell.custom_minimum_size.y = MIN_CELL_HEIGHT


###############################################################
####======= Callbacks =====================================####

func _ready() -> void:
	configure_button.icon = EditorInterface.get_editor_theme().get_icon(&"Tools", &"EditorIcons")


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####

func __clear() -> void:
	_cell_props.clear()
	for i in range(2, get_child_count()):
		var node := get_child(i)
		remove_child(node)
		node.queue_free()


func __set_as_number(hint: int, hint_string: String) -> void:
	if hint == PROPERTY_HINT_RANGE:
		__set_range_props(hint_string)
		_get_cell_func = __add_range
	else:
		_get_cell_func = __add_number
	if _default_value == null:
		_default_value = 0


func __set_as_vector2i() -> void:
	__set_vector_props(2)
	if _default_value == null:
		_default_value = Vector2i.ZERO


func __set_range_props(hint_string: String) -> void:
	var parts := hint_string.split(",", false)
	assert(parts.size() >= 2, "Range hint should declare at least min and max values.")
	_cell_props[&"min_value"] = parts[0].to_float()
	_cell_props[&"max_value"] = parts[1].to_float()
	if parts.size() > 2:
		var index := 2
		if parts[2].is_valid_float():
			_cell_props[&"step"] = parts[2].to_float()
			index = 3
		elif _data_type == TYPE_FLOAT:
			_cell_props[&"step"] = 0.01
		for i in range(index, parts.size()):
			var string := parts[i]
			if string == "or_greater":
				_cell_props[&"allow_greater"] = true
			elif string == "or_less":
				_cell_props[&"allow_lesser"] = true
			elif string == "exp":
				_cell_props[&"exp_edit"] = true
			elif string == "hide_slider":
				_cell_props[&"hide_slider"] = true
	elif _data_type == TYPE_FLOAT:
		_cell_props[&"step"] = 0.01
	if _default_value == null:
		_default_value = _cell_props[&"min_value"]


func __set_vector_props(count: int) -> void:
	_cell_props[&"count"] = count
	_get_cell_func = __add_vector
	#for (int i = 0; i < component_count; i++) {
		#spin_sliders[i]->add_theme_color_override("label_color", colors[i]);
	#}
	#static Color c[4];
	#c[0] = get_theme_color(SNAME("property_color_x"), EditorStringName(Editor));
	#c[1] = get_theme_color(SNAME("property_color_y"), EditorStringName(Editor));
	#c[2] = get_theme_color(SNAME("property_color_z"), EditorStringName(Editor));
	#c[3] = get_theme_color(SNAME("property_color_w"), EditorStringName(Editor));


func __add_number() -> Control:
	var cell := EditorSpinSlider.new()
	cell.value = _default_value
	cell.allow_greater = true
	cell.allow_lesser = true
	if _data_type == TYPE_FLOAT:
		cell.step = 0.01
	return cell


func __add_range() -> Control:
	var cell := EditorSpinSlider.new()
	cell.value = _default_value
	cell.max_value = _cell_props[&"max_value"]
	cell.min_value = _cell_props[&"min_value"]
	cell.step = _cell_props.get(&"step", 1.0)
	cell.allow_greater = _cell_props.get(&"allow_greater", false)
	cell.allow_lesser = _cell_props.get(&"allow_lesser", false)
	cell.exp_edit = _cell_props.get(&"exp_edit", false)
	cell.hide_slider = _cell_props.get(&"hide_slider", false)
	return cell


func __add_vector() -> Control:
	var cell := VBoxContainer.new()
	for i in _cell_props[&"count"]:
		var component := EditorSpinSlider.new()
		component.label = VECTOR_COMPONENT_LABELS[i]
		component.hide_slider = true
		cell.add_child(component)
	return cell


func __get_number_value(cell: Control) -> Variant:
	return cell.value


func __get_vector2i_value(cell: Control) -> Variant:
	var value: Vector2i = Vector2i(cell.get_child(0).value, cell.get_child(1).value)
	return value


###############################################################
####======= Signal Callbacks ==============================####


func _on_options_mouse_entered() -> void:
	options_box.show()


func _on_options_mouse_exited() -> void:
	options_box.hide()
