class_name FSMState
extends Node

onready var obj: Node = get_parent().get_parent()

var fsm

###############################################################################
# Builtin functions                                                           #
###############################################################################

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func on_enter() -> void:
	pass

func run(_delta: float) -> void:
	pass

func on_exit() -> void:
	pass
