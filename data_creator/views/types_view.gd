##
## Brief description.
##
## Long description.
##
@tool
extends ScrollContainer

signal edit_type_pressed(type: Node)

const MAX_ROWS := 8
const DataCreator: GDScript = preload("res://addons/true_data/data_creator/data_creator.gd")
const DataType: GDScript = preload("res://addons/true_data/data_creator/data_type.gd")

@export var add_type: Button
@export var new_type_name: LineEdit
@export var types_rows_scroll: ScrollContainer
@export var file_dialog: FileDialog

@onready var types_rows_box: VBoxContainer = types_rows_scroll.get_child(0)

var undoredo: EditorUndoRedoManager

var _creator: Node
var _dirty := false
var _current_type: Node


# =============================================================
# ========= Public Functions ==================================

func edit(node: DataCreator) -> void:
	if _creator:
		_creator.child_entered_tree.disconnect(_on_creator_child_entered)
		_creator.child_exiting_tree.disconnect(_on_creator_child_exiting)
		_creator.child_order_changed.disconnect(_on_creator_child_order_changed)
	_creator = node
	__queue_fill_types()
	Err.CONN(_creator.child_entered_tree, _on_creator_child_entered)
	Err.CONN(_creator.child_exiting_tree, _on_creator_child_exiting)
	Err.CONN(_creator.child_order_changed, _on_creator_child_order_changed)


func clear() -> void:
	for n in types_rows_box.get_children():
		n.queue_free()
	_creator = null


# =============================================================
# ========= Callbacks =========================================

func _ready() -> void:
	add_type.icon = EditorInterface.get_editor_theme().get_icon(&"Add", &"EditorIcons")

# =============================================================
# ========= Virtual Methods ===================================


# =============================================================
# ========= Private Functions =================================

func __queue_fill_types() -> void:
	if _dirty:
		return

	_dirty = true
	__fill_types.call_deferred()


func __fill_types() -> void:
	if not _creator.is_inside_tree():
		return

	var ntypes := 0
	for n in _creator.get_children():
		if n.get_script() != DataType:
			continue
		var row: Control
		if ntypes < types_rows_box.get_child_count():
			row = types_rows_box.get_child(ntypes)
		else:
			row = preload("res://addons/true_data/data_creator/views/types_row.tscn").instantiate()
			types_rows_box.add_child(row)
			Err.CONN(row.script_pressed, _on_type_script_pressed)
			Err.CONN(row.edit_pressed, _on_type_edit_pressed)
			Err.CONN(row.delete_pressed, _on_type_delete_pressed)
		row.set_type(n)
		ntypes += 1
	for i in range(_creator.get_child_count(), types_rows_box.get_child_count()):
		types_rows_box.get_child(i).queue_free()
	__fit_rows_scroll()
	_dirty = false


func __fit_rows_scroll() -> void:
	await get_tree().process_frame
	var n := mini(MAX_ROWS, types_rows_box.get_child_count())
	var h := n * 32 + 4 * (n - 1) # 32px min size per row plus 4px space between each row.
	types_rows_scroll.custom_minimum_size.y = h


func __disconnect_file_dialog() -> void:
	file_dialog.file_selected.disconnect(_on_script_file_selected)
	file_dialog.canceled.disconnect(_on_file_dialog_canceled)


func __add_type(type_name: String) -> void:
	var nm := type_name.validate_node_name().to_pascal_case()
	var type = DataType.new()
	type.name = nm

	undoredo.create_action("Add Data Type")
	undoredo.add_do_method(_creator, "add_child", type, false)
	undoredo.add_do_method(type, "set_owner", _creator)
	undoredo.add_do_reference(type)
	undoredo.add_undo_method(_creator, "remove_child", type)
	undoredo.commit_action()


# =============================================================
# ========= Signal Callbacks ==================================

func _on_type_script_pressed(type: DataType) -> void:
	_current_type = type
	file_dialog.filters = PackedStringArray(["*.gd ; GDScript"])
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	Err.CONN(file_dialog.file_selected, _on_script_file_selected)
	Err.CONN(file_dialog.canceled, _on_file_dialog_canceled)
	file_dialog.popup_centered(Vector2i(600,540))


func _on_type_edit_pressed(type: DataType) -> void:
	edit_type_pressed.emit(type)


func _on_type_delete_pressed(type: DataType) -> void:
	undoredo.create_action("Remove Data Type")
	undoredo.add_do_method(_creator, &"remove_child", type)
	undoredo.add_undo_method(_creator, &"add_child", type, true)
	undoredo.add_undo_method(_creator, &"move_child", type, type.get_index(false))
	undoredo.add_undo_property(type, &"owner", _creator)
	undoredo.add_undo_reference(type)
	undoredo.commit_action()


func _on_creator_child_exiting(_node: Node) -> void:
	__queue_fill_types()


func _on_creator_child_entered(_node: Node) -> void:
	__queue_fill_types()


func _on_creator_child_order_changed() -> void:
	__queue_fill_types()


func _on_script_file_selected(path: String) -> void:
	var script: Script = load(path) as Script
	_current_type.data_script = script
	__disconnect_file_dialog()


func _on_file_dialog_canceled() -> void:
	__disconnect_file_dialog()


func _on_new_type_name_text_changed(new_text: String) -> void:
	add_type.disabled = new_text.is_empty()


func _on_add_type_pressed() -> void:
	__add_type(new_type_name.text)
	new_type_name.clear()
	add_type.disabled = true
