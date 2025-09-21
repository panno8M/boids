import gdext
import gdext/classes/[gdNode3D]

import global

type BoidRule3D* {.gdsync.} = ptr object of Node3D
  shared*: SharedData
