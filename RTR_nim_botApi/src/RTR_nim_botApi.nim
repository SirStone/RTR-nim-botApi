# standard libraries
import std/[os, strutils, threadpool, math]

# 3rd party libraries
import asyncdispatch, ws, jsony, json

# local components
import RTR_nim_botApi/Components/[Bot, Messages, Colors]

# system variables
var gs_address:string
var debug_is_enabled = false
var running:bool
var firstTickSeen:bool = false

# the following section contains all the methods that are supposed to be overrided by the bot creator
method run(bot:Bot) {.base.} = discard
method onGameAborted(bot:Bot, gameAbortedEvent:GameAbortedEvent) {.base.} = discard
method onGameEnded(bot:Bot, gameEndedEventForBot:GameEndedEventForBot) {.base.} = discard
method onGameStarted(bot:Bot, gameStartedEventForBot:GameStartedEventForBot) {.base.} = discard
method onHitByBullet(bot:Bot, hitByBulletEvent:HitByBulletEvent) {.base.} = discard
method onHitBot(bot:Bot, botHitBotEvent:BotHitBotEvent) {.base.} = discard
method onHitWall(bot:Bot, botHitWallEvent:BotHitWallEvent) {.base.} = discard
method onRoundEnded(bot:Bot, roundEndedEventForBot:RoundEndedEventForBot) {.base.} = discard
method onRoundStarted(bot:Bot, roundStartedEvent:RoundStartedEvent) {.base.} = discard
method onSkippedTurn(bot:Bot, skippedTurnEvent:SkippedTurnEvent) {.base.} = discard
method onScannedBot(bot:Bot, scannedBotEvent:ScannedBotEvent) {.base.} = discard
method onTick(bot:Bot, tickEventForBot:TickEventForBot) {.base.} = discard
method onDeath(bot:Bot, botDeathEvent:BotDeathEvent) {.base.} =  discard
method onConnected(bot:Bot, url:string) {.base.} = discard
method onConnectionError(bot:Bot, error:string) {.base.} = discard

proc setSecret*(bot:Bot, s:string) =
  bot.secret = s

# API callable procs
proc isRunning*(bot:Bot):bool =
  return running

proc setAdjustGunForBodyTurn*(bot:Bot, adjust:bool) =
  bot.adjustGunForBodyTurn = adjust

proc setAdjustRadarForGunTurn*(bot:Bot, adjust:bool) =
  bot.adjustRadarForGunTurn = adjust

proc setAdjustRadarForBodyTurn*(bot:Bot, adjust:bool) =
  bot.adjustRadarForBodyTurn = adjust

proc setBodyColor*(bot:Bot, color:Color) = 
  bot.bodyColor = $color

proc setTurretColor*(bot:Bot, color:Color) = 
  bot.turretColor = $color

proc setRadarColor*(bot:Bot, color:Color) = 
  bot.radarColor = $color

proc setBulletColor*(bot:Bot, color:Color) = 
  bot.bulletColor = $color

proc setScanColor*(bot:Bot, color:Color) = 
  bot.scanColor = $color

proc getArenaWidth*(bot:Bot):int =
  return bot.gameSetup.arenaWidth

proc getArenaHeight*(bot:Bot):int =
  return bot.gameSetup.arenaHeight

proc getDirection*(bot:Bot):float =
  return bot.tick.botState.direction

proc turnRight*(bot:Bot, degrees:float) = 
  bot.intent.turnRate = degrees

proc forward*(bot:Bot, degrees:float) = discard #TODO

# system procs
proc debug(msg:string) =
  if(debug_is_enabled): echo(msg)

proc enableDebug*() = 
  debug_is_enabled = true
  debug("Debug messages enabled")

proc stopBot() = 
  running = false
  firstTickSeen = false
  sync() # force the run() thread to sync the 'running' variable, don't remove this if not for a good reason!

