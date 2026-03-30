class_name LocationData
extends RefCounted

var id: String
var name: String
var location_type: String
var region_id: String
var tile_x: int
var tile_y: int
var sub_scene_path: String
var is_enterable: bool
var metadata: Dictionary

func _init(
	p_id: String = "",
	p_name: String = "",
	p_location_type: String = "landmark",
	p_region_id: String = "",
	p_tile_x: int = 0,
	p_tile_y: int = 0,
	p_sub_scene_path: String = "",
	p_is_enterable: bool = true,
	p_metadata: Dictionary = {}
):
	id = p_id
	name = p_name
	location_type = p_location_type
	region_id = p_region_id
	tile_x = p_tile_x
	tile_y = p_tile_y
	sub_scene_path = p_sub_scene_path
	is_enterable = p_is_enterable
	metadata = p_metadata.duplicate(true)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"location_type": location_type,
		"region_id": region_id,
		"tile_x": tile_x,
		"tile_y": tile_y,
		"sub_scene_path": sub_scene_path,
		"is_enterable": is_enterable,
		"metadata": metadata.duplicate(true)
	}

func from_dict(data: Dictionary) -> LocationData:
	id = data.get("id", "")
	name = data.get("name", "")
	location_type = data.get("location_type", "landmark")
	region_id = data.get("region_id", "")
	tile_x = data.get("tile_x", 0)
	tile_y = data.get("tile_y", 0)
	sub_scene_path = data.get("sub_scene_path", "")
	is_enterable = data.get("is_enterable", true)
	metadata = data.get("metadata", {}).duplicate(true)
	return self
