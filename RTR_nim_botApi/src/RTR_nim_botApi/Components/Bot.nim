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
    remaining_turnRate*:float
    remaining_turnGunRate*:float
    remaining_turnRadarRate*:float
    remaining_distance*:float

    #++++++++ MOVEMENT CONSTRAINTS ++++++++#
    #++++++++ GAME PHYSICS ++++++++#
    # bots accelerate at the rate of 1 unit per turn but decelerate at the rate of 2 units per turn
    ACCELERATION*,DECELERATION*,MAX_SPEED*,MAX_TURN_RATE*,MAX_GUN_TURN_RATE*,MAX_RADAR_TURN_RATE*,MAX_FIRE_POWER*,MIN_FIRE_POWER*: float
    current_maxSpeed*:float

    #++++++++ GAME VARAIBLES ++++++++#
    gameSetup*:GameSetup # game setup
    myId*:int # my ID from the server

    #++++++++ TICK DATA FROM SERVER ++++++++#
    turnNumber*,roundNumber*:int
    energy*,x*,y*,direction*,gunDirection*,radarDirection*,radarSweep*,speed*,turnRate*,gunTurnRate*,radarTurnRate*,gunHeat*:float
    initialPosition*:InitialPosition

# the following section contains all the methods that are supposed to be overrided by the bot creator
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