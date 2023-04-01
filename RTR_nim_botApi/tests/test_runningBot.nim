# standard libraries
import std/[random, osproc, os, sugar, threadpool, streams, strutils, strtabs]
import asyncdispatch, ws, jsony

# unit test library
import unittest

# bot API
import RTR_nim_botApi

# I need to create a new type of Bot
type
    NewBot = ref object of Bot

var bot:NewBot
var serverProcess, booterProcess, botProcess:Process
var botProcesses:seq[Process]
var botSecret, controllerSecret, port, connectionUrl: string

proc rndStr: string =
  for _ in 0..10:
    add(result, char(rand(int('a') .. int('z'))))

proc tankRoyaleServerMessages(server_outputStream:Stream) {.async.} =
  var line = ""
  while server_outputStream.readLine(line):
    echo "SERVER: " & line
    await sleepAsync(1)

proc runTankRoyaleServer() =
  echo "running server"
  try:
    let serverArgs = ["-jar", "robocode-tankroyale-server-0.19.1.jar", "--botSecrets", botSecret, "--controllerSecrets", controllerSecret, "--port", port]
    serverProcess = startProcess(command="java", workingDir="assets", args=serverArgs, options={poStdErrToStdOut, poParentStreams, poUsePath})
    
    # wait for the booter to start
    sleep(2000)
  except:
    echo "error with the server:", getCurrentExceptionMsg()

type
  BotToRun = object
    name: string
    path: string

proc runBots(botsToRun:seq[BotToRun]) =
  botProcesses = newSeq[Process](botsToRun.len)
  for i,bot in botsToRun:
    botProcesses[i] = startProcess(command="bash "&bot.name&".sh", workingDir=joinPath(bot.path,bot.name), options={poStdErrToStdOut, poParentStreams, poUsePath, poEvalCommand}, env=newStringTable({"SERVER_URL":connectionUrl,"SERVER_SECRET":botSecret}) )

var json_message_for_controller = ""
proc joinAsController(numberOfBots:int) {.async.} =
  try: # connects to the server with a websocket
    let controller_ws = await newWebSocket(connectionUrl)

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

          let gameSetup = readFile(joinPath(getAppDir(),"gameSetup.json")).fromJson(GameSetup)
          let start_game = StartGame(`type`:Type.startGame, botAddresses:botAddresses, gameSetup:gameSetup)
          await controller_ws.send(start_game.toJson)
      of gameEndedEventForObserver:
        quit(0)
      of gameStartedEventForObserver:
        continue
      of roundEndedEventForObserver:
        continue
      of roundStartedEvent:
        continue
      of tickEventForObserver:
        continue
      else:
        dump json_message_for_controller

  except:
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
  enableDebug()

  setup: # run before each test
    echo "SETUP PHASE"
    echo "generating new secrets"
    randomize()
    botSecret = rndStr()
    controllerSecret = rndStr()
    port = $rand(10000 .. 32767)
    connectionUrl = "ws://localhost:" & port
    
  teardown: # run after each test
    echo "teardown"
    close(serverProcess)

  test "creating a new bot and starting it":
    # start the server
    runTankRoyaleServer()

    # run bots with booter
    let botsToRun = @[
      # BotToRun(name:"Walls", path:"assets/sample-bots-java-0.19.1"),
      # BotToRun(name:"Crazy", path:"assets/sample-bots-java-0.19.1"),
      BotToRun(name:"RamFire", path:"assets/sample-bots-java-0.19.1"),
      BotToRun(name:"TestBot", path:"out/tests"),
      # BotToRun(name:"Walls", path:"out/SampleBots")
      ]
    runBots(botsToRun)

    # join as controller
    waitFor joinAsController(botsToRun.len)