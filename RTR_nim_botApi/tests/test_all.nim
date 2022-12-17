# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import jsony, json, times
import std/os, std/strutils
import RTR_nim_botApi/Messages
import std/sugar
import nimjson

# STEP 1: import the module
import RTR_nim_botApi

# STEP 2: create a new object reference of Bot object
type
  NewBot = ref object of Bot
  
test "can init bot":
  # variables to use for checking
  let json_file:string = "new_bot.json"
  var json:string = readFile(joinPath(getAppDir(),json_file))
  let bot:Bot = json.fromJson(Bot)

  # STEP 3: istantiate a new object of the new type
  let new_bot = NewBot()

  # STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
  new_bot.initBot(json_file, false)

  # check if the new bot is type of Bot
  check new_bot of Bot

  # check if the read data from the json is the same as the json
  check new_bot.name == bot.name
  check new_bot.version == bot.version
  check new_bot.gameTypes == bot.gameTypes
  check new_bot.authors == bot.authors 
  check new_bot.description == bot.description
  check new_bot.homepage == bot.homepage
  check new_bot.countryCodes == bot.countryCodes
  check new_bot.platform == bot.platform
  check new_bot.programmingLang == bot.programmingLang

test "JSON <-> Message":
  let json_messages = @[
    """{"roundNumber":1,"enemyCount":1,"botState":{"energy":80.0,"x":418.66686836073654,"y":379.3486746531013,"direction":156.56947248748,"gunDirection":156.56947248748,"radarDirection":156.56947248748,"radarSweep":0.0,"speed":0.0,"turnRate":0.0,"gunTurnRate":0.0,"radarTurnRate":0.0,"gunHeat":0.0},"bulletStates":[{"bulletId":1,"ownerId":1,"power":1.0,"x":34.79070179011734,"y":579.340614094316,"direction":351.0,"color":"#008000"}],"events":[],"turnNumber":333,"type":"TickEventForBot"}""",
    """{"sessionId":"7vh2reL+TaeyXxEnN4Ngbg","name":"Robocode Tank Royale server","variant":"Tank Royale","version":"0.17.4","gameTypes":["classic","1v1"],"type":"ServerHandshake"}""",
    """{"type":"GameAbortedEvent"}""",
    """{"turnNumber":332,"type":"SkippedTurnEvent"}""",
    """{"roundNumber":1,"type":"RoundStartedEvent"}""",
    """{"numberOfRounds":1,"results":{"rank":2,"survival":0,"lastSurvivorBonus":0,"bulletDamage":0,"bulletKillBonus":0,"ramDamage":0,"ramKillBonus":0,"totalScore":0,"firstPlaces":0,"secondPlaces":1,"thirdPlaces":0},"type":"GameEndedEventForBot"}"""
  ]

  for json_message in json_messages:
    let `type` = json_message.fromJson(Message).`type`
    case `type`:
    of tickEventForBot:
      let message_obj = json_message.fromJson(TickEventForBot)
      let back_to_json = message_obj.toJson()
      let back_to_obj = back_to_json.fromJson(TickEventForBot)
      check back_to_obj is TickEventForBot
      check back_to_obj.botState is BotState
      check back_to_obj.bulletStates is seq[BulletState]
      check back_to_obj.roundNumber == 1
      check back_to_obj.enemyCount == 1 
      check back_to_obj.botState.energy == 80.0
      check back_to_obj.botState.x == 418.6668683607365 # here I've ignored the last digit
      check back_to_obj.botState.y == 379.3486746531013
      check back_to_obj.botState.direction == 156.56947248748
      check back_to_obj.botState.gunDirection == 156.56947248748
      check back_to_obj.botState.radarDirection == 156.56947248748
      check back_to_obj.botState.radarSweep == 0.0
      check back_to_obj.botState.speed == 0.0
      check back_to_obj.botState.turnRate == 0.0
      check back_to_obj.botState.gunTurnRate == 0.0
      check back_to_obj.botState.gunHeat == 0.0
      check back_to_obj.turnNumber == 333
    of serverHandshake:
      let message_obj = json_message.fromJson(ServerHandshake)
      let back_to_json = message_obj.toJson()
      let back_to_obj = back_to_json.fromJson(ServerHandshake)
      check back_to_obj is ServerHandshake
      check back_to_json == json_message
    of gameAbortedEvent:
      let message_obj = json_message.fromJson(GameAbortedEvent)
      let back_to_json = message_obj.toJson()
      let back_to_obj = back_to_json.fromJson(GameAbortedEvent)
      check back_to_json == json_message
    of skippedTurnEvent:
      let message_obj = json_message.fromJson(SkippedTurnEvent)
      let back_to_json = message_obj.toJson()
      let back_to_obj = back_to_json.fromJson(SkippedTurnEvent)
      check back_to_json == json_message
    of roundStartedEvent:
      let message_obj = json_message.fromJson(RoundStartedEvent)
      let back_to_json = message_obj.toJson()
      let back_to_obj = back_to_json.fromJson(RoundStartedEvent)
      check back_to_json == json_message
    of gameEndedEventForBot:
      let message_obj = json_message.fromJson(GameEndedEventForBot)
      let back_to_json = message_obj.toJson()
      let back_to_obj = back_to_json.fromJson(GameEndedEventForBot)
      check back_to_json == json_message
    else:
      echo "TODO:",json_message
