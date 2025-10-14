{.experimental: "dotOperators".}
import std/[os, osproc, strtabs, terminal, streams]

type ShellEnv* = object
  pwd*: string = "."
  result*: int
  `out`*: string

proc startProcess*(shell: ShellEnv; command: string;
          args: openArray[string] = []; env: StringTableRef = nil;
          options: set[ProcessOption] = {poStdErrToStdOut, poUsePath}): Process =
  if shell.result != 0: return
  startProcess(command, shell.pwd, args, env, options + {poEchoCmd})

proc exec*(shell: ShellEnv; command: string;
          args: openArray[string] = []; env: StringTableRef = nil;
          options: set[ProcessOption] = {poStdErrToStdOut, poUsePath}): ShellEnv =
  result = shell
  if result.result != 0: return
  if stdout.getFileHandle == 1: # console
    stdout.styledWrite fgBlue, expandFilename(shell.pwd), fgDefault, "$ "
  else:
    stdout.write expandFilename(shell.pwd), "$ "
  let process = startProcess(command, result.pwd, args, env, options + {poEchoCmd})
  for line in process.lines:
    result.out.add line
    result.out.add "\n"
    echo line
  result.result = process.peekExitCode

proc exec*(command: string;
          args: openArray[string] = []; env: StringTableRef = nil;
          options: set[ProcessOption] = {poStdErrToStdOut, poUsePath}): ShellEnv {.discardable.} =
  ShellEnv().exec(command, args, env, options)

when defined(windows):
  import std/winlean
  proc setNamedPipeHandleState(hNamedPipe: Handle;
                                lpMode: PDWORD;
                                lpMaxCollectionCount: PDWORD;
                                lpCollectDataTimeout: PDWORD;
    ): WINBOOL {.stdcall, dynlib: "kernel32", importc: "SetNamedPipeHandleState", sideEffect.}

  proc setNonBlock*(p: Process) =
    let h = cast[Handle](p.outputHandle)
    var mode: DWORD = PIPE_NOWAIT
    if setNamedPipeHandleState(h, addr mode, nil, nil) == 0:
      raise newException(OSError, "SetNamedPipeHandleState failed: " & $osLastError())
else:
  import std/posix
  proc setNonBlock*(p: Process) =
    let fd = p.outputHandle
    let flags = fcntl(fd, F_GETFL, 0)
    if flags == -1:
      raise newException(OSError, "fcntl(GETFL) failed: " & $osLastError())
    if fcntl(fd, F_SETFL, flags or O_NONBLOCK) == -1:
      raise newException(OSError, "fcntl(SETFL) failed: " & $osLastError())

proc readAvailable*(p: Process): string =
  if not p.running: return
  try:
    while true:
      result.add p.peekableOutputStream.readChar
  except IOError:
    return

template `.`*(shell: ShellEnv; command: untyped; args: varargs[string]): ShellEnv =
  shell.exec(astToStr command, args)

proc cd*(path: string): ShellEnv = ShellEnv(pwd: path)
proc cd*(shell: ShellEnv; path: string): ShellEnv =
  result = shell
  if path.isAbsolute:
    result.pwd = path
  else:
    result.pwd = result.pwd/path