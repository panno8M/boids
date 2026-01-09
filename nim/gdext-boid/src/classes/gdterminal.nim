import os, osproc, strutils, sequtils, strformat

import gdext
import gdext/nameformats
import gdext/classes/[gdCodeEdit, gdLabel]
import gdext/classes/gdInputEventKey

import shell

type Caret = object
  line: int32
  column: int32

template EOF(_: typedesc[Caret]): Caret =
  Caret(line: int32.high, column: int32.high)

proc once(b: var bool): bool =
  result = b
  b = false

proc getCaret(self: TextEdit): Caret =
  result.line = self.getCaretLine
  result.column = self.getCaretColumn

proc setCaret(self: TextEdit; c: Caret) =
  self.setCaretLine(c.line)
  self.setCaretColumn(c.column)

proc setCaretWithFill(self: TextEdit; c: Caret) =
  self.setCaret(c)
  var res = self.getCaret
  if res.line < c.line:
    self.insertTextAtCaret "\n".repeat(c.line - res.line) & " ".repeat(c.column)
  elif res.column < c.column:
    self.insertTextAtCaret " ".repeat(c.column - res.column)

type Terminal* {.gdsync.} = ptr object of CodeEdit
  resultBuffer* {.gdexport.}: CodeEdit
  env: Shell
  prevdir: string
  front: tuple[process: Process; thread: Thread[(Process, Callable)]]
  promptStartAt: Caret
  caret_prev: Caret
  shouldExecute: bool

proc prompt(self: Terminal): string = &"""

┬─ {self.env.pwd}
╰─>$ """

proc insertPrompt(self: Terminal) =
  self.insertTextAtCaret self.prompt
  self.promptStartAt = self.getCaret
  self.scrollVertical = float self.promptStartAt.line

proc error(self: Terminal; arg: varargs[string, `$`]) =
  for arg in arg:
    self.insertTextAtCaret arg.get(String)
  self.insertTextAtCaret "\n"

proc error_script*(self: Terminal; arg: varargs[Variant, variant]) {.gdsync, name: "error".} =
  self.error(arg.mapIt it.get(string))

method customProcess*(self: Terminal; pwd: String; cmd: String; args: PackedStringArray): Bool {.gdsync, base.} =
  discard

method ready(self: Terminal) {.gdsync.} =
  if self.resultBuffer.isNil: self.resultBuffer = self
  discard self.connect("text_changed", self.callable"_on_text_changed")
  discard self.connect("caret_changed", self.callable"_on_caret_changed")
  self.env.pwd = expandFileName(".")
  self.insertPrompt

proc callback(self: Terminal; kind: LogKind; pid: Int; line: String) {.gdsync.} =
  if self.front.process != nil:
    case kind:
    of LogKind.stdout, LogKind.stderr:
      self.resultBuffer.insertTextAtCaret line + String("\n")
    of LogKind.done:
      self.front.process = nil
    else:
      discard
    if self.front.process == nil:
      self.insertPrompt

proc cd(self: Terminal; cmd: string, args: seq[string]) =
  let path =
    case args.len
    of 0: "~"
    of 1: args[0]
    else:
      self.resultBuffer.insertTextAtCaret "Too many args for cd command\n"
      return
  case path
  of "~":
    self.prevdir = self.env.pwd
    self.env.pwd = getHomeDir()
  of "-":
    if self.prevdir.len != 0:
      swap(self.env.pwd, self.prevdir)
  elif path.isAbsolute:
    self.prevdir = self.env.pwd
    self.env.pwd = expandFilename(path)
  else:
    self.prevdir = self.env.pwd
    self.env.pwd = expandFilename(self.env.pwd/path)

proc embeddedProcess(self: Terminal; cmd: string, args: seq[string]): bool =
  result = true
  case cmd
  of "cd":
    cd(self, cmd, args)
  else:
    result = false

proc isInvalidCaretChange(self: Terminal; c: Caret): bool =
  case cmp(c.line, self.promptStartAt.line):
  of int32.low .. -1: true
  of 0:
    c.column < self.promptStartAt.column
  else: false

proc onCaretChanged(self: Terminal) {.gdsync, rename: toGodotInternalFuncCase.} =
  var caret = self.getCaret
  if self.isInvalidCaretChange(caret):
    self.setCaretWithFill self.caret_prev
  else:
    self.caret_prev = caret

proc onTextChanged(self: Terminal) {.gdsync, rename: toGodotInternalFuncCase.} =
  if once self.shouldExecute:
    let s = ($self.text)
      .split({'$'})[^1]
      .strip(chars = {'\n', ' '})
      .split(' ')
    let cmd = s[0]
    let args = s[1..^1]
    if self.customProcess(self.env.pwd, cmd, newPackedStringArray(args.map(newGdString))):
      self.insertPrompt
    elif self.embeddedProcess(cmd, args):
      self.insertPrompt
    elif findExe(cmd).len != 0:
      if self.front.process == nil:
        self.front.process = self.env.runProcess(cmd, args, self.front.thread, self.callable("callback"))
      else:
        self.resultBuffer.insertTextAtCaret "Another process is already running.\n"
        self.insertPrompt
    else:
      self.resultBuffer.insertTextAtCaret "Unknown command: " & cmd & "\n"
      self.insertPrompt

method guiInput(self: Terminal; event: gdref InputEvent) {.gdsync.} =
  let keyevent = event as gdref InputEventKey
  if keyevent[] != nil and keyevent[].keycode == keyEnter and keyevent[].pressed:
    self.shouldExecute = true
