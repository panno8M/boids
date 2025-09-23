import gdext
import gdext/classes/[gdNode3D]
import gdext/classes/[gdGridMap, gdEngine]
import std/[hashes, tables]
import sparseGrids
import timemeasure
import global

type
  BoidController3D* {.gdsync.} = ptr object of Node3D
    shared*: SharedData
    cellMapInstance*: GridMap
    alignment_factor*: float = 0.05
    alignment_range*: int = 2
    alignmentSensingShape: GridShape = GridShape.sphere(2)
    control_max_acceleration*: float = 75

# =================================== Cell Map ===================================

proc allBoids(grid: SparseGrid[Cell]): seq[int] =
  var res: seq[int] = @[]
  for cell in grid.values:
    res.add(cell.boids)
  res

# =================================== Properties ===================================
gdexport "cell_map",
  getter= proc(self: BoidController3D): GridMap = self.cellMapInstance,
  setter= proc(self: BoidController3D; value: GridMap) =
    self.cellMapInstance = value
    self.shared.cellMapStatus = self.cellMapInstance.getStatus

gdexport[BoidController3D] "auto_instantiate", Appearance.group("auto_instantiate")

gdexport "pausing",
  getter= proc(self: BoidController3D): bool =
    self.shared.pausing,
  setter= proc(self: BoidController3D; value: bool) =
    self.shared.pausing = value

gdexport[BoidController3D] "Rule: Alignment", Appearance.group("alignment")
gdexport BoidController3D.alignment_factor, Appearance.range(0, 1)
gdexport "alignment_range",
  getter= proc(self: BoidController3D): int = self.alignment_range,
  setter= proc(self: BoidController3D; value: int) =
    self.alignment_range = value
    self.alignmentSensingShape = GridShape.sphere(self.alignment_range),
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

proc alignment(self: BoidController3D; boid: var Boid) =
  var sum: Vector3
  var count: int
  for other in self.shared.cellMap.neighborBoids(boid.cell, self.alignmentSensingShape):
    sum += self.shared.boids[other].velocity
    inc count
  boid.velocity += ((sum/count) - boid.velocity) * self.alignment_factor

proc fix_acceleration(self: BoidController3D): Error {.gdsync, signal.}

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if not Engine.isEditorHint:
    if self.shared.running:
      for i, boid in self.shared.boids.mpairs:
        reset boid.acceleration

      discard self.fix_acceleration()

      for i, boid in self.shared.boids.mpairs:
        boid.acceleration = boid.acceleration.limit_length(self.control_max_acceleration * delta)
        boid.velocity += boid.acceleration

      for i, boid in self.shared.boids.mpairs:
        if likely(self.alignment_factor != 0):
          self.alignment(boid)

      for i, boid in self.shared.boids.mpairs:
        let length = boid.velocity.length
        if length < self.shared.control_min_speed or self.shared.control_max_speed < length:
          boid.velocity = (boid.velocity/length) * length.clamp(self.shared.control_min_speed, self.shared.control_max_speed)

        boid.position += boid.velocity * delta
        let newcell = self.shared.cellMapStatus.localToMap(boid.position)
        if boid.cell != newcell:
          self.shared.cellMap.moveBoid(boid.cell, newcell, i)
          boid.cell = newcell

        if likely(boid.velocity != Vector3.Zero):
          boid.agent.lookAt(boid.position + boid.velocity)

        boid.agent.position = boid.position
