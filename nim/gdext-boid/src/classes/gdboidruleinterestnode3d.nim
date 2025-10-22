import gdext
import gdext/classes/[gdNode3D]

import classes/[gdBoidController3D]

type BoidRuleInterestNode3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float = 0.01
  range*: float = 10
  squaredRange: float = 100
  target*: Node3D

gdexport BoidRuleInterestNode3D.factor, Appearance.range(0, 1)
gdexport "range",
  proc(self: BoidRuleInterestNode3D): float = self.range,
  proc(self: BoidRuleInterestNode3D; value: float) =
    self.range = value
    self.squaredRange = value * value
gdexport BoidRuleInterestNode3D.target

proc separation(self: BoidRuleInterestNode3D; targetpos: Vector3; boid: BoidAgent3D) =
  let delta = boid.p - targetpos
  if delta.lengthSquared < self.squaredRange:
    boid.a += delta * self.factor

method update(self: BoidRuleInterestNode3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return
  if phase != ProcessPhaseAcceleration: return

  let targetpos = self.target.position
  for boid in self.controller.boids:
    if likely(boid.enabled):
      self.separation(targetpos, boid)
