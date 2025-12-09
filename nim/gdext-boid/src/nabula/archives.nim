import std/os
import std/tables

import gdext
import gdext/nameformats
import gdext/classes/gdAnimationPlayer
import gdext/classes/gdAnimation
import gdext/classes/gdTexture2D
import gdext/classes/gdMeshInstance3D
import gdext/classes/gdStandardMaterial3D
import gdext/classes/gdMesh
import gdext/classes/gdPackedScene

import classes/gdBoidController3D

import global
import shell

type Bookfly* {.gdsync.} = ptr object of BoidAgent3D
  path* {.gdexport.}: String
  animationPlayer* {.gdexport.}: NodePath
  player: AnimationPlayer
  flyName* {.gdexport.}: StringName = "Fly"
  openName* {.gdexport.}: StringName = "Open"
  pageRightName* {.gdexport.}: StringName = "PagingR2L"
  pageLeftName* {.gdexport.}: StringName = "PagingL2R"
  rightPage* {.gdexport.}: MeshInstance3D
  leftPage* {.gdexport.}: MeshInstance3D
  freePage* {.gdexport.}: MeshInstance3D

type BookFactory* {.gdsync.} = ptr object of Resource

type BookSpawner* {.gdsync.} = ptr object of BoidModule3D
    factory* {.gdexport.}: gdref BookFactory
    range* {.gdexport: Appearance.range(0, 100).}: float = 15
    spawnSyncRequired*: bool
    rootDir: String
    spawned: Table[String, Bookfly]

type VellumSpawner* {.gdsync.} = ptr object of BoidModule3D
    blueprint* {.gdexport.}: gdref PackedScene
    vellum* {.gdexport.}: Bookfly

method create*(self: BookFactory; controller: BoidController3D; path: String): Bookfly {.gdsync, base.} = discard

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

template `or`[T](a, b: GdRef[T]): GdRef[T] =
  var res = a
  if res[].isNil:
    res = b
  res

type MaterialSelector = object
  instance: MeshInstance3D

proc material(self: MeshInstance3D): MaterialSelector =
  MaterialSelector(instance: self)

proc `[]`(selector: MaterialSelector; index: int32): gdref Material =
  selector.instance.getSurfaceOverrideMaterial(index) or
  selector.instance.mesh[].surfaceGetMaterial(index)

proc `[]=`(selector: MaterialSelector; index: int32; value: gdref Material) =
  selector.instance.setSurfaceOverrideMaterial(index, value)

proc clearOverride(selector: MaterialSelector) =
  let count = selector.instance.getSurfaceOverrideMaterialCount
  for i in 0.int32..<count:
    selector[i] = default(gdref Material)

proc init*(self: Bookfly) =
  self.player = self/self.animationPlayer as AnimationPlayer
  var fly = self.player.getAnimation(self.flyName)
  fly[].loopMode = Animation_LoopMode.loopLinear
  self.player.playRandom(self.flyName)
  discard self.player.connect("animation_finished", self.callable"_animation_finished")

proc fileExists*(_: typedesc[BookSpawner]; path: String): Bool {.gdsync.} =
  fileExists($path)

proc spawnSingle*(self: BookSpawner; path: string): Bookfly =
  result = self.spawned.getOrDefault(path, nil)
  if result != nil: return
  result = self.factory[].create(self.controller, path)
  self.spawned[result.path] = result
  self.addChild result
  result.controller = self.controller
  result.p = Vector3.signedRand * self.range
  result.v = Vector3.signedRand.normalized * randfRange(self.controller.controlMinSpeed, self.controller.controlMaxSpeed)
  result.a = Vector3.Zero
  result.cell = self.controller.cellMapStatus.localToMap(result.p)
  result.position = result.p
  result.path = path
  self.controller.boids.add result
  self.controller.cellMap.addBoid(result.cell, result)

  init result

proc spawn(self: BookSpawner; path: string; recursiveCount: int): seq[Bookfly] =
  if fileExists(path):
    result.add self.spawnSingle(path)
  elif recursiveCount == 0:
    return
  elif dirExists(path):
    for kind, filepath in path.walkDir:
      result.add self.spawn(filepath, recursiveCount.pred)

