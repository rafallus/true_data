@tool
extends HBoxContainer

##
## .
##
## .
##

signal script_pressed(type: Node)
signal edit_pressed(type: Node)
signal delete_pressed(type: Node)

@onready var name_line: LineEdit = $Name
@onready var script_button: Button = $ScriptBox/Script
@onready var script_remove: Button = $ScriptBox/RemoveScript
@onready var type_options: OptionButton = $Type
@onready var ncategories: Label = $NCategories

var _type: Node

###############################################################
####======= Public Functions ==============================####

func set_type(type: Node) -> void:
	if _type:
		_type.data_script_changed.disconnect(_on_type_data_script_changed)
		_type.type_changed.disconnect(_on_type_changed)
		_type.child_entered_tree.disconnect(_on_type_child_entered_tree)
		_type.child_exiting_tree.disconnect(_on_type_child_exiting_tree)
		_type.renamed.disconnect(_on_type_renamed)
	_type = type
	name_line.text = _type.name
	ncategories.text = str(_type.get_child_count())
	type_options.selected = _type.type
	__set_type_script_button()
	ERR.CONN(_type.data_script_changed, _on_type_data_script_changed)
	ERR.CONN(_type.type_changed, _on_type_changed)
	ERR.CONN(_type.child_entered_tree, _on_type_child_entered_tree)
	ERR.CONN(_type.child_exiting_tree, _on_type_child_exiting_tree, CONNECT_DEFERRED)
	ERR.CONN(_type.renamed, _on_type_renamed)


###############################################################
####======= Callbacks =====================================####

func _ready() -> void:
	script_remove.icon = EditorInterface.get_editor_theme().get_icon(&"Clear", &"EditorIcons")
	$Edit.icon = EditorInterface.get_editor_theme().get_icon(&"Edit", &"EditorIcons")
	$Delete.icon = EditorInterface.get_editor_theme().get_icon(&"Remove", &"EditorIcons")


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####

func __set_type_script_button() -> void:
	if _type.data_script:
		script_button.text = _type.data_script.resource_path.get_file().get_basename()
		script_remove.disabled = false
	else:
		script_button.text = "..."
		script_remove.disabled = true


###############################################################
####======= Signal Callbacks ==============================####

func _on_type_data_script_changed() -> void:
	__set_type_script_button()


func _on_type_changed() -> void:
	type_options.select(_type.type)


func _on_type_child_entered_tree(_node: Node) -> void:
	ncategories.text = str(_type.get_child_count())


func _on_type_child_exiting_tree(_node: Node) -> void:
	if _type.is_inside_tree():
		ncategories.text = str(_type.get_child_count())


func _on_type_renamed() -> void:
	name_line.text = _type.name


func _on_remove_script_pressed() -> void:
	_type.data_script = null


func _on_type_item_selected(index: int) -> void:
	_type.type = index


func _on_script_pressed() -> void:
	script_pressed.emit(_type)


func _on_edit_pressed() -> void:
	edit_pressed.emit(_type)


func _on_delete_pressed() -> void:
	delete_pressed.emit(_type)


func _on_name_text_submitted(new_text: String) -> void:
	_type.name = new_text
