## ***ROBOCODE TANKROYALE BOT API FOR NIM***

#++++++++ standard libraries ++++++++#
import std/[os, strutils, threadpool, math]

#++++++++ 3rd party libraries ++++++++#
import asyncdispatch, ws, jsony, json

#++++++++ local components ++++++++#
import RTR_nim_botApi/Components/[Bot, Messages]
export Bot, Messages

#++++++++ system variables ++++++++#
var runningState:bool
var firstTickSeen:bool = false
var lastTurnWeSentIntent:int = -1
var sendIntent:bool = false
var gs_ws:WebSocket
var botLocked:bool = false
var isOverDriving:bool = false

#++++++++ GAME VARAIBLES ++++++++#
var gameSetup:GameSetup # game setup
var myId: int # my ID from the server

#++++++++ TICK DATA FROM SERVER ++++++++#
var turnNumber,roundNumber:int
var energy,x,y,direction,gunDirection,radarDirection,radarSweep,speed,turnRate,gunTurnRate,radarTurnRate,gunHeat:float
var initialPosition:InitialPosition = InitialPosition(x:0, y:0, angle:0)

#++++++++ GAME PHYSICS ++++++++#
# bots accelerate at the rate of 1 unit per turn but decelerate at the rate of 2 units per turn
let ACCELERATION:float = 1
let DECELERATION:float = -2

# The speed can never exceed 8 units per turn
let MAX_SPEED:float = 8
var current_maxSpeed:float = MAX_SPEED

# If standing still (0 units/turn), the maximum rate is 10° per turn
let MAX_TURN_RATE:float = 10

# The maximum rate of rotation is 20° per turn. This is added to the current rate of rotation of the bot
let MAX_GUN_TURN_RATE:float = 20

# The maximum rate of rotation is 45° per turn. This is added to the current rate of rotation of the gun
let MAX_RADAR_TURN_RATE:float = 45

# The maximum firepower is 3 and the minimum firepower is 0.1
let MAX_FIRE_POWER:float = 3
let MIN_FIRE_POWER:float = 0.1

#++++++++ INTENT VARIABLES ++++++++#
var intent_turnRate,intent_gunTurnRate,intent_radarTurnRate,intent_targetSpeed,intent_firepower:float
var intent_adjustGunForBodyTurn,intent_adjustRadarForGunTurn,intent_adjustRadarForBodyTurn,intent_rescan,intent_fireAssist:bool
var intent_bodyColor,intent_turretColor,intent_radarColor,intent_bulletColor,intent_scanColor,intent_tracksColor,intent_gunColor:string

#++++++++ REMAININGS ++++++++#
var remaining_turnRate:float = 0
var remaining_turnGunRate:float = 0
var remaining_turnRadarRate:float = 0
var remaining_distance:float = 0

# # proc calcNewSpeed(currentSpeed:float, targetSpeed:float):float =
# #   if currentSpeed < targetSpeed:
# #     # I'm accelerating
# #     return min(currentSpeed + ACCELERATION, current_maxSpeed)
# #   else:
# #     # I'm decelerating
# #     return max(currentSpeed - DECELERATION, -current_maxSpeed)

# #   # in case are equal, return currentSpeed
# #   return MAX_SPEEDpeed

# func isNearZero(value:float):bool =
#   return value.abs < 0.00001

# # 1/3
# # Credits for this algorithm goes to Patrick Cupka (aka Voidious),
# # Julian Kent (aka Skilgannon), and Positive for the original version:
# # https://robowiki.net/wiki/User:Voidious/Optimal_Velocity#Hijack_2
# proc getMaxDeceleration(speed:float):float =
#   let decelerationTime = speed / DECELERATION
#   let accelerationTime = 1.0 - decelerationTime

#   return min(1, decelerationTime) * DECELERATION + max(0, accelerationTime) * ACCELERATION

# # 2/3
# # Credits for thMAX_SPEEDithm goes to Patrick Cupka (aka Voidious),
# # Julian Kent (aka Skilgannon), and Positive for the original version:
# # https://robowiki.net/wiki/User:Voidious/Optimal_Velocity#Hijack_2
# proc getMaxSpeed(distance:float):float =
#   let decelerationTime = max(1, ceil((sqrt((4.0 * 2.0 / DECELERATION) * distance + 1.0) - 1.0) / 2.0))
#   if decelerationTime == Inf: return current_maxSpeed

