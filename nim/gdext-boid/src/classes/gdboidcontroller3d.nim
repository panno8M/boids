import gdext
import gdext/classes/[gdNode3D, gdPackedScene, gdSceneTree]

type Boid = object
  v: Vector3
  a: Vector3
  instance: Node3D
type BoidController3D* {.gdsync, tool.} = ptr object of Node3D
  editorPreview*: bool
  pausing*: bool
  leader*: Node3D
  auto_instantiate_blueprint*: gdref PackedScene
  numOfInstances*: int
  boids*: seq[Boid]
  auto_instantiate_range*: float = 15
  cohesion_factor*: float = 0.05
  cohesion_range*: float = 10
  separation_factor*: float = 0.005
  separation_range*: float = 10
  alignment_factor*: float = 0.05
  alignment_range*: float = 10
  control_max_speed*: float = 15
  control_max_acceleration*: float = 75
  distancemap: seq[seq[Vector3]]
  spawnSyncRequired: bool

proc rand(_: typedesc[Vector3]): Vector3 = vector3(randf(), randf(), randf())
proc signedRand(_: typedesc[Vector3]): Vector3 = (Vector3.rand - 0.5) * 2
proc `+=`[I, T, S](a: var Vector[I, T]; b: Vector[I, S]) {.inline.} = a = a + b
proc `+=`[I, T, S](a: var Vector[I, T]; b: S) {.inline.} = a = a + b
proc `/=`[I, T, S](a: var Vector[I, T]; b: Vector[I, S]) {.inline.} = a = a / b
proc `/=`[I, T, S](a: var Vector[I, T]; b: S) {.inline.} = a = a / b

proc enabled(self: BoidController3D): bool =
  not Engine.isEditorHint or self.editorPreview

proc running(self: BoidController3D): bool =
  self.enabled and not self.pausing

proc spawn(self: BoidController3D): Node3D =
  result = instantiate(self.auto_instantiate_blueprint[]) as Node3D
  result.setPosition Vector3.signedRand * self.auto_instantiate_range
  self.addChild result
  self.boids.add Boid(
    instance: result,
    v: Vector3.signedRand.normalized * self.control_max_speed)

proc destroyLast(self: BoidController3D) =
  let last = self.boids[^1]
  queueFree last.instance
  self.boids.del(self.boids.high)

proc spawnSync(self: BoidController3D) =
  if self.enabled:
    let arr = self.getChildren
    if arr.len != 0 and self.boids.len == 0:
      for node in arr:
        self.boids.add Boid(instance: node as Node3D)

    for i in 0..<(self.numOfInstances - self.boids.len):
      discard self.spawn()
    for i in 0..<(self.boids.len - self.numOfInstances):
      self.destroyLast()

    self.distancemap.setLen(self.numOfInstances)
    for s in  self.distancemap.mitems:
      s.setlen(self.numOfInstances)
  else:
    for i in 0..<self.boids.len:
      self.destroyLast()

# =================================== Properties ===================================

proc simulation_started*(self: BoidController3D): Error {.gdsync, signal.}
proc simulation_ended*(self: BoidController3D): Error {.gdsync, signal.}
proc simulation_paused*(self: BoidController3D): Error {.gdsync, signal.}
proc simulation_resumed*(self: BoidController3D): Error {.gdsync, signal.}

gdexport "editor_preview",
  getter= proc(self: BoidController3D): bool = self.editorPreview,
  setter= proc(self: BoidController3D; value: bool) =
    self.editorPreview = value
    self.spawnSyncRequired = true
    if self.editorPreview:
      discard self.simulation_started()
    else:
      discard self.simulation_ended()
gdexport "pausing",
  getter= proc(self: BoidController3D): bool = self.pausing,
  setter= proc(self: BoidController3D; value: bool) =
    self.pausing = value
    if self.pausing:
      discard self.simulation_paused()
    else:
      discard self.simulation_resumed()
gdexport BoidController3D.leader

gdexport[BoidController3D] "auto_instantiate", Appearance.group("auto_instantiate")

gdexport BoidController3D.auto_instantiate_blueprint
gdexport BoidController3D.auto_instantiate_range, Appearance.range(0, 100)
gdexport "auto_instantiate_count",
  getter= proc(self: BoidController3D): int = self.numOfInstances,
  setter= proc(self: BoidController3D; value: int) =
    self.numOfInstances = value
    self.spawnSyncRequired = true