proc handleMessage(bot:Bot, json_message:string, gs_ws:WebSocket) {.async, gcsafe.} =
  # debug(json_message)
  # get the type of the message from the message itself
  let `type` = json_message.fromJson(Message).`type`

  # 'case' switch over type
  case `type`:
  of serverHandshake:
    debug("ServerHandshake received")
    let server_handshake = json_message.fromJson(ServerHandshake)
    let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors, secret:bot.secret)
    await gs_ws.send(bot_handshake.toJson)
    debug("ServerHandshake sent whit this secret:" & bot.secret)
  
  of gameStartedEventForBot:
    let game_started_event_for_bot = json_message.fromJson(GameStartedEventForBot)
    # store the Game Setup for the bot usage
    bot.gameSetup = game_started_event_for_bot.gameSetup
    bot.myId = game_started_event_for_bot.myId

    # activating the bot method
    bot.onGameStarted(game_started_event_for_bot)
    
    # send bot ready
    let bot_ready = BotReady(`type`:Type.botReady)
    await gs_ws.send(bot_ready.toJson)

  of tickEventForBot:
    bot.intent = BotIntent(`type`: Type.botIntent, turnRate:0, gunTurnRate:0, radarTurnRate:0, targetSpeed:8, firePower:0, adjustGunForBodyTurn:bot.adjustGunForBodyTurn, adjustRadarForBodyTurn:bot.adjustRadarForBodyTurn, adjustRadarForGunTurn:bot.adjustRadarForGunTurn, rescan:bot.rescan, fireAssist:bot.fireAssist, bodyColor:bot.bodyColor, turretColor:bot.turretColor, radarColor:bot.radarColor, bulletColor:bot.bulletColor, scanColor:bot.scanColor, tracksColor:bot.tracksColor, gunColor:bot.gunColor)

    let tick_event_for_bot = json_message.fromJson(TickEventForBot)

    # TODO: store this in a more fruible way
    bot.tick = tick_event_for_bot

    # starting run() thread at first tick seen
    if(not firstTickSeen):
      running = true
      spawn run(bot)
      firstTickSeen = true

    # activating the bot method
    bot.onTick(tick_event_for_bot)

    # for every event inside this tick call the relative event for the bot
    for event in tick_event_for_bot.events:
      case parseEnum[Type](event["type"].getStr()):
      of Type.botDeathEvent:
        stopBot()
        bot.onDeath(fromJson($event, BotDeathEvent))
      of Type.botHitWallEvent:
        bot.onHitWall(fromJson($event, BotHitWallEvent))
      of Type.bulletHitBotEvent:
        # conversion from BulletHitBotEvent to HitByBulletEvent
        let hit_by_bullet_event = fromJson($event, HitByBulletEvent)
        hit_by_bullet_event.`type` = Type.hitByBulletEvent
        bot.onHitByBullet(hit_by_bullet_event)
      of Type.botHitBotEvent:
        bot.onHitBot(fromJson($event, BotHitBotEvent))
      of Type.scannedBotEvent:
        bot.onScannedBot(fromJson($event, ScannedBotEvent))        
        # TODO: add all tick events, what for the "NOT HANDLED BOT TICK EVENT" appearing in game
      else:
        echo "NOT HANDLED BOT TICK EVENT: ", event

    
    # send intent
    await gs_ws.send(bot.intent.toJson)
  of gameAbortedEvent:
    stopBot()

    let game_aborted_event = json_message.fromJson(GameAbortedEvent)

      # activating the bot method
    bot.onGameAborted(game_aborted_event)

  of gameEndedEventForBot:
    stopBot()

    let game_ended_event_for_bot = json_message.fromJson(GameEndedEventForBot)

    # activating the bot method
    bot.onGameEnded(game_ended_event_for_bot)

  of skippedTurnEvent:
    let skipped_turn_event = json_message.fromJson(SkippedTurnEvent)
    
    # activating the bot method
    bot.onSkippedTurn(skipped_turn_event)

  of roundEndedEventForBot:
    stopBot()

    let round_ended_event_for_bot = json_message.fromJson(RoundEndedEventForBot)

    # activating the bot method
    bot.onRoundEnded(round_ended_event_for_bot)

  of roundStartedEvent:
    let round_started_event = json_message.fromJson(RoundStartedEvent)

    # activating the bot method
    bot.onRoundStarted(round_started_event)

  else: echo "NOT HANDLED MESSAGE: ",json_message

proc talkWithGS(bot:Bot, url:string) {.async, gcsafe.} =
  try: # try a websocket connection to server
    var gs_ws = await newWebSocket(url)

    if(gs_ws.readyState == Open):
      bot.onConnected(url)

    # while the connection is open...
    while(gs_ws.readyState == Open):

      # listen for a message
      let json_message = await gs_ws.receiveStrPacket()

      # GATE:asas the message is received we if is empty or similar useless message
      if json_message.isEmptyOrWhitespace(): continue

      # send the message to an handler 
      discard handleMessage(bot, json_message, gs_ws)

  # except WebSocketClosedError:
  #   let error = "Socket closed. Check Server output, could be that a wrong secret have been used"
  #   # bot.onConnectionError(error)
  # except WebSocketProtocolMismatchError:
  #   let error = "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
  # except WebSocketError:
  #   let error = "Unexpected socket error: ", getCurrentExceptionMsg()
  except Exception:
    debug("Exception: " & getCurrentExceptionMsg())
    bot.onConnectionError(getCurrentExceptionMsg())

proc newBot*(bot:Bot, json_file:string) =
  debug("Building BOT from JSON file")
  let bot2 = readFile(joinPath(getAppDir(),json_file)).fromJson(bot.type)
  bot.name = bot2.name
  bot.version = bot2.version
  bot.gameTypes = bot2.gameTypes
  bot.authors = bot2.authors
  bot.description = bot2.description
  bot.homepage = bot2.homepage
  bot.countryCodes = bot2.countryCodes
  bot.platform = bot2.platform
  bot.programmingLang = bot2.programmingLang
  bot.secret = getEnv("SERVER_SECRET", "serversecret")
  bot.rescan = false
  bot.fireAssist = false

proc start*(bot:Bot, connect:bool = true) =

  debug("connect is " & $connect)
  
  # connect to the Game Server
  if(connect):
    if bot.secret == "":
      bot.secret = getEnv("SERVER_SECRET", "serversecret")

    debug("connecting, SERVER_URL is " & $existsEnv("SERVER_URL"))

    # for custom values, first parameter is address, second is the port
    gs_address = getEnv("SERVER_URL", "ws://localhost:1234")
  
    debug("Connetting to " & gs_address)
    
    waitFor talkWithGS(bot, gs_address)