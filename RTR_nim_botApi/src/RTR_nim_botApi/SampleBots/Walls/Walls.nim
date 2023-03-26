import ../../../RTR_nim_botApi
import std/[os, random, math]

type
  Walls = ref object of Bot

# STEP 3: istantiate a new object of the new type
var walls = Walls()
RTR_nim_botApi.enableDebug()

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
  moveAmount = max(getArenaWidth(), getArenaHeight()).float;
  # Initialize peek to false
  peek = false;

  # turn to face a wall.
  # getDirection() % 90` means the remainder of getDirection() divided by 90.
  turnRight(getDirection() mod 90.float)
  forward(moveAmount)

# method onSkippedTurn(bot:Walls, skipped_turn_event:SkippedTurnEvent) =
#   if(false):
#     echo "skipped turn number ",skipped_turn_event.turnNumber

# method onGameStarted(bot:Walls, game_started_event_for_bot:GameStartedEventForBot) =
#   if(false):
#     echo "game started "
#     echo "my ID is ",bot.myId
#     echo "GAME SETUP"
#     echo bot.gameSetup[]

# method onRoundStarted(bot:Walls, round_started_event:RoundStartedEvent) =
#   if(false):
#     echo "round ",round_started_event.roundNumber," started"

# method onGameEnded(bot:Walls, game_ended_event_for_bot:GameEndedEventForBot) =
#   if(false):
#     echo "Game ended in ",game_ended_event_for_bot.numberOfRounds
#     echo "RESULTS ",game_ended_event_for_bot.results[]

# method onTick(bot:Walls, tick_event_for_bot:TickEventForBot) =
#   if(false):
#     echo "TICK:",tick_event_for_bot[]

# method onGameAborted(bot:Walls, game_aborted_event:GameAbortedEvent) =
#   if(false):
#     echo "Game aborted"

# method onDeath(bot:Walls, bot_death_event:BotDeathEvent) = 
#   if(false):
#     echo "BOT DEAD:",bot_death_event[]

# method onHitWall(bot:Walls, bot_hit_wall_event:BotHitWallEvent) = 
#   if(false):
#     echo "HIT WALL:",bot_hit_wall_event[]

# method onHitBot(bot:Walls, bot_hit_bot_event:BotHitBotEvent) = 
#   if(false):
#     echo "HIT BOT:",bot_hit_bot_event[]

# method onHitByBullet(bot:Walls, hit_by_bullet_event:HitByBulletEvent) = 
#   if(false):
#     echo "OUCH:",hit_by_bullet_event[]
#     echo "BULLET:",hit_by_bullet_event.bullet[]

# method onScannedBot(bot:Walls, scanned_bot_event:ScannedBotEvent) = 
#   if(false):
#     echo "SCAN:",scanned_bot_event[]

# method onConnectionError(bot:Walls, error:string) = 
#   if(false):
#     echo "Connection error: ",error
#     echo "Bot not started"

# method onConnected(bot:Walls, url:string) =
#   if(false):
#     echo "connected successfully @ ",url