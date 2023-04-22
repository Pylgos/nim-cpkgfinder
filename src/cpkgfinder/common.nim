import std/[compilesettings]
from os import `/`

type
  PackageLanguage* = enum
    langC
    langCpp

  FindOptions* = object
    lang*: PackageLanguage
    confDir*: string

  FindResult* = object
    meth*: string
    case ok*: bool
    of true:
      version*: string
      compilerArgs*: seq[string]
      linkerArgs*: seq[string]
    of false:
      error*: string


proc defaultFindOptions*: FindOptions =
  let
    langStr = querySetting(SingleValueSetting.backend)
    lang =
      case langStr
      of "c":
        langC
      of "cpp":
        langCpp
      else:
        raise newException(ValueError, "Unsupported backend")
    confDir = querySetting(SingleValueSetting.nimcacheDir)/"cpkgfinder"
  
  FindOptions(
    lang: lang,
    confDir: confDir
  )
