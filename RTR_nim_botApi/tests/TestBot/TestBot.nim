# STEP 1: import the module
import ../../src/RTR_nim_botApi

# TEST LIBS: unit test, websockets
import ws, asyncdispatch

let websocketServer:WebSocket = waitFor newWebSocket("ws://localhost:9001")

# STEP 2: create a new object reference of Bot object
type
  TestBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var test_bot = TestBot()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
test_bot.newBot("TestBot.json")
test_bot.start()

# DEBUG VARIABLES
method run(bot:TestBot) =
  var i = 0
  while(isRunning() and i < 10000):
    i = i + 1
    go()

method onSkippedTurn(bot:TestBot, skipped_turn_event:SkippedTurnEvent) =
  asyncCheck websocketServer.send("skipped")
  if(false):
    echo "[TestBot]SKIPPED TURN NUMBER!! ",skipped_turn_event.turnNumber

method onGameStarted(bot:TestBot, game_started_event_for_bot:GameStartedEventForBot) =
  if(true):
    echo "[TestBot]game started"
    echo "[TestBot]GAME SETUP: ", game_started_event_for_bot.gameSetup[]
    echo "[TestBot]My ID: ", game_started_event_for_bot.myId

method onRoundStarted(bot:TestBot, round_started_event:RoundStartedEvent) =
  if(true):
    echo "[TestBot]round ",round_started_event.roundNumber," started"

method onRoundEnded(bot:TestBot, round_ended_event_for_bot:RoundEndedEventForBot) =
  if(true):
    echo "[TestBot]round ",round_ended_event_for_bot.roundNumber," ended"
    echo "[TestBot]ROUND SCORE: ", round_ended_event_for_bot.results[]

method onGameEnded(bot:TestBot, game_ended_event_for_bot:GameEndedEventForBot) =
  if(false):
    echo "[TestBot]Game ended in ",game_ended_event_for_bot.numberOfRounds
    echo "[TestBot]RESULTS ",game_ended_event_for_bot.results[]

method onTick(bot:TestBot, tick_event_for_bot:TickEventForBot) =
  if(false):
    echo "[TestBot]TICK:",tick_event_for_bot[]

method onGameAborted(bot:TestBot, game_aborted_event:GameAbortedEvent) =
  if(true):
    echo "[TestBot]Game aborted"

method onDeath(bot:TestBot, bot_death_event:BotDeathEvent) = 
  if(false):
    echo "[TestBot]BOT DEAD:",bot_death_event[]

method onHitWall(bot:TestBot, bot_hit_wall_event:BotHitWallEvent) = 
  if(false):
    echo "[TestBot]HIT WALL:",bot_hit_wall_event[]

method onHitBot(bot:TestBot, bot_hit_bot_event:BotHitBotEvent) = 
  if(false):
    echo "[TestBot]HIT BOT:",bot_hit_bot_event[]

method onHitByBullet(bot:TestBot, hit_by_bullet_event:HitByBulletEvent) = 
  if(false):
    echo "[TestBot]OUCH:",hit_by_bullet_event[]
    echo "[TestBot]BULLET:",hit_by_bullet_event.bullet[]

method onScannedBot(bot:TestBot, scanned_bot_event:ScannedBotEvent) = 
  if(false):
    echo "[TestBot]SCAN:",scanned_bot_event[]

method onConnectionError(bot:TestBot, error:string) = 
  if(true):
    echo "[TestBot]Connection error: ",error
    echo "[TestBot]Bot not started"

method onConnected(bot:TestBot, url:string) =
  if(true):
    echo "[TestBot]connected successfully @ ",url