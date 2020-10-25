extends Node

# TODO smaller chunks for testing
const CHUNK_SIZE: float = 640.0
const RANGE_TO_KEEP: Array = [-2, -1, 0, 1, 2]

"""
Layout of chunk storage
[
	[
		chunk1, chunk2, chunk3, chunk4
	],
	[
		chunk5, chunk6, chunk7, chunk8
	],
	[
		chunk9, chunk10, chunk11, chunk12
	],
	[
		chunk13, chunk14, chunk15, chunk16
	]
]
"""

# TODO testing only
var chunk: Resource = preload("res://screens/tile-maps/TestMap0.tscn")
var default_chunk: Resource = preload("res://screens/tile-maps/DefaultMap.tscn")

var all_chunks: Array
# Dictionary of Vector2 to chunk names
var loaded_chunks: Dictionary = {}

var parent: Node2D

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	# TODO testing only
	# Setup 2D array
	for _i in range(4):
		all_chunks.append([])
	for a in all_chunks:
		for _i in range(4):
			a.append(chunk)
	all_chunks[0][1] = load("res://screens/tile-maps/TestMap1.tscn")
	
	parent = get_parent()

func _physics_process(delta: float) -> void:
	# TODO add timer to this so we aren't polling every physics frame
	var current_cell: Vector2 = GameManager.player.get_ref().global_position / CHUNK_SIZE
	current_cell.x = int(round(current_cell.x))
	current_cell.y = int(round(current_cell.y))
	_load_chunks(current_cell)

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

func _get_surrounding_chunks_for(chunk_position: Vector2) -> Dictionary:
	"""
	Returns a dictionary of chunk coordinates to chunk resources
	"""
	return {
		Vector2(chunk_position.x - 1, chunk_position.y): _get_chunk(chunk_position.x - 1, chunk_position.y),
		Vector2(chunk_position.x - 1, chunk_position.y + 1): _get_chunk(chunk_position.x - 1, chunk_position.y + 1),
		Vector2(chunk_position.x, chunk_position.y + 1): _get_chunk(chunk_position.x, chunk_position.y + 1),
		Vector2(chunk_position.x + 1, chunk_position.y + 1): _get_chunk(chunk_position.x + 1, chunk_position.y + 1),
		Vector2(chunk_position.x + 1, chunk_position.y): _get_chunk(chunk_position.x + 1, chunk_position.y),
		Vector2(chunk_position.x + 1, chunk_position.y - 1): _get_chunk(chunk_position.x + 1, chunk_position.y - 1),
		Vector2(chunk_position.x, chunk_position.y - 1): _get_chunk(chunk_position.x, chunk_position.y - 1),
		Vector2(chunk_position.x - 1, chunk_position.y - 1): _get_chunk(chunk_position.x - 1, chunk_position.y - 1)
	}

func _get_chunk(x: int, y: int) -> Resource:
	"""
	Null safe all_chunks access. If we are already on the edge, then a default chunk is returned.
	"""
	if(x < 0 or y < 0):
		return default_chunk
	if(x < all_chunks.size() and y < all_chunks[x].size()):
		return all_chunks[x][y]
	return default_chunk

func _load_chunks(chunk_position: Vector2) -> void:
	var surrounding_chunks: Dictionary = _get_surrounding_chunks_for(chunk_position)

	for vector in surrounding_chunks.keys():
		if not vector in loaded_chunks.keys():
			var chunk_instance = surrounding_chunks[vector].instance()
			chunk_instance.name += str(vector)
			chunk_instance.global_position = Vector2(vector.x * CHUNK_SIZE, vector.y * CHUNK_SIZE)
			loaded_chunks[vector] = chunk_instance.name
			parent.chunks.call_deferred("add_child", chunk_instance)
	
	_unload_chunks(chunk_position, surrounding_chunks.keys())

func _unload_chunks(current_chunk: Vector2, new_chunks: Array) -> void:
	for vector in loaded_chunks.keys():
		if vector == current_chunk:
			continue
		var difference: Vector2 = current_chunk - vector
		if(not round(difference.x) in RANGE_TO_KEEP or not round(difference.y) in RANGE_TO_KEEP):
			_unload_chunk(vector)
		# if not vector in new_chunks:
		# 	_unload_chunk(vector)
	
	# Look for leaked chunks
	# If there are more than 9 chunks loaded, we have a leak
	if(loaded_chunks.size() > 16 or parent.chunks.get_children().size() > 16):
		var loaded_chunk_names_copy: Array = loaded_chunks.values().duplicate()
		var instanced_chunk_names: Array = []
		for child in parent.chunks.get_children():
			if "@" in child.name:
				child.queue_free()
			else:
				instanced_chunk_names.append(child.name)
		
		for n in loaded_chunks.values():
			if n in instanced_chunk_names:
				loaded_chunk_names_copy.erase(n)

		if not loaded_chunk_names_copy.empty():
			for lc in loaded_chunks.keys():
				if loaded_chunks[lc] in loaded_chunk_names_copy:
					loaded_chunks.erase(lc)

				
func _unload_chunk(vector: Vector2) -> void:
	var chunk_name: String = loaded_chunks[vector]
	var loaded_chunk = parent.chunks.get_node_or_null(chunk_name)
	if loaded_chunk:
		loaded_chunk.call_deferred("queue_free")
		loaded_chunks.erase(vector)
	
	var loaded_y_sort = parent.props_y_sort.get_node_or_null(chunk_name)
	if loaded_y_sort:
		loaded_y_sort.call_deferred("queue_free")

	var loaded_back_buffer_y_sort = parent.back_buffer_y_sort.get_node_or_null(chunk_name)
	if loaded_back_buffer_y_sort:
		loaded_back_buffer_y_sort.call_deferred("queue_free")

###############################################################################
# Public functions                                                            #
###############################################################################

func load_chunk(chunk_position: Vector2, instance_position: Vector2) -> void:
	"""
	Load a specific chunk from all_chunks at a specific position.
	"""
	var chunk_instance = all_chunks[chunk_position.x][chunk_position.y].instance()
	chunk_instance.global_position = instance_position
	chunk_instance.name += str(chunk_position)
	loaded_chunks[chunk_position] = chunk_instance.name
	parent.chunks.add_child(chunk_instance)

func load_chunks_for_named_chunk(chunk_name: String) -> void:
	"""
	Loads all surrounding chunks for a given chunk name.
	"""
	for key in loaded_chunks:
		if loaded_chunks[key] == chunk_name:
			_load_chunks(key)
