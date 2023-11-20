@tool
extends Control

enum View {TYPES, SINGLE_TYPE}

const DataCreator: GDScript = preload("res://addons/true_data/data_creator/data_creator.gd")
const DataType: GDScript = preload("res://addons/true_data/data_creator/data_type.gd")

@export var types_view: ScrollContainer
@export var single_type_view: ScrollContainer


###############################################################
####======= Public Functions ==============================####

func edit(node: Node) -> void:
	if node.get_script() == DataCreator:
		types_view.edit(node)
		__show_view(View.TYPES)
	elif node.get_script() == DataType:
		single_type_view.edit(node)
		__show_view(View.SINGLE_TYPE)


func clear() -> void:
	types_view.clear()
	single_type_view.clear()


func set_undoredo(undoredo: EditorUndoRedoManager) -> void:
	types_view.undoredo = undoredo
	single_type_view.undoredo = undoredo


###############################################################
####======= Callbacks =====================================####


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####

func __show_view(view: int) -> void:
	for i in get_child_count():
		var view_node := get_child(i) as Control
		if view_node:
			view_node.visible = i == view


###############################################################
####======= Signal Callbacks ==============================####

func _on_types_view_edit_type_pressed(type: DataType) -> void:
	pass # Replace with function body.
