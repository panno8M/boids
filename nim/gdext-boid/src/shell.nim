import std/[osproc, strtabs]

type
  LogMsg = object
    pid*: int
    stream*: string
    line*: string
  ThreadStream = tuple
    pid: int
    name: string
    handle: FileHandle
  Shell* = object
    pwd*: string = "."
    env*: StringTableRef

proc outputThreadStream(process: Process): ThreadStream =
  (pid: process.processID, name: "stdout", handle: process.outputHandle)

proc errorThreadStream(process: Process): ThreadStream =
  (pid: process.processID, name: "stderr", handle: process.errorHandle)

proc startProcess*(shell: Shell; command: string;
          args: openArray[string] = [];
          options: set[ProcessOption] = {poUsePath}): Process =
  startProcess(command, shell.pwd, args, shell.env, options)

var channel*: Channel[LogMsg]
channel.open()

proc readStream(ps: ThreadStream) {.thread.} =
  var line: string
  var file: File
  if file.open(ps.handle):
    while file.readLine(line):
      channel.send(LogMsg(pid: ps.pid, stream: ps.name, line: line))

proc processWorker(p: Process) {.thread.} =
  let pid = p.processID

  var tErr: Thread[ThreadStream]
  createThread(tErr, readStream, p.errorThreadStream)

  readStream(p.outputThreadStream)

  joinThread tErr

  let exitCode = p.peekExitCode
  channel.send(LogMsg(pid: pid, stream: "done", line: $exitCode))

proc runProcess*(shell: Shell; cmd: string; args: openArray[string]; thread: var Thread[Process]): Process =
  result = shell.startProcess(cmd, args, options = {poUsePath})
  createThread(thread, processWorker, result)
