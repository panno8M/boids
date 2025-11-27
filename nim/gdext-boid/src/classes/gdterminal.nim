import os, osproc, strutils, streams

import gdext
import gdext/nameformats
import gdext/classes/[gdCodeEdit, gdLabel]

import shell

type Terminal* {.gdsync.} = ptr object of CodeEdit
  resultBuffer* {.gdexport.}: CodeEdit
  env: ShellEnv
  prevdir: string
  process: Process

method ready(self: Terminal) {.gdsync.} =
  if self.resultBuffer.isNil: self.resultBuffer = self
  discard self.connect("text_changed", self.callable"_on_write_buffer_text_changed")
  self.env.pwd = expandFileName(".")
  self.text = String(self.env.pwd & " $")
  self.setCaretColumn(10000)
  self.setCaretLine(10000)

method process(self: Terminal; delta: float64) {.gdsync.} =
  if self.process != nil:
    if self.process.running:
      self.resultBuffer.text = self.resultBuffer.text + String(self.process.readAvailable)
    else:
      if not self.process.outputStream.atEnd:
        self.resultBuffer.text = self.resultBuffer.text + String(self.process.outputStream.readAll)
      self.editable = true
      self.process = nil
      self.text = self.text + String(self.env.pwd & " $")
      self.setCaretColumn(10000)
      self.setCaretLine(10000)

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

  self.text = self.text + String(self.env.pwd & " $")
  self.setCaretColumn(10000)
  self.setCaretLine(10000)

proc embeddedProcess(self: Terminal; cmd: string, args: seq[string]): bool =
  result = true
  case cmd
  of "cd":
    cd(self, cmd, args)
  else:
    result = false

proc onWriteBufferTextChanged(self: Terminal) {.gdsync, rename: toGodotInternalFuncCase.} =
  if self.text.endsWith("\n"):
    let s = ($self.text)
      .split({'$'})[^1]
      .strip(chars = {'\n', ' '})
      .split(' ')
    let cmd = s[0]
    let args = s[1..^1]
    if not self.embeddedProcess(cmd, args):
      self.process = self.env.startProcess(cmd, args)
      self.process.setNonBlock()
      self.editable = false
