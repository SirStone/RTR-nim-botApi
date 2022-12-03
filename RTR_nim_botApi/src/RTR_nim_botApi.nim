# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import json
import std/os
import asyncdispatch, ws

type
  Bot* = ref object of RootObj
    # bot related
    name*,version*,gameTypes*,authors*,description*,homepage*,countryCodes*,platform*,programmingLang*:string

# Game Server
var gs_address:string = "localhost"
var gs_port:int = 7654

method run(bot:Bot, message:string) {.base.} = discard

proc talkWithGS(bot:Bot, url:string) {.async, gcsafe.} =
  echo "DEBUG: echoing in a different thread"
  try:
    var gs_ws = await newWebSocket(url)
    while(gs_ws.readyState == Open):
      let packet = await gs_ws.receiveStrPacket()
      echo "RECEIVED PACKET: " & packet
      bot.run("PIPPO")
  except WebSocketClosedError:
    echo "Socket closed. "
  except WebSocketProtocolMismatchError:
    echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
  except WebSocketError:
    echo "Unexpected socket error: ", getCurrentExceptionMsg()
  except Exception:
    echo "Unexpected generic error: ", getCurrentExceptionMsg()

proc initBot*(bot:Bot, json_file:string, connect:bool = true) = 
  echo "DEBUG connect = " & $connect
  let json = parseJson(readFile(joinPath(getAppDir(),json_file)))
  bot.name = json["name"].getStr
  bot.version = json["version"].getStr
  bot.gameTypes = json["gameTypes"].getStr
  bot.authors = json["authors"].getStr
  bot.description = json["description"].getStr
  bot.homepage = json["homepage"].getStr
  bot.countryCodes = json["countryCodes"].getStr
  bot.platform = json["platform"].getStr
  bot.programmingLang = json["programmingLang"].getStr

  # connect to the Game Server
  if(connect):
    waitFor talkWithGS(bot, "ws://" & gs_address & ":" & $(gs_port))