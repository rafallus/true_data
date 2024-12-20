##
##
@tool
class_name Database
extends Resource

class Field:
	var name: String
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
var _fields: Array[Field] = []


# =============================================================
# ========= Public Functions ==================================

func open(path: String) -> void:
	assert(path.get_extension() == _get_extension(), "Incorrect file extension.")
	_file = FileAccess.open(path, FileAccess.READ)
	_open()


func query() -> DatabaseQuery:
	return _query

# set_object


# =============================================================
# ========= Callbacks =========================================

func _init() -> void:
	_query = DatabaseQuery.new()
	Err.conn(_query.commited, _on_query_commited)


# =============================================================
# ========= Virtual Methods ===================================

func _open() -> void:
	pass


func _get_field_record(_field: StringName) -> int:
	return 0


func _get_extension() -> String:
	return ""


# =============================================================
# ========= Private Functions =================================

func __commit_query() -> void:
	var fields := _query.get_eval_fields()
	var records := []
	Err.check_resize(records.resize(fields.size()))
	for ifield in fields.size():
		var field = fields[ifield]
		if typeof(field) == TYPE_ARRAY:
			var a := []
			Err.check_resize(a.resize(field.size()))
			for isubfield in field.size():
				a[isubfield] = _get_field_record(field[isubfield])
			records[ifield] = a
		elif typeof(field) == TYPE_STRING_NAME:
			records[ifield] = _get_field_record(field)

	_query.clear()


# =============================================================
# ========= Signal Callbacks ==================================

func _on_query_commited() -> void:
	__commit_query()
