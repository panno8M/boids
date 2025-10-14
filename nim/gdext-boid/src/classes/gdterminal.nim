import os, osproc, strutils, streams

import gdext
import gdext/nameformats
import gdext/classes/[gdCodeEdit, gdLabel]

import shell

type Terminal* {.gdsync.} = ptr object of Control
  viewBuffer* {.gdexport.}: CodeEdit
  writeBuffer* {.gdexport.}: CodeEdit
  pwd* {.gdexport.}: Label
  env: ShellEnv
  prevdir: string
  process: Process

method ready(self: Terminal) {.gdsync.} =
  discard self.writeBuffer.connect("text_changed", self.callable"_on_write_buffer_text_changed")
  self.env.pwd = expandFileName(".")
  self.pwd.text = self.env.pwd

method process(self: Terminal; delta: float64) {.gdsync.} =
  if self.process != nil:
    if self.process.running:
      self.viewBuffer.insertTextAtCaret self.process.readAvailable
    else:
      if not self.process.outputStream.atEnd:
        self.viewBuffer.insertTextAtCaret self.process.outputStream.readAll
      self.writeBuffer.editable = true
      self.process = nil

proc embeddedProcess(self: Terminal; cmd: string, args: seq[string]): bool =
  result = true
  case cmd
  of "cd":
    let path =
      case args.len
      of 0: "~"
      of 1: args[0]
      else:
        self.viewBuffer.insertTextAtCaret "Too many args for cd command\n"
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
    self.pwd.text = self.env.pwd
  else:
    result = false

proc onWriteBufferTextChanged(self: Terminal) {.gdsync, rename: toGodotInternalFuncCase.} =
  if self.writeBuffer.text.endsWith("\n"):
    let s = ($self.writeBuffer.text)
      .strip(chars = {'\n', ' '})
      .split(' ')
    let cmd = s[0]
    let args = s[1..^1]
    if not self.embeddedProcess(cmd, args):
      self.process = self.env.startProcess(cmd, args)
      self.process.setNonBlock()
      self.writeBuffer.editable = false
    self.viewBuffer.insertTextAtCaret self.writeBuffer.text
    self.writeBuffer.text = ""
