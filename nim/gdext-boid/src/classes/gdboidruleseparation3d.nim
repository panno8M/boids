import gdext

import sparsegrids
import classes/[gdBoidController3D]

type BoidRuleSeparation3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.01
  range*: int = 1
  sensingShape*: GridShape = GridShape.sphere(1)
  target*: BoidController3D

gdexport BoidRuleSeparation3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleSeparation3D): int = self.range,
  setter= proc(self: BoidRuleSeparation3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)
gdexport BoidRuleSeparation3D.target

proc getFlock(self: BoidRuleSeparation3D): BoidController3D =
  if self.target.isNil:
    self.controller
  else:
    self.target

proc separation(self: BoidRuleSeparation3D; flock: BoidController3D; boid: BoidAgent3D) =
  var move: Vector3
  for other in flock.cellMap.neighborBoids(boid.cell, self.sensingShape):
    move += boid.p - other.p
  boid.a += move * self.factor

method update(self: BoidRuleSeparation3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0):return
  if phase != ProcessPhaseAcceleration: return

  let flock = self.getFlock
  for boid in self.controller.boids:
    if likely(boid.enabled):
      self.separation(flock, boid)