#   let decelerationDistance = (decelerationTime / 2.0) * (decelerationTime - 1.0) * DECELERATION
#   return ((decelerationTime - 1.0) * DECELERATION) + ((distance - decelerationDistance) / decelerationTime)

# # Credits fMAX_SPEEDalgorithm goes to Patrick Cupka (aka Voidious),
# # Julian Kent (aka Skilgannon), and Positive for the original version:
# # https://robowiki.net/wiki/User:Voidious/Optimal_Velocity#Hijack_2
# proc getNewTargetSpeed(spped:float, distance:float):float =
#   if distance < 0:
#     return -getNewTargetSpeed(-speed, -distance)

#   let targetSpeed = if distance == Inf:
#     current_maxSpeed
#   else:
#     min(getMaxSpeed(distance), current_maxSpeed)

#   return if speed >= 0:
#     clamp(targetSpeed, speed - DECELERATION .. speed + ACCELERATION)
#   else:
#     clamp(targetSpeed, speed - ACCELERATION .. speed + getMaxDeceleration(-speed))

# proc getDistanceTraveledUntilStop(speed:float):float =
#   var absSpeed = speed.abs
#   var distance = 0.0
#   while absSpeed > 0: 
#     absSpeed = getNewTargetSpeed(absSpeed, 0)
#     distance = distance + absSpeed
#   return distance

# proc getAndSetNewTargetSpeed(distance:float):float =
#   # calculate the new speed
#   let speed = getNewTargetSpeed(speed, distance)

#   # set the new speed
#   intent_targetSpeed = speed

#   # return the new speed
#   return speed

# proc updateMovement() =
#   var distance = remaining_distance

#   # This is Nat Pavasant's method described here:
#   # https://robowiki.net/wiki/User:Positive/Optimal_Velocity#Nat.27s_updateMovement
#   var newSpeed = getAndSetNewTargetSpeed(distance)

#   # If we are over-driving our distance and we are now at velocity=0 then we stopped
#   if isNearZero(newSpeed) and isOverDriving:
#     remaining_distance = 0
#     distance = 0
#     isOverDriving = false

#   # the overdrive flag
#   if sgn(distance * newSpeed) != -1:
#     isOverDriving = getDistanceTraveledUntilStop(newSpeed) > distance

#   # update the remaining distance
#   echo "Remaining distance: ", remaining_distance
#   remaining_distance = remaining_distance - newSpeed

