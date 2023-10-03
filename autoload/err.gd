@tool
extends Node

##
## Error and warning helper.
##
## .
##

const ERROR_IGNORE := 0
const ERROR_NOTIFY_AND_CONTINUE := 1
const ERROR_NOTIFY_AND_BREAK := 2
const ERROR_NOTIFY_AND_EXIT := 3

const ERROR_DEFAULT_LVL := ERROR_NOTIFY_AND_BREAK

###############################################################
####======= Public Functions ==============================####

func PRINTERR(err: int, lvl: int = ERROR_DEFAULT_LVL) -> bool:
	if err != OK:
		# The generic FAILED error doesn't print a message.
		if lvl >= ERROR_NOTIFY_AND_CONTINUE and not err == FAILED:
			printerr("Error: " + error_string(err))
			print_stack()
		if lvl == ERROR_NOTIFY_AND_EXIT:
			if Engine.is_editor_hint():
				assert(err == OK, error_string(err))
			else:
				OS.alert(error_string(err), "Error!")
				self.get_tree().quit(err)
		if lvl <= ERROR_NOTIFY_AND_CONTINUE:
			return false
		else:
			return true
	return false


func PRINTERRQ(err: int, lvl: int = ERROR_DEFAULT_LVL) -> void:
	@warning_ignore("return_value_discarded")
	PRINTERR(err, lvl)


func CHK_RSZ(err: int, lvl: int = ERROR_DEFAULT_LVL) -> void:
	@warning_ignore("return_value_discarded")
	PRINTERR(err, lvl)


func CHK_APPEND(success: bool, lvl: int = ERROR_DEFAULT_LVL) -> void:
	if not success:
		@warning_ignore("return_value_discarded")
		PRINTERR(ERR_OUT_OF_MEMORY, lvl)


func CONN(signal_: Signal, callable: Callable) -> void:
	var err := signal_.connect(callable)
	if err != OK and ERROR_DEFAULT_LVL >= ERROR_NOTIFY_AND_CONTINUE:
		printerr("Cannot connect signal %s to method %s." % [signal_.get_name(), callable.get_method()])


func WARN_DICTERASE(erased: bool, element: String) -> void:
	if not erased and ERROR_DEFAULT_LVL >= ERROR_NOTIFY_AND_CONTINUE:
		push_warning("Trying to erase %s element from Dictionary, but it wasn't found." % element)


func OPEN_FILE(path: String, flags: int, check_exists: bool = false) -> FileAccess:
	if check_exists and not FileAccess.file_exists(path):
		@warning_ignore("return_value_discarded")
		PRINTERR(ERR_FILE_NOT_FOUND)
		return null
	var file = FileAccess.open(path, flags)
	@warning_ignore("return_value_discarded")
	PRINTERR(FileAccess.get_open_error())
	return file


###############################################################
####======= Callbacks =====================================####


###############################################################
####======= Virtual Methods ===============================####


###############################################################
####======= Private Functions =============================####


###############################################################
####======= Signal Callbacks ==============================####
