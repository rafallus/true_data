##
## Brief description.
##
## Long description.
##
@tool
extends ScrollContainer

const DataType: GDScript = preload("res://addons/true_data/data_creator/data_type.gd")

@export var back_button: Button
@export var title_label: Label
@export var columns: HBoxContainer

var undoredo: EditorUndoRedoManager

var _type: DataType


# =============================================================
# ========= Public Functions ==================================

func edit(node: DataType) -> void:
	if _type:
		pass
	_type = node
	title_label.text = "Type: " + _type.name
	__fill_columns()


func clear() -> void:
	_type = null


# =============================================================
# ========= Callbacks =========================================

func _ready() -> void:
	back_button.icon = EditorInterface.get_editor_theme().get_icon(&"ArrowLeft", &"EditorIcons")

# =============================================================
# ========= Virtual Methods ===================================


# =============================================================
# ========= Private Functions =================================

func __fill_columns() -> void:
	if not _type.data_script:
		return
	var props := Data.get_script_storage_props(_type.data_script)
	var iprop := 0
	for prop in props:
		var column: Control
		if iprop < columns.get_child_count():
			column = columns.get_child(iprop)
		else:
			column = preload("res://addons/true_data/data_creator/views/column.tscn").instantiate()
			columns.add_child(column)
		column.set_property(prop, _type.data_script)
		iprop += 1
	for i in range(props.size(), columns.get_child_count()):
		columns.get_child(i).queue_free()


# =============================================================
# ========= Signal Callbacks ==================================
