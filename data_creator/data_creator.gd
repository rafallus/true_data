@tool
extends Node

##
## Helper script to generate game data.
##
## Create a scene with a Node as root and add this script to it.
##

const DataType: GDScript = preload("res://addons/true_data/data_creator/data_type.gd")

###############################################################
####======= Public Functions ==============================####

func save() -> void:
	pass


###############################################################
####======= Callbacks =====================================####

func _enter_tree() -> void:
	ERR.CONN(child_entered_tree, _on_child_entered_tree)
	ERR.CONN(child_exiting_tree, _on_child_exiting_tree)


func _exit_tree() -> void:
	child_entered_tree.disconnect(_on_child_entered_tree)
	child_exiting_tree.disconnect(_on_child_exiting_tree)
	for n in get_children():
		n.script_changed.disconnect(update_configuration_warnings)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for n in get_children():
		if n.get_script() != DataType:
			ERR.CHK_APPEND(
				warnings.push_back("Child with incorrect script was found."))
			break
	return warnings


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####


###############################################################
####======= Signal Callbacks ==============================####

func _on_child_entered_tree(node: Node) -> void:
	ERR.CONN(node.script_changed, update_configuration_warnings)
	if node.get_script() != DataType:
		update_configuration_warnings()


func _on_child_exiting_tree(node: Node) -> void:
	if node.get_script() != DataType:
		await get_tree().process_frame
		update_configuration_warnings()
