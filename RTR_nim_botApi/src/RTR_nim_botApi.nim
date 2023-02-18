# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

import jsony, json
import std/[os, strutils, threadpool, locks, math]
import asyncdispatch, ws

type
  Color* = enum
    BLACK = "#000000"
    ORANGE = "#ff8300"
    CYAN = "#00f3ff"

  Type* = enum
    botHandshake = "BotHandshake"
    serverHandshake = "ServerHandshake"
    botReady = "BotReady"
    botIntent = "BotIntent"
    gameStartedEventForBot = "GameStartedEventForBot"
    gameEndedEventForBot = "GameEndedEventForBot"
    gameAbortedEvent = "GameAbortedEvent"
    roundStartedEvent = "RoundStartedEvent"
    roundEndedEvent = "RoundEndedEvent"
    roundEndedEventForBot = "RoundEndedEventForBot"
    botDeathEvent = "BotDeathEvent"
    botHitBotEvent = "BotHitBotEvent"
    botHitWallEvent = "BotHitWallEvent"
    bulletFiredEvent = "BulletFiredEvent"
    bulletHitBotEvent = "BulletHitBotEvent"
    bulletHitBulletEvent = "BulletHitBulletEvent"
    bulletHitWallEvent = "BulletHitWallEvent"
    hitByBulletEvent = "HitByBulletEvent"
    scannedBotEvent = "ScannedBotEvent"
    skippedTurnEvent = "SkippedTurnEvent"
    tickEventForBot = "TickEventForBot"
    wonRoundEvent = "WonRoundEvent"
  
  Message* = ref object of RootObj
    `type`*: Type

  InitialPosition = ref object of RootObj
    x,y, angle*: float #The x,y and angle coordinate. When it is not set, a random value will be used

  Event* = ref object of Message
    turnNumber*: int #The turn number in current round when event occurred

  BotDeathEvent* = ref object of Event
    victimId*: int #ID of the bot that has died

  BotHandshake* = ref object of Message
    sessionId*: string #Unique session id that must match the session id received from the server handshake
    name*: string #Name of bot, e.g. Killer Bee
    version*: string #Bot version, e.g. 1.0
    authors*: seq[string] #Name of authors, e.g. John Doe (john_doe@somewhere.net)
    description*: string #Short description of the bot, preferable a one-liner
    homepage*: string #URL to a home page for the bot
    countryCodes*: seq[string] #2-letter country code(s) defined by ISO 3166-1, e.g. "UK"
    gameTypes*: seq[string] #Game types supported by this bot (defined elsewhere), e.g. "classic", "melee" and "1v1"
    platform*: string #Platform used for running the bot, e.g. JVM 17 or .NET 5
    programmingLang*: string #Language used for programming the bot, e.g. Java 17 or C# 10
    initialPosition*: InitialPosition #Initial start position of the bot used for debugging
    secret*: string #Secret used for access control with the server

  BotHitBotEvent* = ref object of Event
    victimId*: int #ID of the victim bot that got hit
    botId*: int #ID of the bot that hit another bot
    energy*: float #Remaining energy level of the victim bot
    x*: float #X coordinate of victim bot
    y*: float #Y coordinate of victim bot
    rammed*: bool #Flag specifying, if the victim bot got rammed
  
  BotHitWallEvent* = ref object of Event
    victimId*: int #ID of the victim bot that hit the wall

  BotIntent* = ref object of Message
    turnRate*: float #Turn rate of the body in degrees per turn (can be positive and negative)
    gunTurnRate*: float #Turn rate of the gun in degrees per turn (can be positive and negative)
    radarTurnRate*: float #Turn rate of the radar in degrees per turn (can be positive and negative)
    targetSpeed*: float #New target speed in units per turn (can be positive and negative)
    firePower*: float #Attempt to fire gun with the specified firepower
    adjustGunForBodyTurn*: bool #Flag indicating if the gun must be adjusted to compensate for the body turn. Default is false.
    adjustRadarForBodyTurn*: bool #Flag indicating if the radar must be adjusted to compensate for the body turn. Default is false.
    adjustRadarForGunTurn*: bool #Flag indicating if the radar must be adjusted to compensate for the gun turn. Default is false.
    rescan*: bool #Flag indicating if the bot should rescan with previous radar direction and scan sweep angle.
    fireAssist*: bool #Flag indication if fire assistance is enabled.
    bodyColor*: string #New color of the body
    turretColor*: string #New color of the cannon turret
    radarColor*: string #New color of the radar
    bulletColor*: string #New color of the bullet. Note. This will be the color of a bullet when it is fired
    scanColor*: string #New color of the scan arc
    tracksColor*: string #New color of the tracks
    gunColor*: string #New color of the gun

  BotReady* = ref object of Message

  BotResultsForBot* = ref object of RootObj
    rank*: int #Rank/placement of the bot, where 1 is 1st place, 4 is 4th place etc.
    survival*: int #Survival score gained whenever another bot is defeated
    lastSurvivorBonus*: int #Last survivor score as last survivor in a round
    bulletDamage*: int #Bullet damage given
    bulletKillBonus*: int #Bullet kill bonus
    ramDamage*: int #Ram damage given
    ramKillBonus*: int #Ram kill bonus
    totalScore*: int #Total score
    firstPlaces*: int #Number of 1st places
    secondPlaces*: int #Number of 2nd places
    thirdPlaces*: int #Number of 3rd places

  BotState* = ref object of RootObj
    energy*: float #Energy level
    x*: float #X coordinate
    y*: float #Y coordinate
    direction*: float #Driving direction in degrees
    gunDirection*: float #Gun direction in degrees
    radarDirection*: float #Radar direction in degrees
    radarSweep*: float #Radar sweep angle in degrees, i.e. angle between previous and current radar direction
    speed*: float #Speed measured in units per turn
    turnRate*: float #Turn rate of the body in degrees per turn (can be positive and negative)
    gunTurnRate*: float #Turn rate of the gun in degrees per turn (can be positive and negative)
    radarTurnRate*: float #Turn rate of the radar in degrees per turn (can be positive and negative)
    gunHeat*: float #Gun heat
    bodyColor*: string #Current RGB color of the body
    turretColor*: string #Current color of the cannon turret
    radarColor*: string #Current color of the radar
    bulletColor*: string #Current color of the bullet. Note. This will be the color of a bullet when it is fired
    scanColor*: string #Current color of the scan arc
    tracksColor*: string #Current color of the tracks
    gunColor*: string #Current color of the gun
  
  BulletFiredEvent* = ref object of Event
    bullet*: BulletState #Bullet that was fired

  BulletHitBotEvent* = ref object of Event
    victimId*: int #ID of the bot that got hit
    bullet*: BulletState #Bullet that hit the bot
    damage*: float #Damage inflicted by the bullet
    energy*: float #Remaining energy level of the bot that got hit

  BulletHitBulletEvent* = ref object of Event
    bullet*: BulletState #Bullet that hit another bullet
    hitBullet*: BulletState #The other bullet that was hit by the bullet

  BulletHitWallEvent* = ref object of Event
    bullet*: BulletState #Bullet that has hit a wall

  BulletState* = ref object of RootObj
    bulletId*: int #ID of the bullet
    ownerId*: int #ID of the bot that fired the bullet
    power*: float #Bullet firepower (between 0.1 and 3.0)
    x*: float #X coordinate
    y*: float #Y coordinate
    direction*: float #Direction in degrees
    color*: string #Color of the bullet

  GameSetup* = ref object of RootObj
    gameType*: string #Type of game
    arenaWidth*: int #Width of arena measured in units
    isArenaWidthLocked*: bool #Flag specifying if the width of arena is fixed for this game type
    arenaHeight*: int #Height of arena measured in units
    isArenaHeightLocked*: bool #Flag specifying if the height of arena is fixed for this game type
    minNumberOfParticipants*: int #Minimum number of bots participating in battle
    isMinNumberOfParticipantsLocked*: bool #Flag specifying if the minimum number of bots participating in battle
    maxNumberOfParticipants*: int #Maximum number of bots participating in battle
    isMaxNumberOfParticipantsLocked*: bool #Flag specifying if the maximum number of bots participating in battle
    numberOfRounds*: int #Number of rounds in battle
    isNumberOfRoundsLocked*: bool #Flag specifying if the number-of-rounds is fixed for this game type
    gunCoolingRate*: float #Gun cooling rate. The gun needs to cool down to a gun heat of zero
    isGunCoolingRateLocked*: bool #Flag specifying if the gun cooling rate is fixed for this game type
    maxInactivityTurns*: int #Maximum number of inactive turns allowed, where a bot does not take
    isMaxInactivityTurnsLocked*: bool #Flag specifying if the inactive turns is fixed for this game type
    turnTimeout*: int #Turn timeout in microseconds (1 / 1,000,000 second) for sending intent after having received 'tick' message
    isTurnTimeoutLocked*: bool #Flag specifying if the turn timeout is fixed for this game type
    readyTimeout*: int #Time limit in microseconds (1 / 1,000,000 second) for sending ready
    isReadyTimeoutLocked*: bool #Flag specifying if the ready timeout is fixed for this game type
    defaultTurnsPerSecond*: int #Default number of turns to show per second for an observer/UI

  GameAbortedEvent* = ref object of Message

  GameEndedEventForBot* = ref object of Message
    numberOfRounds*: int #Number of rounds played
    results*: BotResultsForBot #Bot results of the battle

  GameStartedEventForBot* = ref object of Message
    myId*: int #My ID is an unique identifier for this bot
    gameSetup*: GameSetup #Game setup

  HitByBulletEvent* = ref object of Event
    bullet*: BulletState #Bullet that has hit the bot
    damage*: float #Damage inflicted by the bullet
    energy*: float #Remaining energy level of the bot after the damage was inflicted

  RoundStartedEvent* = ref object of Message
    roundNumber*: int #The current round number in the battle when event occurred

  RoundEndedEventForBot* = ref object of Message
    roundNumber*: int #The current round number in the battle when event occurred
    turnNumber*: int #The current turn number in the round when event occurred
    results*: BotResultsForBot #The accumulated bot results by the end of the round.

  ScannedBotEvent* = ref object of Event
    scannedByBotId*: int #ID of the bot did the scanning
    scannedBotId*: int #ID of the bot that was scanned
    energy*: float #Energy level of the scanned bot
    x*: float #X coordinate of the scanned bot
    y*: float #Y coordinate of the scanned bot
    direction*: float #Direction in degrees of the scanned bot
    speed*: float #Speed measured in units per turn of the scanned bot

  ServerHandshake* = ref object of Message
    sessionId*: string #Unique session id used for identifying the caller client (bot, controller, observer) connection.
    name*: string #Name of server, e.g. John Doe's RoboRumble Server
    variant*: string #Game variant, e.g. 'Tank Royale' for Robocode Tank Royale
    version*: string #Game version, e.g. '1.0.0' using Semantic Versioning (https://semver.org/)
    gameTypes*: seq[string] #Game types running at this server, e.g. "melee" and "1v1"

  SkippedTurnEvent* = ref object of Event

  TickEventForBot* = ref object of Event
    roundNumber*: int #The current round number in the battle when event occurred
    enemyCount*: int #Number of enemies left in the current round
    botState*: BotState #Current state of this bot
    bulletStates*: seq[BulletState] #Current state of the bullets fired by this bot
    events*: JsonNode #Events occurring in the turn relevant for this bot

  WonRoundEvent* = ref object of Event

