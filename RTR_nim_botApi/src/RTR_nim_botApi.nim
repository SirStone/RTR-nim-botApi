# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import jsony
import std/os, std/sugar, std/strutils, std/rdstdin
import asyncdispatch, ws
import RTR_nim_botApi/Messages

type
  Bot* = ref object of RootObj
    # bot related
    name*,version*,description*,homepage*,secret:string
    gameTypes*,authors*,countryCodes*,platform*,programmingLang*:seq[string]
    gameSetup*:GameSetup
    myId*: int

# Game Server
var gs_address:string = "localhost"
var gs_port:int = 2391 #default 7654

method run(bot:Bot) {.base.} = discard

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
        let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors, secret:bot.secret)
        await gs_ws.send(bot_handshake.toJson)
        echo "Connected to server ", gs_address, ':', gs_port
      of gameStartedEventForBot:
        let game_started_event_for_bot = json_message.fromJson(GameStartedEventForBot)
        # store the Game Setup for the bot usage
        bot.gameSetup = game_started_event_for_bot.gameSetup
        bot.myId = game_started_event_for_bot.myId
        # send bot ready
        let bot_ready = BotReady(`type`:Type.botReady)
        await gs_ws.send(bot_ready.toJson)
      of tickEventForBot:
        try:
          let tick_event_for_bot = json_message.fromJson(TickEventForBot)
        except Exception:
          echo json_message
      of gameAbortedEvent:
        let game_aborted_event = json_message.fromJson(GameAbortedEvent)
        echo "Game had been aborted"
      of gameEndedEventForBot:
        let game_ended_event = json_message.fromJson(GameEndedEventForBot)
        echo "Game ended in ",game_ended_event.numberOfRounds
        echo "RESULTS ",game_ended_event.results[]
      of skippedTurnEvent:
        let skipped_turn_event = json_message.fromJson(SkippedTurnEvent)
        # echo "skipped turn number ",skipped_turn_event.turnNumber
      of roundStartedEvent:
        let round_started_event = json_message.fromJson(RoundEndedEvent)
        echo "round number ",round_started_event.roundNumber," started"
      else: echo "NOT HANDLED MESSAGE: ",json_message  
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
  bot.secret = "botssecret"

  
  # connect to the Game Server
  if(connect):
    # standard address is localhost, standard port is 7654 at compile time
    var address = $(gs_address)
    var port = $(gs_port)

    if(paramCount() > 1):
      # for custom values, first parameter is address, second is the port
      address = paramStr(1)
      port = paramStr(2)

    waitFor talkWithGS(bot, "ws://" & address & ":" & port)