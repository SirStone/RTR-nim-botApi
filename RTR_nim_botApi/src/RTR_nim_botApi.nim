## ***ROBOCODE TANKROYALE BOT API FOR NIM***

#++++++++ standard libraries ++++++++#
import std/[os, strutils, math, threadpool]

#++++++++ 3rd party libraries ++++++++#
import asyncdispatch, ws, jsony, json

#++++++++ local components ++++++++#
import RTR_nim_botApi/Components/[Bot, Messages, GamePhysics]
export Bot, Messages

#++++++++ system variables ++++++++#
var firstTickSeen:bool = false
var lastTurnWeSentIntent*:int = -1
# var sendIntent*:bool = false
var gs_ws:WebSocket
var botRun = false
var sendFlag = false
var bot3:Bot
var chan: Channel[string]

proc updateRemainings(bot:Bot) =
  # body turn
  if bot.remaining_turnRate != 0:
    if bot.remaining_turnRate > 0:
      bot.intent_turnRate = min(bot.remaining_turnRate, MAX_TURN_RATE)
      bot.remaining_turnRate = max(0, bot.remaining_turnRate - MAX_TURN_RATE)
    else:
      bot.intent_turnRate = max(bot.remaining_turnRate, -MAX_TURN_RATE)
      bot.remaining_turnRate = min(0, bot.remaining_turnRate + MAX_TURN_RATE)

  # gun turn
  if bot.remaining_turnGunRate != 0:
    if bot.remaining_turnGunRate > 0:
      bot.intent_gunTurnRate = min(bot.remaining_turnGunRate, MAX_GUN_TURN_RATE)
      bot.remaining_turnGunRate = max(0, bot.remaining_turnGunRate - MAX_GUN_TURN_RATE)
    else:
      bot.intent_gunTurnRate = max(bot.remaining_turnGunRate, -MAX_GUN_TURN_RATE)
      bot.remaining_turnGunRate = min(0, bot.remaining_turnGunRate + MAX_GUN_TURN_RATE)

  # radar turn
  if bot.remaining_turnRadarRate != 0:
    if bot.remaining_turnRadarRate > 0:
      bot.intent_radarTurnRate = min(bot.remaining_turnRadarRate, MAX_RADAR_TURN_RATE)
      bot.remaining_turnRadarRate = max(0, bot.remaining_turnRadarRate - MAX_RADAR_TURN_RATE)
    else:
      bot.intent_radarTurnRate = max(bot.remaining_turnRadarRate, -MAX_RADAR_TURN_RATE)
      bot.remaining_turnRadarRate = min(0, bot.remaining_turnRadarRate + MAX_RADAR_TURN_RATE)

  # target speed calculation
  if bot.remaining_distance != 0:
    # how much turns requires to stop from the current speed? t = (V_target - V_current)/ -acceleration
    let turnsRequiredToStop = -bot.speed.abs / DECELERATION
    let remaining_distance_breaking = bot.speed.abs * turnsRequiredToStop + 0.5 * DECELERATION * turnsRequiredToStop.pow(2)
    if bot.remaining_distance > 0: # going forward
      # echo "[API] Turns required to stop: ", turnsRequiredToStop, " my speed: ", speed, " remaining distance: ", remaining_distance, " remaining distance breaking: ", remaining_distance_breaking

      # if the distance left is less or equal than the turns required to stop, then we need to slow down
      if bot.remaining_distance - remaining_distance_breaking < bot.speed:
        bot.intent_targetSpeed = max(0, bot.speed+DECELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed # what we left for stopping
      else: # if the distance left is more than the turns required to stop, then we need to speed up to max speed
        # if the current_maxSpeed changes over time this will work for adjusting to the new velocity too
        bot.intent_targetSpeed = min(bot.current_maxSpeed, bot.speed+ACCELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed 
    else: # going backward
      # echo "[API] Turns required to stop: ", turnsRequiredToStop, " my speed: ", speed, " remaining distance: ", remaining_distance, " remaining distance breaking: ", remaining_distance_breaking

      # if the distance left is less or equal than the turns required to stop, then we need to slow down
      if bot.remaining_distance.abs - remaining_distance_breaking < bot.speed.abs:
        bot.intent_targetSpeed = min(0, bot.speed-DECELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed # what we left for stopping
      else: # if the distance left is more than the turns required to stop, then we need to speed up to max speed
        # if the current_maxSpeed changes over time this will work for adjusting to the new velocity too
        bot.intent_targetSpeed = max(-bot.current_maxSpeed, bot.speed-ACCELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed

proc resetIntentVariables(bot:Bot) =
  bot.intent_turnRate = 0
  bot.intent_gunTurnRate = 0
  bot.intent_radarTurnRate = 0
  bot.intent_targetSpeed = 0
  bot.intent_firePower = 0
  bot.intent_rescan = false

# this function is not 'physically' sending the intent, bit just setting the 'sendIntent' flag to true if is the right moment to do so
proc sendIntentLoop(bot:Bot) {.thread.} =
  echo "[API] sendIntent STARTED"
  while true:
    if not bot.isRunning():
      sleep(1)
    else:
      if lastTurnWeSentIntent < bot.getTurnNumber() and sendFlag: # we can send the intent only once per turn
        echo "[API] sendIntent SENDING"
        updateRemainings(bot)

        # if remaining_distance != 0: echo "[API] intent_targetSpeed: " & $intent_targetSpeed
        let intent = BotIntent(`type`: Type.botIntent, turnRate:bot.intent_turnRate, gunTurnRate:bot.intent_gunTurnRate, radarTurnRate:bot.intent_radarTurnRate, targetSpeed:bot.intent_targetSpeed, firepower:bot.intent_firePower, adjustGunForBodyTurn:bot.intent_adjustGunForBodyTurn, adjustRadarForBodyTurn:bot.intent_adjustRadarForBodyTurn, adjustRadarForGunTurn:bot.intent_adjustRadarForGunTurn, rescan:bot.intent_rescan, fireAssist:bot.intent_fireAssist, bodyColor:bot.intent_bodyColor, turretColor:bot.intent_turretColor, radarColor:bot.intent_radarColor, bulletColor:bot.intent_bulletColor, scanColor:bot.intent_scanColor, tracksColor:bot.intent_tracksColor, gunColor:bot.intent_gunColor)
        # asyncCheck gs_ws.send(intent.toJson) #TODO: this must be romoved from here, is breaking the WebSocket
        echo "[API] Sent intent: ", intent.toJson

        lastTurnWeSentIntent = bot.getTurnNumber()

        # reset the intent variables
        resetIntentVariables(bot)

        sendFlag = false
      # echo "[API] sendIntent sleeping, lastTurnWeSentIntent: ", lastTurnWeSentIntent, " bot.getTurnNumber(): ", bot.getTurnNumber()

proc go(bot:Bot) =
  ## call `go()` to send the intent immediately
  sendFlag = true
  sleep(1)
  
# very delicate process, don't touch unless you know what you are doing
# we don't knwow if this will be a blocking call or not, so we need to run it in a separate thread
proc runAsync(bot:Bot) {.thread.} =
  while true:
    if not bot.isRunning():
      sleep(1)
    else:
      echo "[API] Bot run() started"
      # first run the bot 'run()' method, the one scripted by the bot creator
      bot.run() # this could be going in loop until the bot is dead or could finish up quckly or could be that is not implemented at all
      echo "[API] Bot run() finished, starting the automatic go() loop"

      # when the bot creator's 'run()' exits, if the bot is still runnning, we send the intent automatically
      while bot.isRunning():
        bot.go()
        # TODO: if you put an `await sleepAsync(1) here the API will start working, but I don;t like this solution, I want to find a better one
      echo "[API] Bot automatic go() loop finished"

proc stopBot(bot:Bot) = 
  bot.runningState = false
  firstTickSeen = false
  lastTurnWeSentIntent = -1
  bot.locked = false
  # sendIntent = true

  bot.remaining_distance = 0
  bot.remaining_turnGunRate = 0
  bot.remaining_turnRate = 0
  bot.remaining_turnRadarRate = 0

  resetIntentVariables(bot)

  # sync() # force the run() thread to sync the 'running' variable, don't remove this if not for a good reason!

proc messageHandler() =
  while true:
    let tried = chan.tryRecv()
    if tried.dataAvailable:
      echo "[API]",tried.msg
    else:
      sleep(100)
  # # get the type of the message from the message itself
  # let `type` = json_message.fromJson(Message).`type`

  # # 'case' switch over type
  # case `type`:
  # of serverHandshake:
  #   let server_handshake = json_message.fromJson(ServerHandshake)
  #   let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors, secret:bot.secret, initialPosition:bot.initialPosition)
  #   waitFor gs_ws.send(bot_handshake.toJson)
  
  # of gameStartedEventForBot:
  #   # in case the bot is still running from a previous game we stop it
  #   bot.stopBot()

  #   let game_started_event_for_bot = json_message.fromJson(GameStartedEventForBot)
  #   # store the Game Setup for the bot usage
  #   bot.gameSetup = game_started_event_for_bot.gameSetup
  #   bot.myId = game_started_event_for_bot.myId

  #   # activating the bot method
  #   bot.onGameStarted(game_started_event_for_bot)
    
  #   # send bot ready
  #   let bot_ready = BotReady(`type`:Type.botReady)
  #   waitFor gs_ws.send(bot_ready.toJson)
  #   echo "[API] Sent bot ready: ", bot_ready.toJson
  # of tickEventForBot:
  #   let tick_event_for_bot = json_message.fromJson(TickEventForBot)

  #   # store the tick data for bot in local variables
  #   bot.turnNumber = tick_event_for_bot.turnNumber
  #   bot.roundNumber = tick_event_for_bot.roundNumber
  #   bot.energy = tick_event_for_bot.botState.energy
  #   bot.x = tick_event_for_bot.botState.x
  #   bot.y = tick_event_for_bot.botState.y
  #   bot.direction = tick_event_for_bot.botState.direction
  #   bot.gunDirection = tick_event_for_bot.botState.gunDirection
  #   bot.radarDirection = tick_event_for_bot.botState.radarDirection
  #   bot.radarSweep = tick_event_for_bot.botState.radarSweep
  #   bot.speed = tick_event_for_bot.botState.speed
  #   bot.turnRate = tick_event_for_bot.botState.turnRate
  #   bot.gunHeat = tick_event_for_bot.botState.gunHeat
  #   bot.radarTurnRate = tick_event_for_bot.botState.radarTurnRate
  #   bot.gunTurnRate = tick_event_for_bot.botState.gunTurnRate
  #   bot.gunHeat = tick_event_for_bot.botState.gunHeat

  #   # about colors, we are intent to keep the same color as the previous tick
  #   bot.intent_bodyColor = tick_event_for_bot.botState.bodyColor
  #   bot.intent_turretColor = tick_event_for_bot.botState.turretColor
  #   bot.intent_radarColor = tick_event_for_bot.botState.radarColor
  #   bot.intent_bulletColor = tick_event_for_bot.botState.bulletColor
  #   bot.intent_scanColor = tick_event_for_bot.botState.scanColor
  #   bot.intent_tracksColor = tick_event_for_bot.botState.tracksColor
  #   bot.intent_gunColor = tick_event_for_bot.botState.gunColor

  #   stdout.write "t",bot.getTurnNumber()
  #   stdout.flushFile()

  #   # starting run() thread at first tick seen
  #   if(not firstTickSeen):
  #     firstTickSeen = true
  #     bot.runningState = true

  #   # activating the bot method
  #   bot.onTick(tick_event_for_bot)

  #   # for every event inside this tick call the relative event for the bot
  #   for event in tick_event_for_bot.events:
  #     case parseEnum[Type](event["type"].getStr()):
  #     of Type.botDeathEvent:
  #       bot.stopBot()
  #       bot.onDeath(fromJson($event, BotDeathEvent))
  #     of Type.botHitWallEvent:
  #       bot.remaining_distance = 0
  #       bot.onHitWall(fromJson($event, BotHitWallEvent))
  #     of Type.bulletHitBotEvent:
  #       # conversion from BulletHitBotEvent to HitByBulletEvent
  #       let hit_by_bullet_event = fromJson($event, HitByBulletEvent)
  #       hit_by_bullet_event.`type` = Type.hitByBulletEvent
  #       bot.onHitByBullet(hit_by_bullet_event)
  #     of Type.botHitBotEvent:
  #       bot.remaining_distance = 0
  #       bot.onHitBot(fromJson($event, BotHitBotEvent))
  #     of Type.scannedBotEvent:
  #       bot.onScannedBot(fromJson($event, ScannedBotEvent))        
  #     else:
  #       echo "NOT HANDLED BOT TICK EVENT: ", event

    
  #   # send intent
  # of gameAbortedEvent:
  #   bot.stopBot()

  #   let game_aborted_event = json_message.fromJson(GameAbortedEvent)

  #   # activating the bot method
  #   bot.onGameAborted(game_aborted_event)

  # of gameEndedEventForBot:
  #   bot.stopBot()

  #   let game_ended_event_for_bot = json_message.fromJson(GameEndedEventForBot)

  #   # activating the bot method
  #   bot.onGameEnded(game_ended_event_for_bot)

  # of skippedTurnEvent:
  #   let skipped_turn_event = json_message.fromJson(SkippedTurnEvent)
    
  #   # activating the bot method
  #   bot.onSkippedTurn(skipped_turn_event)

  # of roundEndedEventForBot:
  #   bot.stopBot()

  #   let round_ended_event_for_bot = json_message.fromJson(RoundEndedEventForBot)

  #   # activating the bot method
  #   bot.onRoundEnded(round_ended_event_for_bot)

  # of roundStartedEvent:
  #   let round_started_event = json_message.fromJson(RoundStartedEvent)

  #   # activating the bot method
  #   bot.onRoundStarted(round_started_event)

  # else: echo "NOT HANDLED MESSAGE: ",json_message

proc messageListener(url:string) {.gcsafe.}=
  try: # try a websocket connection to server
    gs_ws = waitFor newWebSocket(url)

    # if(gs_ws.readyState == Open):
    #   bot.onConnected(url)

    # while the connection is open...
    while(gs_ws.readyState == Open):

      # listen for a message
      let json_message = waitFor gs_ws.receiveStrPacket()

      # GATE:asas the message is received we if is empty or similar useless message
      if json_message.isEmptyOrWhitespace(): continue

      # send the message to an handler 
      # handleMessage(bot, json_message, gs_ws)
      chan.send(json_message)

  except CatchableError:
    bot3.onConnectionError(getCurrentExceptionMsg())

proc newBot*(bot:Bot, json_file:string) =
  ## **Create a new bot instance**
  ## 
  ## This method is used to create a new bot instance.
  ## 
  ## The bot instance is created with the data contained in the json file.
  ## 
  ## the passed Bot object must be a new `type ref object of Bot`. Example:
  ## 
  ## .. code-block:: nim 
  ##  type
  ##    MyBot = ref object of Bot
  ##  var my_bot = MyBot()
  ##  my_bot.newBot("my_bot.json")
  ## 
  ## To create a json file for your bot follow the `official Robocode TankRoyale documentation
  ## <https://robocode-dev.github.io/tank-royale/tutorial/my-first-bot.html>`_.
  
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
  bot.intent_rescan = false
  bot.intent_fireAssist = false
  bot.initialPosition = InitialPosition(x:0, y:0, angle:0)
  bot.ACCELERATION = ACCELERATION
  bot.DECELERATION = DECELERATION
  bot.MAX_SPEED = MAX_SPEED
  bot.current_maxSpeed = MAX_SPEED
  bot.MAX_TURN_RATE = MAX_TURN_RATE
  bot.MAX_RADAR_TURN_RATE = MAX_RADAR_TURN_RATE
  bot.MAX_GUN_TURN_RATE = MAX_GUN_TURN_RATE
  bot.MAX_FIRE_POWER = MAX_FIRE_POWER
  bot.MIN_FIRE_POWER = MIN_FIRE_POWER

  bot3 = bot

proc start*(bot:Bot, connect:bool = true, position:InitialPosition = InitialPosition(x:0,y:0,angle:0)) =
  ## **Start the bot**
  ## 
  ## This method is used to start the bot instance. This coincide with asking the bot to connect to the game server
  ## 
  ## `bot` is your bot istance that you created with the `newBot` procedure.
  ## 
  ## `connect` (can be omitted) is a boolean value that if `true` (default) will ask the bot to connect to the game server.
  ## If `false` the bot will not connect to the game server. Mostly used for testing.
  ## 
  ## `position` (can be omitted) is the initial position of the bot. If not specified the bot will be placed at the center of the map.
  ## This custom position will work if the server is configured to use the custom initial positions.
  
  bot.initialPosition = position

  # connect to the Game Server
  if(connect):
    if bot.secret == "":
      bot.secret = getEnv("SERVER_SECRET", "serversecret")

    if bot.serverConnectionURL == "": 
      bot.serverConnectionURL = getEnv("SERVER_URL", "ws://localhost:7654")
    
    chan.open()
    var messageListenerWorker: Thread[void]
    var messageHandlerWorker: Thread[void]
    createThread(messageListenerWorker, messageListener)
    createThread(messageHandlerWorker, messageHandler)
    
    messageListenerWorker.joinThread()
    chan.close()