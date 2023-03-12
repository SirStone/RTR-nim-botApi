# standard libraries
import std/[os, random, asyncdispatch]

# unit test library
import unittest

# bot API
import RTR_nim_botApi

# I need to create a new type of Bot
type
    NewBot = ref object of Bot

enableDebug()

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
  checkpoint("skipped turn " & $skippedTurnEvent.turnNumber)

test "new bot":
    var bot = NewBot()
    bot.newBot("testJson.json")

    check bot != nil
    check bot.name == "test json file"
    check bot is NewBot
    check bot is Bot

    bot.setSecret("botssecret")

    bot.start()