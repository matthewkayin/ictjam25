extends TileMap

var astar: AStarGrid2D

const DIRECTIONS = [
    Vector2i.UP,
    Vector2i(1, -1),
    Vector2i.RIGHT,
    Vector2i(1, 1),
    Vector2i.DOWN,
    Vector2i(-1, 1),
    Vector2i.LEFT,
    Vector2i(-1, -1)
]

func _ready():
    var min_x = 0
    var min_y = 0
    var max_x = 0
    var max_y = 0
    for cell in get_used_cells(0):
        min_x = min(min_x, cell.x)
        max_x = max(min_x, cell.x)
        min_y = min(min_y, cell.y)
        max_y = max(min_y, cell.y)

    astar = AStarGrid2D.new()
    astar.region = Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)
    astar.cell_size = Vector2i(16, 16)
    astar.update()

    for cell in get_used_cells(0):
        var block_cell = false
        for direction in DIRECTIONS:
            var tile_data = get_cell_tile_data(1, cell + direction)
            if tile_data and tile_data.get_collision_polygons_count(0) != 0:
                block_cell = true
        if block_cell:
            astar.set_point_solid(cell, true)

func pathfind(from: Vector2, to: Vector2):
    return astar.get_point_path(local_to_map(from), local_to_map(to))
