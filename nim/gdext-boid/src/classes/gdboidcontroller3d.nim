import gdext
import gdext/classes/[gdNode3D]
import gdext/classes/[gdGridMap, gdEngine]
import std/[sets, hashes, importutils, tables]
import sparseGrids
import timemeasure
import global
import classes/[gdBoidSpawner3D]

type
  BoidController3D* {.gdsync, tool.} = ptr object of Node3D
    shared*: SharedData
    spawner: BoidSpawner3D
    collisionMapInstance: GridMap
    leader*: Node3D
    cohesion_factor*: float = 0.05
    cohesion_range*: int = 2
    cohesionSensingShape: GridShape
    separation_factor*: float = 0.005
    separation_range*: int = 1
    separationSensingShape: GridShape
    alignment_factor*: float = 0.05
    alignment_range*: int = 2
    alignmentSensingShape: GridShape
    control_max_acceleration*: float = 75
    collisionMap: HashSet[Vector3i]


# =================================== Cell Map ===================================

iterator neighborBoids(grid: var SparseGrid[Cell]; pos: Vector3i; gridShape: GridShape): int =
  for cell in grid.neighbors(pos, gridShape):
    for boid in cell.boids:
      yield boid

proc allBoids(grid: SparseGrid[Cell]): seq[int] =
  var res: seq[int] = @[]
  for cell in grid.values:
    res.add(cell.boids)
  res

proc updateSensingMap(self: BoidController3D) =
    self.cohesionSensingShape = GridShape.sphere(self.cohesion_range)
    self.separationSensingShape = GridShape.sphere(self.separation_range)
    self.alignmentSensingShape = GridShape.sphere(self.alignment_range)

proc loadCollisionMap(self: BoidController3D; map: GridMap) =
  self.collisionMapInstance = map
  self.shared.collisionMapStatus = self.collisionMapInstance.getStatus
  self.updateSensingMap()
  for cell in map.getUsedCells:
    self.collisionMap.incl cell

# =================================== Properties ===================================
gdexport "collision_map",
  getter= proc(self: BoidController3D): GridMap = self.collisionMapInstance,
  setter= proc(self: BoidController3D; value: GridMap) =
    self.loadCollisionMap value

gdexport BoidController3D.leader

gdexport[BoidController3D] "auto_instantiate", Appearance.group("auto_instantiate")

gdexport "pausing",
  getter= proc(self: BoidController3D): bool =
    self.shared.pausing,
  setter= proc(self: BoidController3D; value: bool) =
    self.shared.pausing = value

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
gdexport "control_min_speed",
  getter= proc(self: BoidController3D): float = self.shared.control_min_speed,
  setter= proc(self: BoidController3D; value: float) = self.shared.control_min_speed = value
gdexport "control_max_speed",
  getter= proc(self: BoidController3D): float = self.shared.control_max_speed,
  setter= proc(self: BoidController3D; value: float) = self.shared.control_max_speed = value
gdexport BoidController3D.control_max_acceleration

# =================================== Functions ===================================

method onInit*(self: BoidController3D) =
  new self.shared

method ready*(self: BoidController3D) {.gdsync.} =
  if not Engine.isEditorHint:
    self.shared.cellMap = initTable[Vector3i, Cell](1024)
    for child in self.getChildren:
      if self.spawner == nil and child of BoidSpawner3D:
        self.spawner = child as BoidSpawner3D
        self.spawner.shared = self.shared

method getConfigurationWarnings*(self: BoidController3D): PackedStringArray {.gdsync.} =
  var
    boidSpawner3DCount: int
  for child in self.getChildren:
    if child of BoidSpawner3D:
      inc boidSpawner3DCount

  case boidSpawner3DCount
  of 0:
    result.add "no BoidSpawner3D found"
  of 1:
    discard
  else:
    result.add "more than one BoidSpawner3Ds found"

proc cohesion(self: BoidController3D; boid: var Boid) =
  var center: Vector3
  var count: int
  for other in self.shared.cellMap.neighborBoids(boid.cell, self.cohesionSensingShape):
    center += self.shared.boids[other].position
    inc count
  boid.acceleration += ((center / count) - boid.position) * self.cohesion_factor

proc separation(self: BoidController3D; boid: var Boid) =
  var move: Vector3
  for other in self.shared.cellMap.neighborBoids(boid.cell, self.separationSensingShape):
    move += boid.position - self.shared.boids[other].position
  boid.acceleration += move * self.separation_factor

proc alignment(self: BoidController3D; boid: var Boid) =
  var sum: Vector3
  var count: int
  for other in self.shared.cellMap.neighborBoids(boid.cell, self.alignmentSensingShape):
    sum += self.shared.boids[other].velocity
    inc count
  boid.velocity += ((sum/count) - boid.velocity) * self.alignment_factor

proc interactCollisionMap(self: BoidController3D; boid: var Boid) =
  var move: Vector3
  for delta in self.cohesionSensingShape:
    let np = boid.cell + delta
    if np in self.collisionMap:
      move -= delta

  if move != Vector3.Zero:
    boid.acceleration += move * 0.2

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if not Engine.isEditorHint:
    if self.shared.running:
      for i, boid in self.shared.boids.mpairs:

        reset boid.acceleration

        if likely(self.cohesion_factor != 0):
          self.cohesion(boid)
        if likely(self.separation_factor != 0):
          self.separation(boid)

        self.interactCollisionMap(boid)

        boid.acceleration = boid.acceleration.limit_length(self.control_max_acceleration * delta)
        boid.velocity += boid.acceleration

        if likely(self.alignment_factor != 0):
          self.alignment(boid)

        let length = boid.velocity.length
        if length < self.shared.control_min_speed or self.shared.control_max_speed < length:
          boid.velocity = (boid.velocity/length) * length.clamp(self.shared.control_min_speed, self.shared.control_max_speed)

        boid.position += boid.velocity * delta
        let newcell = self.shared.collisionMapStatus.localToMap(boid.position)
        if boid.cell != newcell:
          self.shared.cellMap.moveBoid(boid.cell, newcell, i)
          boid.cell = newcell

        if likely(boid.velocity != Vector3.Zero):
          boid.agent.lookAt(boid.position + boid.velocity)

        boid.agent.position = boid.position