proc updateRemainings() =
  # body turn
  if remaining_turnRate != 0:
    if remaining_turnRate > 0:
      intent_turnRate = min(remaining_turnRate, MAX_TURN_RATE)
      remaining_turnRate = max(0, remaining_turnRate - MAX_TURN_RATE)
    else:
      intent_turnRate = max(remaining_turnRate, -MAX_TURN_RATE)
      remaining_turnRate = min(0, remaining_turnRate + MAX_TURN_RATE)

  # gun turn
  if remaining_turnGunRate != 0:
    if remaining_turnGunRate > 0:
      intent_gunTurnRate = min(remaining_turnGunRate, MAX_GUN_TURN_RATE)
      remaining_turnGunRate = max(0, remaining_turnGunRate - MAX_GUN_TURN_RATE)
    else:
      intent_gunTurnRate = max(remaining_turnGunRate, -MAX_GUN_TURN_RATE)
      remaining_turnGunRate = min(0, remaining_turnGunRate + MAX_GUN_TURN_RATE)

  # radar turn
  if remaining_turnRadarRate != 0:
    if remaining_turnRadarRate > 0:
      intent_radarTurnRate = min(remaining_turnRadarRate, MAX_RADAR_TURN_RATE)
      remaining_turnRadarRate = max(0, remaining_turnRadarRate - MAX_RADAR_TURN_RATE)
    else:
      intent_radarTurnRate = max(remaining_turnRadarRate, -MAX_RADAR_TURN_RATE)
      remaining_turnRadarRate = min(0, remaining_turnRadarRate + MAX_RADAR_TURN_RATE)

  # target speed calculation
  if remaining_distance != 0:
    # how much turns requires to stop from the current speed? t = (V_target - V_current)/ -acceleration
    let turnsRequiredToStop = -speed.abs / DECELERATION
    let remaining_distance_breaking = speed.abs * turnsRequiredToStop + 0.5 * DECELERATION * turnsRequiredToStop.pow(2)
    if remaining_distance > 0: # going forward
      # echo "[API] Turns required to stop: ", turnsRequiredToStop, " my speed: ", speed, " remaining distance: ", remaining_distance, " remaining distance breaking: ", remaining_distance_breaking

      # if the distance left is less or equal than the turns required to stop, then we need to slow down
      if remaining_distance - remaining_distance_breaking < speed:
        intent_targetSpeed = max(0, speed+DECELERATION)
        remaining_distance = remaining_distance - intent_targetSpeed # what we left for stopping
      else: # if the distance left is more than the turns required to stop, then we need to speed up to max speed
        # if the current_maxSpeed changes over time this will work for adjusting to the new velocity too
        intent_targetSpeed = min(current_maxSpeed, speed+ACCELERATION)
        remaining_distance = remaining_distance - intent_targetSpeed 
    else: # going backward
      # echo "[API] Turns required to stop: ", turnsRequiredToStop, " my speed: ", speed, " remaining distance: ", remaining_distance, " remaining distance breaking: ", remaining_distance_breaking

      # if the distance left is less or equal than the turns required to stop, then we need to slow down
      if remaining_distance.abs - remaining_distance_breaking < speed.abs:
        intent_targetSpeed = min(0, speed-DECELERATION)
        remaining_distance = remaining_distance - intent_targetSpeed # what we left for stopping
      else: # if the distance left is more than the turns required to stop, then we need to speed up to max speed
        # if the current_maxSpeed changes over time this will work for adjusting to the new velocity too
        intent_targetSpeed = max(-current_maxSpeed, speed-ACCELERATION)
        remaining_distance = remaining_distance - intent_targetSpeed

      
    # updateMovement()

    

    

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
  ## call `go()` to send the intent immediately
  sendIntent = true
  while sendIntent and runningState:
    sleep(1)

# this loop is responsible for sending the intent to the server, it works untl the bot is a running state and if the sendIntend flag is true
proc sendIntentLoop() {.async.} =
  while(true):
    if sendIntent and lastTurnWeSentIntent < turnNumber:
      updateRemainings()

      # if remaining_distance != 0: echo "[API] intent_targetSpeed: " & $intent_targetSpeed
      let intent = BotIntent(`type`: Type.botIntent, turnRate:intent_turnRate, gunTurnRate:intent_gunTurnRate, radarTurnRate:intent_radarTurnRate, targetSpeed:intent_targetSpeed, firePower:intent_firePower, adjustGunForBodyTurn:intent_adjustGunForBodyTurn, adjustRadarForBodyTurn:intent_adjustRadarForBodyTurn, adjustRadarForGunTurn:intent_adjustRadarForGunTurn, rescan:intent_rescan, fireAssist:intent_fireAssist, bodyColor:intent_bodyColor, turretColor:intent_turretColor, radarColor:intent_radarColor, bulletColor:intent_bulletColor, scanColor:intent_scanColor, tracksColor:intent_tracksColor, gunColor:intent_gunColor)
      await gs_ws.send(intent.toJson)

      lastTurnWeSentIntent = turnNumber

      # reset the intent variables
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
proc isRunning*():bool =
  ## returns true if the bot is alive
  return runningState

#++++++++ BOT SETUP +++++++++#
proc setAdjustGunForBodyTurn*(adjust:bool) =
  ## this is permanent, no need to call this multiple times
  ## 
  ## use ``true`` if the gun should turn independent from the body
  ## 
  ## use ``false`` if the gun should turn with the body
  intent_adjustGunForBodyTurn = adjust

proc setAdjustRadarForGunTurn*(adjust:bool) =
  ## this is permanent, no need to call this multiple times
  ## 
  ## use ``true`` if the radar should turn independent from the gun
  ## 
  ## use ``false`` if the radar should turn with the gun
  intent_adjustRadarForGunTurn = adjust

proc setAdjustRadarForBodyTurn*(adjust:bool) =
  ## this is permanent, no need to call this multiple times
  ## 
  ## use ``true`` if the radar should turn independent from the body
  ## 
  ## use ``false`` if the radar should turn with the body
  intent_adjustRadarForBodyTurn = adjust

