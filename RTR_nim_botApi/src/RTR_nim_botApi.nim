#++++++++ standard libraries ++++++++#
import std/[os, strutils, math, sugar, locks]

#++++++++ local components ++++++++#
import RTR_nim_botApi/Components/[Bot, Messages, GamePhysics]
export Bot, Messages

#++++++++ 3rd party libraries ++++++++#
import asyncdispatch, ws, jsony, json

#++++++++ system variables ++++++++#
var firstTickSeen:bool = false
var lastTurnWeSentIntent*:int = -1

var bot*:Bot # Bot object
var gs_ws:WebSocket # websocket connection to the game server
var inputBM: seq[string] = @[] # input and output message buffers
var outputBM: seq[string] = @[] # input and output message buffers

proc put(buffer:var seq[string], message:string) =
    buffer = message & buffer

proc get(buffer: var seq[string]):string =
    buffer.pop()

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

proc newBot*(new_bot:Bot, json_file:string) =
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
  
  let bot2 = readFile(joinPath(getAppDir(),json_file)).fromJson(new_bot.type)
  new_bot.name = bot2.name
  new_bot.version = bot2.version
  new_bot.gameTypes = bot2.gameTypes
  new_bot.authors = bot2.authors
  new_bot.description = bot2.description
  new_bot.homepage = bot2.homepage
  new_bot.countryCodes = bot2.countryCodes
  new_bot.platform = bot2.platform
  new_bot.programmingLang = bot2.programmingLang
  new_bot.secret = getEnv("SERVER_SECRET", "serversecret")
  new_bot.intent_rescan = false
  new_bot.intent_fireAssist = false
  new_bot.initialPosition = InitialPosition(x:0, y:0, angle:0)
  new_bot.ACCELERATION = ACCELERATION
  new_bot.DECELERATION = DECELERATION
  new_bot.MAX_SPEED = MAX_SPEED
  new_bot.current_maxSpeed = MAX_SPEED
  new_bot.MAX_TURN_RATE = MAX_TURN_RATE
  new_bot.MAX_RADAR_TURN_RATE = MAX_RADAR_TURN_RATE
  new_bot.MAX_GUN_TURN_RATE = MAX_GUN_TURN_RATE
  new_bot.MAX_FIRE_POWER = MAX_FIRE_POWER
  new_bot.MIN_FIRE_POWER = MIN_FIRE_POWER

  bot = new_bot

proc messageSender() {.async.} =
    echo "MessageSender started"
    # while the connection is open...
    while true:
        echo "MessageSender cycle"
        # fetch a message from the Output Message Buffer
        # if outputBM.len > 0:
        #     let json_message = outputBM.get()
        #     echo "[API] Sending message: ", json_message
        #     waitFor gs_ws.send(json_message)
        await sleepAsync(1.seconds)
    echo "MessageSender stopped"

