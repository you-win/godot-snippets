# ChunkLoader

Add `ChunkLoader.tscn` as a child of a Node2D and attach `ChunkLoader.gd` as a script to `chunk-loader.tscn`. You will need to manually load the starting chunk by calling `load_chunk(chunk_position, instance_position)` from `ChunkLoader.gd`.

By default, the ChunkLoader will load in the surrounding 8 chunks for a given chunk. Currently, I have configured the ChunkLoader to check the player's global position from a GameManager singleton but this can be changed in the `physics_process(delta)` function in `ChunkLoader.gd`.

ChunkLoader will hold 16 chunks in memory before freeing a chunk. This can be configured in the `_unload_chunks(...)` function in `ChunkLoader.gd`.

