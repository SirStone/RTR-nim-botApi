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

method run(bot: NewBot) =
  randomize()
  let num = rand(100000)
  var i = 0
  while(isRunning()):
    i = i+1
    turnRight(180)
    go()
  echo num," stopped running ",i

# method onHitByBullet(bot:NewBot, hitByBulletEvent:HitByBulletEvent) =
#   checkpoint("onHitByBullet")

method onSkippedTurn(bot:NewBot, skippedTurnEvent:SkippedTurnEvent) =
  echo "skipped turn ",skippedTurnEvent.turnNumber


var bot:NewBot
var serverProcess, booterProcess:Process
var botSecret, controllerSecret, port, connectionUrl: string

proc rndStr: string =
  for _ in 0..10:
    add(result, char(rand(int('a') .. int('z'))))

proc runTankRoyaleServer() =
  echo "running server"
  try:
    let serverArgs = ["-jar", "robocode-tankroyale-server-0.19.1.jar", "--botSecrets", botSecret, "--controllerSecrets", controllerSecret, "--port", port]
    serverProcess = startProcess(command="java", workingDir="assets", args=serverArgs, options={poEchoCmd, poStdErrToStdOut, poParentStreams, poUsePath})
    sleep(2000)    
  except:
    echo "error with the server:", getCurrentExceptionMsg()

proc runBooter() =
  echo "running booter"
  try:
    let booterArgs = ["-jar", "robocode-tankroyale-booter-0.19.1.jar", "run", "../out/SampleBots/Walls"]
    let bot_env = newStringTable({"SERVER_URL": connectionUrl, "SERVER_SECRET": botSecret})
    booterProcess = startProcess(command="java", workingDir="assets", args=booterArgs, options={poEchoCmd, poStdErrToStdOut, poParentStreams, poUsePath}, env=bot_env)
  except:
    echo "error with the booter:", getCurrentExceptionMsg()

proc joinAsController() {.async.} =
  try: # connects to the server with a websocket
    let controller_ws = await newWebSocket(connectionUrl)

     # while the connection is open...
    while(controller_ws.readyState == Open):
      # listen for a message
      let json_message_for_controller = await controller_ws.receiveStrPacket()

      # GATE:asas the message is received we if is empty or similar useless message
      if json_message_for_controller.isEmptyOrWhitespace(): continue

      # get the type of the message from the message itself
      let `type` = json_message_for_controller.fromJson(Message).`type`

      case `type`:
      of serverHandshake:
        let server_handshake = json_message_for_controller.fromJson(ServerHandshake)
        let controller_handshake = ControllerHandshake(`type`:Type.controllerHandshake, sessionId:server_handshake.sessionId, name:"Conroller from tests", version:"1.0.0", author:"SirStone", secret:controllerSecret)
        await controller_ws.send(controller_handshake.toJson)
      else:
        dump json_message_for_controller

  except:
    echo "error with the controller websocket:", getCurrentExceptionMsg()

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

    # run the booter
    runBooter()

    # join as controller
    asyncCheck joinAsController()
    
    echo "creating a new bot"
    bot = NewBot()
    bot.newBot("testJson.json")

    bot.setSecret(botSecret)
    bot.setServerURL(connectionUrl)

    check bot != nil
    check bot.name == "TEST BOT"
    check bot is NewBot
    check bot is Bot

    # bot.start()