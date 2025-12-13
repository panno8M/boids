import gdext

import classes/[gdBoidController3D]

type BoidRulePostureLookAt3D* {.gdsync.} = ptr object of BoidModule3D
  enableX* {.gdexport.}: Bool = true
  enableY* {.gdexport.}: Bool = true
  enableZ* {.gdexport.}: Bool = true

method update(self: BoidRulePostureLookAt3D; phase: ProcessPhase) {.gdsync.} =
  var rotater {.global.}: array[bool, array[bool, array[bool, proc(a: BoidAgent3D, p, v: Vector3)]]]
  once:
    rotater[false][false][true ] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + vector(0.0, 0.0, v.z))
    rotater[false][true ][false] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + vector(0.0, v.y, 0.0))
    rotater[false][true ][true ] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + vector(0.0, v.y, v.z))
    rotater[true ][false][false] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + vector(v.x, 0.0, 0.0))
    rotater[true ][false][true ] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + vector(v.x, 0.0, v.z))
    rotater[true ][true ][false] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + vector(v.x, v.y, 0.0))
    rotater[true ][true ][true ] = proc (a: BoidAgent3D; p, v: Vector3) = a.lookAt(p + v)

  if phase != ProcessPhasePosture: return
  let rot = rotater[self.enableX][self.enableY][self.enableZ]
  if rot.isNil: return

  for boid in self.controller.boids.alive:
    if likely(boid.enabled):
      boid.rot(boid.p, boid.v)