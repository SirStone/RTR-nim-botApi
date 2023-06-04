# STEP 1: import the module
import ../../src/RTR_nim_botApi
import os

# TEST LIBS: unit test, websockets
import std/[parsecsv, parseutils, sugar]
# import asyncdispatch

# let websocketServer:WebSocket = waitFor newWebSocket("ws://localhost:9001")

type
  Test = object
    action:string
    value:float
    turn_start:int
    turn_end:int

# import tests
var testsToDo = newSeq[Test]()
proc importTests() =
  var p:CsvParser
  p.open("testsToDo.csv", separator = '|')
  p.readHeaderRow()
  while p.readRow():
    let action = p.rowEntry("action")
    var value:float
    var turn_start, turn_end:int
    discard parseFloat(p.rowEntry("value"), value)
    discard parseInt(p.rowEntry("turn_start"), turn_start)
    discard parseInt(p.rowEntry("turn_end"), turn_end)
    testsToDo.add(Test(action: action, value: value, turn_start: turn_start, turn_end: turn_end))
  p.close()


# STEP 2: create a new object reference of Bot object
type
  TestBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var test_bot = TestBot()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
test_bot.newBot("TestBot.json")
assert test_bot.name == "TeStBoT"

test_bot.start( position=InitialPosition(x:400, y:300, angle:0))

method run(bot:TestBot) =
  importTests()
  echo "[TestBot] run started"
  var test_index = 0
  bot.setAdjustGunForBodyTurn(true)
  bot.setAdjustRadarForGunTurn(true)
  bot.setAdjustRadarForBodyTurn(true)
  echo "[TestBot] adjusted gun, radar and body"

  echo "[TestBot] starting tests, bot status is ",bot.isRunning()
  while bot.isRunning() and test_index < testsToDo.len:
    let test = testsToDo[test_index]
    if test.turn_start == bot.getTurnNumber():
      echo "[TestBot] ",test.action," started ",test.value, " at turn ",bot.getTurnNumber()
      case test.action:
      of "turnLeft":
        bot.turnLeft(test.value)
      of "turnRight":
        bot.turnRight(test.value)
      of "turnGunLeft":
        bot.turnGunLeft(test.value)
      of "turnGunRight":
        bot.turnGunRight(test.value)
      of "turnRadarLeft":
       bot. turnRadarLeft(test.value)
      of "turnRadarRight":
        bot.turnRadarRight(test.value)
      of "forward":
        bot.forward(test.value)
      of "back":
        bot.back(test.value)
      
      echo "[TestBot] ",test.action," done ",test.value, " at turn ",bot.getTurnNumber()
      test_index = test_index + 1
    
    bot.go()
  bot.go()
  echo "[TestBot] tests ended"
    

method onSkippedTurn(bot:TestBot, skipped_turn_event:SkippedTurnEvent) =
  # asyncCheck websocketServer.send("skipped")
  # echo "[TestBot] skipped turn ",skipped_turn_event.turnNumber
  stdout.write "s" & $skipped_turn_event.turnNumber
  stdout.flushFile()

method onGameStarted(bot:TestBot, game_started_event_for_bot:GameStartedEventForBot) =
  let id = game_started_event_for_bot.myId
  echo "[TestBot] My id is ",id

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
  # stdout.write "."
  # stdout.flushFile()

  if(false):
    echo "[TestBot]TICK:",tick_event_for_bot[]

method onGameAborted(bot:TestBot, game_aborted_event:GameAbortedEvent) =
  if(true):
    echo "[TestBot]Game aborted"

method onDeath(bot:TestBot, bot_death_event:BotDeathEvent) = 
  if(true):
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