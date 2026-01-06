import gdext
import gdext/classes/[gdGridMap, gdBoxShape3D, gdCollisionShape3D]

import classes/[gdBoidController3D]

type Cache = object
  boundsMin: Vector3
  boundsMax: Vector3

type BoidRuleStayInArea3D* {.gdsync.} = ptr object of BoidModule3D
  factor* {.gdexport: Appearance.range(0, 1).}: float = 0.2
  cache: Cache

proc createCache(box: gdref BoxShape3D; offset: Vector3): Cache =
  Cache(
    boundsMin: offset - (box[].size / 2),
    boundsMax: offset + (box[].size / 2),
  )

method ready(self: BoidRuleStayInArea3D) {.gdsync.} =
  for child in self.getChildren:
    if child.isClass("Area3D"):
      let area3D = child
      for child in area3D.getChildren:
        if child.isClass("CollisionShape3D"):
          let collisionShape3D = child as CollisionShape3D
          if collisionShape3D.shape[].isClass("BoxShape3D"):
            let boxshape = collisionShape3D.shape as gdref BoxShape3D
            self.cache = createCache(boxshape, collisionShape3D.globalPosition)

proc axisForce(boundsMin, boundsMax, pos: float32): float32 =
  if unlikely(pos < boundsMin):
    boundsMin - pos
  elif unlikely(boundsMax < pos):
    boundsMax - pos
  else:
    0

proc stayInBounds(self: BoidRuleStayInArea3D; boid: BoidAgent3D) =
  boid.a += vector3(
    axisForce(self.cache.boundsMin.x, self.cache.boundsMax.x, boid.p.x),
    axisForce(self.cache.boundsMin.y, self.cache.boundsMax.y, boid.p.y),
    axisForce(self.cache.boundsMin.z, self.cache.boundsMax.z, boid.p.z),
  ) * self.factor

method update(self: BoidRuleStayInArea3D; phase: ProcessPhase) {.gdsync.} =
  if unlikely(self.factor == 0): return
  if phase != ProcessPhaseAcceleration: return

  for boid in self.controller.boids.alive:
    if likely(boid.enabled):
      self.stayInBounds(boid)
