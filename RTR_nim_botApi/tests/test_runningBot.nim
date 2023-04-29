# standard libraries
import std/[random, osproc, os, sugar, strutils, strtabs, math]
import asyncdispatch, ws, jsony, asynchttpserver

# unit test library
import unittest

# bot API
import RTR_nim_botApi

# I need to create a new type of Bot
type
    NewBot = ref object of Bot

var bot:NewBot
var serverProcess:Process
var botProcesses:seq[Process]
var botSecret, controllerSecret, port, connectionUrl: string
var gameSetup:GameSetup
let assets_version = "0.19.2"
var botId = 0

proc rndStr: string =
  for _ in 0..10:
    add(result, char(rand(int('a') .. int('z'))))

proc runTankRoyaleServer() =
  echo "running server"
  try:
    let serverArgs = ["-jar", "robocode-tankroyale-server-"&assets_version&".jar", "--botSecrets", botSecret, "--controllerSecrets", controllerSecret, "--port", port, "--enable-initial-position"]
    serverProcess = startProcess(command="java", workingDir="assets", args=serverArgs, options={poStdErrToStdOut, poUsePath, poParentStreams})
    
    # wait for the booter to start
    sleep(2000)
  except CatchableError:
    echo "error with the server:", getCurrentExceptionMsg()

type
  Test = object
    action:string
    value:float
    turn_start:int
    turn_end:int

type
  BotToRun = object
    name: string
    path: string

proc runBots(botsToRun:seq[BotToRun]) =
  botProcesses = newSeq[Process](botsToRun.len)
  for i,bot in botsToRun:
    botProcesses[i] = startProcess(command=bot.name&".sh ", workingDir=joinPath(bot.path,bot.name), options={poStdErrToStdOut, poParentStreams, poUsePath, poEvalCommand}, env=newStringTable({"SERVER_URL":connectionUrl,"SERVER_SECRET":botSecret}) )

var number_of_skipped_turns = 0
proc cb(req: Request) {.async, gcsafe.} =
  try:
    var ws = await newWebSocket(req)
    await ws.send("Welcome to simple chat server")
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      case packet:
      of "skipped":
        number_of_skipped_turns = number_of_skipped_turns + 1
  except WebSocketClosedError:
    echo "Socket closed. "
  except WebSocketProtocolMismatchError:
    echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
  except WebSocketError:
    echo "Unexpected socket error: ", getCurrentExceptionMsg()

proc runChatServer() = 
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9001), cb)

var json_message_for_controller = ""
let actions = @["turnLeft", "turnRight", "turnGunLeft", "turnGunRight", "turnRadarLeft", "turnRadarRight", "forward", "back"]
# let actions = @["forward", "back"]
var testsToDo = newSeq[Test]()
randomize()
var testTime = 10
for i in 1..10:
  let action = actions[rand(0..actions.high)]
  var value = rand(-360.0..360.0)
  let turn_start_test = testTime
  var dividend:float
  case action:
  of "turnLeft":
    dividend = 10
  of "turnRight":
    dividend = 10
  of "turnGunLeft":
    dividend = 20
  of "turnGunRight":
    dividend = 20
  of "turnRadarLeft":
    dividend = 45
  of "turnRadarRight":
    dividend = 45
  of "forward":
    value = rand(-100.0..100.0).ceil
    dividend = 3
  of "back":
    value = rand(-100.0..100.0).ceil
    dividend = 3
  else:
    dividend = 10

  let turn_end_test = 10 + testTime + (abs(value) / dividend).int
  testsToDo.add(Test(action:action, value:value, turn_start:turn_start_test, turn_end:turn_end_test))
  testtime = turn_end_test + 10

# open file for tests results
let fileNameResults = "out/tests/TestBot/testsResults.csv"
removeFile(fileNameResults)
var csvResults = open(fileNameResults, fmAppend)
csvResults.setFilePos(0)
csvResults.writeLine("ROUND|ACTION|ACTION_START_VALUE|ACTION_END_VALUE|EXPECTED_VALUE|VALUE|OUTCOME")

proc actionCheck(actionType:string, value_start:seq[float], value_end:seq[float], expected:float):float =
  echo "[TEST] ",actionType,"_start: [x:",value_start[0],",y:",value_start[1],"]"
  echo "[TEST] ",actionType,"_end: [x:",value_end[0],",y:",value_end[1],"]"
  return sqrt((value_end[0] - value_start[0]).pow(2) + (value_end[1] - value_start[1]).pow(2))

