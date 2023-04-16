# standard libraries
import std/[os, strutils, threadpool]

# 3rd party libraries
import asyncdispatch, ws, jsony, json

# local components
import RTR_nim_botApi/Components/[Bot, Messages]
export Bot, Messages

# system variables
var runningState*:bool
var firstTickSeen:bool = false
var lastTurnWeSentIntent:int = -1
var sendIntent:bool = false
var gs_ws:WebSocket
var botLocked:bool = false

## GAME VARAIBLES
# game setup
var gameSetup:GameSetup
# my ID for the server
var myId: int
# tick data for Bot
var turnNumber*,roundNumber:int
var energy,x,y,direction,gunDirection,radarDirection,radarSweep,speed,turnRate,gunTurnRate,radarTurnRate,gunHeat:float
var initialPosition:InitialPosition = InitialPosition(x:0, y:0, angle:0)

# game physics
let maxSpeed:float = 8
let maxTurnRate:float = 10
let maxGunTurnRate:float = 20
let maxRadarTurnRate:float = 45
let maxFirePower:float = 3
let minFirePower:float = 0.1

# intent
var intent_turnRate,intent_gunTurnRate,intent_radarTurnRate,intent_targetSpeed,intent_firepower:float
var intent_adjustGunForBodyTurn,intent_adjustRadarForGunTurn,intent_adjustRadarForBodyTurn,intent_rescan,intent_fireAssist:bool
var intent_bodyColor,intent_turretColor,intent_radarColor,intent_bulletColor,intent_scanColor,intent_tracksColor,intent_gunColor:string

# remainings
var remaining_turnRate:float = 0
var remaining_turnGunRate:float = 0
var remaining_turnRadarRate:float = 0

proc updateRemainings() =
  # body turn
  if remaining_turnRate != 0:
    if remaining_turnRate > 0:
      intent_turnRate = min(remaining_turnRate, maxTurnRate)
      remaining_turnRate = max(0, remaining_turnRate - maxTurnRate)
    else:
      intent_turnRate = max(remaining_turnRate, -maxTurnRate)
      remaining_turnRate = min(0, remaining_turnRate + maxTurnRate)

  # gun turn
  if remaining_turnGunRate != 0:
    if remaining_turnGunRate > 0:
      intent_gunTurnRate = min(remaining_turnGunRate, maxGunTurnRate)
      remaining_turnGunRate = max(0, remaining_turnGunRate - maxGunTurnRate)
    else:
      intent_gunTurnRate = max(remaining_turnGunRate, -maxGunTurnRate)
      remaining_turnGunRate = min(0, remaining_turnGunRate + maxGunTurnRate)

  # radar turn
  if remaining_turnRadarRate != 0:
    if remaining_turnRadarRate > 0:
      intent_radarTurnRate = min(remaining_turnRadarRate, maxRadarTurnRate)
      remaining_turnRadarRate = max(0, remaining_turnRadarRate - maxRadarTurnRate)
    else:
      intent_radarTurnRate = max(remaining_turnRadarRate, -maxRadarTurnRate)
      remaining_turnRadarRate = min(0, remaining_turnRadarRate + maxRadarTurnRate)

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

# this function is not 'physically' sending the intent, bit just setting the 'sendIntent' flag to true if is the right moment to do so
proc go*() =
  sendIntent = true
  while sendIntent and runningState:
    sleep(1)

# this loop is responsible for sending the intent to the server, it works untl the bot is a running state and if the sendIntend flag is true
proc sendIntentLoop() {.async.} =
  while(true):
    if sendIntent and lastTurnWeSentIntent < turnNumber:
      updateRemainings()

      let intent = BotIntent(`type`: Type.botIntent, turnRate:intent_turnRate, gunTurnRate:intent_gunTurnRate, radarTurnRate:intent_radarTurnRate, targetSpeed:intent_targetSpeed, firePower:intent_firePower, adjustGunForBodyTurn:intent_adjustGunForBodyTurn, adjustRadarForBodyTurn:intent_adjustRadarForBodyTurn, adjustRadarForGunTurn:intent_adjustRadarForGunTurn, rescan:intent_rescan, fireAssist:intent_fireAssist, bodyColor:intent_bodyColor, turretColor:intent_turretColor, radarColor:intent_radarColor, bulletColor:intent_bulletColor, scanColor:intent_scanColor, tracksColor:intent_tracksColor, gunColor:intent_gunColor)
      await gs_ws.send(intent.toJson)

      lastTurnWeSentIntent = turnNumber

      #reset the intent variables
      intent_turnRate = 0
      intent_gunTurnRate = 0
      intent_radarTurnRate = 0
      intent_targetSpeed = 0
      intent_firePower = 0

      sendIntent = false
            
    else:
      await sleepAsync(1)

