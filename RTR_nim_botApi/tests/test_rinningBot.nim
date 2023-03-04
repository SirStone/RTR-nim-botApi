# standard libraries
import std/[os]

# unit test library
import unittest

# bot API
import RTR_nim_botApi
import RTR_nim_botApi/Components/[Bot]

# I need to create a new type of Bot
type
    NewBot = ref object of Bot

enableDebug()

test "new bot":
    var bot = NewBot()
    bot.newBot("testJson.json")

    check bot != nil
    check bot.name == "test json file"
    check bot is NewBot
    check bot is Bot

    bot.setSecret("botssecret")

    bot.start()