import std/os

import gdext
import gdext/nameformats
import gdext/classes/gdAnimationPlayer
import gdext/classes/gdAnimation
import gdext/classes/gdTexture2D
import gdext/classes/gdMeshInstance3D
import gdext/classes/gdStandardMaterial3D
import gdext/classes/gdMesh

import classes/gdBoidController3D
import classes/gdBoidSpawner3D

import shell

import gdext/coronation/header/classes
proc surfaceSetMaterial*(self: Mesh; surfIdx: int32; material: gdref Material): void =
  expandMethodBind(className Mesh, "surface_set_material", 3671737478)
  methodbind.ptrcall(self, [getPtr surfIdx, getPtr material])

proc surfaceGetMaterial*(self: Mesh; surfIdx: int32): gdref Material =
  expandMethodBind(className Mesh, "surface_get_material", 2897466400)
  var ret: encoded gdref Material
  methodbind.ptrcall(self, [getPtr surfIdx], addr ret)
  (addr ret).decode_result(gdref Material)

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
  self.rightPage.material.clearOverride
  self.leftPage.material.clearOverride
  self.freePage.material.clearOverride

proc open*(self: Bookfly; rightPage, leftPage: gdref Material) {.gdsync.} =
  self.player.play(self.openName)
  self.rightPage.material[0] = rightPage
  self.leftPage.material[0] = leftPage

proc close*(self: Bookfly) {.gdsync.} =
  self.player.playBackwards(self.openName)

proc pageRight*(self: Bookfly; rightPage, leftPage: gdref Material): Bool {.gdsync.} =
  if self.player.isPlaying: return false
  self.freePage.material[1] = self.rightPage.material[0]
  self.freePage.material[0] = leftPage
  self.rightPage.material[0] = rightPage
  self.player.play(self.pageRightName)
  return true

proc pageLeft*(self: Bookfly; rightPage, leftPage: gdref Material): Bool {.gdsync.} =
  if self.player.isPlaying: return false
  self.freePage.material[0] = self.leftPage.material[0]
  self.freePage.material[1] = rightPage
  self.leftPage.material[0] = leftPage
  self.player.play(self.pageLeftName)
  return true

proc animationFinished*(self: Bookfly; anim_name: StringName) {.gdsync, rename: toGodotInternalFuncCase.} =
  if anim_name == self.pageRightName:
    self.player.playBackwards(self.openName)
    self.player.pause()
    self.leftPage.material[0] = self.freePage.material[0]
  if anim_name == self.pageLeftName:
    self.player.playBackwards(self.openName)
    self.player.pause()
    self.rightPage.material[0] = self.freePage.material[1]