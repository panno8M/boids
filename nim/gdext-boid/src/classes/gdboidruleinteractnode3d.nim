import gdext
import gdext/classes/[gdNode3D]

import classes/[gdBoidController3D]

type BoidRuleInteractNode3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float
  range*: float = 10
  squaredRange: float = 100
  target*: Node3D

gdexport BoidRuleInteractNode3D.factor, Appearance.range(0, 5)
gdexport "range",
  proc(self: BoidRuleInteractNode3D): float = self.range,
  proc(self: BoidRuleInteractNode3D; value: float) =
    self.range = value
    self.squaredRange = value * value
gdexport BoidRuleInteractNode3D.target

proc interact(self: BoidRuleInteractNode3D; targetpos: Vector3; boid: BoidAgent3D) =
  let delta = boid.p - targetpos
  if delta.lengthSquared < self.squaredRange:
    boid.a += delta * self.factor

method update(self: BoidRuleInteractNode3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return
  if phase != ProcessPhaseAcceleration: return

  let targetpos = self.target.position
  for boid in self.controller.boids.alive:
    if likely(boid.enabled):
      self.interact(targetpos, boid)
