import std/[tables]

import gdext

import classes/[gdBoidController3D, gdBoidSpawner3D]

type
  BoidSpawnerFixed3D* {.gdsync.} = ptr object of BoidSpawner3D
    numOfInstances*: int
    spawnSyncRequired*: bool

gdexport "count",
  getter= proc(self: BoidSpawnerFixed3D): int = self.numOfInstances,
  setter= proc(self: BoidSpawnerFixed3D; value: int) =
    self.numOfInstances = value
    self.spawnSyncRequired = true

proc spawnSync*(self: BoidSpawnerFixed3D) =
  for i in 0..<(self.numOfInstances - self.controller.boids.len):
    discard self.spawn()
  for i in 0..<(self.controller.boids.len - self.numOfInstances):
    self.despawnLast()

method process(self: BoidSpawnerFixed3D; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync()
    self.spawnSyncRequired = false