# very delicate process, don't touch unless you know what you are doing
# we don't knwow if this will be a blocking call or not, so we need to run it in a separate thread
proc runAsync(bot:Bot) {.thread.} =
  # first run the bot 'run()' method, the one scripted by the bot creator
  # this could be going in loop until the bot is dead or could finish up quckly or could be that is not implemented at all
  bot.run()

  # when the bot creator's 'run()' exits, if the bot is still runnning, we send the intent automatically
  while runningState:
    go()

proc setSecret*(bot:Bot, s:string) =
  bot.secret = s

proc setServerURL*(bot:Bot, url:string) =
  bot.serverConnectionURL = url

# API callable procs
proc isRunning*():bool =
  return runningState

############ BOT SETUP ############
proc setAdjustGunForBodyTurn*(adjust:bool) =
  intent_adjustGunForBodyTurn = adjust

proc setAdjustRadarForGunTurn*(adjust:bool) =
  intent_adjustRadarForGunTurn = adjust

proc setAdjustRadarForBodyTurn*(adjust:bool) =
  intent_adjustRadarForBodyTurn = adjust

proc isAdjustGunForBodyTurn*():bool =
  return intent_adjustGunForBodyTurn

proc isAdjustRadarForGunTurn*():bool =
  return intent_adjustRadarForGunTurn

proc isAdjustRadarForBodyTurn*():bool =
  return intent_adjustRadarForBodyTurn

############ COLORS ############
proc setBodyColor*(color:string) =
  intent_bodyColor = color

proc setTurretColor*(color:string) =
  intent_turretColor = color

proc setRadarColor*(color:string) =
  intent_radarColor = color

proc setBulletColor*(color:string) =
  intent_bulletColor = color

proc setScanColor*(color:string) =
  intent_scanColor = color

proc setTracksColor*(color:string) =
  intent_tracksColor = color

proc setGunColor*(color:string) =
  intent_gunColor = color

proc getBodyColor*():string =
  return intent_bodyColor

proc getTurretColor*():string =
  return intent_turretColor

proc getRadarColor*():string =
  return intent_radarColor

proc getBulletColor*():string =
  return intent_bulletColor

proc getScanColor*():string =
  return intent_scanColor

proc getTracksColor*():string =
  return intent_tracksColor

proc getGunColor*():string =
  return intent_gunColor

############ MISC GETTERS ############
proc getArenaHeight*():int =
  return gameSetup.arenaHeight

proc getArenaWidth*():int =
  return gameSetup.arenaWidth

proc getTurnNumber*():int =
  return turnNumber

proc getTurnRemaining*():float =
  return remaining_turnRate

############ TURNING RADAR ############
proc setTurnRadarLeft*(degrees:float) =
  if not botLocked:
    remaining_turnRadarRate = degrees

proc setTurnRadarRight*(degrees:float) =
  setTurnRadarLeft(-degrees)

proc turnRadarLeft*(degrees:float) =
  # ask to turnRadar left for all degrees, the server will take care of turnRadaring the bot the max amount of degrees allowed
  setTurnRadarLeft(degrees)
  
  # lock the bot, no other actions must be done until the action is completed
  botLocked = true

  # go until the bot is not running or the remaining_turnRadarRate is 0
  while runningState and remaining_turnRadarRate != 0: go()

  # unlock the bot
  botLocked = false

proc turnRadarRight*(degrees:float) =
  turnRadarLeft(-degrees)

proc getRadarTurnRate*():float =
  return remaining_turnRadarRate

proc getRadarDirection*():float =
  return radarDirection

proc getMaxRadarTurnRate*():float =
  return maxRadarTurnRate

############ TURNING GUN ############
proc setTurnGunLeft*(degrees:float) =
  if not botLocked:
    remaining_turnGunRate = degrees

proc setTurnGunRight*(degrees:float) =
  setTurnGunLeft(-degrees)

proc turnGunLeft*(degrees:float) =
  # ask to turnGun left for all degrees, the server will take care of turnGuning the bot the max amount of degrees allowed
  setTurnGunLeft(degrees)
  
  # lock the bot, no other actions must be done until the action is completed
  botLocked = true

  # go until the bot is not running or the remaining_turnGunRate is 0
  while runningState and remaining_turnGunRate != 0: go()

  # unlock the bot
  botLocked = false

proc turnGunRight*(degrees:float) =
  turnGunLeft(-degrees)

proc getGunTurnRate*():float =
  return remaining_turnGunRate

proc getGunDirection*():float =
  return gunDirection

proc getMaxGunTurnRate*():float =
  return maxGunTurnRate

############ TURNING BODY ############
proc setTurnLeft*(degrees:float) =
  if not botLocked:
    remaining_turnRate = degrees

proc setTurnRight*(degrees:float) =
  setTurnLeft(-degrees)

proc turnLeft*(degrees:float) =
  # ask to turn left for all degrees, the server will take care of turning the bot the max amount of degrees allowed
  setTurnLeft(degrees)
  
  # lock the bot, no other actions must be done until the action is completed
  botLocked = true

  # go until the bot is not running or the remaining_turnRate is 0
  while runningState and remaining_turnRate != 0: go()

  # unlock the bot
  botLocked = false

