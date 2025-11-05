import std/os

import gdext
import gdext/classes/gdAnimationPlayer
import gdext/classes/gdAnimation

import classes/gdBoidController3D
import classes/gdBoidSpawner3D

import shell

type Bookfly* {.gdsync.} = ptr object of BoidAgent3D
  path* {.gdexport.}: String
  animationPlayer* {.gdexport.}: NodePath
  player: AnimationPlayer
  flyName* {.gdexport.}: StringName = "Fly"

type BookSpawner* {.gdsync.} = ptr object of BoidSpawner3D
    spawnSyncRequired*: bool
    rootDir: String

gdexport "root_directory",
  getter= proc(self: BookSpawner): String = self.rootDir,
  setter= proc(self: BookSpawner; value: String) =
    self.rootDir = value
    self.spawnSyncRequired = true,
  Appearance.globalDir

proc seekRandom(player: AnimationPlayer) =
  player.seek(randfRange(0, player.currentAnimationLength))

proc playRandom(player: AnimationPlayer; animation: StringName) =
  player.play(animation)
  player.seekRandom()

proc init*(self: Bookfly) =
  self.player = self/self.animationPlayer as AnimationPlayer
  var fly = self.player.getAnimation(self.flyName)
  fly[].loopMode = Animation_LoopMode.loopLinear
  self.player.playRandom(self.flyName)

proc spawn*(self: BookSpawner; path: String): Bookfly =
  result = self.spawn() as Bookfly
  init result
  result.path = path

proc spawnSync*(self: BookSpawner) =
  for i in 0..self.controller.boids.high:
    self.despawnLast()
  for kind, filepath in self.rootDir.`$`.walkDir:
    case kind
    of pcFile:
      discard self.spawn(filepath)
    else:
      discard

method process(self: BookSpawner; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync()
    self.spawnSyncRequired = false

proc execute*(self: Bookfly) {.gdsync.} =
  discard cd".".startProcess("xdg-open", [$self.path])
