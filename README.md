# Robocode Tankroyale bot library written in NIM
This project has two independent goals:
1. creating a bot library that allows me (and others) to build bots in NIM
1. learning NIM. In this very moment I'm writing this README my exprience in writing NIM code is the basic "hello world"

## This document
I'm going to use this README for taking notes and instructions both.

## NOTES
### inspirational message
This is the inspirational message given to me from [Flemming N. Larsen](https://github.com/flemming-n-larsen) the author of the legendary (for me) [Robocode](https://robocode.sourceforge.io/) and the new promising [Robocode Tank Royale](https://robocode-dev.github.io/tank-royale/) abot how to head a project that aims to build a new bot library, discussion [here](https://github.com/robocode-dev/tank-royale/discussions/52):

>...bot might be as simple as the BaseBot from the JVM and .Net APIs. That is a thin layer on top of a web socket.
>
>In order to make a Bot API, all aspects involving a "bot" with the schemas must be implemented, which is not very complicated.
>
>Basically, a bot must:
>- Connect to the server via a WebSocket
>- Receive the server handshake and send its own handshake
>- When a start-game event is received, the bot must reply with a bot-ready
>- After this, the bot will receive tick-events with the game state, but only containing information visible for its perspective
>- The bot must send a bot-intent before turn-timeout with its new turn rates, target speed etc.
>- A battle-ended is received when the game is over.
>
>You can decide how the API must be, but the ones provided for JVM (Java) and .Net should serve as good sources of inspiration.
>
>Btw. there is no need for reverse engineering in the current Bot APIs, as the sources are provided as Open Source, and they have been kept as simple and straightforward as possible. At least that has been the intention...

### Bot interactions TODO (taken from [Schemas](https://github.com/robocode-dev/tank-royale/tree/master/schema/schemas#readme))
- [x] Joining a Server
    - [x] connect WebSocket
    - [x] receive [server-handshake](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/server-handshake.yaml) from Server
    - [x] send [bot-handshake](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-handshake.yaml) to Server
- [x] Leaving a Server
    - [x] disconnect WebSocket
- [x] Partecipating in a Game
    - [x] receive [game-started-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/game-started-event-for-bot.yaml) from Server
    - [x] send [bot-ready](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-ready.yaml) to Server
- [ ] Running turns of the game
    - [x] receive [round-started-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/round-started-event.yaml) from Server
    - [ ] receive [round-ended-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/round-ended-event-for-bot.yaml) from Server
    - [x] receive [tick-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/tick-event-for-bot.yaml) from Server
    - [x] receive [skipped-turn-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/skipped-turn-event.yaml) from Server
    - [x] send [bot-intent](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-intent.yaml) to Server
- [ ] end of the Game
    - [x] receive [game-ended-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/game-ended-event-for-bot.yaml)
    - [ ] receive [won-round-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/won-round-event.yaml)
- [ ] in-game events
    - [x] receive [game-aborted-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/game-aborted-event.yaml) from Server
    - [x] receive [bot-death-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-death-event.yaml) from Server when a bot dies
    - [x] receive [bot-hit-bot-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-hit-bot-event.yaml) from Server when our bot collides with another bot
    - [x] receive [bot-hit-wall-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-hit-wall-event.yaml) from Server when our bot collides with a wall
    - [ ] receive [bullet-fired-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-fired-event.yaml) from Server when our bot fires a bullet
    - [x] receive [bullet-hit-bot-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-hit-bot-event.yaml) from Server when our bullet has hit a bot
    - [ ] receive [bullet-hit-bullet-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-hit-bullet-event.yaml) from Server when our bullet collided with another bullet
    - [ ] receive [bullet-hit-wall-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-hit-wall-event.yaml) from Server when our bullet has hit the wall
    - [ ] receive [hit-by-bullet-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/hit-by-bullet-event.yaml) from Server when our bot has been hit by a bullet
    - [x] receive [scanned-bot-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/scanned-bot-event.yaml) from Server when our bot has scanned another bot
    - [x] receive [skipped-turn-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/skipped-turn-event.yaml) from Server when our bot skipped a turn (the intent was not received at the server in time)
    - [x] receive [tick-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/tick-event-for-bot.yaml) from Server when a new turn is about to begin
    - [ ] receive [won-round-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/won-round-event.yaml) from Server

### IBaseBot methods to implement
- [ ] addCustomEvent​(Condition condition) _#Adds an event handler that will be automatically triggered onCustomEvent(dev.robocode.tankroyale.botapi.events.CustomEvent) when the Condition.test() returns true._
- [ ] bearingTo​(double x, double y) _#Calculates the bearing (delta angle) between the current direction of the botÂ´s body and the direction to the point x,y._
- [ ] calcBearing​(double direction) _#Calculates the bearing (delta angle) between the input direction and the direction of this bot._
- [ ] calcBulletSpeed​(double firepower) _#Calculates the bullet speed given a fire power._
- [ ] calcDeltaAngle​(double targetAngle, double sourceAngle) _#Calculates the difference between two angles, i.e. the number of degrees from a source angle to a target angle._
- [ ] calcGunBearing​(double direction) _#Calculates the bearing (delta angle) between the input direction and the direction of the gun._
- [ ] calcGunHeat​(double firepower) _#Calculates gun heat after having fired the gun._
- [ ] calcMaxTurnRate​(double speed) _#Calculates the maximum turn rate for a specific speed._
- [ ] calcRadarBearing​(double direction) _#Calculates the bearing (delta angle) between the input direction and the direction of the radar._
- [ ] clearEvents() _#Clears the remaining events that have not been processed yet._
- [ ] directionTo​(double x, double y) _#Calculates the direction (angle) from the bot´s coordinates to a point x,y._
- [ ] distanceTo​(double x, double y) _#Calculates the distance from the bot's coordinates to a point x,y._
- [ ] getArenaHeight() _#Height of the arena measured in units._
- [ ] getArenaWidth() _#Width of the arena measured in units._
- [ ] getBodyColor() _#Returns the color of the body._
- [ ] getBulletColor() _#Returns the color of the fired bullets._
- [ ] getBulletStates() _#Current bullet states._
- [ ] getDirection() _#Current driving direction of the bot in degrees._
- [ ] getEnemyCount() _#Number of enemies left in the round._
- [ ] getEnergy() _#Current energy level._
- [ ] getEventPriority​(java.lang.Class<BotEvent> eventClass) _#Returns the event priority for a specific event class._
- [ ] getEvents() _#Events that remain to be processed in event handlers, which is useful to see the events that remain from event handlers being called before other event handlers._
- [ ] getFirepower() _#Returns the firepower._
- [ ] getGameType() _#Game type, e.g._
- [ ] getGunColor() _#Returns the color of the gun._
- [ ] getGunCoolingRate() _#Gun cooling rate._
- [ ] getGunDirection() _#Current direction of the gun in degrees._
- [ ] getGunHeat() _#Current gun heat._
- [ ] getGunTurnRate() _#Returns the gun turn rate in degrees per turn._
- [ ] getMaxGunTurnRate() _#Returns the maximum gun turn rate in degrees per turn._
- [ ] getMaxInactivityTurns() _#The maximum number of inactive turns allowed the bot will become zapped by the game for being inactive._
- [ ] getMaxRadarTurnRate() _#Returns the maximum radar turn rate in degrees per turn._
- [ ] getMaxSpeed() _#Returns the maximum speed in units per turn._
- [ ] getMaxTurnRate() _#Returns the maximum turn rate of the bot in degrees per turn._
- [ ] getMyId() _#Unique id of this bot, which is available when the game has started._
- [ ] getNumberOfRounds() _#The number of rounds in a battle._
- [ ] getRadarColor() _#Returns the color of the radar._
- [ ] getRadarDirection() _#Current direction of the radar in degrees._
- [ ] getRadarTurnRate() _#Returns the radar turn rate in degrees per turn._
- [ ] getRoundNumber() _#Current round number._
- [ ] getScanColor() _#Returns the color of the scan arc._
- [ ] getSpeed() _#The current speed measured in units per turn._
- [ ] getTargetSpeed() _#Returns the target speed in units per turn._
- [ ] getTimeLeft() _#The number of microseconds left of this turn before the bot will skip the turn._
- [ ] getTracksColor() _#Returns the color of the tracks._
- [ ] getTurnNumber() _#Current turn number._
- [ ] getTurnRate() _#Returns the turn rate of the bot in degrees per turn._
- [ ] getTurnTimeout() _#The turn timeout is important as the bot needs to take action by calling go() before the turn timeout occurs._
- [ ] getTurretColor() _#Returns the color of the gun turret._
- [ ] getVariant() _#The game variant, which is "Tank Royale"._
- [ ] getVersion() _#Game version, e.g. "1.0.0"._
- [ ] getX() _#Current X coordinate of the center of the bot._
- [ ] getY() _#Current Y coordinate of the center of the bot._
- [ ] go() _#Commits the current commands (actions), which finalizes the current turn for the bot._
- [ ] gunBearingTo​(double x, double y) _#Calculates the bearing (delta angle) between the current direction of the bot's gun and the direction to the point x,y._
- [ ] isAdjustGunForBodyTurn() _#Checks if the gun is set to adjust for the bot turning, i.e. to turn independent of the botÂ´s body turn._
- [ ] isAdjustRadarForBodyTurn() _#Checks if the radar is set to adjust for the body turning, i.e. to turn independent of the body's turn._
- [ ] isAdjustRadarForGunTurn() _#Checks if the radar is set to adjust for the gun turning, i.e. to turn independent of the gun's turn._
- [ ] isDisabled() _#Specifies if the bot is disabled, i.e., when the energy is zero._
- [ ] isStopped() _#Checks if the movement has been stopped._
- [ ] normalizeAbsoluteAngle​(double angle) _#Normalizes an angle to an absolute angle into the range [0,360[_
- [ ] normalizeRelativeAngle​(double angle) _#Normalizes an angle to an relative angle into the range [-180,180[_
- [ ] onBotDeath​(BotDeathEvent botDeathEvent) _#The event handler triggered when another bot has died._
- [ ] onBulletFired​(BulletFiredEvent bulletFiredEvent) _#The event handler triggered when the bot has fired a bullet._
- [ ] onBulletHit​(BulletHitBotEvent bulletHitBotEvent) _#The event handler triggered when the bot has hit another bot with a bullet._
onBulletHitBullet​(BulletHitBulletEvent bulletHitBulletEvent) _#The event handler triggered when a bullet fired from the bot has collided with another bullet._
- [ ] onBulletHitWall​(BulletHitWallEvent bulletHitWallEvent) _#The event handler triggered when a bullet has hit a wall._
- [x] onConnected​(ConnectedEvent connectedEvent) _#The event handler triggered when connected to the server._
- [x] onConnectionError​(ConnectionErrorEvent connectionErrorEvent) _#The event handler triggered when a connection error occurs._
- [ ] onCustomEvent​(CustomEvent customEvent) _#The event handler triggered when some condition has been met._
- [x] onDeath​(DeathEvent deathEvent) _#The event handler triggered when this bot has died._
- [ ] onDisconnected​(DisconnectedEvent disconnectedEvent) _#The event handler triggered when disconnected from the server._
- [x] onGameEnded​(GameEndedEvent gameEndedEvent) _#The event handler triggered when a game has ended._
- [x] onGameStarted​(GameStartedEvent gameStatedEvent) _#The event handler triggered when a game has started._
- [x] onHitBot​(HitBotEvent botHitBotEvent) _#The event handler triggered when the bot has collided with another bot._
- [x] onHitByBullet​(HitByBulletEvent hitByBulletEvent) _#The event handler triggered when the bot has been hit by a bullet._
- [x] onHitWall​(HitWallEvent botHitWallEvent) _#The event handler triggered when the bot has hit a wall._
- [ ] onRoundEnded​(RoundEndedEvent roundEndedEvent) _#The event handler triggered when a round has ended._
- [x] onRoundStarted​(RoundStartedEvent roundStartedEvent) _#The event handler triggered when a new round has started._
- [x] onScannedBot​(ScannedBotEvent scannedBotEvent) _#The event handler triggered when the bot has skipped a turn._
- [x] onSkippedTurn​(SkippedTurnEvent skippedTurnEvent) _#The event handler triggered when the bot has skipped a turn._
- [x] onTick​(TickEvent tickEvent) _#The event handler triggered when a game tick event occurs, ie., when a new turn in a round has started._
- [ ] onWonRound​(WonRoundEvent wonRoundEvent) _#The event handler triggered when the bot has won a round._
- [ ] radarBearingTo​(double x, double y) _#Calculates the bearing (delta angle) between the current direction of the botÂ´s radar and the direction to the point x,y._
- [ ] removeCustomEvent​(Condition condition) _#Removes triggering a custom event handler for a specific condition that was previously added with addCustomEvent(dev.robocode.tankroyale.botapi.events.Condition)._
- [ ] setAdjustGunForBodyTurn​(boolean adjust) _#Sets the gun to adjust for the botÂ´s turn when setting the gun turn rate._
- [ ] setAdjustRadarForBodyTurn​(boolean adjust) _#Sets the radar to adjust for the body's turn when setting the radar turn rate._
- [ ] setAdjustRadarForGunTurn​(boolean adjust) _#Sets the radar to adjust for the gun's turn when setting the radar turn rate._
- [ ] setBodyColor​(Color color) _#Sets the color of the body._
- [ ] setBulletColor​(Color color) _#Sets the color of the fired bullets._
- [ ] setEventPriority​(java.lang.Class<BotEvent> eventClass, int priority) _#Changes the event priority for an event class._
- [ ] setFire​(double firepower) _#Sets the gun to fire in the direction that the gun is pointing with the specified firepower._
- [ ] setFireAssist​(boolean enable) _#Enables or disables fire assistance explicitly._
- [ ] setGunColor​(Color color) _#Sets the color of the gun._
- [ ] setGunTurnRate​(double gunTurnRate) _#Sets the turn rate of the gun, which can be positive and negative._
- [ ] setInterruptible​(boolean interruptible) _#Call this method during an event handler to control continuing or restarting the event handler, when a new event occurs again for the same event handler while processing an earlier event._
- [ ] setMaxGunTurnRate​(double maxGunTurnRate) _#Sets the maximum turn rate which applies to turn the gun to the left or right._
- [ ] setMaxRadarTurnRate​(double maxRadarTurnRate) _#Sets the maximum turn rate which applies to turn the radar to the left or right._
- [ ] setMaxSpeed​(double maxSpeed) _#Sets the maximum speed which applies when moving forward and backward._
- [ ] setMaxTurnRate​(double maxTurnRate) _#Sets the maximum turn rate which applies to turn the bot to the left or right._
- [ ] setRadarColor​(Color color) _#Sets the color of the radar._
- [ ] setRadarTurnRate​(double gunRadarTurnRate) _#Sets the turn rate of the radar, which can be positive and negative._
- [ ] setRescan() _#Sets the bot to rescan with the radar._
- [ ] setResume() _#Sets the bot to scan (again) with the radar._
- [ ] setScanColor​(Color color) _#Sets the color of the scan arc._
- [ ] setStop() _#Set the bot to stop all movement including turning the gun and radar._
- [ ] setTargetSpeed​(double targetSpeed) _#Sets the new target speed for the bot in units per turn._
- [ ] setTracksColor​(Color color) _#Sets the color of the tracks._
- [ ] setTurnRate​(double turnRate) _#Sets the turn rate of the bot, which can be positive and negative._
- [ ] setTurretColor​(Color color) _#Sets the color of the gun turret._
- [ ] start() _#The method used to start running the bot._

### IBot methods to implement
- [ ] back​(double distance) _#Moves the bot backward until it has traveled a specific distance from its current position, or it is moving into an obstacle._
- [ ] fire​(double firepower) _#Fire the gun in the direction as the gun is pointing._
- [ ] forward​(double distance) _#Moves the bot forward until it has traveled a specific distance from its current position, or it is moving into an obstacle._
- [ ] getDistanceRemaining() _#Returns the distance remaining till the bot has finished moving after having called IBot.setForward(double), IBot.setBack(double), IBot.forward(double), or IBot.back(double)._
- [ ] getGunTurnRemaining() _#Returns the remaining turn in degrees till the gun has finished turning after having called IBot.setTurnGunLeft(double), IBot.setTurnGunRight(double), IBot.turnGunLeft(double), or IBot.turnGunRight(double)._
- [ ] getRadarTurnRemaining() _#Returns the remaining turn in degrees till the radar has finished turning after having called IBot.setTurnRadarLeft(double), IBot.setTurnRadarRight(double), IBot.turnRadarLeft(double), or IBot.turnRadarRight(double)._
- [ ] getTurnRemaining() _#Returns the remaining turn in degrees till the bot has finished turning after having called IBot.setTurnLeft(double), IBot.setTurnRight(double), IBot.turnLeft(double), or IBot.turnRight(double)._
- [x] isRunning() _#Checks if this bot is running._
- [ ] rescan() 	_#Scan (again) with the radar._
- [ ] resume() 	_#Resume the movement prior to calling the IBaseBot.setStop() or IBot.stop() method._
- [ ] setBack​(double distance) _#Set the bot to move backward until it has traveled a specific distance from its current position, or it is moving into an obstacle._
- [ ] setForward​(double distance) _#Set the bot to move forward until it has traveled a specific distance from its current position, or it is moving into an obstacle._
- [ ] setGunTurnRate​(double turnRate) _#Sets the turn rate of the gun, which can be positive and negative._
- [ ] setRadarTurnRate​(double turnRate) _#Sets the turn rate of the radar, which can be positive and negative._
- [ ] setTargetSpeed​(double targetSpeed) _#Sets the new target speed for the bot in units per turn._
- [ ] setTurnGunLeft​(double degrees) _#Set the gun to turn to the left (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] setTurnGunRight​(double degrees) _#Set the gun to turn to the right (following the decreasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] setTurnLeft​(double degrees)	_#Set the bot to turn to the left (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] setTurnRadarLeft​(double degrees) _#Set the radar to turn to the left (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] setTurnRadarRight​(double degrees) _#Set the radar to turn to the right (following the decreasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] setTurnRate​(double turnRate) _#Sets the turn rate of the bot, which can be positive and negative._
- [ ] setTurnRight​(double degrees) _#Set the bot to turn to the right (following the decreasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] stop() _#Stop all movement including turning the gun and radar._
- [ ] turnGunLeft​(double degrees) _#Turn the gun to the left (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] turnGunRight​(double degrees) _#Turn the gun to the right (following the decreasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] turnLeft​(double degrees) _#Turn the bot to the left (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] turnRadarLeft​(double degrees) _#Turn the radar to the left (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] turnRadarRight​(double degrees) _#Turn the radar to the right (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
- [ ] turnRight​(double degrees) _#Turn the bot to the right (following the increasing degrees of the unit circle) until it turned the specified amount of degrees._
waitFor​(Condition condition) _#Blocks until a condition is met, i.e. when a Condition.test() returns true._

### planned TODO
- [x] ~~init a new Bot importing the library~~ crete a new bot inheriting from a Bot object
- [x] init the bot passing a standard json file (read [create a json file for bot info](https://robocode-dev.github.io/tank-royale/tutorial/my-first-bot.html#create-a-json-file-for-bot-info))
- [x] have a "run" method
- [x] open WebSocket to Server to start the connection handshake
- [x] find out how to call a method that can be overridden from a new bot
- [x] find elegant method to convert between json and Messages object
- [x] implement all Messages objects
- [x] connect to server completing the handshake
- [ ] implement all [IBaseBot](https://robocode-dev.github.io/tank-royale/api/java/dev/robocode/tankroyale/botapi/IBaseBot.html) methods
- [ ] implement all [IBot](https://robocode-dev.github.io/tank-royale/api/java/dev/robocode/tankroyale/botapi/IBot.html) methods
- [x] write bash launcher (maybe with input functionality)
- [ ] complete standard bot bits and bobs necessary to make a working version 1.0.0