##
##
@tool
class_name Database
extends Resource

class Field:
	var name: StringName
	var shift: int
	var size: int
	var type: int

const MODULE := &"Database"

var _query: DatabaseQuery
var _file: FileAccess
var _buffer := StreamPeerBuffer.new()
var _data_shift := 0
var _nrecords := 0
var _record_length := 0
var _field_list: Array[Field] = []
var _field_map: Dictionary[StringName, Field] = {}


# =============================================================
# ========= Public Functions ==================================

func open(path: String) -> void:
	assert(path.get_extension() == _get_extension(), "Incorrect file extension.")
	_file = FileAccess.open(path, FileAccess.READ)
	_open()


func query() -> DatabaseQuery:
	_query = DatabaseQuery.new()
	Err.conn(_query.commited, _on_query_commited)
	return _query


# =============================================================
# ========= Callbacks =========================================


# =============================================================
# ========= Virtual Methods ===================================

func _open() -> void:
	pass


func _get_entry(_field: Field) -> Variant:
	return 0


func _get_extension() -> String:
	return ""


# =============================================================
# ========= Private Functions =================================

func __commit_query() -> void:
	_query._data.clear()
	var eval_fields := _query.get_eval_fields()
	var indices := PackedInt32Array()
	_file.seek(_data_shift)
	_buffer.data_array = _file.get_buffer(_nrecords * _record_length)
	if eval_fields.is_empty():
		Err.check_resize(indices.resize(_nrecords))
		for i in _nrecords:
			indices[i] = i
	else:
		var fields := []
		Err.check_resize(fields.resize(eval_fields.size()))
		for ifield in eval_fields.size():
			var field = eval_fields[ifield]
			if typeof(field) == TYPE_ARRAY:
				var a := []
				Err.check_resize(a.resize(field.size()))
				for isubfield in field.size():
					assert(_field_map.has(field[isubfield]), "Non existent field name %s." % field[isubfield])
					a[isubfield] = _field_map[field[isubfield]]
				fields[ifield] = a
			elif typeof(field) == TYPE_STRING_NAME:
				assert(_field_map.has(field), "Non existent field name %s." % field)
				fields[ifield] = _field_map[field]
		for irecord in _nrecords:
			_query.start_record()
			var index0 := irecord * _record_length
			var valid := true
			for ifield in fields.size():
				var f = fields[ifield]
				if f is Field:
					var field := f as Field
					_buffer.seek(index0 + field.shift)
					var value: Variant = _get_entry(field)
					if not _query.eval_next(value):
						valid = false
						break
				elif typeof(f) == TYPE_ARRAY:
					valid = false
					for isubfield in f:
						var field := f[isubfield] as Field
						_buffer.seek(index0 + field.shift)
						var value: Variant = _get_entry(field)
						if _query.eval_next(value):
							valid = true
							break
					if not valid:
						break
			if valid:
				Err.check_append(indices.push_back(irecord))
	var selection := _query.get_selection()
	# TODO: Check id field is not duplicated.
	if selection.is_empty():
		Err.check_resize(selection.resize(_field_list.size()))
		for ifield in _field_list.size():
			selection[ifield] = _field_list[ifield].name
	var selected_fields: Array[Field] = []
	Err.check_resize(selected_fields.resize(selection.size()))
	for ifield in selection.size():
		var field := _field_map[selection[ifield]]
		selected_fields[ifield] = field
	#if _field_map.has(_query.get_id_name()):
		#selected_fields.push_back(_field_map[_query.get_id_name()])
	for i in indices:
		var index0 := i * _record_length
		var entry := {}
		var id = i
		for ifield in selected_fields.size():
			var field := selected_fields[ifield]
			_buffer.seek(index0 + field.shift)
			var value = _get_entry(field)
			entry[field.name] = value
			if field.name == _query.get_id_name():
				id = value
		_query._data[id] = entry
	_query.commited.disconnect(_on_query_commited)


# =============================================================
# ========= Signal Callbacks ==================================

func _on_query_commited() -> void:
	__commit_query()
