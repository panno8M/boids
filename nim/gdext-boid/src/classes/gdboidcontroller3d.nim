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
    boids*: seq[Boid]
    cellMapStatus*: GridMapStatus
    cellMapInstance*: GridMap
    controlMinSpeed*: float = 5
    controlMaxSpeed*: float = 15
    controlMaxAcceleration*: float = 75

  BoidModule3D* {.gdsync.} = ptr object of Node3D
    controller*: BoidController3D

  ProcessPhase* = enum
    ProcessPhaseAcceleration
    ProcessPhaseVelocity

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

proc running*(self: BoidController3D): bool =
  not self.pausing

method ready*(self: BoidController3D) {.gdsync.} =
  if not Engine.isEditorHint:
    self.cellMap = initTable[Vector3i, Cell](1024)

method enterTree*(self: BoidModule3D) {.gdsync.} =
  self.controller = self.getParent.as(BoidController3D)
  discard self.controller.connect("phased_process", self.callable"update")

proc phasedProcess*(self: BoidController3D; phase: ProcessPhase): Error {.gdsync, signal.}

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if not Engine.isEditorHint:
    if self.running:
      for i, boid in self.boids.mpairs:
        reset boid.acceleration

      discard self.phasedProcess(ProcessPhaseAcceleration)

      for i, boid in self.boids.mpairs:
        boid.acceleration = boid.acceleration.limitLength(self.controlMaxAcceleration * delta)
        boid.velocity += boid.acceleration

      discard self.phasedProcess(ProcessPhaseVelocity)

      for i, boid in self.boids.mpairs:
        let length = boid.velocity.length
        if length < self.controlMinSpeed or self.controlMaxSpeed < length:
          boid.velocity = (boid.velocity/length) * length.clamp(self.controlMinSpeed, self.controlMaxSpeed)

        boid.position += boid.velocity * delta
        let newcell = self.cellMapStatus.localToMap(boid.position)
        if boid.cell != newcell:
          self.cellMap.moveBoid(boid.cell, newcell, i)
          boid.cell = newcell

        if likely(boid.velocity != Vector3.Zero):
          boid.agent.lookAt(boid.position + boid.velocity)

        boid.agent.position = boid.position
