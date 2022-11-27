# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import json
import std/os

type
    Bot* = ref object of RootObj
      name*,version*,gameTypes*,authors*,description*,homepage*,countryCodes*,platform*,programmingLang*:string

proc initBot*(json_file:string): Bot =
  let json = parseJson(readFile(joinPath(getAppDir(),json_file)))
  Bot(
    name:json["name"].getStr,
    version:json["version"].getStr,
    gameTypes:json["gameTypes"].getStr,
    authors:json["authors"].getStr,
    description:json["description"].getStr,
    homepage:json["homepage"].getStr,
    countryCodes:json["countryCodes"].getStr,
    platform:json["platform"].getStr,
    programmingLang:json["programmingLang"].getStr  
  )
