import gdext
import std/[tables {.all.}, hashes, importutils]

type
  GridShape* = seq[Vector3i]
  SparseGrid*[T: not pointer] = Table[Vector3i, T]

proc getUnsafePtr*[A, B](t: var Table[A, B], key: A): ptr B =
  privateAccess Table
  checkIfInitialized()
  var hc: Hash = default(Hash)
  var index = rawGet(t, key, hc)
  if index < 0:
    nil
  else:
    addr t.data[index].val

template neighborsImpl[T](grid: SparseGrid[T]; pos: Vector3i; shape: GridShape; `yield`): untyped =
  for delta in shape:
    let np {.inject.} = pos + delta
    let point {.inject.} = grid.getUnsafePtr(np)
    if point != nil:
      `yield`

iterator neighbors*[T](grid: SparseGrid[T]; pos: Vector3i; shape: GridShape): T =
  neighborsImpl(grid, pos, shape):
    yield point[]

iterator neighbors*[T](grid: var SparseGrid[T]; pos: Vector3i; shape: GridShape): var T =
  neighborsImpl(grid, pos, shape):
    yield point[]

iterator neighborPairs*[T](grid: SparseGrid[T]; pos: Vector3i; shape: GridShape): (Vector3i, T) =
  neighborsImpl(grid, pos, shape):
    yield (np, point[])

iterator neighborPairs*[T](grid: var SparseGrid[T]; pos: Vector3i; shape: GridShape): (Vector3i, var T) =
  neighborsImpl(grid, pos, shape):
    yield (np, point[])
