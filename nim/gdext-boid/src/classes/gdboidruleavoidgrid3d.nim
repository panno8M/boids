import std/[sets]

import gdext
import gdext/classes/[gdGridMap]

import global
import sparsegrids
import classes/[gdBoidController3D]

type BoidRuleAvoidGrid3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.2
  range*: int = 2
  sensingShape*: GridShape = GridShape.sphere(2)
  collisionMap: HashSet[Vector3i]

gdexport BoidRuleAvoidGrid3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleAvoidGrid3D): int = self.range,
  setter= proc(self: BoidRuleAvoidGrid3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)

proc loadCellMap*(self: BoidRuleAvoidGrid3D) {.gdsync.} =
  for cell in self.controller.cellMapInstance.getUsedCells:
    self.collisionMap.incl cell


proc avoidGrid(self: BoidRuleAvoidGrid3D; boid: var Boid) =
  var move: Vector3
  for delta in self.sensingShape:
    let np = boid.cell + delta
    if np in self.collisionMap:
      move -= delta

  if move != Vector3.Zero:
    boid.acceleration += move * self.factor

proc update(self: BoidRuleAvoidGrid3D; phase: ProcessPhase) {.gdsync.} =
  case phase
  of ProcessPhaseAcceleration:
    for i, boid in self.controller.boids.mpairs:
      if likely(self.factor != 0):
        self.avoidGrid(boid)
  of ProcessPhaseVelocity:
    discard

method ready(self: BoidRuleAvoidGrid3D) {.gdsync.} =
  discard (self/"..").connect("phased_process", self.callable"update")
  discard self.callDeferred("load_cell_map")