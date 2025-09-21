import gdext
import gdext/classes/[gdNode3D]
import classes/[gdBoidRule3D]

import global
import sparsegrids

type BoidRuleCohesion3D* {.gdsync.} = ptr object of BoidRule3D
  factor*: float = 0.005
  range*: int = 2
  sensingShape*: GridShape = GridShape.sphere(2)

gdexport BoidRuleCohesion3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleCohesion3D): int = self.range,
  setter= proc(self: BoidRuleCohesion3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)

proc cohesion(self: BoidRuleCohesion3D; boid: var Boid) =
  var center: Vector3
  var count: int
  for other in self.shared.cellMap.neighborBoids(boid.cell, self.sensingShape):
    center += self.shared.boids[other].position
    inc count
  boid.acceleration += ((center / count) - boid.position) * self.factor

proc update(self: BoidRuleCohesion3D) {.gdsync.} =
  for i, boid in self.shared.boids.mpairs:
    if likely(self.factor != 0):
      self.cohesion(boid)

method ready(self: BoidRule3D) {.gdsync.} =
  discard (self/"..").connect("fix_acceleration", self.callable"update")