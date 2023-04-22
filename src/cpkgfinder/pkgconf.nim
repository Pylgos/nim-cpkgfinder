import std/[os, strformat, strutils, sugar]
import common


proc exeExists(bin: string): bool =
  gorgeEx("type " & bin.quoteShell).exitCode == 0


proc findPkgConfPackage*(name: string, opt: FindOptions): FindResult =
  let exe =
    if exeExists("pkgconf"): "pkgconf"
    else: "pkg-config"
  
  let libsRes = gorgeEx(fmt"{exe} --libs {name.quoteShell}")
  if libsRes.exitCode != 0:
    return FindResult(
      ok: false,
      error: libsRes.output
    )
  
  let cflagsRes = gorgeEx(fmt"{exe} --cflags {name.quoteShell}")
  if libsRes.exitCode != 0:
    return FindResult(
      ok: false,
      error: cflagsRes.output
    )
  
  let versionRes = gorgeEx(fmt"{exe} --modversion {name.quoteShell}")
  if versionRes.exitCode != 0:
    return FindResult(
      ok: false,
      error: versionRes.output
    )
  
  FindResult(
    ok: true,
    version: versionRes.output.dup(removeSuffix('\n')),
    compilerArgs: cflagsRes.output.splitWhitespace(),
    linkerArgs: libsRes.output.splitWhitespace(),
  )


when isMainModule:
  echo findPkgConfPackage("opencv4", FindOptions())
