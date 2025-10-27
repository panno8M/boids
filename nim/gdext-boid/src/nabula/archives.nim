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
  openName* {.gdexport.}: StringName = "Open"

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

proc pause(player: AnimationPlayer; animation: StringName; seconds: float = 0) =
  player.play(animation)
  player.seek(seconds)
  player.pause()

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

proc transfer*(self: Bookfly; newParent: Node3D) {.gdsync.} =
  self.enabled = false
  self.getParent.removeChild(self)
  newParent.addChild(self)
  self.p = vector3(0, 0, -2.5)
  self.transform = Transform3D(origin: self.p)
  self.player.pause(self.openName)

proc release*(self: Bookfly; newParent: Node3D) {.gdsync.} =
  self.enabled = true
  let global = self.globalTransform
  self.getParent.removeChild(self)
  newParent.addChild(self)
  self.globalTransform = global
  self.p = self.position
  self.player.play(self.flyName)

proc open*(self: Bookfly) {.gdsync.} =
  self.player.play(self.openName)

proc close*(self: Bookfly) {.gdsync.} =
  self.player.playBackwards(self.openName)
