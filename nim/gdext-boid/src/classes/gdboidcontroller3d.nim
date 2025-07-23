import gdext
import gdext/classes/[gdNode3D, gdPackedScene, gdSceneTree]
import gdext/classes/[gdGridMap]
import std/[tables {.all.}, hashes, times, strformat, importutils]

privateAccess Table

type
  BoidIndex = int ## Index of BoidController3D.boids
  CellShape = seq[Vector3i]
  Cell = object
    boids: seq[BoidIndex]
  CellMap = Table[Vector3i, Cell]
  GridMapStatus = object
    cellSize: Vector3
    centerX, centerY, centerZ: bool
    offset: Vector3
  BoidController3D* {.gdsync, tool.} = ptr object of Node3D
    collision_map: GridMap
    collisionMapStatus: GridMapStatus
    force_subdivision* {.gdexport.}: int = 0
    editorPreview*: bool
    pausing*: bool
    leader*: Node3D
    auto_instantiate_blueprint*: gdref PackedScene
    numOfInstances*: int
    positions: seq[Vector3]
    velocities: seq[Vector3]
    accelerations: seq[Vector3]
    affiliations: seq[Vector3i]
    instances: seq[Node3D]
    auto_instantiate_range*: float = 15
    cohesion_factor*: float = 0.05
    cohesion_range*: int = 2
    cohesionSensingShape: CellShape
    separation_factor*: float = 0.005
    separation_range*: int = 1
    separationSensingShape: CellShape
    alignment_factor*: float = 0.05
    alignment_range*: int = 2
    alignmentSensingShape: CellShape
    control_min_speed*: float = 5
    control_max_speed*: float = 15
    control_max_acceleration*: float = 75
    cellMap: CellMap
    spawnSyncRequired: bool

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

proc getStatus(gridmap: GridMap): GridMapStatus =
  result.cellSize = gridmap.cellSize
  result.centerX = gridmap.cellCenterX
  result.centerY = gridmap.cellCenterY
  result.centerZ = gridmap.cellCenterZ
  result.offset = getOffset(result.cellSize, result.centerX, result.centerY, result.centerZ)

proc localToMap(status: GridMapStatus; worldPosition: Vector3): Vector3i =
  localToMap(worldPosition, status.cellSize)

proc mapToLocal(status: GridMapStatus; mapPosition: Vector3i): Vector3 =
  mapToLocal(mapPosition, status.cellSize, status.offset)

# =================================== Cell Shapes ===================================

proc sphere(_: typedesc[CellShape]; radius: Natural): CellShape =
  let r2 = radius * radius
  for x in -radius..radius:
    for y in -radius..radius:
      for z in -radius..radius:
        if x*x + y*y + z*z <= r2:
          result.add vector3i(int32 x, int32 y, int32 z)

# =================================== Cell Map ===================================

proc getUnsafePtr[A, B](t: var Table[A, B], key: A): ptr B =
  checkIfInitialized()
  var hc: Hash = default(Hash)
  var index = rawGet(t, key, hc)
  if index < 0:
    nil
  else:
    addr t.data[index].val

proc addBoid(grid: var CellMap; pos: Vector3i; boidId: int) =
  grid.mGetOrPut(pos).boids.add boidId

proc removeBoidUnsafe(grid: var CellMap; pos: Vector3i; boidId: int) =
  let map = addr grid[pos].boids
  map[].del map[].find boidId

proc removeBoid(grid: var CellMap; pos: Vector3i; boidId: int) =
  if grid.hasKey(pos):
    removeBoidUnsafe(grid, pos, boidId)

iterator neighborAliveCells(grid: var CellMap; pos: Vector3i; cellShape: CellShape): var Cell =
  for delta in cellShape:
    let np = pos + delta
    let point = grid.getUnsafePtr(np)
    if point != nil:
      yield point[]
iterator neighbors(grid: var CellMap; pos: Vector3i; cellShape: CellShape): int =
  for cell in grid.neighborAliveCells(pos, cellShape):
    for boid in cell.boids:
      yield boid

iterator neighborAliveCellPairs(grid: var CellMap; pos: Vector3i; cellShape: CellShape): (Vector3i, var Cell) =
  for delta in cellShape:
    let np = pos + delta
    let point = grid.getUnsafePtr(np)
    if point != nil:
      yield (np, point[])

proc allBoids(grid: CellMap): seq[int] =
  var res: seq[int] = @[]
  for cell in grid.values:
    res.add(cell.boids)
  res

# =================================== utilities ===================================

