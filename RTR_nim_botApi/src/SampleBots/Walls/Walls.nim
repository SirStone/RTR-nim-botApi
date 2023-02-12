# STEP 1: import the module
import ../../RTR_nim_botApi
import std/[os, random, math]

# STEP 2: create a new object reference of Bot object
type
  NewBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var walls = NewBot()
RTR_nim_botApi.enableDebug()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
walls.start("Walls.json")

var peek:bool # Don't turn if there's a bot there
var moveAmount:float # How much to move

# Called when a new round is started -> initialize and do some movement
method run(bot:NewBot) =
  # set colors
  walls.setBodyColor(Color.BLACK)
  walls.setTurretColor(Color.BLACK)
  walls.setRadarColor(Color.ORANGE)
  walls.setBulletColor(Color.CYAN)
  walls.setScanColor(Color.CYAN)
  
  # Initialize moveAmount to the maximum possible for the arena
  moveAmount = max(walls.getArenaWidth(), walls.getArenaHeight()).float;
  # Initialize peek to false
  peek = false;

  # turn to face a wall.
  # getDirection() % 90` means the remainder of getDirection() divided by 90.
  discard walls.getDirection()
  walls.turnRight(walls.getDirection() mod 90.float)
  walls.forward(moveAmount)

# method onSkippedTurn(bot:NewBot, skipped_turn_event:SkippedTurnEvent) =
#   if(false):
#     echo "skipped turn number ",skipped_turn_event.turnNumber

# method onGameStarted(bot:NewBot, game_started_event_for_bot:GameStartedEventForBot) =
#   if(false):
#     echo "game started "
#     echo "my ID is ",bot.myId
#     echo "GAME SETUP"
#     echo bot.gameSetup[]

# method onRoundStarted(bot:NewBot, round_started_event:RoundStartedEvent) =
#   if(false):
#     echo "round ",round_started_event.roundNumber," started"

# method onGameEnded(bot:NewBot, game_ended_event_for_bot:GameEndedEventForBot) =
#   if(false):
#     echo "Game ended in ",game_ended_event_for_bot.numberOfRounds
#     echo "RESULTS ",game_ended_event_for_bot.results[]

# method onTick(bot:NewBot, tick_event_for_bot:TickEventForBot) =
#   if(false):
#     echo "TICK:",tick_event_for_bot[]

# method onGameAborted(bot:NewBot, game_aborted_event:GameAbortedEvent) =
#   if(false):
#     echo "Game aborted"

# method onDeath(bot:NewBot, bot_death_event:BotDeathEvent) = 
#   if(false):
#     echo "BOT DEAD:",bot_death_event[]

# method onHitWall(bot:NewBot, bot_hit_wall_event:BotHitWallEvent) = 
#   if(false):
#     echo "HIT WALL:",bot_hit_wall_event[]

# method onHitBot(bot:NewBot, bot_hit_bot_event:BotHitBotEvent) = 
#   if(false):
#     echo "HIT BOT:",bot_hit_bot_event[]

# method onHitByBullet(bot:NewBot, hit_by_bullet_event:HitByBulletEvent) = 
#   if(false):
#     echo "OUCH:",hit_by_bullet_event[]
#     echo "BULLET:",hit_by_bullet_event.bullet[]

# method onScannedBot(bot:NewBot, scanned_bot_event:ScannedBotEvent) = 
#   if(false):
#     echo "SCAN:",scanned_bot_event[]

# method onConnectionError(bot:NewBot, error:string) = 
#   if(false):
#     echo "Connection error: ",error
#     echo "Bot not started"

# method onConnected(bot:NewBot, url:string) =
#   if(false):
#     echo "connected successfully @ ",url