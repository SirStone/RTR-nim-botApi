# import component
import std/[math]
import Messages

type
  Bot* = ref object of RootObj
    # filled from JSON
    name*,version*,description*,homepage*,secret*,serverConnectionURL*,platform*,programmingLang*:string
    gameTypes*,authors*,countryCodes*:seq[string]
    runningState*,locked*:bool

    #++++++++ INTENT VARIABLES ++++++++#
    intent_turnRate*,intent_gunTurnRate*,intent_radarTurnRate*,intent_targetSpeed*,intent_firepower*:float
    intent_adjustGunForBodyTurn*,intent_adjustRadarForGunTurn*,intent_adjustRadarForBodyTurn*,intent_rescan*,intent_fireAssist*:bool
    intent_bodyColor*,intent_turretColor*,intent_radarColor*,intent_bulletColor*,intent_scanColor*,intent_tracksColor*,intent_gunColor*:string

    #++++++++ REMAININGS ++++++++#
    remaining_turnRate*,remaining_turnGunRate*,remaining_turnRadarRate*,remaining_distance*:float

    #++++++++ MOVEMENT CONSTRAINTS ++++++++#
    #++++++++ GAME PHYSICS ++++++++#
    ACCELERATION*,DECELERATION*,MAX_SPEED*,MAX_TURN_RATE*,MAX_GUN_TURN_RATE*,MAX_RADAR_TURN_RATE*,MAX_FIRE_POWER*,MIN_FIRE_POWER*: float

    #++++++++ CUSTOM LIMITS ++++++++#
    current_maxSpeed*:float

    #++++++++ GAME VARAIBLES ++++++++#
    gameSetup*:GameSetup # game setup
    myId*:int # my ID from the server

    #++++++++ TICK DATA FROM SERVER ++++++++#
    turnNumber*,roundNumber*:int
    energy*,x*,y*,direction*,gunDirection*,radarDirection*,radarSweep*,speed*,turnRate*,gunTurnRate*,radarTurnRate*,gunHeat*:float
    initialPosition*:InitialPosition

# the following section contains all the methods that are supposed to be overrided by the bot creator
method go*(bot:Bot) {.base.} = discard
method run*(bot:Bot) {.base.} = discard
method onGameAborted*(bot:Bot, gameAbortedEvent:GameAbortedEvent) {.base.} = discard
method onGameEnded*(bot:Bot, gameEndedEventForBot:GameEndedEventForBot) {.base.} = discard
method onGameStarted*(bot:Bot, gameStartedEventForBot:GameStartedEventForBot) {.base.} = discard
method onHitByBullet*(bot:Bot, hitByBulletEvent:HitByBulletEvent) {.base.} = discard
method onHitBot*(bot:Bot, botHitBotEvent:BotHitBotEvent) {.base.} = discard
method onHitWall*(bot:Bot, botHitWallEvent:BotHitWallEvent) {.base.} = discard
method onRoundEnded*(bot:Bot, roundEndedEventForBot:RoundEndedEventForBot) {.base.} = discard
method onRoundStarted*(bot:Bot, roundStartedEvent:RoundStartedEvent) {.base.} = discard
method onSkippedTurn*(bot:Bot, skippedTurnEvent:SkippedTurnEvent) {.base.} = discard
method onScannedBot*(bot:Bot, scannedBotEvent:ScannedBotEvent) {.base.} = discard
method onTick*(bot:Bot, tickEventForBot:TickEventForBot) {.base.} = discard
method onDeath*(bot:Bot, botDeathEvent:BotDeathEvent) {.base.} =  discard
method onConnected*(bot:Bot, url:string) {.base.} = discard
method onConnectionError*(bot:Bot, error:string) {.base.} = discard

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
    while bot.runningState and bot.remaining_turnRate != 0: bot.go()

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