proc rand(_: typedesc[Vector3]): Vector3 = vector3(randf(), randf(), randf())
proc signedRand(_: typedesc[Vector3]): Vector3 = (Vector3.rand - 0.5) * 2
proc `+=`[I, T, S](a: var Vector[I, T]; b: Vector[I, S]) {.inline.} = a = a + b

proc enabled(self: BoidController3D): bool =
  not Engine.isEditorHint or self.editorPreview

proc running(self: BoidController3D): bool =
  self.enabled and not self.pausing

proc map[T, S](ratio: T; range: HSlice[S, S]): auto =
  range.a * ratio + range.b * (1 - ratio)

proc spawn(self: BoidController3D): Node3D =
  result = instantiate(self.auto_instantiate_blueprint[]) as Node3D
  let pos = Vector3.signedRand * self.auto_instantiate_range
  let cell = self.collisionMapStatus.localToMap(pos)
  result.setPosition pos
  self.addChild result
  self.instances.add result
  self.positions.add pos
  self.velocities.add Vector3.signedRand.normalized.map(self.control_min_speed..self.control_max_speed)
  self.accelerations.add Vector3.Zero
  self.affiliations.add cell
  self.cellMap.addBoid(cell, self.affiliations.high)

proc destroyLast(self: BoidController3D) =
  queueFree self.instances[^1]
  self.cellMap.removeBoidUnsafe(self.affiliations[^1], self.affiliations.high)
  self.positions.setLen(self.positions.len.pred)
  self.velocities.setLen(self.velocities.len.pred)
  self.accelerations.setLen(self.accelerations.len.pred)
  self.affiliations.setLen(self.affiliations.len.pred)
  self.instances.setLen(self.instances.len.pred)

proc spawnSync(self: BoidController3D) =
  if self.enabled:
    let arr = self.getChildren
    if arr.len != 0 and self.affiliations.len == 0:
      for node in arr:
        self.instances.add node as Node3D
        self.positions.add self.instances[^1].position
        self.velocities.add Vector3.Zero
        self.accelerations.add Vector3.Zero
        self.affiliations.add self.collisionMapStatus.localToMap(self.positions[^1])

    for i in 0..<(self.numOfInstances - self.affiliations.len):
      discard self.spawn()
    for i in 0..<(self.affiliations.len - self.numOfInstances):
      self.destroyLast()
  else:
    for i in 0..<self.affiliations.len:
      self.destroyLast()

proc updateSensingMap(self: BoidController3D) =
    self.cohesionSensingShape = CellShape.sphere(self.cohesion_range)
    self.separationSensingShape = CellShape.sphere(self.separation_range)
    self.alignmentSensingShape = CellShape.sphere(self.alignment_range)

# =================================== Properties ===================================

proc simulation_started*(self: BoidController3D): Error {.gdsync, signal.}
proc simulation_ended*(self: BoidController3D): Error {.gdsync, signal.}
proc simulation_paused*(self: BoidController3D): Error {.gdsync, signal.}
proc simulation_resumed*(self: BoidController3D): Error {.gdsync, signal.}

gdexport "editor_preview",
  getter= proc(self: BoidController3D): bool = self.editorPreview,
  setter= proc(self: BoidController3D; value: bool) =
    self.editorPreview = value
    self.spawnSyncRequired = true
    if self.editorPreview:
      discard self.simulation_started()
    else:
      discard self.simulation_ended()
gdexport "pausing",
  getter= proc(self: BoidController3D): bool = self.pausing,
  setter= proc(self: BoidController3D; value: bool) =
    self.pausing = value
    if self.pausing:
      discard self.simulation_paused()
    else:
      discard self.simulation_resumed()

gdexport "collision_map",
  getter= proc(self: BoidController3D): GridMap = self.collisionMap,
  setter= proc(self: BoidController3D; value: GridMap) =
    self.collisionMap = value
    self.collisionMapStatus = self.collisionMap.getStatus
    self.updateSensingMap()

gdexport BoidController3D.leader

gdexport[BoidController3D] "auto_instantiate", Appearance.group("auto_instantiate")

gdexport BoidController3D.auto_instantiate_blueprint
gdexport BoidController3D.auto_instantiate_range, Appearance.range(0, 100)
gdexport "auto_instantiate_count",
  getter= proc(self: BoidController3D): int = self.numOfInstances,
  setter= proc(self: BoidController3D; value: int) =
    self.numOfInstances = value
    self.spawnSyncRequired = true

gdexport[BoidController3D] "Rule: Cohesion", Appearance.group("cohesion")
gdexport BoidController3D.cohesion_factor, Appearance.range(0, 1)
gdexport "cohesion_range",
  getter= proc(self: BoidController3D): int = self.cohesion_range,
  setter= proc(self: BoidController3D; value: int) =
    self.cohesion_range = value
    self.updateSensingMap(),
  Appearance.range(0, 5)