proc isAdjustGunForBodyTurn*():bool =
  ## returns true if the gun is turning independent from the body
  return intent_adjustGunForBodyTurn

proc isAdjustRadarForGunTurn*():bool =
  ## returns true if the radar is turning independent from the gun
  return intent_adjustRadarForGunTurn

proc isAdjustRadarForBodyTurn*():bool =
  ## returns true if the radar is turning independent from the body
  return intent_adjustRadarForBodyTurn



#++++++++ COLORS +++++++++#
proc setBodyColor*(color:string) =
  ## set the body color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_bodyColor = color

proc setTurretColor*(color:string) =
  ## set the turret color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_turretColor = color

proc setRadarColor*(color:string) =
  ## set the radar color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_radarColor = color

proc setBulletColor*(color:string) =
  ## set the bullet color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_bulletColor = color

proc setScanColor*(color:string) =
  ## set the scan color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_scanColor = color

proc setTracksColor*(color:string) =
  ## set the tracks color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_tracksColor = color

proc setGunColor*(color:string) =
  ## set the gun color, permanently
  ## 
  ## use hex colors, like ``#FF0000``
  intent_gunColor = color

proc getBodyColor*():string =
  ## returns the body color
  return intent_bodyColor

proc getTurretColor*():string =
  ## returns the turret color
  return intent_turretColor

proc getRadarColor*():string =
  ## returns the radar color
  return intent_radarColor

proc getBulletColor*():string =
  ## returns the bullet color
  return intent_bulletColor

proc getScanColor*():string =
  ## returns the scan color
  return intent_scanColor

proc getTracksColor*():string =
  ## returns the tracks color
  return intent_tracksColor

proc getGunColor*():string =
  ## returns the gun color
  return intent_gunColor


#++++++++ MISC GETTERS +++++++++#
proc getArenaHeight*():int =
  ## returns the arena height (vertical)
  return gameSetup.arenaHeight

proc getArenaWidth*():int =
  ## returns the arena width (horizontal)
  return gameSetup.arenaWidth

proc getTurnNumber*():int =
  ## returns the current turn number
  return turnNumber


#++++++++ TURNING RADAR +++++++++#
proc setRadarTurnRate*(degrees:float) =
  ## set the radar turn rate if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_turnRadarRate = degrees

proc setTurnRadarLeft*(degrees:float) =
  ## set the radar to turn left by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_turnRadarRate = degrees

proc setTurnRadarRight*(degrees:float) =
  ## set the radar to turn right by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setTurnRadarLeft(-degrees)

proc turnRadarLeft*(degrees:float) =
  ## turn the radar left by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  
  if not botLocked:
    # ask to turnRadar left for all degrees, the server will take care of turnRadaring the bot the max amount of degrees allowed
    setTurnRadarLeft(degrees)
    
    # lock the bot, no other actions must be done until the action is completed
    botLocked = true

    # go until the bot is not running or the remaining_turnRadarRate is 0
    while runningState and remaining_turnRadarRate != 0: go()

    # unlock the bot
    botLocked = false

proc turnRadarRight*(degrees:float) =
  ## turn the radar right by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  turnRadarLeft(-degrees)

proc getRadarTurnRemaining*():float =
  ## returns the remaining radar turn rate in degrees
  return remaining_turnRadarRate

proc getRadarDirection*():float =
  ## returns the current radar direction in degrees
  return radarDirection


#++++++++ TURNING GUN +++++++++#
proc setGunTurnRate*(degrees:float) =
  ## set the gun turn rate if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_turnGunRate = degrees

proc setTurnGunLeft*(degrees:float) =
  ## set the gun to turn left by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_turnGunRate = degrees

proc setTurnGunRight*(degrees:float) =
  ## set the gun to turn right by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setTurnGunLeft(-degrees)

proc turnGunLeft*(degrees:float) =
  ## turn the gun left by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**

  # ask to turnGun left for all degrees, the server will take care of turnGuning the bot the max amount of degrees allowed
  if not botLocked:
    setTurnGunLeft(degrees)
    
    # lock the bot, no other actions must be done until the action is completed
    botLocked = true

    # go until the bot is not running or the remaining_turnGunRate is 0
    while runningState and remaining_turnGunRate != 0: go()

    # unlock the bot
    botLocked = false

