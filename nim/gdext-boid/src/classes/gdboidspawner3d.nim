import gdext
import gdext/classes/[gdPackedScene]

import global
import classes/[gdBoidController3D]

type
  BoidSpawner3D* {.gdsync.} = ptr object of BoidModule3D
    blueprint* {.gdexport.}: gdref PackedScene
    range* {.gdexport: Appearance.range(0, 100).}: float = 15

proc spawn*(self: BoidSpawner3D): Node3D =
  result = instantiate(self.blueprint[]) as Node3D
  let pos = Vector3.signedRand * self.range
  let cell = self.controller.cellMapStatus.localToMap(pos)
  result.setPosition pos
  self.addChild result
  self.controller.boids.add Boid(
    agent: result,
    position: pos,
    velocity: Vector3.signedRand.normalized.map(self.controller.controlMinSpeed..self.controller.controlMaxSpeed),
    acceleration: Vector3.Zero,
    cell: cell,
  )
  self.controller.cellMap.addBoid(cell, self.controller.boids.high)

proc despawnLast*(self: BoidSpawner3D) =
  if self.controller.boids.len == 0: return
  queueFree self.controller.boids[^1].agent
  self.controller.cellMap.removeBoidUnsafe(self.controller.boids[^1].cell, self.controller.boids.high)
  discard self.controller.boids.pop()