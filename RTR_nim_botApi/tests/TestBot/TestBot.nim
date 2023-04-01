# STEP 1: import the module
import ../../src/RTR_nim_botApi
import std/[os, random]

# STEP 2: create a new object reference of Bot object
type
  TestBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var test_bot = TestBot()
test_bot.enableDebug()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
test_bot.newBot("TestBot.json")
test_bot.start()

method run(bot:TestBot) =
  # bot.setAdjustGunForBodyTurn(true)
  # bot.setAdjustRadarForGunTurn(true)
  # bot.setAdjustRadarForBodyTurn(true)

  # echo "NEW BOT " ,test_bot[]

  randomize()
  let num = rand(100000)
  var i = 0
  while(isRunning()):
    sleep(1000)
    echo $num," running is " & $isRunning() & "->" & $i
    i = i+1
  echo $num," stopped running"

method onSkippedTurn(bot:TestBot, skipped_turn_event:SkippedTurnEvent) =
  if(false):
    echo "skipped turn number ",skipped_turn_event.turnNumber

method onGameStarted(bot:TestBot, game_started_event_for_bot:GameStartedEventForBot) =
  discard

method onRoundStarted(bot:TestBot, round_started_event:RoundStartedEvent) =
  if(true):
    echo "round ",round_started_event.roundNumber," started"

method onRoundEnded(bot:TestBot, round_ended_event_for_bot:RoundEndedEventForBot) =
  if(true):
    echo "round ",round_ended_event_for_bot.roundNumber," ended"
    echo "ROUND SCORE: ", round_ended_event_for_bot.results[]

method onGameEnded(bot:TestBot, game_ended_event_for_bot:GameEndedEventForBot) =
  if(false):
    echo "Game ended in ",game_ended_event_for_bot.numberOfRounds
    echo "RESULTS ",game_ended_event_for_bot.results[]

method onTick(bot:TestBot, tick_event_for_bot:TickEventForBot) =
  if(false):
    echo "TICK:",tick_event_for_bot[]

method onGameAborted(bot:TestBot, game_aborted_event:GameAbortedEvent) =
  if(true):
    echo "Game aborted"

method onDeath(bot:TestBot, bot_death_event:BotDeathEvent) = 
  if(false):
    echo "BOT DEAD:",bot_death_event[]

method onHitWall(bot:TestBot, bot_hit_wall_event:BotHitWallEvent) = 
  if(false):
    echo "HIT WALL:",bot_hit_wall_event[]

method onHitBot(bot:TestBot, bot_hit_bot_event:BotHitBotEvent) = 
  if(false):
    echo "HIT BOT:",bot_hit_bot_event[]

method onHitByBullet(bot:TestBot, hit_by_bullet_event:HitByBulletEvent) = 
  if(true):
    echo "OUCH:",hit_by_bullet_event[]
    echo "BULLET:",hit_by_bullet_event.bullet[]

method onScannedBot(bot:TestBot, scanned_bot_event:ScannedBotEvent) = 
  if(false):
    echo "SCAN:",scanned_bot_event[]

method onConnectionError(bot:TestBot, error:string) = 
  if(true):
    echo "Connection error: ",error
    echo "Bot not started"

method onConnected(bot:TestBot, url:string) =
  if(true):
    echo "connected successfully @ ",url