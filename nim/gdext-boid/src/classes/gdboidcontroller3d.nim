import gdext
import gdext/classes/[gdNode3D]
import gdext/classes/[gdGridMap, gdEngine]
import std/[hashes, tables]
import sparseGrids
import timemeasure
import global

export gdNode3D

type
  BoidController3D* {.gdsync.} = ptr object of Node3D
    pausing*: bool
    cellMap*: SparseGrid[Cell]
    boids*: seq[BoidAgent3D]
    cellMapStatus*: GridMapStatus
    cellMapInstance*: GridMap
    controlMinSpeed*: float = 5
    controlMaxSpeed*: float = 15
    controlMaxAcceleration*: float = 75

  BoidModule3D* {.gdsync.} = ptr object of Node3D
    enabled* {.gdexport.}: bool = true
    controller*: BoidController3D

  BoidAgent3D* {.gdsync.} = ptr object of Node3D
    enabled* {.gdexport.}: bool = true
    controller* {.gdexport: Appearance.storage.}: BoidController3D
    p*: Vector3
    v*: Vector3
    a*: Vector3
    cell*: Vector3i

  Cell* = object
    boids*: seq[BoidAgent3D]

  ProcessPhase* = enum
    ProcessPhaseAcceleration
    ProcessPhaseVelocity
    ProcessPhasePosture

# =================================== Properties ===================================

BoidController3D.bind ProcessPhase

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
gdexport BoidController3D.controlMinSpeed
gdexport BoidController3D.controlMaxSpeed
gdexport BoidController3D.controlMaxAcceleration

proc getAgentCount*(self: BoidController3D): Int {.gdsync.} =
  Int(self.boids.len)

# =================================== Functions ===================================

iterator neighborBoids*(grid: var SparseGrid[Cell]; pos: Vector3i; gridShape: GridShape): BoidAgent3D =
  for cell in grid.neighbors(pos, gridShape):
    for boid in cell.boids:
      yield boid

proc allBoids*(grid: SparseGrid[Cell]): seq[BoidAgent3D] =
  for cell in grid.values:
    result.add(cell.boids)

proc addBoid*(grid: var SparseGrid[Cell]; pos: Vector3i; boid: BoidAgent3D) =
  grid.mGetOrPut(pos).boids.add boid

proc removeBoidUnsafe*(grid: var SparseGrid[Cell]; pos: Vector3i; boid: BoidAgent3D) =
  let map = addr grid[pos].boids
  map[].del map[].find boid
  if map[].len == 0:
    grid.del(pos)

proc removeBoid*(grid: var SparseGrid[Cell]; pos: Vector3i; boid: BoidAgent3D) =
  if grid.hasKey(pos):
    removeBoidUnsafe(grid, pos, boid)

proc moveBoid*(grid: var SparseGrid[Cell]; src, dst: Vector3i; boid: BoidAgent3D) =
  grid.removeBoidUnsafe(src, boid)
  grid.addBoid(dst, boid)

proc running*(self: BoidController3D): bool =
  not self.pausing

method ready*(self: BoidController3D) {.gdsync.} =
  if not Engine.isEditorHint:
    self.cellMap = initTable[Vector3i, Cell](1024)


method update*(self: BoidModule3D; phase: ProcessPhase) {.gdsync, base.} = discard
proc onPhasedProcess*(self: BoidModule3D; phase: ProcessPhase) {.gdsync, name: "_on_phased_process".} =
  if self.enabled:
    self.update(phase)

method enterTree*(self: BoidModule3D) {.gdsync.} =
  self.controller = self.getParent.as(BoidController3D)
  discard self.controller.connect("phased_process", self.callable"_on_phased_process")

proc phasedProcess*(self: BoidController3D; phase: ProcessPhase): Error {.gdsync, signal.}

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if not Engine.isEditorHint:
    if self.running:
      for boid in self.boids:
        reset boid.a

      discard self.phasedProcess(ProcessPhaseAcceleration)

      for boid in self.boids:
        boid.a = boid.a.limitLength(self.controlMaxAcceleration * delta)
        boid.v += boid.a

      discard self.phasedProcess(ProcessPhaseVelocity)

      for boid in self.boids:
        if likely(boid.enabled):
          let length = boid.v.length
          if length < self.controlMinSpeed or self.controlMaxSpeed < length:
            boid.v = (boid.v/length) * length.clamp(self.controlMinSpeed, self.controlMaxSpeed)
          boid.p += boid.v * delta

      discard self.phasedProcess(ProcessPhasePosture)

      for boid in self.boids:
          let newcell = self.cellMapStatus.localToMap(boid.p)
          if boid.cell != newcell:
            self.cellMap.moveBoid(boid.cell, newcell, boid)
            boid.cell = newcell

          boid.position = boid.p
