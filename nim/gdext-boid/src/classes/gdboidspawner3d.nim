import gdext
import gdext/classes/[gdPackedScene]

import global
import classes/[gdBoidController3D]

type
  BoidSpawner3D* {.gdsync.} = ptr object of BoidModule3D
    blueprint* {.gdexport.}: gdref PackedScene
    range* {.gdexport: Appearance.range(0, 100).}: float = 15

proc spawn*(self: BoidSpawner3D): BoidAgent3D =
  result = instantiate(self.blueprint[]) as BoidAgent3D
  self.addChild result
  result.controller = self.controller
  result.p = Vector3.signedRand * self.range
  result.v = Vector3.signedRand.normalized.map(self.controller.controlMinSpeed..self.controller.controlMaxSpeed)
  result.a = Vector3.Zero
  result.cell = self.controller.cellMapStatus.localToMap(result.p)
  result.position = result.p
  self.controller.boids.add result
  self.controller.cellMap.addBoid(result.cell, result)

proc despawnLast*(self: BoidSpawner3D) =
  if self.controller.boids.len == 0: return
  let boid = self.controller.boids[^1]
  queueFree boid
  self.controller.cellMap.removeBoidUnsafe(boid.cell, boid)
  discard self.controller.boids.pop()