extends NavigationRegion2D

func _ready():
    var tilemap = get_node("../tilemap")
    var obstacles = NavigationMeshSourceGeometryData2D.new()
    for cell in tilemap.get_used_cells(1):
        if tilemap.get_cell_tile_data(1, cell).get_collision_polygons_count(0) != 0:
            var obstacle_outline = PackedVector2Array([
                tilemap.map_to_local(cell) + Vector2(-16, -16),
                tilemap.map_to_local(cell) + Vector2(32, -16),
                tilemap.map_to_local(cell) + Vector2(32, 32),
                tilemap.map_to_local(cell) + Vector2(-16, 32)
            ])
            obstacles.add_obstruction_outline(obstacle_outline)
    NavigationServer2D.bake_from_source_geometry_data(navigation_polygon, obstacles)
