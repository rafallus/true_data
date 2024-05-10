@tool
extends EditorPlugin

# This plugin adds three Autoload scripts that can be accessed anywhere in the
# game:
# ERR - Helper for managing errors.
# DATA - Helper for processing data. This script can be extended to contain all
#		data needed by the game.
# IO - Helper to write/read files.

const ADDON_PREFIX := "addons/true_data/"
const ADDON_PATH := "res://" + ADDON_PREFIX
const DEFAULT_DATA_PATH := "autoload/global_data.gd"
const DATA_NAME := "Data"
const IO_NAME := "IO"

var data_path: String
var DataCreator: GDScript
var DataType: GDScript
var plugin: Control
var button: Button

func _enter_tree() -> void:
	# Get Data singleton script from path in project settings.
	if not ProjectSettings.has_setting(ADDON_PREFIX + "data_script_path"):
		ProjectSettings.set_setting(ADDON_PREFIX + "data_script_path",
			ADDON_PATH + DEFAULT_DATA_PATH)
		ProjectSettings.add_property_info({
			name = ADDON_PREFIX + "data_script_path",
			type = TYPE_STRING,
			hint = PROPERTY_HINT_FILE,
			hint_string = "*.gd"
		})
		ProjectSettings.set_initial_value(ADDON_PREFIX + "data_script_path", ADDON_PATH + DEFAULT_DATA_PATH)
	data_path = ProjectSettings.get_setting(ADDON_PREFIX + "data_script_path")
	add_autoload_singleton(DATA_NAME, data_path)

	# Add IO singleton.
	#add_autoload_singleton(IO_NAME, ADDON_PATH + "autoload/file_io.gd")

	# Load resources.
	DataCreator = load("res://addons/true_data/data_creator/data_creator.gd")
	DataType = load("res://addons/true_data/data_creator/data_type.gd")
	plugin = load("res://addons/true_data/data_creator/plugin.tscn").instantiate()
	plugin.set_undoredo(get_undo_redo())
	button = add_control_to_bottom_panel(plugin, "Data Creator")
	button.hide()

	# If project settings change, make sure to have the correct path to Data
	# singleton.
	if ProjectSettings.settings_changed.connect(_on_project_settings_changed) != OK:
		printerr("Cannot connect 'settings_changed' signal.")


func _exit_tree() -> void:
	remove_control_from_bottom_panel(plugin)
	plugin.free()
	button = null

	##remove_autoload_singleton(IO_NAME)
	remove_autoload_singleton(DATA_NAME)

	ProjectSettings.settings_changed.disconnect(_on_project_settings_changed)


func _disable_plugin() -> void:
	ProjectSettings.clear(ADDON_PREFIX + "data_script_path")


func _make_visible(visible: bool) -> void:
	if not visible and plugin.visible:
		hide_bottom_panel()
		plugin.hide()
	button.visible = visible


func _handles(object: Object) -> bool:
	var script: Script = object.get_script()
	return script and (script == DataCreator or script == DataType)


func _edit(object: Object) -> void:
	if object:
		plugin.edit(object)


func _clear() -> void:
	plugin.clear()


func _on_project_settings_changed() -> void:
	var path: String = ProjectSettings.get_setting(ADDON_PREFIX + "data_script_path")
	if path != data_path:
		remove_autoload_singleton(DATA_NAME)
		data_path = path
		add_autoload_singleton(DATA_NAME, data_path)
