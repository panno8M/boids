import gdext
import gdext/classes/[gdNode3D]
import gdext/classes/[gdGridMap, gdEngine]
import std/[hashes, tables]
import sparseGrids
import timemeasure
import global

type
  BoidController3D* {.gdsync.} = ptr object of Node3D
    pausing*: bool
    cellMap*: SparseGrid[Cell]
    boids*: seq[Boid]
    cellMapStatus*: GridMapStatus
    controlMinSpeed*: float = 5
    controlMaxSpeed*: float = 15
    fixAcceleration*: seq[proc()]
    fixVelocity*: seq[proc()]
    cellMapInstance*: GridMap
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
    self.cellMapStatus = self.cellMapInstance.getStatus

gdexport[BoidController3D] "auto_instantiate", Appearance.group("auto_instantiate")

gdexport "pausing",
  getter= proc(self: BoidController3D): bool =
    self.pausing,
  setter= proc(self: BoidController3D; value: bool) =
    self.pausing = value

gdexport[BoidController3D] "Control", Appearance.group("control")
gdexport "control_min_speed",
  getter= proc(self: BoidController3D): float = self.control_min_speed,
  setter= proc(self: BoidController3D; value: float) = self.control_min_speed = value
gdexport "control_max_speed",
  getter= proc(self: BoidController3D): float = self.control_max_speed,
  setter= proc(self: BoidController3D; value: float) = self.control_max_speed = value
gdexport BoidController3D.control_max_acceleration

# =================================== Functions ===================================
proc running*(self: BoidController3D): bool =
  not self.pausing

method ready*(self: BoidController3D) {.gdsync.} =
  if not Engine.isEditorHint:
    self.cellMap = initTable[Vector3i, Cell](1024)

proc fix_acceleration(self: BoidController3D): Error {.gdsync, signal.}
proc fix_velocity(self: BoidController3D): Error {.gdsync, signal.}

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if not Engine.isEditorHint:
    if self.running:
      for i, boid in self.boids.mpairs:
        reset boid.acceleration

      discard self.fix_acceleration()

      for i, boid in self.boids.mpairs:
        boid.acceleration = boid.acceleration.limit_length(self.control_max_acceleration * delta)
        boid.velocity += boid.acceleration

      discard self.fix_velocity()

      for i, boid in self.boids.mpairs:
        let length = boid.velocity.length
        if length < self.control_min_speed or self.control_max_speed < length:
          boid.velocity = (boid.velocity/length) * length.clamp(self.control_min_speed, self.control_max_speed)

        boid.position += boid.velocity * delta
        let newcell = self.cellMapStatus.localToMap(boid.position)
        if boid.cell != newcell:
          self.cellMap.moveBoid(boid.cell, newcell, i)
          boid.cell = newcell

        if likely(boid.velocity != Vector3.Zero):
          boid.agent.lookAt(boid.position + boid.velocity)

        boid.agent.position = boid.position
