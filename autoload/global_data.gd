@tool
extends Node

##
## Contains function that help processing data.
##
## Extend this script to include all data used by the game for easy access from
## any script.
##

## Ignore script variables set as exported for storage. What is checked to
## consider that a variable is exported is the precense of the flag
## PROPERTY_USAGE_SCRIPT_VARIABLE in the usage of the property. If this flag is
## set manually, it will be considered as an export variable.
const FLAG_IGNORE_EXPORTED := 1
## Store core properties of the object, i.e. properties defined by Godot.
const FLAG_STORE_CORE_PROPERTIES := 2
## Class properties inside sections (as Categories and Groups) are saved inside
## a JSON object.
const FLAG_STORE_SECTIONS := 4
## Ignore categories. Only useful in conjunction with FLAG_STORE_SECTIONS.
const FLAG_IGNORE_CATEGORY_SECTIONS := 8

## Supported variable types that can be stored in text format.
const SUPPORTED_TYPES_TEXT := [
	TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME
]

###############################################################
####======= Public Functions ==============================####

## Returns script properties that are displayed in the inspector.
func get_script_editor_props(script: Script) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var s := script
	while s:
		var sprops := s.get_script_property_list()
		for prop in sprops:
			var usage: int = prop.usage
			if usage & PROPERTY_USAGE_EDITOR && usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				props.push_back(prop)
		s = s.get_base_script()
	return props


func get_script_storage_props(script: Script, flags: int = 0) -> Array[Dictionary]:
	var props := script.get_script_property_list()
	return get_storage_props(props, flags)


## Filters out storage properties from a list of properties. Flags can be used
## to be more specific on what type of properties should be considered. The
## white_list property can be used to force including a list of properties
## despite the flags being used.
func get_storage_props(in_props: Array[Dictionary], flags: int = 0,
		white_list: PackedStringArray = PackedStringArray()) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var is_core := false
	var save_core: bool = flags & FLAG_STORE_CORE_PROPERTIES
	var use_sections: bool = flags & FLAG_STORE_SECTIONS
	var ignore_categories: bool = flags & FLAG_IGNORE_CATEGORY_SECTIONS
	var ignore_exported: bool = flags & FLAG_IGNORE_EXPORTED
	for prop in in_props:
		var usage: int = prop.usage
		var prop_name: String = prop.name
		if usage == PROPERTY_USAGE_CATEGORY:
			# If the category name is that of a Godot class, further properties
			# are considered to be core.
			is_core = ClassDB.class_exists(prop_name)
			if ((not is_core or save_core) and use_sections and \
					not ignore_categories) or white_list.has(prop_name):
				props.push_back(prop)
		elif white_list.has(prop_name):
			props.push_back(prop)
		elif not is_core or save_core:
			if usage == PROPERTY_USAGE_GROUP or usage == PROPERTY_USAGE_SUBGROUP:
				if use_sections:
					props.push_back(prop)
			elif not is_core or save_core:
				var type: int = prop.type
				if type != TYPE_NIL and \
						(usage & PROPERTY_USAGE_STORAGE and
						not usage & PROPERTY_USAGE_INTERNAL) and \
						(not ignore_exported or
						not usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
					props.push_back(prop)
	return props


## Returns a list of strings representing the storage properties of the
## [param object] with its values in the format [i]<property_name> :
## <property_value>[/i]. If [param properties] is not empty, it will serve as
## the list of properties to use. Otherwise all storage properties from object
## will be considered, taking into account the value of [param flags].
## Properties listed in [param white_list] are forced to be considered as
## storage properties even if it would be discarded by default or from the
## [param flags] value.
func obj_props_to_strings(object: Object, flags: int = 0, properties: Array = [],
		white_list: Array = []) -> PackedStringArray:
	var props := get_storage_props(object.get_property_list(), flags, white_list) \
		if properties.is_empty() else properties
	var strings := PackedStringArray()
	for prop in props:
		var type: int = prop.type
		if type in SUPPORTED_TYPES_TEXT:
			var prop_name: String = prop.name
			var string := "%s : %s" % [prop.name, str(object.get(prop_name))]
			ERR.CHK_APPEND(strings.push_back(string))
	return strings


## Sets [param object]s properties from a list of [param strings]. The strings
## are expected to have the format [i]<property_name> : <property_value>[/i].
## If the part [i]<property_name>[/i] is found in the list of [param skips], it
## won't be used to set any property, but instead, it will be added to the
## output list.
func obj_props_from_strings(object: Object, strings: PackedStringArray,
		skips: PackedStringArray = []) -> PackedStringArray:
	var remaining := PackedStringArray()
	for string in strings:
		var parts := string.split(":", false, 1)
		var prop := StringName(parts[0].strip_edges())
		if prop in skips:
			ERR.CHK_APPEND(remaining.push_back(string))
		else:
			var str_val := parts[1].strip_edges()
			var val: Variant = object.get(prop)
			match typeof(val):
				TYPE_BOOL:
					object.set(prop, true if str_val == "true" else false)
				TYPE_INT:
					object.set(prop, str_val.to_int())
				TYPE_FLOAT:
					object.set(prop, str_val.to_float())
				TYPE_STRING:
					object.set(prop, str_val)
				TYPE_STRING_NAME:
					object.set(prop, StringName(str_val))
				_:
					printerr("Type not supported.")
	return remaining


## Returns [code]true[/code] if a variable type is supported when converting
## properties to text format.
func is_type_supported_text_format(type: int) -> bool:
	return type in SUPPORTED_TYPES_TEXT


###############################################################
####======= Callbacks =====================================####


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####


###############################################################
####======= Signal Callbacks ==============================####
