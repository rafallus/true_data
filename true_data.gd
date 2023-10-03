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
const err_name := "ERR"
const data_name := "DATA"
const io_name := "IO"

var data_path: String

func _enter_tree() -> void:
	# Add ERR singleton.
	add_autoload_singleton(err_name, ADDON_PATH + "autoload/err.gd")

	# Get DATA singleton script from path in project settings.
	if not ProjectSettings.has_setting(ADDON_PREFIX + "data_script_path"):
		ProjectSettings.set_setting(ADDON_PREFIX + "data_script_path",
			ADDON_PATH + DEFAULT_DATA_PATH)
		ProjectSettings.add_property_info({
			name = "addons/true_data/data_script_path",
			type = TYPE_STRING,
			hint = PROPERTY_HINT_FILE,
			hint_string = "*.gd"
		})
	data_path = ProjectSettings.get_setting(ADDON_PREFIX + "data_script_path")
	add_autoload_singleton(data_name, data_path)

	# Add IO singleton.
	add_autoload_singleton(io_name, ADDON_PATH + "autoload/file_io.gd")

	# If project settings change, make sure to have the correct path to DATA
	# singleton.
	if not project_settings_changed.connect(_on_project_settings_changed):
		printerr("Cannot connect 'project_settings_changed' signal.")


func _exit_tree() -> void:
	remove_autoload_singleton(io_name)
	remove_autoload_singleton(data_name)
	remove_autoload_singleton(err_name)


func _on_project_settings_changed() -> void:
	var path: String = ProjectSettings.get_setting(ADDON_PREFIX + "data_script_path")
	if path != data_path:
		remove_autoload_singleton(data_name)
		data_path = path
		add_autoload_singleton(data_name, data_path)