proc eventHandler() {.async.} =
    echo "EventHandler started"
    # while the connection is open...
    while(gs_ws.readyState == Open):
        echo "EventHandler cycle"
        # # fetch a message from the input Message Buffer
        # if inputBM.len > 0:
        #     let json_message = inputBM.get()

        #     echo "[API] EventHandler found message: ", json_message

            # # get the type of the message from the message itself
            # let `type` = json_message.fromJson(Message).`type`

            # # echo "[API] Received message: ", json_message
            # # 'case' switch over type
            # case `type`:
            # of serverHandshake:
            #     let server_handshake = json_message.fromJson(ServerHandshake)
            #     let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors, secret:bot.secret, initialPosition:bot.initialPosition)
            #     outputBM.put(bot_handshake.toJson)
            #     echo "[API] Putting bot_handshake in buffer:"
            #     dump(outputBM)
            #     bot.onConnected(bot.serverConnectionURL)
                
            
            # of gameStartedEventForBot:
            #     # in case the bot is still running from a previous game we stop it
            #     bot.stopBot()
            #     # asyncCheck sendIntent(bot)

            #     let game_started_event_for_bot = json_message.fromJson(GameStartedEventForBot)
            #     # store the Game Setup for the bot usage
            #     bot.gameSetup = game_started_event_for_bot.gameSetup
            #     bot.myId = game_started_event_for_bot.myId

            #     # activating the bot method
            #     bot.onGameStarted(game_started_event_for_bot)
                
            #     # send bot ready
            #     let bot_ready = BotReady(`type`:Type.botReady)
            #     waitFor gs_ws.send(bot_ready.toJson)
            #     echo "[API] Sent bot ready: ", bot_ready.toJson
            # of tickEventForBot:
            #     let tick_event_for_bot = json_message.fromJson(TickEventForBot)

            #     # store the tick data for bot in local variables
            #     bot.turnNumber = tick_event_for_bot.turnNumber
            #     bot.roundNumber = tick_event_for_bot.roundNumber
            #     bot.energy = tick_event_for_bot.botState.energy
            #     bot.x = tick_event_for_bot.botState.x
            #     bot.y = tick_event_for_bot.botState.y
            #     bot.direction = tick_event_for_bot.botState.direction
            #     bot.gunDirection = tick_event_for_bot.botState.gunDirection
            #     bot.radarDirection = tick_event_for_bot.botState.radarDirection
            #     bot.radarSweep = tick_event_for_bot.botState.radarSweep
            #     bot.speed = tick_event_for_bot.botState.speed
            #     bot.turnRate = tick_event_for_bot.botState.turnRate
            #     bot.gunHeat = tick_event_for_bot.botState.gunHeat
            #     bot.radarTurnRate = tick_event_for_bot.botState.radarTurnRate
            #     bot.gunTurnRate = tick_event_for_bot.botState.gunTurnRate
            #     bot.gunHeat = tick_event_for_bot.botState.gunHeat

            #     # about colors, we are intent to keep the same color as the previous tick
            #     bot.intent_bodyColor = tick_event_for_bot.botState.bodyColor
            #     bot.intent_turretColor = tick_event_for_bot.botState.turretColor
            #     bot.intent_radarColor = tick_event_for_bot.botState.radarColor
            #     bot.intent_bulletColor = tick_event_for_bot.botState.bulletColor
            #     bot.intent_scanColor = tick_event_for_bot.botState.scanColor
            #     bot.intent_tracksColor = tick_event_for_bot.botState.tracksColor
            #     bot.intent_gunColor = tick_event_for_bot.botState.gunColor

            #     stdout.write "t",bot.getTurnNumber()
            #     stdout.flushFile()

            #     # starting run() thread at first tick seen
            #     if(not firstTickSeen):
            #         firstTickSeen = true

            #     # activating the bot method
            #     bot.onTick(tick_event_for_bot)

            #     # for every event inside this tick call the relative event for the bot
            #     for event in tick_event_for_bot.events:
            #         case parseEnum[Type](event["type"].getStr()):
            #         of Type.botDeathEvent:
            #             bot.stopBot()
            #             bot.onDeath(fromJson($event, BotDeathEvent))
            #         of Type.botHitWallEvent:
            #             bot.remaining_distance = 0
            #             bot.onHitWall(fromJson($event, BotHitWallEvent))
            #         of Type.bulletHitBotEvent:
            #             # conversion from BulletHitBotEvent to HitByBulletEvent
            #             let hit_by_bullet_event = fromJson($event, HitByBulletEvent)
            #             hit_by_bullet_event.`type` = Type.hitByBulletEvent
            #             bot.onHitByBullet(hit_by_bullet_event)
            #         of Type.botHitBotEvent:
            #             bot.remaining_distance = 0
            #             bot.onHitBot(fromJson($event, BotHitBotEvent))
            #         of Type.scannedBotEvent:
            #             bot.onScannedBot(fromJson($event, ScannedBotEvent))        
            #         else:
            #             echo "NOT HANDLED BOT TICK EVENT: ", event
            
            # # send intent
            # of gameAbortedEvent:
            #     # bot.stopBot()

            #     let game_aborted_event = json_message.fromJson(GameAbortedEvent)

            #     # activating the bot method
            #     bot.onGameAborted(game_aborted_event)

            # of gameEndedEventForBot:
            #     bot.stopBot()

            #     let game_ended_event_for_bot = json_message.fromJson(GameEndedEventForBot)

            #     # activating the bot method
            #     bot.onGameEnded(game_ended_event_for_bot)

            # of skippedTurnEvent:
            #     let skipped_turn_event = json_message.fromJson(SkippedTurnEvent)
                
            #     # activating the bot method
            #     bot.onSkippedTurn(skipped_turn_event)

            # of roundEndedEventForBot:
            #     bot.stopBot()

            #     let round_ended_event_for_bot = json_message.fromJson(RoundEndedEventForBot)

            #     # activating the bot method
            #     bot.onRoundEnded(round_ended_event_for_bot)

            # of roundStartedEvent:
            #     bot.runningState = true
            #     # discard runAsync(bot)
            #     let round_started_event = json_message.fromJson(RoundStartedEvent)

            #     # activating the bot method
            #     bot.onRoundStarted(round_started_event)

            # else: echo "NOT HANDLED MESSAGE: ",json_message
        

        await sleepAsync(100)
    echo "eventHandler stopped"

proc messageListener() {.async.} =
    echo "MessageListener started"
    # while the connection is open...
    while(gs_ws.readyState == Open):
        echo "MessageListener waiting for a message"
        # listen for a message
        let json_message = await gs_ws.receiveStrPacket()
        dump(json_message)

        # GATE:as the message is received we if is empty or similar useless message
        if json_message.isEmptyOrWhitespace():
            echo "keep alive"
        else:
            # put the message in the input Message Buffer
            inputBM.put(json_message)
        # await sleepAsync(10)
    echo "MessageListener stopped"

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

    try: # try a websocket connection to server
      gs_ws = waitFor newWebSocket(bot.serverConnectionURL)

      if(gs_ws.readyState == Open):
        echo "[API]Connected to the Game Server"
        # start the 4 async tasks
        # echo "messageListener starting"
        # asyncCheck messageListener()
        echo "messageSender starting"
        asyncCheck messageSender()
        echo "eventHandler starting"
        asyncCheck eventHandler()
        
    except CatchableError:
      bot.onConnectionError(getCurrentExceptionMsg())