@tool
extends Resource

##
## .
##
## .
##

var data_script: Script:
	set(script):
		data_script = script
		notify_property_list_changed()

var _props := {}
var _tmp := {}

# =============================================================
# ========= Public Functions ==================================


# =============================================================
# ========= Callbacks =========================================

func _set(property: StringName, value: Variant) -> bool:
	if not data_script:
		_tmp[property] = value
	elif property in _props:
		_props[property] = value
		return true
	return false


func _get(property: StringName) -> Variant:
	if property in _props:
		return _props[property]
	return null


func _get_property_list() -> Array[Dictionary]:
	if data_script:
		var props := Data.get_script_editor_props(data_script)
		if _props.is_empty():
			for prop in props:
				var prop_name := StringName(prop.name)
				if prop_name in _tmp:
					_props[prop_name] = _tmp[prop_name]
				else:
					_props[prop_name] = data_script.get_property_default_value(prop_name)
			_tmp.clear()
		return props
	return []


# =============================================================
# ========= Virtual Methods ===================================


# =============================================================
# ========= Private Functions =================================


# =============================================================
# ========= Signal Callbacks ==================================