proc turnRight*(degrees:float) =
  turnLeft(-degrees)

proc getTurnRate*():float =
  return remaining_turnRate

proc getDirection*():float =
  return direction

proc getMaxTurnRate*():float =
  return maxTurnRate

############ MOVING ############
proc forward*(degrees:float) = discard #TODO

proc stopBot() = 
  echo "[API] Stopping bot"
  runningState = false
  firstTickSeen = false
  lastTurnWeSentIntent = -1
  sync() # force the run() thread to sync the 'running' variable, don't remove this if not for a good reason!
  echo "[API] Bot stopped"

proc handleMessage(bot:Bot, json_message:string, gs_ws:WebSocket) {.async.} =
  # get the type of the message from the message itself
  let `type` = json_message.fromJson(Message).`type`

  # 'case' switch over type
  case `type`:
  of serverHandshake:
    let server_handshake = json_message.fromJson(ServerHandshake)
    let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors, secret:bot.secret, initialPosition:initialPosition)
    await gs_ws.send(bot_handshake.toJson)
  
  of gameStartedEventForBot:
    # in case the bot is still running from a previuos game we stop it
    stopBot()

    let game_started_event_for_bot = json_message.fromJson(GameStartedEventForBot)
    # store the Game Setup for the bot usage
    gameSetup = game_started_event_for_bot.gameSetup
    myId = game_started_event_for_bot.myId

    # activating the bot method
    bot.onGameStarted(game_started_event_for_bot)
    
    # send bot ready
    let bot_ready = BotReady(`type`:Type.botReady)
    await gs_ws.send(bot_ready.toJson)

  of tickEventForBot:
    let tick_event_for_bot = json_message.fromJson(TickEventForBot)

    # store the tick data for bot in local variables
    turnNumber = tick_event_for_bot.turnNumber
    roundNumber = tick_event_for_bot.roundNumber
    energy = tick_event_for_bot.botState.energy
    x = tick_event_for_bot.botState.x
    y = tick_event_for_bot.botState.y
    direction = tick_event_for_bot.botState.direction
    gunDirection = tick_event_for_bot.botState.gunDirection
    radarDirection = tick_event_for_bot.botState.radarDirection
    radarSweep = tick_event_for_bot.botState.radarSweep
    speed = tick_event_for_bot.botState.speed
    turnRate = tick_event_for_bot.botState.turnRate
    gunHeat = tick_event_for_bot.botState.gunHeat
    radarTurnRate = tick_event_for_bot.botState.radarTurnRate
    gunTurnRate = tick_event_for_bot.botState.gunTurnRate
    gunHeat = tick_event_for_bot.botState.gunHeat

    # about colors, we are intent to keep the same color as the previous tick
    intent_bodyColor = tick_event_for_bot.botState.bodyColor
    intent_turretColor = tick_event_for_bot.botState.turretColor
    intent_radarColor = tick_event_for_bot.botState.radarColor
    intent_bulletColor = tick_event_for_bot.botState.bulletColor
    intent_scanColor = tick_event_for_bot.botState.scanColor
    intent_tracksColor = tick_event_for_bot.botState.tracksColor
    intent_gunColor = tick_event_for_bot.botState.gunColor

    # starting run() thread at first tick seen
    if(not firstTickSeen):
      runningState = true
      spawn runAsync(bot)
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
      else:
        echo "NOT HANDLED BOT TICK EVENT: ", event

    
    # send intent
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

proc talkWithGS(bot:Bot, url:string) {.async.} =
  try: # try a websocket connection to server
    gs_ws = await newWebSocket(url)

    if(gs_ws.readyState == Open):
      bot.onConnected(url)

    # while the connection is open...
    while(gs_ws.readyState == Open):

      # listen for a message
      let json_message = await gs_ws.receiveStrPacket()

      # GATE:asas the message is received we if is empty or similar useless message
      if json_message.isEmptyOrWhitespace(): continue

      # send the message to an handler 
      asyncCheck handleMessage(bot, json_message, gs_ws)

  except CatchableError:
    bot.onConnectionError(getCurrentExceptionMsg())

proc newBot*(bot:Bot, json_file:string) =
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
  intent_rescan = false
  intent_fireAssist = false

proc start*(bot:Bot, connect:bool = true, position:InitialPosition = InitialPosition(x:0,y:0,angle:0)) =
  initialPosition = position

  # connect to the Game Server
  if(connect):
    if bot.secret == "":
      bot.secret = getEnv("SERVER_SECRET", "serversecret")

    if bot.serverConnectionURL == "": 
      bot.serverConnectionURL = getEnv("SERVER_URL", "ws://localhost:7654")

    asyncCheck sendIntentLoop()

    waitFor talkWithGS(bot, bot.serverConnectionURL)