import gdext
import std/[sets, times, strformat, tables]

type TimeBuffer*[Steps: static int] = object
  b: array[Steps, float]
  filled: int
  current: int
  min: float = Inf
  max: float
  iteration: int
  avg: float

var defaultTimeBuffer* = TimeBuffer[8]()

proc `$`*[Steps](buffer: TimeBuffer[Steps]; value: float): string =
  fmt"[{buffer.iteration.pred}]: {value} (avg: {buffer.avg} min: {buffer.min} max: {buffer.max})"

proc push*[Steps](buffer: var TimeBuffer[Steps]; value: float) =
  inc buffer.iteration
  buffer.b[buffer.current] = value
  buffer.current = buffer.current.succ mod Steps
  buffer.filled = min(buffer.filled.succ, Steps)
  if buffer.filled == Steps:
    buffer.min = min(buffer.min, value)
  buffer.max = max(buffer.max, value)
  buffer.avg = sum(buffer.b.toOpenArray(0, buffer.filled.pred)) / buffer.filled

proc avg*(buffer: var TimeBuffer): float = buffer.avg

template measure*(buffer: TimeBuffer; body): string =
  var start = epochTime()
  body
  buffer.push(epochTime() - start)
  $buffer