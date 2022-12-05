# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import jsony, json, times
import std/os
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

# proc parseHook*(s: string, i: var int, v: var string) =
#   case v:
#     of "ServerHandshake": 

test "JSON <-> Message":
  let json_message = """{"sessionId":"7vh2reL+TaeyXxEnN4Ngbg","name":"Robocode Tank Royale server","variant":"Tank Royale","version":"0.17.4","gameTypes":["classic","1v1"],"type":"ServerHandshake"}"""
  
  let t0 = epochTime()
  let `type` = json_message.fromJson(Message).`type`
  case `type`:
  of botHandshake:
    let message:BotHandshake = json_message.fromJson(BotHandshake)
    let json_message2 = message.toJson()
    check message is BotHandshake
    check json_message2 == json_message
  of serverHandshake:
    let message:ServerHandshake = json_message.fromJson(ServerHandshake)
    let json_message2 = message.toJson()
    check message is ServerHandshake
    check json_message2 == json_message
  echo "JSON-->object: ", epochTime() - t0