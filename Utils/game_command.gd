class_name GameCommand
extends RefCounted

## Base class for all game commands
## Commands encapsulate game actions that need to be executed by the GameManager
## This enables clean separation between effects (pure logic) and game state mutations
## Supports command chaining: commands can queue other commands during execution

## Shared data dictionary for passing information between chained commands
## Example: CopyCardCommand stores card_data, CreateCardVisualCommand retrieves it
var shared_data: Dictionary = {}

## Reference to the next command in the chain (optional)
## Commands can queue this after their execution completes
var next_command: GameCommand = null

## Execute this command with the given game manager
## Now async to support animations, waits, and other async operations
## Must be overridden by subclasses
func execute(game_manager: GameManager) -> void:
	push_error("execute() must be implemented by subclass: " + get_script().resource_path)

## Optional: Check if this command can be executed
## Override in subclasses to add validation logic
func can_execute(game_manager: GameManager) -> bool:
	return true

## Optional: Undo this command (for future undo/redo system)
## Override in subclasses that support undo
func undo(game_manager: GameManager) -> void:
	push_warning("undo() not implemented for: " + get_script().resource_path)

## Helper: Store data to be shared with subsequent commands
func set_shared_data(key: String, value: Variant) -> void:
	shared_data[key] = value

## Helper: Retrieve data from shared storage
func get_shared_data(key: String, default: Variant = null) -> Variant:
	return shared_data.get(key, default)

## Helper: Set the next command in the chain
func set_next_command(command: GameCommand) -> void:
	next_command = command
	# Share the data dictionary with the next command
	if command:
		command.shared_data = shared_data
