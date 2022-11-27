# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import json
import std/os

import RTR_nim_botApi
test "can init bot":
  # variables to use for checking
  let json_file = "new_bot.json"
  let json = parseJson(readFile(joinPath(getAppDir(),json_file)))
  let test_name = json["name"].getStr
  let test_version = json["version"].getStr
  let test_gameTypes = json["gameTypes"].getStr
  let test_authors = json["authors"].getStr
  let test_description = json["description"].getStr
  let test_homepage = json["homepage"].getStr
  let test_countryCodes = json["countryCodes"].getStr
  let test_platform = json["platform"].getStr
  let test_programmingLang = json["programmingLang"].getStr 

  # init bot
  let new_bot = initBot(json_file)

  # check if the new bot is type of Bot
  check new_bot of Bot

  # check if the read data from the json is the same as the json
  check new_bot.name == test_name
  check new_bot.version == test_version
  check new_bot.gameTypes == test_gameTypes
  check new_bot.authors == test_authors
  check new_bot.description == test_description
  check new_bot.homepage == test_homepage
  check new_bot.countryCodes == test_countryCodes
  check new_bot.platform == test_platform
  check new_bot.programmingLang == test_programmingLang
