import std/[json, os, strformat, strutils, osproc, base64]
import common

proc escapeFileName(s: string): string =
  result = s
  var escaped = false
  for c in invalidFilenameChars:
    if c in result:
      escaped = true
      result = result.replace(c, '_')
  if escaped:
    result.add base64.encode(s)

proc getLinkerArgsFromLinkTxt(content: string): seq[string] =
  let cmd = content.splitWhitespace()
  let startIdx = cmd.find("dummy_executable") + 1
  if startIdx >= cmd.len:
    return @[]
  cmd[startIdx..^1]

proc getCCArgsFromCompileCommandsJson(content: string): seq[string] =
  let cmd = content.parseJson()[0]["command"].getStr().splitWhitespace
  cmd[1..^5]

proc genCMakeLists(name: string, opt: FindOptions): string =
  let lang =
    case opt.lang
    of langC: "C"
    of langCpp: "CXX"
  let res = fmt"""
  cmake_minimum_required()
  project(dummy_project)
  find_package({name} REQUIRED)
  file(WRITE version.txt "${{{name}_VERSION}}")
  add_executable(dummy_executable dummy.c)
  target_link_libraries(dummy_executable "${{{name}_LIBRARIES}}")
  target_include_directories(dummy_executable PRIVATE "${{{name}_INCLUDE_DIRS}}")
  target_compile_options(dummy_executable PRIVATE "${{{name}_{lang}_FLAGS}}")
  """
  res.dedent()

proc findCMakePackage*(name: string, opt: FindOptions): FindResult =
  let
    confDir = opt.confDir/"cmake"/escapeFileName(name)
    buildDir = confDir/"build"
  createDir(buildDir)
  
  writeFile(confDir/"CMakeLists.txt", genCMakeLists(name, opt))
  writeFile(confDir/"dummy.c", "")

  let res = gorgeEx(fmt"cmake -B {buildDir.quoteShell} -S {confDir.quoteShell} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
  if res.exitCode != 0:
    return FindResult(
      ok: false,
      error: res.output,
    )

  FindResult(
    ok: true,
    linkerArgs: readFile(buildDir/"CMakeFiles/dummy_executable.dir/link.txt").getLinkerArgsFromLinkTxt(),
    compilerArgs: readFile(buildDir/"compile_commands.json").getCCArgsFromCompileCommandsJson(),
    version: readFile(confDir/"version.txt")
  )

when isMainModule:
  echo findCMakePackage("OpenCV", FindOptions(lang: langCpp, confDir: "config"))
