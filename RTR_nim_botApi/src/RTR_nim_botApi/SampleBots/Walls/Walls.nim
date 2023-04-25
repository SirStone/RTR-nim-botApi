import ../../../RTR_nim_botApi
import std/[os, random, math]

type
  Walls = ref object of Bot

# STEP 3: istantiate a new object of the new type
var walls = Walls()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
walls.newBot("Walls.json")
walls.start()

var peek:bool # Don't turn if there's a bot there
var moveAmount:float # How much to move

# Called when a new round is started -> initialize and do some movement
method run(bot:Walls) =
  # set colors
  setBodyColor("#000000")
  setTurretColor("#000000")
  setRadarColor("#FFA500")
  setBulletColor("#00FFFF")
  setScanColor("#00FFFF")
  
  # Initialize moveAmount to the maximum possible for the arena
  moveAmount = max(getArenaWidth(), getArenaHeight()).float
  # Initialize peek to false
  peek = false

  # turn to face a wall.
  # getDirection() % 90` means the remainder of getDirection() divided by 90.
  let direction = getDirection()
  let angle = direction mod 90.0
  echo "angle: ",angle, " getDirection(): ",direction
  turnRight(angle)
  forward(moveAmount)
  echo "moveAmount done: ",moveAmount
  # Turn the gun to turn right 90 degrees.
  peek = true
  turnGunRight(90)
  turnRight(90)

  # Main loop
  while isRunning():
    # Peek before we turn when forward() completes
    peek = true
    # Move up the wall
    forward(moveAmount)
    # Don't peek now
    peek = false
    # Turn to the next wall
    turnRight(90)

method onSkippedTurn(bot:Walls, skipped_turn_event:SkippedTurnEvent) = 
  echo "skipped turn: ",skipped_turn_event.turnNumber
  echo "is running: ",isRunning()
  echo "last turn we sent intent", lastTurnWeSentIntent
  echo "send intent: ",sendIntent

# We hit another bot -> move away a bit
method onHitBot(bot:Walls, bot_hit_bot_event:BotHitBotEvent) = 
  # If he's in front of us, set back up a bit.
  let bearing = bearingTo(bot_hit_bot_event.x, bot_hit_bot_event.y)
  if bearing > -90 and bearing < 90:
    back(100)
  else: # else he's in back of us, so set ahead a bit.
    forward(100)

method onDeath(bot:Walls, death_event:BotDeathEvent) = 
  echo "DEATH"

# method onHitByBullet(bot:Walls, hit_by_bullet_event:HitByBulletEvent) = 
#   if(false):
#     echo "OUCH:",hit_by_bullet_event[]
#     echo "BULLET:",hit_by_bullet_event.bullet[]

# We scanned another bot -> fire!
method onScannedBot(bot:Walls, scanned_bot_event:ScannedBotEvent) = 
  discard fire(2)
  # Note that scan is called automatically when the bot is turning.
  # By calling it manually here, we make sure we generate another scan event if there's a bot
  # on the next wall, so that we do not start moving up it until it's gone.
  if peek:
    rescan()

# method onConnectionError(bot:Walls, error:string) = 
#   if(false):
#     echo "Connection error: ",error
#     echo "Bot not started"

# method onConnected(bot:Walls, url:string) =
#   if(false):
#     echo "connected successfully @ ",url