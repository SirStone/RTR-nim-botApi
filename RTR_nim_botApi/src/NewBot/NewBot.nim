# STEP 1: import the module
import ../RTR_nim_botApi
  

# STEP 2: create a new object reference of Bot object
type
  NewBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var new_bot = NewBot()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
new_bot.start("NewBot.json")

# STEP 5: start overriding the Bot methods
method run(bot:NewBot) =
  echo "run"
  # while(bot.isRunning):
  #   var sum = 2+5

method onSkippedTurn​(bot:NewBot, skipped_turn_event:SkippedTurnEvent) =
  echo "skipped turn number ",skipped_turn_event.turnNumber

method onRoundStarted(bot:NewBot, round_started_event:RoundStartedEvent) =
  echo "round ",round_started_event.roundNumber," started"