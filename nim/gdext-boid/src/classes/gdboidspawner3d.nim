import gdext
import gdext/classes/[gdPackedScene]
import std/[tables]

import global
import classes/[gdBoidController3D]

type
  BoidSpawner3D* {.gdsync.} = ptr object of BoidModule3D
    numOfInstances*: int
    blueprint*: gdref PackedScene
    range*: float = 15
    spawnSyncRequired*: bool

gdexport BoidSpawner3D.blueprint
gdexport BoidSpawner3D.range, Appearance.range(0, 100)
gdexport "count",
  getter= proc(self: BoidSpawner3D): int = self.numOfInstances,
  setter= proc(self: BoidSpawner3D; value: int) =
    self.numOfInstances = value
    self.spawnSyncRequired = true

proc spawn(self: BoidSpawner3D; gridmapStatus: GridMapStatus; minSpeed, maxSpeed: float): Node3D =
  result = instantiate(self.blueprint[]) as Node3D
  let pos = Vector3.signedRand * self.range
  let cell = gridmapStatus.localToMap(pos)
  result.setPosition pos
  self.addChild result
  self.controller.boids.add Boid(
    agent: result,
    position: pos,
    velocity: Vector3.signedRand.normalized.map(minSpeed..maxSpeed),
    acceleration: Vector3.Zero,
    cell: cell,
  )
  self.controller.cellMap.addBoid(cell, self.controller.boids.high)

proc destroyLast(self: BoidSpawner3D) =
  queueFree self.controller.boids[^1].agent
  self.controller.cellMap.removeBoidUnsafe(self.controller.boids[^1].cell, self.controller.boids.high)
  discard self.controller.boids.pop()

proc spawnSync*(self: BoidSpawner3D; gridmapStatus: GridMapStatus; minSpeed, maxSpeed: float) =
  let arr = self.getChildren
  if arr.len != 0 and self.controller.boids.len == 0:
    for node in arr:
      let agent = node as Node3D
      let position = agent.position
      self.controller.boids.add Boid(
        agent: agent,
        position: position,
        cell: gridmapStatus.localToMap(position),
      )

  for i in 0..<(self.numOfInstances - self.controller.boids.len):
    discard self.spawn(gridmapStatus, minSpeed, maxSpeed)
  for i in 0..<(self.controller.boids.len - self.numOfInstances):
    self.destroyLast()

method process(self: BoidSpawner3D; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync(self.controller.cellMapStatus, self.controller.controlMinSpeed, self.controller.controlMaxSpeed)
    self.spawnSyncRequired = false