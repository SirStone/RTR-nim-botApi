# STEP 1: import the module
import ../RTR_nim_botApi
import std/[os, random]

# STEP 2: create a new object reference of Bot object
type
  NewBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var new_bot = NewBot()
RTR_nim_botApi.enableDebug()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
new_bot.start("NewBot.json")

method run(bot:NewBot) =
  randomize()
  let num = rand(100000)
  var i = 0
  while(bot.isRunning()):
    sleep(1000)
    echo $num," running is " & $bot.isRunning() & "->" & $i
    i = i+1
  echo $num," stopped running"

method onSkippedTurn​(bot:NewBot, skipped_turn_event:SkippedTurnEvent) =
  if(false):
    echo "skipped turn number ",skipped_turn_event.turnNumber

method onGameStarted(bot:NewBot, game_started_event_for_bot:GameStartedEventForBot) =
  if(false):
    echo "game started "
    echo "my ID is ",bot.myId
    echo "GAME SETUP"
    echo bot.gameSetup[]

method onRoundStarted(bot:NewBot, round_started_event:RoundStartedEvent) =
  if(false):
    echo "round ",round_started_event.roundNumber," started"

method onGameEnded(bot:NewBot, game_ended_event_for_bot:GameEndedEventForBot) =
  if(false):
    echo "Game ended in ",game_ended_event_for_bot.numberOfRounds
    echo "RESULTS ",game_ended_event_for_bot.results[]

method onTick(bot:NewBot, tick_event_for_bot:TickEventForBot) =
  if(false):
    echo "TICK:",tick_event_for_bot[]

method onGameAborted(bot:NewBot, game_aborted_event:GameAbortedEvent) =
  if(true):
    echo "Game aborted"

method onDeath​(bot:NewBot, bot_death_event:BotDeathEvent) = 
  if(false):
    echo "BOT DEAD:",bot_death_event[]

method onHitWall​(bot:NewBot, bot_hit_wall_event:BotHitWallEvent) = 
  if(false):
    echo "HIT WALL:",bot_hit_wall_event[]

method onHitBot(bot:NewBot, bot_hit_bot_event:BotHitBotEvent) = 
  if(false):
    echo "HIT BOT:",bot_hit_bot_event[]

method onHitByBullet(bot:NewBot, hit_by_bullet_event:HitByBulletEvent) = 
  if(false):
    echo "OUCH:",hit_by_bullet_event[]
    echo "BULLET:",hit_by_bullet_event.bullet[]

method onScannedBot(bot:NewBot, scanned_bot_event:ScannedBotEvent) = 
  if(false):
    echo "SCAN:",scanned_bot_event[]

method onConnectionError​(bot:NewBot, error:string) = 
  if(true):
    echo "Connection error: ",error
    echo "Bot not started"

method onConnected​(bot:NewBot, url:string) =
  if(true):
    echo "connected successfully @ ",url