gdexport[BoidController3D] "Rule: Cohesion", Appearance.group("cohesion")
gdexport BoidController3D.cohesion_factor, Appearance.range(0, 1)
gdexport BoidController3D.cohesion_range, Appearance.range(0, 100)

gdexport[BoidController3D] "Rule: Separation", Appearance.group("separation")
gdexport BoidController3D.separation_factor, Appearance.range(0, 1)
gdexport BoidController3D.separation_range, Appearance.range(0, 100)

gdexport[BoidController3D] "Rule: Alignment", Appearance.group("alignment")
gdexport BoidController3D.alignment_factor, Appearance.range(0, 1)
gdexport BoidController3D.alignment_range, Appearance.range(0, 100)

gdexport[BoidController3D] "Control", Appearance.group("control")
gdexport BoidController3D.control_max_speed
gdexport BoidController3D.control_max_acceleration

# =================================== Functions ===================================

proc updateDistanceMap(self: BoidController3D) =
  for i in 0..<self.boids.len:
    for j in i..<self.boids.len:
      self.distanceMap[i][j] = self.boids[i].instance.position - self.boids[j].instance.position
      self.distanceMap[j][i] = -self.distanceMap[i][j]

proc cohesion(self: BoidController3D) =
  # let center = self.leader
  # let centerpos = center.global_position

  # for boid in self.boids.mitems:
  #   boid.ddv += (centerpos - boid.instance.global_position) * self.cohesion_factor
  let range2 = self.cohesion_range * self.cohesion_range
  for i, boid in self.boids.mpairs:
    var center: Vector3
    var count: int
    for j, dis in self.distancemap[i]:
      if i == j: continue
      if dis.lengthSquared < range2:
        center += dis
        inc count
    if count != 0:
      center /= count

      boid.a += (center - boid.instance.position) * self.cohesion_factor

proc separation(self: BoidController3D) =
  let range2 = self.separation_range * self.separation_range
  for i, boid in self.boids.mpairs:
    var move: Vector3
    for j, dis in self.distancemap[i]:
      if i == j: continue
      if dis.lengthSquared < range2:
        move += dis

    boid.a += move * self.separation_factor

proc alignment(self: BoidController3D) =
  let range2 = self.alignment_range * self.alignment_range
  for i, boid in self.boids.mpairs:
    var avg: Vector3
    var count: int
    for j, dis in self.distancemap[i]:
      if i == j: continue
      if dis.lengthSquared < range2:
        avg += boid.v
        inc count
    if count != 0:
      avg /= count
      boid.v += (avg - boid.v) * self.alignment_factor

proc clearAcceleration(self: BoidController3D) =
  for boid in self.boids.mitems:
    reset boid.a

proc calcVelocity(self: BoidController3D) =
  for boid in self.boids.mitems:
    boid.v += boid.a

proc limitVelocity(self: BoidController3D) =
  for boid in self.boids.mitems:
    boid.v = boid.v.limit_length(self.control_max_speed)

proc limitAcceleration(self: BoidController3D; delta: float64) =
  for boid in self.boids.mitems:
    boid.a = boid.a.limit_length(self.control_max_acceleration * delta)

proc calcPosition(self: BoidController3D; delta: float64) =
  for boid in self.boids:
    boid.instance.position = boid.instance.position + boid.v * delta

proc calcRotation(self: BoidController3D) =
  for boid in self.boids:
    if likely(boid.v != Vector3.Zero):
      boid.instance.lookAt(boid.instance.position + boid.v)

method ready*(self: BoidController3D) {.gdsync.} =
  self.spawnSync()

method process*(self: BoidController3D; delta: float64) {.gdsync.} =
  if self.spawnSyncRequired:
    self.spawnSync()
    self.spawnSyncRequired = false
  if self.running:
    self.updateDistanceMap()
    self.cohesion()
    self.separation()
    self.limitAcceleration(delta)
    self.calcVelocity()
    self.alignment()
    self.limitVelocity()
    self.calcPosition(delta)
    self.calcRotation()
    self.clearAcceleration()
