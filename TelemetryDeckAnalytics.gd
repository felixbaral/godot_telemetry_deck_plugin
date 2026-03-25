class_name TelemetryDeck
extends Node

@export var http: HTTPRequest
@export var _timer: Timer
var url = "https://nom.telemetrydeck.com/v2/"
@export var appId: String= "xxx"
# https://telemetrydeck.com/docs/ingest/default-parameters/
# https://telemetrydeck.com/docs/ingest/v2/
var time_start_sec = 0
var time_session_sec = 0
var _buffer: Array = []
var _last_batch: Array = []  # kept until HTTP confirms success
var _is_busy_sending = false
var _parameters: Dictionary = {}
# shows up as test data in telemetrydecks dash
var _isTestMode = false

const BUFFER_FILE = "user://telemetry_buffer.json"


func _ready() -> void:
	http.request_completed.connect(self._http_request_completed)
	_timer.timeout.connect(self._trySend)
	time_start_sec = Time.get_ticks_msec() / 1000
	print("TelemetryDeck crash handler available: ", OS.is_debug_build() == false)
	_load_buffer_from_disk()
	sendSignal("application_start")
	_parameters["TelemetryDeck.Device.platform"] = OS.get_name()
	_parameters["platform"] = OS.get_name()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CRASH:
		sendSignal("application_crash")
		_save_buffer_to_disk()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not _buffer.is_empty() or not _last_batch.is_empty():
			_save_buffer_to_disk()

func startSession() -> void:
	time_session_sec = Time.get_ticks_msec() / 1000
	sendSignal("start_session")

func logError(error_id: String, error: String):
	sendSignalWithDict("TelemetryDeck.Error.occurred", {
		"TelemetryDeck.Error.id": error_id,
		"TelemetryDeck.Error.message": error
	})

func setParameter(name: String, value: Variant):
	_parameters[name] = value

func _enricht_data(data: Dictionary) -> Dictionary:
	var runtime =  ((Time.get_ticks_msec() / 1000) - time_start_sec)/60
	var runtime_session =  ((Time.get_ticks_msec() / 1000) - time_session_sec)/60
	data["runtime_m"] = runtime
	data["session_runtime_m"] = runtime_session
	for key in _parameters.keys():
		data[key] = _parameters[key]
	return data

func bufferSignal(dict: Dictionary):
	_buffer.append(dict)
	print("buffering "+ dict["type"])

func sendSignalWithDict(type: String, dict: Dictionary):
	bufferSignal({
			"appID": appId,
			"type": type,
			"clientUser": "myClientUserHash",
			"payload": _enricht_data(dict),
			"isTestMode": _isTestMode
		})
	_trySend()

func _trySend():
	if _buffer.is_empty():
		return
	if _is_busy_sending:
		_timer.start()
		return

	var headers = ["Content-Type: application/json; charset=utf-8"]
	var json = JSON.stringify(_buffer)
	_last_batch = _buffer.duplicate()
	_buffer = []
	print(json)
	_is_busy_sending = true
	http.request(url, headers, HTTPClient.METHOD_POST, json)

func sendSignal(type: String):
	sendSignalWithDict(type, {})

func sendSignalWithData(type: String, data: String):
	sendSignalWithDict(type, {"data": data})

# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	_is_busy_sending = false
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("error with analytics call — re-queuing batch to disk")
		_buffer = _last_batch + _buffer
		_save_buffer_to_disk()
	_last_batch = []
	print(body)

#region persistence

func _save_buffer_to_disk() -> void:
	var thread := Thread.new()
	thread.start(_write_buffer_thread.bind(_buffer))

func _write_buffer_thread(data: Array) -> void:
	var file := FileAccess.open(BUFFER_FILE, FileAccess.WRITE)
	if file == null:
		push_error("TelemetryDeck: could not open buffer file for writing")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	print("TelemetryDeck: buffer saved to disk (%d signals)" % data.size())

func _load_buffer_from_disk() -> void:
	if not FileAccess.file_exists(BUFFER_FILE):
		print("TelemetryDeck: no buffer file")
		return
	var thread := Thread.new()
	thread.start(_read_buffer_thread)

func _read_buffer_thread() -> void:
	var file := FileAccess.open(BUFFER_FILE, FileAccess.READ)
	if file == null:
		print("TelemetryDeck: no stored signals found")
		return
	var text := file.get_as_text()
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BUFFER_FILE))
	var parsed = JSON.parse_string(text)
	if parsed is Array and not parsed.is_empty():
		print("TelemetryDeck: restored %d signals from disk" % parsed.size())
		call_deferred("_prepend_restored_buffer", parsed)

func _prepend_restored_buffer(data: Array) -> void:
	_buffer = data + _buffer
	_trySend()
#endregion
