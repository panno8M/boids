import gdext
import gdext/classes/[gdNode3D]

import global
import classes/[gdBoidController3D]

export gdNode3D

type BoidModule3D* {.gdsync.} = ptr object of Node3D
  controller*: BoidController3D
  shared*: SharedData

method enterTree*(self: BoidModule3D) {.gdsync.} =
  self.controller = self.getParent.as(BoidController3D)
  self.shared = self.controller.shared