class_name TelemetryDeck
extends Node

@onready var http: HTTPRequest = $HTTPRequest
var url = "https://nom.telemetrydeck.com/v2/"
@export var appId: String= "xxx"
# https://telemetrydeck.com/docs/ingest/default-parameters/
# https://telemetrydeck.com/docs/ingest/v2/
var time_start_sec = 0

func _ready() -> void:
	time_start_sec = Time.get_ticks_msec() / 1000
	sendSignal("application_start")

func _enricht_data(data: Dictionary) -> Dictionary:
	var runtime =  ((Time.get_ticks_msec() / 1000) - time_start_sec)/60
	data["runtime_m"] = runtime
	return data

func sendSignalWithDict(type: String, dict: Dictionary):
	print("sending "+type)
	var headers = ["Content-Type: application/json; charset=utf-8"]
	var data = [
		{
			"appID": appId,
			"type": type,
			"clientUser": "myClientUserHash",
			"payload": _enricht_data(dict)
		}
	]
	var json = JSON.stringify(data)
	print(json)
	http.request(url, headers, HTTPClient.METHOD_POST, json)

func sendSignal(type: String):
	sendSignalWithDict(type, {})

func sendSignalWithData(type: String, data: String):
	sendSignalWithDict(type, {"data": data})
