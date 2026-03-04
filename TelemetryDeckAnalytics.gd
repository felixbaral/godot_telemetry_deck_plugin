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
var _is_busy_sending = false


func _ready() -> void:
	http.request_completed.connect(self._http_request_completed)
	_timer.timeout.connect(self._trySend)
	time_start_sec = Time.get_ticks_msec() / 1000
	sendSignal("application_start")

func startSession() -> void:
	time_session_sec = Time.get_ticks_msec() / 1000
	sendSignal("start_session")

func _enricht_data(data: Dictionary) -> Dictionary:
	var runtime =  ((Time.get_ticks_msec() / 1000) - time_start_sec)/60
	var runtime_session =  ((Time.get_ticks_msec() / 1000) - time_session_sec)/60
	data["runtime_m"] = runtime
	data["session_runtime_m"] = runtime_session
	data["platform"] = OS.get_name()
	return data

func bufferSignal(dict: Dictionary):
	_buffer.append(dict)
	print("buffering "+ dict["type"])

func sendSignalWithDict(type: String, dict: Dictionary):
	bufferSignal({
			"appID": appId,
			"type": type,
			"clientUser": "myClientUserHash",
			"payload": _enricht_data(dict)
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
		push_error("error with analytics call")

	print(body)
