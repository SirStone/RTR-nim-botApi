#++++++++ standard libraries ++++++++#
import std/[os, strutils, math, sugar, threadpool]

#++++++++ local components ++++++++#
import RTR_nim_botApi/Components/[Bot, Messages, GamePhysics]
export Bot, Messages

#++++++++ 3rd party libraries ++++++++#
import asyncdispatch, ws, jsony, json

#++++++++ system variables ++++++++#
var firstTickSeen:bool = false
var lastTurnWeSentIntent*:int = -1

var bot{.threadvar.}:Bot # Bot object
var gs_ws:WebSocket # websocket connection to the game server
var inputBM: seq[string] = @[] # input and output message buffers
var outputBM: seq[string] = @[] # input and output message buffers

proc put(buffer:var seq[string], message:string) =
    buffer = message & buffer

proc get(buffer: var seq[string]):string =
    buffer.pop()

proc updateRemainings*(bot:Bot) =
  # echo "[API] Updating remainings"
  # dump bot[]
  # body turn
  if bot.remaining_turnRate != 0:
    if bot.remaining_turnRate > 0:
      bot.intent_turnRate = min(bot.remaining_turnRate, bot.MAX_TURN_RATE)
      bot.remaining_turnRate = max(0, bot.remaining_turnRate - bot.MAX_TURN_RATE)
    else:
      bot.intent_turnRate = max(bot.remaining_turnRate, -bot.MAX_TURN_RATE)
      bot.remaining_turnRate = min(0, bot.remaining_turnRate + bot.MAX_TURN_RATE)

  # gun turn
  if bot.remaining_turnGunRate != 0:
    if bot.remaining_turnGunRate > 0:
      bot.intent_gunTurnRate = min(bot.remaining_turnGunRate, bot.MAX_GUN_TURN_RATE)
      bot.remaining_turnGunRate = max(0, bot.remaining_turnGunRate - bot.MAX_GUN_TURN_RATE)
    else:
      bot.intent_gunTurnRate = max(bot.remaining_turnGunRate, -bot.MAX_GUN_TURN_RATE)
      bot.remaining_turnGunRate = min(0, bot.remaining_turnGunRate + bot.MAX_GUN_TURN_RATE)

  # radar turn
  if bot.remaining_turnRadarRate != 0:
    if bot.remaining_turnRadarRate > 0:
      bot.intent_radarTurnRate = min(bot.remaining_turnRadarRate, bot.MAX_RADAR_TURN_RATE)
      bot.remaining_turnRadarRate = max(0, bot.remaining_turnRadarRate - bot.MAX_RADAR_TURN_RATE)
    else:
      bot.intent_radarTurnRate = max(bot.remaining_turnRadarRate, -bot.MAX_RADAR_TURN_RATE)
      bot.remaining_turnRadarRate = min(0, bot.remaining_turnRadarRate + bot.MAX_RADAR_TURN_RATE)

  # target speed calculation
  if bot.remaining_distance != 0:
    # how much turns requires to stop from the current speed? t = (V_target - V_current)/ -acceleration
    let turnsRequiredToStop = -bot.speed.abs / bot.DECELERATION
    let remaining_distance_breaking = bot.speed.abs * turnsRequiredToStop + 0.5 * bot.DECELERATION * turnsRequiredToStop.pow(2)
    if bot.remaining_distance > 0: # going forward
      # echo "[API] Turns required to stop: ", turnsRequiredToStop, " my speed: ", speed, " remaining distance: ", bot.remaining_distance, " remaining distance breaking: ", bot.remaining_distance_breaking

      # if the distance left is less or equal than the turns required to stop, then we need to slow down
      if bot.remaining_distance - remaining_distance_breaking < bot.speed:
        bot.intent_targetSpeed = max(0, bot.speed+bot.DECELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed # what we left for stopping
      else: # if the distance left is more than the turns required to stop, then we need to speed up to max speed
        # if the current_maxSpeed changes over time this will work for adjusting to the new velocity too
        bot.intent_targetSpeed = min(bot.current_maxSpeed, bot.speed+bot.ACCELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed 
    else: # going backward
      # echo "[API] Turns required to stop: ", turnsRequiredToStop, " my speed: ", speed, " remaining distance: ", bot.remaining_distance, " remaining distance breaking: ", bot.remaining_distance_breaking

      # if the distance left is less or equal than the turns required to stop, then we need to slow down
      if bot.remaining_distance.abs - remaining_distance_breaking < bot.speed.abs:
        bot.intent_targetSpeed = min(0, bot.speed-bot.DECELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed # what we left for stopping
      else: # if the distance left is more than the turns required to stop, then we need to speed up to max speed
        # if the current_maxSpeed changes over time this will work for adjusting to the new velocity too
        bot.intent_targetSpeed = max(-bot.current_maxSpeed, bot.speed-bot.ACCELERATION)
        bot.remaining_distance = bot.remaining_distance - bot.intent_targetSpeed

proc go*(bot:Bot) =
  ## Use this function to send the intent to the server

  # check if inent has already been sent this turn
  if bot.turnNumber > lastTurnWeSentIntent:
    # update the last turn we sent the intent
    lastTurnWeSentIntent = bot.turnNumber
    # update the remaingings
    updateRemainings(bot)
    # create a new intent message
    let intent = BotIntent(`type`: Type.botIntent, turnRate:bot.intent_turnRate, gunTurnRate:bot.intent_gunTurnRate, radarTurnRate:bot.intent_radarTurnRate, targetSpeed:bot.intent_targetSpeed, firepower:bot.intent_firePower, adjustGunForBodyTurn:bot.intent_adjustGunForBodyTurn, adjustRadarForBodyTurn:bot.intent_adjustRadarForBodyTurn, adjustRadarForGunTurn:bot.intent_adjustRadarForGunTurn, rescan:bot.intent_rescan, fireAssist:bot.intent_fireAssist, bodyColor:bot.intent_bodyColor, turretColor:bot.intent_turretColor, radarColor:bot.intent_radarColor, bulletColor:bot.intent_bulletColor, scanColor:bot.intent_scanColor, tracksColor:bot.intent_tracksColor, gunColor:bot.intent_gunColor)
    # put the intent in the output queue
    outputBM.put intent.toJson

proc setSecret*(bot:Bot, s:string) =
  ## Use this function to override the default method to receive the secret
  ## 
  ## must be called before `start()`
  bot.secret = s

proc setServerURL*(bot:Bot, url:string) =
  ## Use this function to override the default method to receive the server URL
  ## 
  ## must be called before `start()`
  bot.serverConnectionURL = url

# API callable procs
proc isRunning*(bot:Bot):bool =
  ## returns true if the bot is alive
  return bot.runningState

#++++++++ BOT SETUP +++++++++#
proc setAdjustGunForBodyTurn*(bot:Bot, adjust:bool) =
  ## this is permanent, no need to call this multiple times
  ## 
  ## use ``true`` if the gun should turn independent from the body
  ## 
  ## use ``false`` if the gun should turn with the body
  bot.intent_adjustGunForBodyTurn = adjust

proc setAdjustRadarForGunTurn*(bot:Bot, adjust:bool) =
  ## this is permanent, no need to call this multiple times
  ## 
  ## use ``true`` if the radar should turn independent from the gun
  ## 
  ## use ``false`` if the radar should turn with the gun
  bot.intent_adjustRadarForGunTurn = adjust

proc setAdjustRadarForBodyTurn*(bot:Bot, adjust:bool) =
  ## this is permanent, no need to call this multiple times
  ## 
  ## use ``true`` if the radar should turn independent from the body
  ## 
  ## use ``false`` if the radar should turn with the body
  bot.intent_adjustRadarForBodyTurn = adjust

proc isAdjustGunForBodyTurn*(bot:Bot):bool =
  ## returns true if the gun is turning independent from the body
  return bot.intent_adjustGunForBodyTurn

proc isAdjustRadarForGunTurn*(bot:Bot):bool =
  ## returns true if the radar is turning independent from the gun
  return bot.intent_adjustRadarForGunTurn

proc isAdjustRadarForBodyTurn*(bot:Bot):bool =
  ## returns true if the radar is turning independent from the body
  return bot.intent_adjustRadarForBodyTurn


#++++++++ COLORS +++++++++#
proc setBodyColor*(bot:Bot, color:string) =
  ## set the body color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_bodyColor = color

proc setTurretColor*(bot:Bot, color:string) =
  ## set the turret color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_turretColor = color

proc setRadarColor*(bot:Bot, color:string) =
  ## set the radar color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_radarColor = color

proc setBulletColor*(bot:Bot, color:string) =
  ## set the bullet color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_bulletColor = color

proc setScanColor*(bot:Bot, color:string) =
  ## set the scan color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_scanColor = color

proc setTracksColor*(bot:Bot, color:string) =
  ## set the tracks color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_tracksColor = color

proc setGunColor*(bot:Bot, color:string) =
  ## set the gun color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  bot.intent_gunColor = color

proc getBodyColor*(bot:Bot):string =
  ## returns the body color
  return bot.intent_bodyColor

proc getTurretColor*(bot:Bot):string =
  ## returns the turret color
  return bot.intent_turretColor

proc getRadarColor*(bot:Bot):string =
  ## returns the radar color
  return bot.intent_radarColor

proc getBulletColor*(bot:Bot):string =
  ## returns the bullet color
  return bot.intent_bulletColor

proc getScanColor*(bot:Bot):string =
  ## returns the scan color
  return bot.intent_scanColor

proc getTracksColor*(bot:Bot):string =
  ## returns the tracks color
  return bot.intent_tracksColor

proc getGunColor*(bot:Bot):string =
  ## returns the gun color
  return bot.intent_gunColor

#++++++++ ARENA +++++++++#
proc getArenaHeight*(bot:Bot):int =
  ## returns the arena height (vertical)
  return bot.gameSetup.arenaHeight

proc getArenaWidth*(bot:Bot):int =
  ## returns the arena width (horizontal)
  return bot.gameSetup.arenaWidth

#++++++++ GAME AND BOT STATUS +++++++++#
proc getTurnNumber*(bot:Bot):int =
  ## returns the current turn number
  return bot.turnNumber

proc getX*(bot:Bot):float =
  ## returns the bot's X position
  return bot.x

proc getY*(bot:Bot):float =
  ## returns the bot's Y position
  return bot.y


#++++++++ TURNING RADAR +++++++++#
proc setRadarTurnRate*(bot:Bot, degrees:float) =
  ## set the radar turn rate if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_turnRadarRate = degrees

proc setTurnRadarLeft*(bot:Bot, degrees:float) =
  ## set the radar to turn left by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_turnRadarRate = degrees

proc setTurnRadarRight*(bot:Bot, degrees:float) =
  ## set the radar to turn right by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setTurnRadarLeft(bot, -degrees)

proc turnRadarLeft*(bot:Bot, degrees:float) =
  ## turn the radar left by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  
  if not bot.locked:
    # ask to turnRadar left for all degrees, the server will take care of turnRadaring the bot the max amount of degrees allowed
    setTurnRadarLeft(bot, degrees)
    
    # lock the bot, no other actions must be done until the action is completed
    bot.locked = true

    # go until the bot is not running or the bot.remaining_turnRadarRate is 0
    while bot.runningState and bot.remaining_turnRadarRate != 0: bot.go()

    # unlock the bot
    bot.locked = false

proc turnRadarRight*(bot:Bot, degrees:float) =
  ## turn the radar right by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  turnRadarLeft(bot, -degrees)

proc getRadarTurnRemaining*(bot:Bot):float =
  ## returns the remaining radar turn rate in degrees
  return bot.remaining_turnRadarRate

proc getRadarDirection*(bot:Bot):float =
  ## returns the current radar direction in degrees
  return bot.radarDirection

proc setRescan*(bot:Bot) =
  ## set the radar to rescan if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  bot.intent_rescan = true

proc rescan*(bot:Bot) =
  ## rescan the radar if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  
  # ask to rescan
  setRescan(bot)
    
  # lock the bot, no other actions must be done until the action is completed
  # bot.locked = true
  # bot.go() # go once to start the rescan is set
  # unlock the bot
  # bot.locked = false

#++++++++ TURNING GUN +++++++++#
proc setGunTurnRate*(bot:Bot, degrees:float) =
  ## set the gun turn rate if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_turnGunRate = degrees

proc setTurnGunLeft*(bot:Bot, degrees:float) =
  ## set the gun to turn left by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_turnGunRate = degrees

proc setTurnGunRight*(bot:Bot, degrees:float) =
  ## set the gun to turn right by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setTurnGunLeft(bot, -degrees)

proc turnGunLeft*(bot:Bot, degrees:float) =
  ## turn the gun left by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**

  # ask to turnGun left for all degrees, the server will take care of turnGuning the bot the max amount of degrees allowed
  if not bot.locked:
    setTurnGunLeft(bot, degrees)
    
    # lock the bot, no other actions must be done until the action is completed
    bot.locked = true

    # go until the bot is not running or the bot.remaining_turnGunRate is 0
    while bot.runningState and bot.remaining_turnGunRate != 0: bot.go()

    # unlock the bot
    bot.locked = false

proc turnGunRight*(bot:Bot, degrees:float) =
  ## turn the gun right by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  turnGunLeft(bot, -degrees)

proc getGunTurnRemaining*(bot:Bot):float =
  ## returns the remaining gun turn rate in degrees
  return bot.remaining_turnGunRate

proc getGunDirection*(bot:Bot):float =
  ## returns the current gun direction in degrees
  return bot.gunDirection

proc getMaxGunTurnRate*(bot:Bot):float =
  return bot.MAX_GUN_TURN_RATE


#++++++++ TURNING BODY +++++++#
proc setTurnRate(bot:Bot, degrees:float) =
  ## set the body turn rate if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_turnRate = degrees

proc setTurnLeft*(bot:Bot, degrees:float) =
  ## set the body to turn left by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_turnRate = degrees

proc setTurnRight*(bot:Bot, degrees:float) =
  ## set the body to turn right by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setTurnLeft(bot, -degrees)

proc turnLeft*(bot:Bot, degrees:float) =
  ## turn the body left by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**

  if not bot.locked:
    # ask to turn left for all degrees, the server will take care of turning the bot the max amount of degrees allowed
    setTurnLeft(bot, degrees)
    
    # lock the bot, no other actions must be done until the action is completed
    bot.locked = true

    # go until the bot is not running or the bot.remaining_turnRate is 0
    while bot.runningState and bot.remaining_turnRate != 0:
      echo "[API] turnLeft remaining_turnRate: ", bot.remaining_turnRate, " runningState: ", bot.runningState, " locked: ", bot.locked
      bot.go()

    # unlock the bot
    bot.locked = false

proc turnRight*(bot:Bot, degrees:float) =
  ## turn the body right by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  turnLeft(bot, -degrees)

proc getTurnRemaining*(bot:Bot):float =
  ## returns the remaining body turn rate in degrees
  return bot.remaining_turnRate

proc getDirection*(bot:Bot):float =
  ## returns the current body direction in degrees
  return bot.direction

proc getMaxTurnRate*(bot:Bot):float =
  ## returns the maximum turn rate of the body in degrees
  return bot.MAX_TURN_RATE


#++++++++ MOVING +++++++++#
proc setTargetSpeed*(bot:Bot, speed:float) =
  ## set the target speed of the bot if the bot is not locked doing a blocking call
  ## 
  ## `speed` can be any value between ``-current max speed`` and ``+current max speed``, any value outside this range will be clamped
  ## 
  ## by default ``max speed`` is ``8 pixels per turn``
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    if speed > 0:
      bot.intent_targetSpeed = min(speed, bot.current_maxSpeed)
    elif speed < 0:
      bot.intent_targetSpeed = max(speed, -bot.current_maxSpeed)
    else:
      bot.intent_targetSpeed = speed

proc setForward*(bot:Bot, distance:float) =
  ## set the bot to move forward by `distance` if the bot is not locked doing a blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not bot.locked:
    bot.remaining_distance = distance

proc setBack*(bot:Bot, distance:float) =
  ## set the bot to move back by `distance` if the bot is not locked doing a blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setForward(bot, -distance)

proc forward*(bot:Bot, distance:float) =
  ## move the bot forward by `distance` if the bot is not locked doing another blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **BLOCKING CALL**

  if not bot.locked:
    # ask to move forward for all pixels (distance), the server will take care of moving the bot the max amount of pixels allowed
    setForward(bot, distance)
    
    # lock the bot, no other actions must be done until the action is completed
    bot.locked = true

    # go until the bot is not running or the bot.remaining_turnRate is 0
    while bot.runningState and bot.remaining_distance != 0: bot.go()

    # unlock the bot
    bot.locked = false

proc back*(bot:Bot, distance:float) =
  ## move the bot back by `distance` if the bot is not locked doing another blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **BLOCKING CALL**
  forward(bot, -distance)

proc getDistanceRemaining*(bot:Bot):float =
  ## returns the remaining distance to move in pixels
  return bot.remaining_distance

#++++++++++++++ FIRE! ++++++++++++++#
proc setFire*(bot:Bot, firepower:float):bool =
  ## set the firepower of the next shot if the bot is not locked doing a blocking call
  ## 
  ## `firepower` can be any value between ``0.1`` and ``3``, any value outside this range will be clamped
  ## 
  ## If the `gun heat` is not 0 or if the `energy` is less than `firepower` the intent of firing will not be added

  # clamp the value
  if bot.energy < firepower or bot.gunHeat > 0:
    return false # can't fire
  else:
    bot.intent_firePower = clamp(firepower, bot.MIN_FIRE_POWER, bot.MAX_FIRE_POWER)
    echo "[API] firepower set to: ", bot.intent_firePower
    return true 

proc fire*(bot:Bot, firepower:float):bool =
  ## fire a shot with `firepower` if the bot is not locked doing another blocking call
  ## 
  ## `firepower` can be any value between ``0.1`` and ``3``, any value outside this range will be clamped
  ## 
  ## If the `gun heat` is not 0 or if the `energy` is less than `firepower` the shot will not be fired
  ## 
  ## **BLOCKING CALL**
  return setFire(bot, firepower) # check if the bot is not locked and the bot is able to shoot

#++++++++++++++ UTILS ++++++++++++++#
proc normalizeAbsoluteAngle*(angle:float):float =
  ## normalize the angle to an absolute angle into the range [0,360]
  ## 
  ## `angle` is the angle to normalize
  ## `return` is the normalized absolute angle
  let angle_mod = angle mod 360.float
  return if angle_mod >= 0: angle_mod
  else: angle_mod + 360.float

proc normalizeRelativeAngle*(angle:float):float =
  ## normalize the angle to the range [-180,180]
  ## 
  ## `angle` is the angle to normalize
  ## `return` is the normalized angle
  let angle_mod = angle mod 360
  return if angle_mod >= 0:
    if angle_mod < 180: angle_mod
    else: angle_mod - 360
  else:
    if angle_mod >= -180: angle_mod
    else: angle_mod + 360

proc directionTo*(bot:Bot, x,y:float):float =
  ## returns the direction (angle) from the bot's coordinates to the point (x,y).
  ## 
  ## `x` and `y` are the coordinates of the point
  ## `return` is the direction to the point x,y in degrees in the range [0,360]
  result = normalizeAbsoluteAngle(radToDeg(arctan2(y-bot.getY(), x-bot.getX())))

proc bearingTo*(bot:Bot, x,y:float):float =
  ## returns the bearing to the point (x,y) in degrees
  ## 
  ## `x` and `y` are the coordinates of the point
  ## `return` is the bearing to the point x,y in degrees in the range [-180,180]
  result = normalizeRelativeAngle(bot.directionTo(x,y) - bot.direction)

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

  # reset the outputBM
  outputBM = @[]

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

proc auxiliaryRun(bot:Bot):bool =
  bot.run()
  return true

proc botRunner() {.async.} =
  echo "BotRunner started"
  # while the connection is open...
  while gs_ws.readyState == Open:
    while not bot.isRunning:
      await sleepAsync(10) # wait for the bot to be started
    
    # first we run the bot real run method, that could go forever
    var botRun_ended = spawn auxiliaryRun(bot)
    while not botRun_ended.isReady:
      await sleepAsync(10)

    # now we run go() until the bot is running
    while bot.isRunning:
      bot.go()
      await sleepAsync(10)

proc messageSender() {.async.} =
    echo "MessageSender started"
    # while the connection is open...
    while gs_ws.readyState == Open:
        # echo "MessageSender cycle"
        # fetch a message from the Output Message Buffer
        if outputBM.len > 0:
            let json_message = outputBM.get()
            waitFor gs_ws.send(json_message)
        else:
          await sleepAsync(1)
    echo "MessageSender stopped"

proc eventHandler() {.async.} =
    echo "EventHandler started"
    # while the connection is open...
    while gs_ws.readyState == Open:
        # fetch a message from the input Message Buffer
        if inputBM.len > 0:
            let json_message = inputBM.get()

            # get the type of the message from the message itself
            let `type` = json_message.fromJson(Message).`type`

            # 'case' switch over type
            case `type`:
            of serverHandshake:
                let server_handshake = json_message.fromJson(ServerHandshake)
                let bot_handshake = BotHandshake(`type`:Type.botHandshake, sessionId:server_handshake.sessionId, name:bot.name, version:bot.version, authors:bot.authors, secret:bot.secret, initialPosition:bot.initialPosition)
                outputBM.put(bot_handshake.toJson)
                bot.onConnected(bot.serverConnectionURL)
            
            of gameStartedEventForBot:
                # in case the bot is still running from a previous game we stop it
                bot.stopBot()

                let game_started_event_for_bot = json_message.fromJson(GameStartedEventForBot)
                # store the Game Setup for the bot usage
                bot.gameSetup = game_started_event_for_bot.gameSetup
                bot.myId = game_started_event_for_bot.myId

                # activating the bot method
                bot.onGameStarted(game_started_event_for_bot)
                
                # send bot ready
                let bot_ready = BotReady(`type`:Type.botReady)
                outputBM.put(bot_ready.toJson)
            of tickEventForBot:
                let tick_event_for_bot = json_message.fromJson(TickEventForBot)

                # store the tick data for bot in local variables
                bot.turnNumber = tick_event_for_bot.turnNumber
                bot.roundNumber = tick_event_for_bot.roundNumber
                bot.energy = tick_event_for_bot.botState.energy
                bot.x = tick_event_for_bot.botState.x
                bot.y = tick_event_for_bot.botState.y
                bot.direction = tick_event_for_bot.botState.direction
                bot.gunDirection = tick_event_for_bot.botState.gunDirection
                bot.radarDirection = tick_event_for_bot.botState.radarDirection
                bot.radarSweep = tick_event_for_bot.botState.radarSweep
                bot.speed = tick_event_for_bot.botState.speed
                bot.turnRate = tick_event_for_bot.botState.turnRate
                bot.gunHeat = tick_event_for_bot.botState.gunHeat
                bot.radarTurnRate = tick_event_for_bot.botState.radarTurnRate
                bot.gunTurnRate = tick_event_for_bot.botState.gunTurnRate
                bot.gunHeat = tick_event_for_bot.botState.gunHeat

                # about colors, we are intent to keep the same color as the previous tick
                bot.intent_bodyColor = tick_event_for_bot.botState.bodyColor
                bot.intent_turretColor = tick_event_for_bot.botState.turretColor
                bot.intent_radarColor = tick_event_for_bot.botState.radarColor
                bot.intent_bulletColor = tick_event_for_bot.botState.bulletColor
                bot.intent_scanColor = tick_event_for_bot.botState.scanColor
                bot.intent_tracksColor = tick_event_for_bot.botState.tracksColor
                bot.intent_gunColor = tick_event_for_bot.botState.gunColor

                # stdout.write "t",bot.getTurnNumber()
                # stdout.flushFile()

                # starting run() thread at first tick seen
                if(not firstTickSeen):
                    firstTickSeen = true

                # activating the bot method
                bot.onTick(tick_event_for_bot)

                # for every event inside this tick call the relative event for the bot
                for event in tick_event_for_bot.events:
                    case parseEnum[Type](event["type"].getStr()):
                    of Type.botDeathEvent:
                        bot.stopBot()
                        bot.onDeath(fromJson($event, BotDeathEvent))
                    of Type.botHitWallEvent:
                        bot.remaining_distance = 0
                        bot.onHitWall(fromJson($event, BotHitWallEvent))
                    of Type.bulletHitBotEvent:
                        # conversion from BulletHitBotEvent to HitByBulletEvent
                        let hit_by_bullet_event = fromJson($event, HitByBulletEvent)
                        hit_by_bullet_event.`type` = Type.hitByBulletEvent
                        bot.onHitByBullet(hit_by_bullet_event)
                    of Type.botHitBotEvent:
                        bot.remaining_distance = 0
                        bot.onHitBot(fromJson($event, BotHitBotEvent))
                    of Type.scannedBotEvent:
                        bot.onScannedBot(fromJson($event, ScannedBotEvent))        
                    else:
                        echo "NOT HANDLED BOT TICK EVENT: ", event
            
            of gameAbortedEvent:
                let game_aborted_event = json_message.fromJson(GameAbortedEvent)

                # activating the bot method
                bot.onGameAborted(game_aborted_event)

            of gameEndedEventForBot:
                bot.stopBot()

                let game_ended_event_for_bot = json_message.fromJson(GameEndedEventForBot)

                # activating the bot method
                bot.onGameEnded(game_ended_event_for_bot)

            of skippedTurnEvent:
                let skipped_turn_event = json_message.fromJson(SkippedTurnEvent)
                
                # activating the bot method
                bot.onSkippedTurn(skipped_turn_event)

            of roundEndedEventForBot:
                bot.stopBot()

                let round_ended_event_for_bot = json_message.fromJson(RoundEndedEventForBot)

                # activating the bot method
                bot.onRoundEnded(round_ended_event_for_bot)

            of roundStartedEvent:
                bot.runningState = true
                # discard runAsync(bot)
                let round_started_event = json_message.fromJson(RoundStartedEvent)

                # activating the bot method
                bot.onRoundStarted(round_started_event)

            else: echo "NOT HANDLED MESSAGE: ",json_message
        else:
          await sleepAsync(10)
    echo "eventHandler stopped"

proc messageListener() {.async.} =
    echo "MessageListener started"
    # while the connection is open...
    while gs_ws.readyState == Open:
      # listen for a message
      let json_message = await gs_ws.receiveStrPacket()

      # don't elaborate empty messages, could be just a keep-alive
      if not json_message.isEmptyOrWhitespace():
        # put the message in the input Message Buffer
        inputBM.put(json_message)
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
        echo "botRunner starting"
        asyncCheck botRunner()
        echo "messageListener starting"
        let ml = messageListener()
        echo "messageSender starting"
        asyncCheck messageSender()
        echo "eventHandler starting"
        asyncCheck eventHandler()
        runForever()
        
    except CatchableError:
      bot.onConnectionError(getCurrentExceptionMsg())