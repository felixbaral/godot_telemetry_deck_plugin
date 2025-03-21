@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"Analytics", "Node",
		load("res://addons/telemetry_deck/TelemetryDeckAnalytics.gd"),
		load("res://addons/telemetry_deck/icon.webp"))
	


func _exit_tree() -> void:
	remove_custom_type("Analytics")
