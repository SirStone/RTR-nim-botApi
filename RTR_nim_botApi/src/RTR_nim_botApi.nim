# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import jsony
import std/os, std/sugar
import asyncdispatch, ws
import RTR_nim_botApi/Messages

type
  Bot* = ref object of RootObj
    # bot related
    name*,version*,gameTypes*,authors*,description*,homepage*,countryCodes*,platform*,programmingLang*:string

# Game Server
var gs_address:string = "localhost"
var gs_port:int = 7654

method run(bot:Bot, message:string) {.base.} = discard

proc handleMessage(json_message:string) =
  try:
    let `type` = json_message.fromJson(Message).`type`
    case `type`:
    of serverHandshake:
      let server_handshake = json_message.fromJson(ServerHandshake)
      echo server_handshake[]
    of botHandshake:
      let bot_handshake = json_message.fromJson(BotHandshake)
      echo bot_handshake[]
  except Exception:
    echo "EXCEPTION: ", getCurrentExceptionMsg()

proc talkWithGS(bot:Bot, url:string) {.async, gcsafe.} =
  echo "DEBUG: echoing in a different thread"
  try:
    var gs_ws = await newWebSocket(url)
    while(gs_ws.readyState == Open):
      let json_message = await gs_ws.receiveStrPacket()
      handleMessage(json_message)
      
  except WebSocketClosedError:
    echo "Socket closed. "
  except WebSocketProtocolMismatchError:
    echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
  except WebSocketError:
    echo "Unexpected socket error: ", getCurrentExceptionMsg()
  except Exception:
    echo "Unexpected generic error: ", getCurrentExceptionMsg()

proc initBot*(bot:Bot, json_file:string, connect:bool = true) = 
  let bot2 = readFile(joinPath(getAppDir(),json_file)).fromJson(Bot)
  bot.name = bot2.name
  bot.version = bot2.version
  bot.gameTypes = bot2.gameTypes
  bot.authors = bot2.authors 
  bot.description = bot2.description
  bot.homepage = bot2.homepage
  bot.countryCodes = bot2.countryCodes
  bot.platform = bot2.platform
  bot.programmingLang = bot2.programmingLang
  

  # connect to the Game Server
  if(connect):
    waitFor talkWithGS(bot, "ws://" & gs_address & ":" & $(gs_port))