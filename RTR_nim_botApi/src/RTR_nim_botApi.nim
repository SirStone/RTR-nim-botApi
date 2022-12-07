# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import jsony
import std/os, std/sugar, std/strutils
import asyncdispatch, ws
import RTR_nim_botApi/Messages

type
  Bot* = ref object of RootObj
    # bot related
    name*,version*,description*,homepage*,platform*,programmingLang*:string
    gameTypes*,authors*,countryCodes*:seq[string]

# Game Server
var gs_address:string = "localhost"
var gs_port:int = 7654

method run(bot:Bot, message:string) {.base.} = discard

proc talkWithGS(bot:Bot, url:string) {.async, gcsafe.} =
  try:
    var gs_ws = await newWebSocket(url)
    while(gs_ws.readyState == Open):
      let json_message = await gs_ws.receiveStrPacket()
      if json_message.isEmptyOrWhitespace(): continue
      let `type` = json_message.fromJson(Message).`type`
      case `type`:
      of serverHandshake:
        let server_handshake = json_message.fromJson(ServerHandshake)
        let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors)
        await gs_ws.send(bot_handshake.toJson)
      else: echo "NOT HANDLED MESAGE: ",json_message  
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