gdexport[BoidController3D] "Rule: Separation", Appearance.group("separation")
gdexport BoidController3D.separation_factor, Appearance.range(0, 1)
gdexport "separation_range",
  getter= proc(self: BoidController3D): int = self.separation_range,
  setter= proc(self: BoidController3D; value: int) =
    self.separation_range = value
    self.updateSensingMap(),
  Appearance.range(0, 5)

gdexport[BoidController3D] "Rule: Alignment", Appearance.group("alignment")
gdexport BoidController3D.alignment_factor, Appearance.range(0, 1)
gdexport "alignment_range",
  getter= proc(self: BoidController3D): int = self.alignment_range,
  setter= proc(self: BoidController3D; value: int) =
    self.alignment_range = value
    self.updateSensingMap(),
  Appearance.range(0, 5)

gdexport[BoidController3D] "Control", Appearance.group("control")
gdexport BoidController3D.control_min_speed
gdexport BoidController3D.control_max_speed
gdexport BoidController3D.control_max_acceleration

# =================================== Functions ===================================

method ready*(self: BoidController3D) {.gdsync.} =
  self.cellMap = initTable[Vector3i, Cell](1024)
  self.spawnSync()

type TimeBuffer[Steps: static int] = object
  b: array[Steps, float]
  filled: int
  current: int
  min: float = Inf
  max: float
  iteration: int

proc pushavg[Steps](buffer: var TimeBuffer[Steps]; value: float): string =
  buffer.b[buffer.current] = value
  buffer.current = buffer.current.succ mod Steps
  buffer.filled = min(buffer.filled.succ, Steps)
  if buffer.filled == Steps:
    buffer.min = min(buffer.min, value)
  buffer.max = max(buffer.max, value)
  let avg = sum(buffer.b.toOpenArray(0, buffer.filled.pred)) / buffer.filled
  result = fmt"[{buffer.iteration}]: {value} (avg: {avg} min: {buffer.min} max: {buffer.max})"
  inc buffer.iteration

template measure(buffer: TimeBuffer; body): string =
  var start = epochTime()
  body
  buffer.pushavg(epochTime() - start)

var timebuf = TimeBuffer[8]()

proc cohesion(self: BoidController3D; position: Vector3; acceleration: var Vector3; affiliation: Vector3i) =
  var center: Vector3
  var count: int
  for boid in self.cellMap.neighbors(affiliation, self.cohesionSensingShape):
    center += self.positions[boid]
    inc count
  acceleration += ((center / count) - position) * self.cohesion_factor

proc separation(self: BoidController3D; position: Vector3; acceleration: var Vector3; affiliation: Vector3i) =
  var move: Vector3
  for boid in self.cellMap.neighbors(affiliation, self.separationSensingShape):
    move += position - self.positions[boid]
  acceleration += move * self.separation_factor

proc alignment(self: BoidController3D; velocity: var Vector3; affiliation: Vector3i) =
  var sum: Vector3
  var count: int
  for other in self.cellMap.neighbors(affiliation, self.alignmentSensingShape):
    sum += self.velocities[other]
    inc count
  velocity += ((sum/count) - velocity) * self.alignment_factor

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync()
    self.spawnSyncRequired = false
  if self.running:
    print: timebuf.measure:
      for i in 0..<self.numOfInstances:
        let position = addr self.positions[i]
        let velocity = addr self.velocities[i]
        let acceleration = addr self.accelerations[i]
        let affiliation = addr self.affiliations[i]
        let instance = addr self.instances[i]

        reset acceleration[]

        self.cohesion(position[], acceleration[], affiliation[])
        self.separation(position[], acceleration[], affiliation[])

        acceleration[] = acceleration[].limit_length(self.control_max_acceleration * delta)
        velocity[] += acceleration[]

        self.alignment(velocity[], affiliation[])

        let length = velocity[].length
        if length < self.control_min_speed or self.control_max_speed < length:
          velocity[] = (velocity[]/length) * length.clamp(self.control_min_speed, self.control_max_speed)

        position[] += velocity[] * delta
        let newcell = self.collisionMapStatus.localToMap(position[])
        if affiliation[] != newcell:
          self.cellMap.removeBoidUnsafe(affiliation[], i)
          self.cellMap.addBoid(newcell, i)
          affiliation[] = newcell

        if likely(velocity[] != Vector3.Zero):
          instance[].lookAt(position[] + velocity[])

        instance[].position = position[]
