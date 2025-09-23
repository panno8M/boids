import gdext

import global
import sparsegrids
import classes/[gdBoidController3D]

type BoidRuleSeparation3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.01
  range*: int = 1
  sensingShape*: GridShape = GridShape.sphere(1)

gdexport BoidRuleSeparation3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleSeparation3D): int = self.range,
  setter= proc(self: BoidRuleSeparation3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)

proc separation(self: BoidRuleSeparation3D; boid: var Boid) =
  var move: Vector3
  for other in self.controller.cellMap.neighborBoids(boid.cell, self.sensingShape):
    move += boid.position - self.controller.boids[other].position
  boid.acceleration += move * self.factor

proc update(self: BoidRuleSeparation3D) {.gdsync.} =
  for i, boid in self.controller.boids.mpairs:
    if likely(self.factor != 0):
      self.separation(boid)

method ready(self: BoidModule3D) {.gdsync.} =
  discard (self/"..").connect("fix_acceleration", self.callable"update")