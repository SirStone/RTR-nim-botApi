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
    let serverArgs = ["-jar", "robocode-tankroyale-server-"&assets_version&".jar", "--botSecrets", botSecret, "--controllerSecrets", controllerSecret, "--port", port]
    serverProcess = startProcess(command="java", workingDir="assets", args=serverArgs, options={poStdErrToStdOut, poUsePath})
    
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

var turn_start:float = 0
var turn_end:float = 0
var json_message_for_controller = ""
let actions = @["turnLeft", "turnRight"]
var testsToDo = newSeq[Test]()
randomize()
var testTime = 10
for i in 0..3:
  let action = actions[rand(0..1)]
  let value = rand(-360.0..360.0)
  let turn_start_test = testTime
  let turn_end_test = 10 + testTime + (abs(value) / 10).int
  testsToDo.add(Test(action:action, value:value, turn_start:turn_start_test, turn_end:turn_end_test))
  testtime = turn_end_test + 10



proc actionCheck(actionType:string, turn_start:float, turn_end:float, expected_diff:float) =
  case actionType:
  of "turnLeft":    
    echo "turn_start: ",turn_start
    echo "turn_end: ",turn_end
    var diff = turn_end - turn_start
    if expected_diff >= 0:
      if diff < 0: diff = diff + 360.0
    else:
      if diff > 0: diff = diff - 360.0
    check round(diff,2) == round(expected_diff,2)
  of "turnRight":
    echo "turn_start: ",turn_start
    echo "turn_end: ",turn_end
    var diff = turn_start - turn_end
    if expected_diff >= 0:
      if diff < 0: diff = diff + 360.0
    else:
      if diff > 0: diff = diff - 360.0
    check round(diff,2) == round(expected_diff,2)

proc joinAsController(numberOfBots:int) {.async.} =
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
        let controller_handshake = ControllerHandshake(`type`:Type.controllerHandshake, sessionId:server_handshake.sessionId, name:"Conroller from tests", version:"1.0.0", author:"SirStone", secret:controllerSecret)
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
        controller_ws.close()
      of gameStartedEventForObserver:
        let game_Started_event_for_observer = json_message_for_controller.fromJson(GameStartedEventForObserver)
        for participant in game_Started_event_for_observer.participants:
          if participant.name == "TeStBoT":
            botId = participant.id
      of roundEndedEventForObserver:
        let round_ended_event_for_observer = json_message_for_controller.fromJson(RoundEndedEventForObserver)
        echo "skipped turns up to round ",round_ended_event_for_observer.roundNumber,": ",number_of_skipped_turns
      of roundStartedEvent:
        # reset some variables
        turn_start = 0
        currentTestIndex = 0
      of tickEventForObserver:
        let tick_event_for_observer = json_message_for_controller.fromJson(TickEventForObserver)
        for botState in tick_event_for_observer.botStates:
          if botState.id == botId:
            if turn_start == 0:
              turn_start = botState.direction
            else:
              turn_end = botState.direction
            break
        
        if currentTestIndex < testsToDo.len:
          let current_test = testsToDo[currentTestIndex]
          if tick_event_for_observer.turnNumber == current_test.turn_end:
            actionCheck(current_test.action,turn_start,turn_end,current_test.value)
            turn_start = turn_end
            currentTestIndex = currentTestIndex + 1
        # else:
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
      # BotToRun(name:"Crazy", path:"assets/sample-bots-java-"&assets_version),
      # BotToRun(name:"RamFire", path:"assets/sample-bots-java-"&assets_version),

      BotToRun(name:"TestBot", path:"out/tests"),
      # BotToRun(name:"Walls", path:"out/SampleBots")
      ]
    runBots(botsToRun)

    # run a Websocket server for the TestBot
    runChatServer()

    gameSetup = readFile(joinPath(getAppDir(),"gameSetup.json")).fromJson(GameSetup)

    # join as controller
    waitFor joinAsController(botsToRun.len)

    # cheks about the run
    check number_of_skipped_turns < 2 * gameSetup.numberOfRounds