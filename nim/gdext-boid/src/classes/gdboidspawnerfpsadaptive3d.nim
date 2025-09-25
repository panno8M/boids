import std/[tables]

import gdext
import gdext/classes/[gdEngine]

import classes/[gdBoidController3D, gdBoidSpawner3D]

type
  BoidSpawnerFpsAdaptive3D* {.gdsync.} = ptr object of BoidSpawner3D
    minFps* {.gdexport: Appearance.range(0, 60).}: float = 30
    margin* {.gdexport: Appearance.range(0, 10).}: float = 5

proc spawnSync*(self: BoidSpawnerFpsAdaptive3D) =
  let fps = Engine.getFramesPerSecond

  if self.minFps < fps:
    discard self.spawn()
  if fps < self.minFps + self.margin:
    self.despawnLast()

method process(self: BoidSpawnerFpsAdaptive3D; delta: float64) {.gdsync.} =
  self.spawnSync()
