##
## .
##
## .
##
@tool
extends Node

signal data_script_changed
signal type_changed

enum {DATA_SINGLE, DATA_DICTIONARY, DATA_ARRAY}

@export var use_categories := false:
	set(value):
		use_categories = value
		notify_property_list_changed()
@export_enum("Single", "Dictionary", "Array") var type: int = DATA_SINGLE:
	set(value):
		type = value
		type_changed.emit()

var data_script: Script:
	set(script):
		data_script = script
		for n in get_children():
			n.data_script = data_script
		for item in _items:
			item.data_script = data_script
		notify_property_list_changed()
		data_script_changed.emit()

var _DATA_RES: GDScript = preload("res://addons/true_data/data_creator/data_resource.gd")
var _items := Array([], TYPE_OBJECT, &"Resource", _DATA_RES)

###############################################################
####======= Public Functions ==============================####


###############################################################
####======= Callbacks =====================================####

func _ready() -> void:
	if data_script:
		for n in get_children():
			n.data_script = data_script


func _exit_tree() -> void:
	if __is_root():
		pass


func _set(property: StringName, value: Variant) -> bool:
	if property == &"data_script":
		data_script = value
		return true
	elif property == &"items":
		_items = value
		var changed := false
		for i in _items.size():
			var item = _items[i]
			if not item or item.script != _DATA_RES:
				item = _DATA_RES.new()
				item.data_script = data_script
				_items[i] = item
				changed = true
		if changed:
			notify_property_list_changed()
		return true
	return false


func _get(property: StringName) -> Variant:
	if property == &"data_script":
		return data_script
	elif property == &"items":
		return _items
	return null


func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	if __is_root():
		props.push_back({
			name = "data_script",
			type = TYPE_OBJECT,
			usage = PROPERTY_USAGE_DEFAULT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "Script"
		})
	if data_script:
		if use_categories:
			props.push_back({
				name = "new_category",
				type = TYPE_BOOL
			})
		else:
			props.push_back({
				name = "items",
				type = TYPE_ARRAY,
				usage = PROPERTY_USAGE_DEFAULT,
				hint = PROPERTY_HINT_ARRAY_TYPE,
				hint_string = "Resource"
			})
	return props


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####

func __create_new_category() -> void:
	var category: Node = get_script().new()
	add_child(category)
	category.name = "NewCategory"
	category.owner = owner
	category.data_script = data_script


func __is_root() -> bool:
	return get_parent().get_script() != get_script()


func __save(path: String) -> void:
	print("Saving...")
	if use_categories:
		var data_path := path + name.to_snake_case() + "/"
		if not DirAccess.dir_exists_absolute(data_path):
			DirAccess.make_dir_absolute(data_path)
		for c in get_children():
			c.__save(data_path)
	else:
		var file_path := path + name.to_snake_case() + ".txt"


###############################################################
####======= Signal Callbacks ==============================####
