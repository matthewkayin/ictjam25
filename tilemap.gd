extends TileMap

var map_width: int
var map_height: int

enum Direction {
    NORTH,
    NORTHEAST,
    EAST,
    SOUTHEAST,
    SOUTH,
    SOUTHWEST,
    WEST,
    NORTHWEST,
    COUNT
}

const DIRECTION_VECTOR2I = [
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
    var max_x = 0
    var max_y = 0
    for cell in get_used_cells(0):
        max_x = max(max_x, cell.x)
        max_y = max(max_y, cell.y)
    map_width = max_x + 1
    map_height = max_y + 1

func pathfind_node_score(pathfind_node):
    return pathfind_node.cost + pathfind_node.distance

func pathfind(from_position: Vector2, from_size: Vector2i, to_position: Vector2):
    var from_cell = local_to_map(from_position) - (from_size / 2)
    var to_cell = local_to_map(to_position)
    print("From: ", from_cell, " To: ", to_cell)

    var frontier = [
        {
            cell = from_cell,
            parent = -1,
            cost = 0,
            distance = 0
        }
    ]
    var explored = []
    var explored_indices = []
    for index in range(0, map_width * map_height):
        explored_indices.push_back(-1)

    var path_end = null
    while not frontier.is_empty():
        var smallest_index = 0
        for index in range(1, frontier.size()):
            if pathfind_node_score(frontier[index]) < pathfind_node_score(frontier[smallest_index]):
                smallest_index = index
        var smallest = frontier[smallest_index]
        frontier.remove_at(smallest_index)

        if smallest.cell == to_cell:
            path_end = smallest
            break

        explored_indices[smallest.cell.x + (smallest.cell.y * map_width)] = explored.size() - 1
        explored.push_back(smallest)

        const CHILD_DIRECTIONS = [
            Direction.NORTH,
            Direction.EAST,
            Direction.SOUTH,
            Direction.WEST,
            Direction.NORTHEAST,
            Direction.SOUTHEAST,
            Direction.SOUTHWEST,
            Direction.NORTHWEST
        ]
        var is_adjacent_direction_blocked = [true, true, true, true]
        for direction_index in range(0, CHILD_DIRECTIONS.size()):
            var direction = CHILD_DIRECTIONS[direction_index]
            var child_cell = smallest.cell + DIRECTION_VECTOR2I[direction]
            var child = {
                cell = child_cell,
                parent = explored.size() - 1,
                cost = smallest.cost + 1,
                distance = child_cell.distance_to(to_cell)
            }

            if child_cell.x < 0 or child_cell.y < 0 or child_cell.x + from_size.x > map_width or child_cell.y + from_size.y > map_height:
                continue

            # TODO: check if map is blocked
            var is_blocked = false
            for y in range(child_cell.y, child_cell.y + from_size.y):
                for x in range(child_cell.x, child_cell.x + from_size.x):
                    if get_cell_tile_data(0, Vector2i(x, y)).get_custom_data("blocked"):
                        is_blocked = true
            if is_blocked:
                continue

            # Don't allow diagonal movement through cracks
            if direction % 2 == 0:
                is_adjacent_direction_blocked[direction / 2] = false
            else:
                var next_direction = direction + 1
                if next_direction == Direction.COUNT:
                    next_direction = Direction.NORTH
                var prev_direction = direction - 1
                if is_adjacent_direction_blocked[next_direction / 2] and is_adjacent_direction_blocked[prev_direction / 2]:
                    continue

            # Don't consider already explored children
            if explored_indices[child_cell.x + (child_cell.y * map_width)] != -1:
                continue

            # Don't consider children already in frontier
            var frontier_index = 0
            while frontier_index < frontier.size():
                if frontier[frontier_index].cell == child_cell:
                    break
                frontier_index += 1

            # If it is in the frontier
            if frontier_index < frontier.size():
                if pathfind_node_score(child) < pathfind_node_score(frontier[frontier_index]):
                    frontier[frontier_index] = child
                continue
            else:
                frontier.push_back(child)
        # end for each direction
    # end while not frontier empty

    var path = []
    if path_end != null:
        var current = path_end
        while current.parent != -1:
            path.push_front(map_to_local(current.cell + (from_size / 2)))
            current = explored[current.parent]
    
    return path
