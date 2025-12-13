import gdext
import gdext/classes/[gdNode3D]

import classes/[gdBoidController3D]

type BoidRuleFollowNode3D* {.gdsync.} = ptr object of BoidModule3D
  factor*: float
  range*: float = 10
  squaredRange: float = 100
  target*: Node3D

gdexport BoidRuleFollowNode3D.factor, Appearance.range(0, 1)
gdexport "range",
  proc(self: BoidRuleFollowNode3D): float = self.range,
  proc(self: BoidRuleFollowNode3D; value: float) =
    self.range = value
    self.squaredRange = value * value
gdexport BoidRuleFollowNode3D.target

proc interact(self: BoidRuleFollowNode3D; targetpos: Vector3; boid: BoidAgent3D) =
  let dir = targetpos - boid.p
  boid.a += dir * self.factor
  let len = dir.length
  if len != 0:
    boid.a -= boid.v / len

method update(self: BoidRuleFollowNode3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return
  if phase != ProcessPhaseAcceleration: return

  let targetpos = self.target.globalPosition
  for boid in self.controller.boids.alive:
    if likely(boid.enabled):
      self.interact(targetpos, boid)