type
  Bot* = ref object of RootObj
    # bot related
    name*,version*,description*,homepage*,secret,platform*,programmingLang*:string
    gameTypes*,authors*,countryCodes*:seq[string]
    gameSetup*:GameSetup
    tick*:TickEventForBot
    myId*: int
    adjustGunForBodyTurn*,adjustRadarForBodyTurn*,adjustRadarForGunTurn*:bool
    rescan*,fireAssist*:bool
    bodyColor*,turretColor*,radarColor*,bulletColor*,scanColor*,tracksColor*,gunColor*:string
    intent:BotIntent

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

# system variables
var gs_address:string
var debug_is_enabled = false
var runlock: Lock
var running {.guard: runlock.}:bool
var firstTickSeen:bool = false

# API callable procs
proc isRunning*(bot:Bot):bool =
  {.locks: [runlock].}:
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
  {.locks: [runlock].}: running = false
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
      {.locks: [runlock].}:running = true
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
    bot.onConnectionError(getCurrentExceptionMsg())

proc start*(bot:Bot, json_file:string, connect:bool = true) =
  debug("Building BOT from JSON file")
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
  bot.secret = getEnv("SERVER_SECRET", "serversecret")
  bot.rescan = false
  bot.fireAssist = false

  debug("connect is " & $connect)
  
  # connect to the Game Server
  if(connect):
    debug("connecting, SERVER_URL is " & $existsEnv("SERVER_URL"))

    # for custom values, first parameter is address, second is the port
    gs_address = getEnv("SERVER_URL", "ws://localhost:7654")
  
    debug("Connetting to " & gs_address)
    
    waitFor talkWithGS(bot, gs_address)