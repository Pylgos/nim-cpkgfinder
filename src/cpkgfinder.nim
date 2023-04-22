import std/[strformat, macros, strutils]
import cpkgfinder/[common, cmake, pkgconf]


proc findCPackage*(name: string, opt = defaultFindOptions(), required = true, showHint = true): FindResult =
  let pkgConfRes = findPkgConfPackage(name, opt)
  if pkgConfRes.ok:
    if showHint:
      hint(fmt"Package '{name}' {pkgConfRes.version} found by pkg-config")
    return pkgConfRes

  let cmakeRes = findCMakePackage(name, opt)
  if cmakeRes.ok:
    if showHint:
      hint(fmt"Package '{name}' {cmakeRes.version} found by CMake")
    return cmakeRes

  if not required:
    return cmakeRes
  
  var msg = &"Could not find package '{name}'.\n"
  msg.add "Tried:" & '\n'
  msg.add "  pkg-config:\n" & pkgConfRes.error.indent(4) & '\n'
  msg.add "  cmake:\n" & cmakeRes.error.indent(4)
  error(msg)


template configureCPackage*(name: string): untyped =
  const
    res = findCPackage(name)
    ccArg = join(res.compilerArgs, " ")
    ldArg = join(res.linkerArgs, " ")

  {.passC: ccArg.}
  {.passL: ldArg.}
