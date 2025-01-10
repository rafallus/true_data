##
##
@tool
class_name DatabaseQuery
extends RefCounted

signal commited

class DBOperationElements:
	var operator: Variant.Operator
	var value: Variant
	var callback: Callable


class DBOperation:
	var field: StringName
	var elements: Array[DBOperationElements]


const MODULE := &"Database"

var _selection: Array[StringName] = []
var _operations: Array = []
var _or_array := []
var _index := 0
var _index_or := 0
var _data: Dictionary[Variant, Dictionary] = {}
var _id_name := &"id"

# =============================================================
# ========= Public Functions ==================================

func get_values() -> Array[Dictionary]:
	return _data.values()


func select(fields: Array[StringName]) -> DatabaseQuery:
	assert(_selection.is_empty(), "Selection has been already done in query.")
	_selection = fields
	return self


func get_selection() -> Array[StringName]:
	return _selection


func where(field: StringName, op: Variant.Operator, value: Variant) -> DatabaseQuery:
	_or_array = []
	var elements := DBOperationElements.new()
	for o in _operations:
		if o is DBOperation:
			var oo := o as DBOperation
			if oo.field == field:
				elements.operator = op
				elements.value = value
				oo.elements.push_back(elements)
				return self
	var operation := DBOperation.new()
	operation.field = field
	elements.operator = op
	elements.value = value
	operation.elements = [elements]
	_operations.push_back(operation)
	return self


func or_where(field: StringName, op: Variant.Operator, value: Variant) -> DatabaseQuery:
	if _or_array.is_empty():
		_operations.push_back(_or_array)
	var operation := DBOperation.new()
	operation.field = field
	var elements := DBOperationElements.new()
	elements.operator = op
	elements.value = value
	operation.elements = [elements]
	_or_array.push_back(operation)
	return self


func with_id(id: StringName) -> void:
	_id_name = id


func commit() -> DatabaseQuery:
	commited.emit()
	return self


func clear() -> void:
	_selection.clear()
	_operations.clear()
	_or_array.clear()
	_index = 0
	_index_or = 0
	_data.clear()


func get_eval_fields() -> Array:
	var fields := []
	Err.check_resize(fields.resize(_operations.size()))
	for i in _operations.size():
		var o = _operations[i]
		if o is DBOperation:
			var oo := o as DBOperation
			fields[i] = oo.field
		elif typeof(o) == TYPE_ARRAY:
			var oo := o as Array
			var a := []
			Err.check_resize(a.resize(oo.size()))
			for j in oo.size():
				var p = oo[j]
				if p is DBOperation:
					var pp := p as DBOperation
					a[j] = pp.field
				else:
					Log.error("Incorrect operation field", ERR_INVALID_DATA, MODULE)
			fields[i] = a
		else:
			Log.error("Incorrect operation field", ERR_INVALID_DATA, MODULE)
	return fields


func start_record() -> void:
	_index = 0
	_index_or = 0


func eval_next(data: Variant) -> bool:
	var operation: DBOperation = null
	var is_or := false
	if _operations[_index] is DBOperation:
		operation = _operations[_index]
	else:
		var a: Array = _operations[_index]
		if _index_or >= a.size():
			# Is this point ever reached?
			_index += 1
			operation = _operations[_index]
			_index_or = 0
		else:
			operation = a[_index_or]
			is_or = true
	var result := true
	for e in operation.elements:
		if not e.callback.is_valid():
			e.callback = __select_function(e.operator)
		if not e.callback.call(data, e.value):
			result = false
			break
	if is_or:
		if result:
			_index_or = 0
		else:
			_index_or += 1
	else:
		_index += 1
	return result


func get_id_name() -> StringName:
	return _id_name


# =============================================================
# ========= Callbacks =========================================


# =============================================================
# ========= Virtual Methods ===================================


# =============================================================
# ========= Private Functions =================================

func __select_function(op: Variant.Operator) -> Callable:
	match op:
		OP_EQUAL:
			return __equal
		OP_NOT_EQUAL:
			return __not_equal
		OP_LESS:
			return __less
		OP_LESS_EQUAL:
			return __less_equal
		OP_GREATER:
			return __greater
		OP_GREATER_EQUAL:
			return __greater_equal
		_:
			Log.warning("Non supported operation in DB query.", ERR_INVALID_PARAMETER, MODULE)
			return __null


func __equal(v1, v2) -> bool:
	return v1 == v2


func __not_equal(v1, v2) -> bool:
	return v1 != v2


func __less(v1, v2) -> bool:
	return v1 < v2


func __less_equal(v1, v2) -> bool:
	return v1 <= v2


func __greater(v1, v2) -> bool:
	return v1 > v2


func __greater_equal(v1, v2) -> bool:
	return v1 >= v2


func __null(_v1, _v2) -> bool:
	return false

# =============================================================
# ========= Signal Callbacks ==================================
