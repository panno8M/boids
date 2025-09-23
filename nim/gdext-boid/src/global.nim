import std/[tables]

import gdext
import gdext/classes/[gdGridMap]
import sparsegrids

type
  BoidIndex* = int ## Index of BoidController3D.boids
  Cell* = object
    boids*: seq[BoidIndex]
  GridMapStatus* = object
    cellSize*: Vector3
    centerX*, centerY*, centerZ*: bool
    offset*: Vector3
  Boid* = object
    position*: Vector3
    velocity*: Vector3
    acceleration*: Vector3
    cell*: Vector3i
    agent*: Node3D
  SharedData* = ref object
    pausing*: bool
    cellMap*: SparseGrid[Cell]
    boids*: seq[Boid]
    cellMapStatus*: GridMapStatus
    controlMinSpeed*: float = 5
    controlMaxSpeed*: float = 15
    fixAcceleration*: seq[proc()]
    fixVelocity*: seq[proc()]

# =================================== GridMap utils ===================================

# -- Implement frequently called processes in-house to reduce overhead. --

proc getOffset(cell_size: Vector3; center_x, center_y, center_z: bool): Vector3 =
  vector3(
    cell_size.x * 0.5 * int(center_x),
    cell_size.y * 0.5 * int(center_y),
    cell_size.z * 0.5 * int(center_z))

proc localToMap(p_world_position: Vector3; cell_size: Vector3): Vector3i =
  (p_world_position / cell_size).floor.vector3i

proc mapToLocal(p_map_position: Vector3i; cell_size: Vector3; offset: Vector3): Vector3 =
  vector3(
    p_map_position.x * cell_size.x + offset.x,
    p_map_position.y * cell_size.y + offset.y,
    p_map_position.z * cell_size.z + offset.z)

proc getStatus*(gridmap: GridMap): GridMapStatus =
  result.cellSize = gridmap.cellSize
  result.centerX = gridmap.cellCenterX
  result.centerY = gridmap.cellCenterY
  result.centerZ = gridmap.cellCenterZ
  result.offset = getOffset(result.cellSize, result.centerX, result.centerY, result.centerZ)

proc localToMap*(status: GridMapStatus; worldPosition: Vector3): Vector3i =
  localToMap(worldPosition, status.cellSize)

proc mapToLocal*(status: GridMapStatus; mapPosition: Vector3i): Vector3 =
  mapToLocal(mapPosition, status.cellSize, status.offset)

# =================================== utilities ===================================

proc rand*(_: typedesc[Vector3]): Vector3 = vector3(randf(), randf(), randf())
proc signedRand*(_: typedesc[Vector3]): Vector3 = (Vector3.rand - 0.5) * 2

proc map*[T, S](ratio: T; range: HSlice[S, S]): auto =
  range.a * ratio + range.b * (1 - ratio)

# =================================== Cell Map ===================================

iterator neighborBoids*(grid: var SparseGrid[Cell]; pos: Vector3i; gridShape: GridShape): int =
  for cell in grid.neighbors(pos, gridShape):
    for boid in cell.boids:
      yield boid

proc addBoid*(grid: var SparseGrid[Cell]; pos: Vector3i; boidId: int) =
  grid.mGetOrPut(pos).boids.add boidId

proc removeBoidUnsafe*(grid: var SparseGrid[Cell]; pos: Vector3i; boidId: int) =
  let map = addr grid[pos].boids
  map[].del map[].find boidId
  if map[].len == 0:
    grid.del(pos)

proc removeBoid*(grid: var SparseGrid[Cell]; pos: Vector3i; boidId: int) =
  if grid.hasKey(pos):
    removeBoidUnsafe(grid, pos, boidId)

proc moveBoid*(grid: var SparseGrid[Cell]; src, dst: Vector3i; boidId: int) =
  grid.removeBoidUnsafe(src, boidId)
  grid.addBoid(dst, boidId)

# =================================== meta data ===================================

proc running*(self: SharedData): bool =
  not self.pausing
