import gdext
import std/[sets, times, strformat, tables]

type TimeBuffer*[Steps: static int] = object
  b: array[Steps, float]
  filled: int
  current: int
  min: float = Inf
  max: float
  iteration: int

var defaultTimeBuffer* = TimeBuffer[8]()

proc pushavg*[Steps](buffer: var TimeBuffer[Steps]; value: float): string =
  buffer.b[buffer.current] = value
  buffer.current = buffer.current.succ mod Steps
  buffer.filled = min(buffer.filled.succ, Steps)
  if buffer.filled == Steps:
    buffer.min = min(buffer.min, value)
  buffer.max = max(buffer.max, value)
  let avg = sum(buffer.b.toOpenArray(0, buffer.filled.pred)) / buffer.filled
  result = fmt"[{buffer.iteration}]: {value} (avg: {avg} min: {buffer.min} max: {buffer.max})"
  inc buffer.iteration

template measure*(buffer: TimeBuffer; body): string =
  var start = epochTime()
  body
  buffer.pushavg(epochTime() - start)