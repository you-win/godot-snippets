class_name FSM
extends Reference

var obj: Node

var states: Dictionary = {}

var last_state: FSMState
var current_state: FSMState
var next_state: FSMState

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _init(obj: Node, states: Node, starting_state: Node) -> void:
	self.obj = obj
	
	for state in states.get_children():
		state.fsm = self
		state.obj = obj
		self.states[state.name] = state
	
	last_state = starting_state
	current_state = starting_state
	next_state = starting_state

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func run(delta: float) -> void:
	if current_state != next_state:
		current_state.on_exit()
		next_state.on_enter()
		last_state = current_state
		current_state = next_state
	current_state.run(delta)

func switch_state_now(delta: float, state: FSMState) -> void:
	self.next_state = state
	run(delta)

func switch_state_deferred(state: FSMState) -> void:
	self.next_state = state