proc spawn_script*(self: BookSpawner; path: String; recursiveCount: int = -1): Array[Bookfly] {.gdsync, name: "spawn".} =
  newArray[Bookfly](self.spawn($path, recursiveCount))

proc despawnLast*(self: BookSpawner) =
  if self.controller.boids.len == 0: return
  let boid = self.controller.boids[^1]
  queueFree boid
  self.controller.cellMap.removeBoidUnsafe(boid.cell, boid)
  discard self.controller.boids.pop()

proc spawnSync*(self: BookSpawner) =
  for i in 0..self.controller.boids.high:
    self.despawnLast()
  discard self.spawn($self.rootDir, 1)

method process(self: BookSpawner; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync()
    self.spawnSyncRequired = false

method process(self: VellumSpawner; delta: float64) {.gdsync.} =
  once:
    self.vellum = self.blueprint[].instantiate() as Bookfly
    self.addChild self.vellum
    self.vellum.controller = self.controller
    self.vellum.p = Vector3.Zero
    self.vellum.v = Vector3.signedRand.normalized * randfRange(self.controller.controlMinSpeed, self.controller.controlMaxSpeed)
    self.vellum.a = Vector3.Zero
    self.vellum.cell = self.controller.cellMapStatus.localToMap(self.vellum.p)
    self.vellum.position = self.vellum.p
    self.controller.boids.add self.vellum
    self.controller.cellMap.addBoid(self.vellum.cell, self.vellum)

    init self.vellum

proc execute*(self: Bookfly) {.gdsync.} =
  discard Shell().startProcess("xdg-open", [$self.path])

proc playHold*(self: Bookfly; newParent: Node3D) {.gdsync.} =
  self.enabled = false
  self.getParent.removeChild(self)
  newParent.addChild(self)
  self.p = vector3(0, 0, -0.18)
  self.transform = Transform3D(origin: self.p)
  self.player.pause(self.openName)

proc playRelease*(self: Bookfly) {.gdsync.} =
  self.enabled = true
  let global = self.globalTransform
  self.getParent.removeChild(self)
  self.controller.addChild(self)
  self.globalTransform = global
  self.p = self.position
  self.player.play(self.flyName)
  self.rightPage.material.clearOverride
  self.leftPage.material.clearOverride
  self.freePage.material.clearOverride

proc playOpen*(self: Bookfly; rightPage, leftPage: gdref Material) {.gdsync.} =
  self.player.play(self.openName)
  self.rightPage.material[0] = rightPage
  self.leftPage.material[0] = leftPage

proc playClose*(self: Bookfly) {.gdsync.} =
  self.player.playBackwards(self.openName)

proc playPageRight*(self: Bookfly; rightPage, leftPage: gdref Material): Bool {.gdsync.} =
  if self.player.isPlaying: return false
  self.freePage.material[1] = self.rightPage.material[0]
  self.freePage.material[0] = leftPage
  self.rightPage.material[0] = rightPage
  self.player.play(self.pageRightName)
  return true

proc playPageLeft*(self: Bookfly; rightPage, leftPage: gdref Material): Bool {.gdsync.} =
  if self.player.isPlaying: return false
  self.freePage.material[0] = self.leftPage.material[0]
  self.freePage.material[1] = rightPage
  self.leftPage.material[0] = leftPage
  self.player.play(self.pageLeftName)
  return true

proc animationFinished*(self: Bookfly; anim_name: StringName) {.gdsync, rename: toGodotInternalFuncCase.} =
  if anim_name == self.pageRightName:
    self.player.playBackwards(self.openName)
    self.player.seek(0)
    self.player.pause()
    self.leftPage.material[0] = self.freePage.material[0]
  if anim_name == self.pageLeftName:
    self.player.playBackwards(self.openName)
    self.player.seek(0)
    self.player.pause()
    self.rightPage.material[0] = self.freePage.material[1]
