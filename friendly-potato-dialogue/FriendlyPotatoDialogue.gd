extends Node

"""
DialogueSystem

Stores dialogue data and exposes helper functions.

dialogue_data is structured as follows:
{
	'name': string,
	'initial_dialogue_node': string,
	'variables': {
		<variable_name>: {
			'type': string,
			'value': based on type
		}
	},
	'dialogue': {
		<node_name>: {
			'node_text': string,
			'should_end': bool,
			'choices': [{
				'choice_name': string,
				'removable': bool,
				'next_node': string,
				'conditional': bool,
				'conditional_variables': {
					<variable_name>: {
						'operator': string,
						'value': based on type
					}
				},
				'on_exit_set_variables': {
					<variable_name>: value <- accesses global dialogue vars
				},
				'on_exit_functions': {
					<function_name>: [string] <- accesses global dialogue vars
				}
			}],
			'on_enter_set_variables': {
				<variable_name>: value <- accesses global dialogue vars
			},
			'on_enter_functions': {
				<function_name>: [string] <- accesses global dialogue vars
			}
		}
	}
}
"""

const VARIABLE_TYPES = {
	"FLOAT": "FLOAT",
	"STRING": "STRING",
	"BOOL": "BOOL"
}

const OPERATOR_TYPES = {
	"EQUAL_TO": "EQUAL_TO",
	"NOT_EQUAL_TO": "NOT_EQUAL_TO",
	"LESS_THAN": "LESS_THAN",
	"LESS_THAN_EQUAL_TO": "LESS_THAN_EQUAL_TO",
	"GREATER_THAN": "GREATER_THAN",
	"GREATER_THAN_EQUAL_TO": "GREATER_THAN_EQUAL_TO"
}

var dialogue_data: Dictionary
var dialogue_functions: Dictionary

var next_dialogue_node: String
var current_choices: Array = Array()
var should_end: bool = false

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(data: Dictionary, initial_variable_state: Dictionary = {}, functions_to_bind: Dictionary = {}) -> void:
	"""
	data: The contents of the dialogue file in JSON format
	initial_variable_state: The initial variable state of the dialogue. The variables must
	pre-defined in the dialogue.
	{
		<variable_name>: <variable_value>
	}
	functions_to_bind: Contains references to objects with functions that will be called
	from the dialogue
	{
		<function_name>: <node_ref>
	}
	"""
	self.dialogue_data = data

	if typeof(dialogue_data) != TYPE_DICTIONARY:
		printerr("Invalid dialogue file loaded. Exiting.")

	# Set the next active dialogue node
	next_dialogue_node = dialogue_data.initial_dialogue_node

	if not initial_variable_state.empty():
		for key in initial_variable_state.keys():
			dialogue_data.variables[key].value = initial_variable_state[key]

	dialogue_functions = functions_to_bind

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _parse_choices(dialogue_node: Dictionary) -> void:
	current_choices.clear()
	for choice in dialogue_node.choices:
		if choice.conditional:
			var conditional_count: int = choice.conditional_variables.size()
			for conditional_variable_key in choice.conditional_variables.keys():
				# Store the amount of conditionals to check
				# If the condition is true, decrement the amount
				# If all conditions are true, then add the choice
				var conditional_variable = choice.conditional_variables[conditional_variable_key]
				match conditional_variable.operator:
					OPERATOR_TYPES.EQUAL_TO:
						if dialogue_data.variables[conditional_variable_key].value == _convert_variable_to_type(conditional_variable.value, dialogue_data.variables[conditional_variable_key].type):
							conditional_count -= 1
					OPERATOR_TYPES.NOT_EQUAL_TO:
						if dialogue_data.variables[conditional_variable_key].value != _convert_variable_to_type(conditional_variable.value, dialogue_data.variables[conditional_variable_key].type):
							conditional_count -= 1
					OPERATOR_TYPES.LESS_THAN:
						if dialogue_data.variables[conditional_variable_key].value < _convert_variable_to_type(conditional_variable.value, dialogue_data.variables[conditional_variable_key].type):
							conditional_count -= 1
					OPERATOR_TYPES.LESS_THAN_EQUAL_TO:
						if dialogue_data.variables[conditional_variable_key].value <= _convert_variable_to_type(conditional_variable.value, dialogue_data.variables[conditional_variable_key].type):
							conditional_count -= 1
					OPERATOR_TYPES.GREATER_THAN:
						if dialogue_data.variables[conditional_variable_key].value > _convert_variable_to_type(conditional_variable.value, dialogue_data.variables[conditional_variable_key].type):
							conditional_count -= 1
					OPERATOR_TYPES.GREATER_THAN_EQUAL_TO:
						if dialogue_data.variables[conditional_variable_key].value >= _convert_variable_to_type(conditional_variable.value, dialogue_data.variables[conditional_variable_key].type):
							conditional_count -= 1
					_:
						printerr("Invalid operator type for choice conditional: " + conditional_variable.operator)
			if conditional_count == 0:
				current_choices.append(choice)
		else:
			current_choices.append(choice)

func _convert_variable_to_type(value, type: String):
	match type:
		VARIABLE_TYPES.FLOAT:
			return float(value)
		VARIABLE_TYPES.STRING:
			return str(value)
		VARIABLE_TYPES.BOOL:
			return bool(value)
		_:
			printerr("Unrecognized variable type, cannot convert")

###############################################################################
# Public functions                                                            #
###############################################################################

func continue_dialogue() -> String:
	var dialogue_node: Dictionary = dialogue_data.dialogue[next_dialogue_node]

	if dialogue_node.should_end:
		self.should_end = true
	
	# Set new dialogue choices
	_parse_choices(dialogue_node)

	# Run on_enter keys
	if dialogue_node.has("on_enter_set_variables"):
		for set_variable in dialogue_node.on_enter_set_variables.keys():
			dialogue_data.variables[set_variable].value = dialogue_node.on_enter_set_variables[set_variable]

	if dialogue_node.has("on_enter_functions"):
		for enter_function_name in dialogue_node.on_enter_functions.keys():
			dialogue_functions[enter_function_name].callv(enter_function_name, dialogue_node.on_enter_functions[enter_function_name])
	return dialogue_node.node_text

func choose_choice(choice_index: int) -> void:
	var choice: Dictionary = current_choices[choice_index]
	
	if choice.removable:
		current_choices.remove(choice_index)
		dialogue_data.dialogue[next_dialogue_node].choices = current_choices.duplicate(true)

	next_dialogue_node = choice.next_node

	# Run on_exit keys
	if choice.has("on_exit_set_variables"):
		for set_variable in choice.on_exit_set_variables.keys():
			dialogue_data.variables[set_variable].value = choice.on_enter_set_variables[set_variable]
	if choice.has("on_exit_functions"):
		for exit_function_name in choice.on_exit_functions.keys():
			dialogue_functions[exit_function_name].callv(exit_function_name, choice.on_exit_functions[exit_function_name])

func get_variable(variable_name: String):
	var dialogue_variable = dialogue_data.variables[variable_name]

	return _convert_variable_to_type(dialogue_variable.value, dialogue_variable.type)
