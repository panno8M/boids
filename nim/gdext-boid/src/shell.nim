import gdext
import std/[osproc, strtabs]

type
  LogKind* = enum
    invalid
    stdin
    stdout
    stderr
    done
  ThreadStream = tuple
    kind: LogKind
    pid: int
    handle: FileHandle
    callback: Callable
  Shell* = object
    pwd*: string = "."
    env*: StringTableRef

proc outputThreadStream(process: Process; callback: Callable): ThreadStream =
  (kind: LogKind.stdout, pid: process.processID, handle: process.outputHandle, callback: callback)

proc errorThreadStream(process: Process; callback: Callable): ThreadStream =
  (kind: LogKind.stderr, pid: process.processID, handle: process.errorHandle, callback: callback)

proc startProcess*(shell: Shell; command: string;
          args: openArray[string] = [];
          options: set[ProcessOption] = {poUsePath}): Process =
  startProcess(command, shell.pwd, args, shell.env, options)

proc readStream(ps: ThreadStream) {.thread.} =
  var line: string
  var file: File
  if file.open(ps.handle):
    while file.readLine(line):
      {.gcsafe.}:
        if ps.callback != nil:
          ps.callback.callDeferred(ps.kind, ps.pid, line)

proc processWorker(arg: tuple[process: Process; callback: Callable]) {.thread.} =
  let pid = arg.process.processID

  var tErr: Thread[ThreadStream]
  createThread(tErr, readStream, arg.process.errorThreadStream(arg.callback))

  readStream(arg.process.outputThreadStream(arg.callback))

  joinThread tErr

  let exitCode = arg.process.peekExitCode

  {.gcsafe.}:
    if arg.callback != nil:
      arg.callback.callDeferred(LogKind.done, pid, $exitCode)

proc runProcess*(shell: Shell; cmd: string; args: openArray[string]; thread: var Thread[(Process, Callable)]; callback: Callable): Process =
  result = shell.startProcess(cmd, args, options = {poUsePath})
  createThread(thread, processWorker, (result, callback))
