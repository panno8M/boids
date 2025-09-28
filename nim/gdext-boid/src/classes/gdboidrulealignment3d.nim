import gdext

import sparsegrids
import classes/[gdBoidController3D]

type BoidRuleAlignment3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.05
  range*: int = 2
  sensingShape*: GridShape = GridShape.sphere(2)
  target*: BoidController3D

gdexport BoidRuleAlignment3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleAlignment3D): int = self.range,
  setter= proc(self: BoidRuleAlignment3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)
gdexport BoidRuleAlignment3D.target

proc getFlock(self: BoidRuleAlignment3D): BoidController3D =
  if self.target.isNil:
    self.controller
  else:
    self.target

proc alignment(self: BoidRuleAlignment3D; flock: BoidController3D; boid: BoidAgent3D) =
  var sum: Vector3
  var count: int
  for other in flock.cellMap.neighborBoids(boid.cell, self.sensingShape):
    sum += other.v
    inc count
  boid.v += ((sum/count) - boid.v) * self.factor

method update(self: BoidRuleAlignment3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return

  let flock = self.getFlock
  case phase
  of ProcessPhaseAcceleration:
    discard
  of ProcessPhaseVelocity:
    for boid in self.controller.boids:
      if likely(boid.enabled):
        self.alignment(flock, boid)