proc actionCheck(actionType:string, value_start:float, value_end:float, expected:float):float =
  echo "[TEST] ",actionType,"_start: ",value_start
  echo "[TEST] ",actionType,"_end: ",value_end

  case actionType:
  of "turnLeft":    
    result = value_end - value_start
  of "turnRight":
    result = value_start - value_end
  of "turnGunLeft":
    result = value_end - value_start
  of "turnGunRight":
    result = value_start - value_end
  of "turnRadarLeft":
    result = value_end - value_start
  of "turnRadarRight":
    result = value_start - value_end
  else:
    result = 0

  if expected >= 0:
    if result < 0: result = result + 360.0
  else:
    if result > 0: result = result - 360.0

proc joinAsController(numberOfBots:int) {.async.} =
  var body_turn_start, body_turn_end, gun_turn_start, gun_turn_end, radar_turn_start, radar_turn_end, x_start, x_end, y_start, y_end:float
  try: # connects to the server with a websocket
    let controller_ws = await newWebSocket(connectionUrl)
    var currentTestIndex = 0

    # while the connection is open...
    while(controller_ws.readyState == Open):
      # listen for a message
      json_message_for_controller = await controller_ws.receiveStrPacket()

      # GATE:asas the message is received we if is empty or similar useless message
      if json_message_for_controller.isEmptyOrWhitespace(): continue

      # get the type of the message from the message itself
      let `type` = json_message_for_controller.fromJson(Message).`type`

      case `type`:
      of serverHandshake:
        let server_handshake = json_message_for_controller.fromJson(ServerHandshake)
        let controller_handshake = ControllerHandshake(`type`:Type.controllerHandshake, sessionId:server_handshake.sessionId, name:"Controller from tests", version:"1.0.0", author:"SirStone", secret:controllerSecret)
        await controller_ws.send(controller_handshake.toJson)
      of botListUpdate:
        let bot_list_update = json_message_for_controller.fromJson(BotListUpdate)
        echo bot_list_update.bots.len,"/",numberOfBots
        if bot_list_update.bots.len == numberOfBots:
          var botAddresses:seq[BotAddress] = @[]
          for bot in bot_list_update.bots:
            let botAddress = BotAddress(host:bot.host, port:bot.port)
            botAddresses.add(botAddress)

          let start_game = StartGame(`type`:Type.startGame, botAddresses:botAddresses, gameSetup:gameSetup)
          await controller_ws.send(start_game.toJson)
      of gameEndedEventForObserver:
        # close results file
        csvResults.close()

        # close websocket
        controller_ws.close()
      of gameStartedEventForObserver:
        let game_Started_event_for_observer = json_message_for_controller.fromJson(GameStartedEventForObserver)
        for participant in game_Started_event_for_observer.participants:
          if participant.name == "TeStBoT":
            botId = participant.id
      of roundEndedEventForObserver:
        let round_ended_event_for_observer = json_message_for_controller.fromJson(RoundEndedEventForObserver)
        # echo "[TEST] skipped turns up to round ",round_ended_event_for_observer.roundNumber,": ",number_of_skipped_turns
      of roundStartedEvent:
        # reset some variables
        body_turn_start = -1
        gun_turn_start = -1
        radar_turn_start = -1
        x_start = -1
        y_start = -1
        currentTestIndex = 0
      of tickEventForObserver:
        if currentTestIndex < testsToDo.len:
          let tick_event_for_observer = json_message_for_controller.fromJson(TickEventForObserver)
          for botState in tick_event_for_observer.botStates:
            if botState.id == botId:
              if body_turn_start == -1:
                body_turn_start = botState.direction
              else:
                body_turn_end = botState.direction

              if gun_turn_start == -1:
                gun_turn_start = botState.gunDirection
              else:
                gun_turn_end = botState.gunDirection

              if radar_turn_start == -1:
                radar_turn_start = botState.radarDirection
              else:
                radar_turn_end = botState.radarDirection

              if x_start == -1:
                x_start = botState.x
              else:
                x_end = botState.x

              if y_start == -1:
                y_start = botState.y
              else:
                y_end = botState.y

              break # no need to check other bots

          var turn_start_value, turn_end_value, x_start_value, x_end_value, y_start_value, y_end_value:float
          let current_test = testsToDo[currentTestIndex]
          var isXY = false
          case current_test.action:
          of "turnLeft":
            turn_start_value = body_turn_start
            turn_end_value = body_turn_end
          of "turnRight":
            turn_start_value = body_turn_start
            turn_end_value = body_turn_end
          of "turnGunLeft":
            turn_start_value = gun_turn_start
            turn_end_value = gun_turn_end
          of "turnGunRight":
            turn_start_value = gun_turn_start
            turn_end_value = gun_turn_end
          of "turnRadarLeft":
            turn_start_value = radar_turn_start
            turn_end_value = radar_turn_end
          of "turnRadarRight":
            turn_start_value = radar_turn_start
            turn_end_value = radar_turn_end
          of "forward":
            x_start_value = x_start
            y_start_value = y_start
            x_end_value = x_end
            y_end_value = y_end
            isXY = true
          of "back":
            x_start_value = x_start
            y_start_value = y_start
            x_end_value = x_end
            y_end_value = y_end
            isXY = true

          # echo "[TEST] x_start_value: ", x_start_value, " y_start_value: ", y_start_value, " x_end_value: ", x_end_value, " y_end_value: ", y_end_value

          if tick_event_for_observer.turnNumber == current_test.turn_end:
            var csv_start_value, csv_end_value:string
            var diff:float
            if isXY: 
              diff = actionCheck(current_test.action,@[x_start_value, y_start_value],@[x_end_value, y_end_value],current_test.value)
              csv_start_value = "x:" & $x_start_value & " y:" & $y_start_value
              csv_end_value = "x:" & $x_end_value & " y:" & $y_end_value
            else:
              diff = actionCheck(current_test.action,turn_start_value,turn_end_value,current_test.value)
              csv_start_value = $turn_start_value
              csv_end_value = $turn_end_value
            let outcome = diff.round.abs == current_test.value.round.abs
            check outcome

            # write results to file
            csvResults.writeLine($tick_event_for_observer.roundNumber & "|" & current_test.action & "|" & csv_start_value & "|" & csv_end_value & "|" & $current_test.value.abs & "|" & $diff.abs & "|" & $outcome)

            body_turn_start = body_turn_end
            gun_turn_start = gun_turn_end
            radar_turn_start = radar_turn_end
            x_start = x_end
            y_start = y_end
            
            currentTestIndex = currentTestIndex + 1
        # else:
          # close results file
          # csvResults.close()
        #   let stop_game = StopGame(`type`:Type.stopGame)
        #   await controller_ws.send(stop_game.toJson)
          
          
      else:
        dump json_message_for_controller

  except CatchableError:
    echo "error with the controller websocket:", getCurrentExceptionMsg()
    echo "LAST MESSAGE:"
    dump json_message_for_controller

