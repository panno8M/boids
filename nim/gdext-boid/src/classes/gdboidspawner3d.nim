import gdext
import gdext/classes/[gdPackedScene]
import std/[tables]

import global
import classes/[gdBoidModule3D]

type
  BoidSpawner3D* {.gdsync.} = ptr object of BoidModule3D
    numOfInstances*: int
    auto_instantiate_blueprint*: gdref PackedScene
    auto_instantiate_range*: float = 15
    spawnSyncRequired*: bool

gdexport BoidSpawner3D.auto_instantiate_blueprint
gdexport BoidSpawner3D.auto_instantiate_range, Appearance.range(0, 100)
gdexport "auto_instantiate_count",
  getter= proc(self: BoidSpawner3D): int = self.numOfInstances,
  setter= proc(self: BoidSpawner3D; value: int) =
    self.numOfInstances = value
    self.spawnSyncRequired = true

proc spawn(self: BoidSpawner3D; gridmapStatus: GridMapStatus; minSpeed, maxSpeed: float): Node3D =
  result = instantiate(self.auto_instantiate_blueprint[]) as Node3D
  let pos = Vector3.signedRand * self.auto_instantiate_range
  let cell = gridmapStatus.localToMap(pos)
  result.setPosition pos
  self.addChild result
  self.shared.boids.add Boid(
    agent: result,
    position: pos,
    velocity: Vector3.signedRand.normalized.map(minSpeed..maxSpeed),
    acceleration: Vector3.Zero,
    cell: cell,
  )
  self.shared.cellMap.addBoid(cell, self.shared.boids.high)

proc destroyLast(self: BoidSpawner3D) =
  queueFree self.shared.boids[^1].agent
  self.shared.cellMap.removeBoidUnsafe(self.shared.boids[^1].cell, self.shared.boids.high)
  discard self.shared.boids.pop()

proc spawnSync*(self: BoidSpawner3D; gridmapStatus: GridMapStatus; minSpeed, maxSpeed: float) =
  let arr = self.getChildren
  if arr.len != 0 and self.shared.boids.len == 0:
    for node in arr:
      let agent = node as Node3D
      let position = agent.position
      self.shared.boids.add Boid(
        agent: agent,
        position: position,
        cell: gridmapStatus.localToMap(position),
      )

  for i in 0..<(self.numOfInstances - self.shared.boids.len):
    discard self.spawn(gridmapStatus, minSpeed, maxSpeed)
  for i in 0..<(self.shared.boids.len - self.numOfInstances):
    self.destroyLast()

method process(self: BoidSpawner3D; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync(self.shared.cellMapStatus, self.shared.controlMinSpeed, self.shared.controlMaxSpeed)
    self.spawnSyncRequired = false