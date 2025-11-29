import os, osproc, strutils, sequtils, streams, strformat

import gdext
import gdext/nameformats
import gdext/classes/[gdCodeEdit, gdLabel]

import shell

type Caret = object
  line: int32
  column: int32

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
  env: ShellEnv
  prevdir: string
  process: Process
  promptStartAt: Caret
  caret_prev: Caret

proc prompt(self: Terminal): string = &"""

┬─ {self.env.pwd}
╰─>$ """

proc insertPrompt(self: Terminal) =
  self.insertTextAtCaret self.prompt
  self.promptStartAt = self.getCaret
  self.scrollVertical = float self.promptStartAt.line

method customProcess*(self: Terminal; cmd: String; args: PackedStringArray): Bool {.gdsync, base.} =
  discard

method ready(self: Terminal) {.gdsync.} =
  if self.resultBuffer.isNil: self.resultBuffer = self
  discard self.connect("text_changed", self.callable"_on_text_changed")
  discard self.connect("caret_changed", self.callable"_on_caret_changed")
  self.env.pwd = expandFileName(".")
  self.insertPrompt

method process(self: Terminal; delta: float64) {.gdsync.} =
  if self.process != nil:
    if self.process.running:
      let output = self.process.readAvailable
      if output.len != 0:
        self.resultBuffer.insertTextAtCaret output
    else:
      if not self.process.outputStream.atEnd:
        let output = self.process.outputStream.readAll
        if output.len != 0:
          self.resultBuffer.insertTextAtCaret output
      self.process = nil
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
  if self.text.endsWith("\n"):
    let s = ($self.text)
      .split({'$'})[^1]
      .strip(chars = {'\n', ' '})
      .split(' ')
    let cmd = s[0]
    let args = s[1..^1]
    if self.customProcess(cmd, newPackedStringArray(args.map(newGdString))):
      self.insertPrompt
    elif self.embeddedProcess(cmd, args):
      self.insertPrompt
    elif findExe(cmd).len != 0:
      self.process = self.env.startProcess(cmd, args)
      self.process.setNonBlock()
    else:
      self.resultBuffer.insertTextAtCaret "Unknown command: " & cmd & "\n"
      self.insertPrompt
