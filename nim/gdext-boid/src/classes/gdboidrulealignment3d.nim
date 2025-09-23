import gdext
import gdext/classes/[gdNode3D]

import global
import sparsegrids
import classes/[gdBoidModule3D]

type BoidRuleAlignment3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.05
  range*: int = 2
  sensingShape*: GridShape = GridShape.sphere(2)

gdexport BoidRuleAlignment3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleAlignment3D): int = self.range,
  setter= proc(self: BoidRuleAlignment3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)

proc alignment(self: BoidRuleAlignment3D; boid: var Boid) =
  var sum: Vector3
  var count: int
  for other in self.controller.cellMap.neighborBoids(boid.cell, self.sensingShape):
    sum += self.controller.boids[other].velocity
    inc count
  boid.velocity += ((sum/count) - boid.velocity) * self.factor

proc update(self: BoidRuleAlignment3D) {.gdsync.} =
  for i, boid in self.controller.boids.mpairs:
    if likely(self.factor != 0):
      self.alignment(boid)

method ready(self: BoidModule3D) {.gdsync.} =
  discard (self/"..").connect("fix_acceleration", self.callable"update")