proc turnGunRight*(degrees:float) =
  ## turn the gun right by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  turnGunLeft(-degrees)

proc getGunTurnRemaining*():float =
  ## returns the remaining gun turn rate in degrees
  return remaining_turnGunRate

proc getGunDirection*():float =
  ## returns the current gun direction in degrees
  return gunDirection

proc getMaxGunTurnRate*():float =
  return MAX_GUN_TURN_RATE


#++++++++ TURNING BODY +++++++#
proc setTurnRate(degrees:float) =
  ## set the body turn rate if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_turnRate = degrees

proc setTurnLeft*(degrees:float) =
  ## set the body to turn left by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_turnRate = degrees

proc setTurnRight*(degrees:float) =
  ## set the body to turn right by `degrees` if the bot is not locked doing a blocking call
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setTurnLeft(-degrees)

proc turnLeft*(degrees:float) =
  ## turn the body left by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**

  if not botLocked:
    # ask to turn left for all degrees, the server will take care of turning the bot the max amount of degrees allowed
    setTurnLeft(degrees)
    
    # lock the bot, no other actions must be done until the action is completed
    botLocked = true

    # go until the bot is not running or the remaining_turnRate is 0
    while runningState and remaining_turnRate != 0: go()

    # unlock the bot
    botLocked = false

proc turnRight*(degrees:float) =
  ## turn the body right by `degrees` if the bot is not locked doing another blocking call
  ## 
  ## **BLOCKING CALL**
  turnLeft(-degrees)

proc getTurnRemaining*():float =
  ## returns the remaining body turn rate in degrees
  return remaining_turnRate

proc getDirection*():float =
  ## returns the current body direction in degrees
  return direction

proc getMaxTurnRate*():float =
  ## returns the maximum turn rate of the body in degrees
  return MAX_TURN_RATE



#++++++++ MOVING +++++++++#
proc setTargetSpeed*(speed:float) =
  ## set the target speed of the bot if the bot is not locked doing a blocking call
  ## 
  ## `speed` can be any value between ``-current max speed`` and ``+current max speed``, any value outside this range will be clamped
  ## 
  ## by default ``max speed`` is ``8 pixels per turn``
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    if speed > 0:
      intent_targetSpeed = min(speed, current_maxSpeed)
    elif speed < 0:
      intent_targetSpeed = max(speed, -current_maxSpeed)
    else:
      intent_targetSpeed = speed

proc setForward*(distance:float) =
  ## set the bot to move forward by `distance` if the bot is not locked doing a blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **OVERRIDES CURRENT VALUE**
  if not botLocked:
    remaining_distance = distance

proc setBack*(distance:float) =
  ## set the bot to move back by `distance` if the bot is not locked doing a blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **OVERRIDES CURRENT VALUE**
  setForward(-distance)

proc forward*(distance:float) =
  ## move the bot forward by `distance` if the bot is not locked doing another blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **BLOCKING CALL**

  if not botLocked:
    # ask to move forward for all pixels (distance), the server will take care of moving the bot the max amount of pixels allowed
    setForward(distance)
    
    # lock the bot, no other actions must be done until the action is completed
    botLocked = true

    # go until the bot is not running or the remaining_turnRate is 0
    while runningState and remaining_distance != 0: go()

    # unlock the bot
    botLocked = false

proc back*(distance:float) =
  ## move the bot back by `distance` if the bot is not locked doing another blocking call
  ## 
  ## `distance` is in pixels
  ## 
  ## **BLOCKING CALL**
  forward(-distance)

proc getDistanceRemaining*():float =
  ## returns the remaining distance to move in pixels
  return remaining_distance



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
  intent_rescan = false
  intent_fireAssist = false

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
  
  initialPosition = position

  # connect to the Game Server
  if(connect):
    if bot.secret == "":
      bot.secret = getEnv("SERVER_SECRET", "serversecret")

    if bot.serverConnectionURL == "": 
      bot.serverConnectionURL = getEnv("SERVER_URL", "ws://localhost:7654")

    asyncCheck sendIntentLoop()

    waitFor talkWithGS(bot, bot.serverConnectionURL)