suite "Creating a bot":
  # echo "creating a new bot"
    bot = NewBot()
    bot.newBot("testJson.json")

    bot.setSecret(botSecret)
    bot.setServerURL(connectionUrl)

    check bot != nil
    check bot.name == "TEST BOT"
    check bot is NewBot
    check bot is Bot

suite "Running a full game":
  setup: # run before each test
    echo "SETUP PHASE"
    echo "generating new secrets"
    randomize()
    botSecret = rndStr()
    controllerSecret = rndStr()
    port = $rand(10000 .. 65535)
    connectionUrl = "ws://localhost:" & port
    
  teardown: # run after each test
    echo "teardown"
    close(serverProcess)

  test "creating a new bot and testing the API on it":
    # start the server
    runTankRoyaleServer()

    # write the tests for the bot here
    let fileName = "out/tests/TestBot/testsToDo.csv"
    removeFile(fileName)
    var csv = open(fileName, fmAppend)
    csv.setFilePos(0)
    csv.writeLine("action|value|turn_start|turn_end")
    for test in testsToDo:
      csv.writeLine(test.action & "|" & $(test.value) & "|" & $(test.turn_start) & "|" & $(test.turn_end) )
    csv.close()

    # run bots with booter
    let botsToRun = @[
      BotToRun(name:"TrackFire", path:"assets/sample-bots-java-"&assets_version), # fast death
      # BotToRun(name:"Target", path:"assets/sample-bots-java-"&assets_version), # slowest death
      # BotToRun(name:"Corners", path:"assets/sample-bots-java-"&assets_version),
      # BotToRun(name:"Walls", path:"assets/sample-bots-java-"&assets_version),
      # BotToRun(name:"Crazy", path:"assets/sample-bots-java-"&assets_version), # medium speed death
      # BotToRun(name:"RamFire", path:"assets/sample-bots-java-"&assets_version),

      BotToRun(name:"TestBot", path:"out/tests"),
      # BotToRun(name:"Walls", path:"out/SampleBots")
      ]
    runBots(botsToRun)

    # run a Websocket server for the TestBot
    # runChatServer()

    gameSetup = readFile(joinPath(getAppDir(),"gameSetup.json")).fromJson(GameSetup)

    # join as controller
    waitFor joinAsController(botsToRun.len)

    # cheks about the run
    # check number_of_skipped_turns < 2 * gameSetup.numberOfRounds