import gdext
import gdext/classes/[gdGridMap]

import classes/[gdBoidController3D]

type Cache = object
  boundsMin: Vector3
  boundsMax: Vector3

type BoidRuleStayInBounds3D* {.gdsync.} = ptr object of BoidModule3D
  factor* {.gdexport: Appearance.range(0, 1).}: float = 0.2
  bounds*: AABB
  threshold*: float = 1
  cache: Cache

proc createCache(bounds: AABB; threshold: float): Cache =
  Cache(
    boundsMin: bounds.position + threshold,
    boundsMax: bounds.position + bounds.size - threshold,
  )

gdexport "bounds",
  proc(self: BoidRuleStayInBounds3D): AABB = self.bounds,
  proc(self: BoidRuleStayInBounds3D; value: AABB) =
    self.bounds = value
    self.cache = createCache(self.bounds, self.threshold)

gdexport "threshold",
  proc(self: BoidRuleStayInBounds3D): float = self.threshold,
  proc(self: BoidRuleStayInBounds3D; value: float) =
    self.threshold = value
    self.cache = createCache(self.bounds, self.threshold)

method onInit(self: BoidRuleStayInBounds3D) =
  self.cache = createCache(self.bounds, self.threshold)

proc axisForce(boundsMin, boundsMax, pos: float32): float32 =
  if unlikely(pos < boundsMin):
    boundsMin - pos
  elif unlikely(boundsMax < pos):
    boundsMax - pos
  else:
    0

proc stayInBounds(self: BoidRuleStayInBounds3D; boid: BoidAgent3D) =
  boid.a += vector3(
    axisForce(self.cache.boundsMin.x, self.cache.boundsMax.x, boid.p.x),
    axisForce(self.cache.boundsMin.y, self.cache.boundsMax.y, boid.p.y),
    axisForce(self.cache.boundsMin.z, self.cache.boundsMax.z, boid.p.z),
  ) * self.factor

method update(self: BoidRuleStayInBounds3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return

  case phase
  of ProcessPhaseAcceleration:
    for boid in self.controller.boids:
      if likely(boid.enabled):
        self.stayInBounds(boid)
  of ProcessPhaseVelocity:
    discard
