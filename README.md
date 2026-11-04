# TelemetryDeck for Godot

A small Godot 4 addon for sending analytics signals to [TelemetryDeck](https://telemetrydeck.com) through the [v3 ingest API](https://telemetrydeck.com/docs/ingest/v3/).

Signals are buffered and sent in batches. If sending fails, they are written to disk and sent again on the next start.

## Installation

1. Copy the `telemetry_deck` folder to `res://addons/`.
2. Enable the plugin under **Project → Project Settings → Plugins**.
3. Add `res://addons/telemetry_deck/analytics.tscn` as an autoload.
4. On the `Analytics` node, set:
   - `appId`: your TelemetryDeck app ID
   - `your_namespace`: your TelemetryDeck namespace

## Usage

```gdscript
# simple signal
Analytics.sendSignal("application_start")

# signal with a single "data" value
Analytics.sendSignalWithData("menu_opened", "settings")

# signal with custom parameters
Analytics.sendSignalWithDict("level_completed", {"level": "livingroom", "time_s": 123})

# parameter that is attached to every following signal
Analytics.setParameter("game_version", "1.2.0")

# mark the start of a session (resets session_runtime_m)
Analytics.startSession()

# report an error
Analytics.logError("save_failed", "could not write savegame")
```
