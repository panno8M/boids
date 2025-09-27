import gdext
import gdext/classes/[gdGridMap]

import global
import classes/[gdBoidController3D]

type BoidRuleStayInBounds3D* {.gdsync.} = ptr object of BoidModule3D
  factor* {.gdexport: Appearance.range(0, 1).}: float = 0.2
  bounds* {.gdexport.}: AABB
  threshold* {.gdexport.}: float = 1

proc axisForce(boundpos, size, threshold, pos: float32): float32 =
  if unlikely(pos < boundpos + threshold):
    boundpos + threshold - pos
  elif unlikely(pos > boundpos + size - threshold):
    boundpos + size - threshold - pos
  else:
    0

proc stayInBounds(self: BoidRuleStayInBounds3D; boid: var Boid) =
  boid.acceleration += vector3(
    axisForce(self.bounds.position.x, self.bounds.size.x, self.threshold, boid.position.x),
    axisForce(self.bounds.position.y, self.bounds.size.y, self.threshold, boid.position.y),
    axisForce(self.bounds.position.z, self.bounds.size.z, self.threshold, boid.position.z),
  ) * self.factor

method update(self: BoidRuleStayInBounds3D; phase: ProcessPhase) {.gdsync.} =
  case phase
  of ProcessPhaseAcceleration:
    if likely(self.factor != 0):
      for i, boid in self.controller.boids.mpairs:
        self.stayInBounds(boid)
  of ProcessPhaseVelocity:
    discard
