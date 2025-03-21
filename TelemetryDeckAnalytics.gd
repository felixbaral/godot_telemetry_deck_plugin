extends Node

@onready var http: HTTPRequest = $HTTPRequest
var url = "https://nom.telemetrydeck.com/v2/"
@export var appId: String= "xxx"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sendSignal("application_start")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func sendSignal(type: String):
	print("sending "+type)
	var headers = ["Content-Type: application/json; charset=utf-8"]
	var data = [
		{
			"appID": appId,
			"type": type,
			"clientUser": "myClientUserHash"
		}
	]
	var json = JSON.stringify(data)
	print(json)
	http.request(url, headers, HTTPClient.METHOD_POST, json)
	pass
