import gdext

import global
import sparsegrids
import classes/[gdBoidController3D]

type BoidRuleCohesion3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.005
  range*: int = 2
  sensingShape*: GridShape = GridShape.sphere(2)
  target*: BoidController3D

gdexport BoidRuleCohesion3D.factor, Appearance.range(0, 1)
gdexport "range",
  getter= proc(self: BoidRuleCohesion3D): int = self.range,
  setter= proc(self: BoidRuleCohesion3D; value: int) =
    self.range = value
    self.sensingShape = GridShape.sphere(value),
  Appearance.range(0, 5)
gdexport BoidRuleCohesion3D.target

proc getFlock(self: BoidRuleCohesion3D): BoidController3D =
  if self.target.isNil:
    self.controller
  else:
    self.target

proc cohesion(self: BoidRuleCohesion3D; flock: BoidController3D; boid: var Boid) =
  var center: Vector3
  var count: int
  for other in flock.cellMap.neighborBoids(boid.cell, self.sensingShape):
    center += flock.boids[other].position
    inc count
  boid.acceleration += ((center / count) - boid.position) * self.factor

method update(self: BoidRuleCohesion3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return

  let flock = self.getFlock
  case phase
  of ProcessPhaseAcceleration:
    for i, boid in self.controller.boids.mpairs:
      self.cohesion(flock, boid)
  of ProcessPhaseVelocity:
    discard
