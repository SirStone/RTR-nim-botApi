# STEP 1: import the module
import ../RTR_nim_botApi

# STEP 2: create a new object reference of Bot object
type
  NewBot = ref object of Bot

# STEP 3: istantiate a new object of the new type
var new_bot = NewBot()

# STEP 4: start the bot calling for the initBot(json_file, connect[true/false]) proc
new_bot.start("NewBot.json")

method onSkippedTurn​(bot:NewBot, skipped_turn_event:SkippedTurnEvent) =
  if(false):
    echo "skipped turn number ",skipped_turn_event.turnNumber

method onGameStarted(bot:NewBot, game_started_event_for_bot:GameStartedEventForBot) =
  if(false):
    echo "game started "
    echo "my ID is ",bot.myId
    echo "GAME SETUP"
    echo bot.gameSetup[]

method onRoundStarted(bot:NewBot, round_started_event:RoundStartedEvent) =
  if(false):
    echo "round ",round_started_event.roundNumber," started"

method onGameEnded(bot:NewBot, game_ended_event_for_bot:GameEndedEventForBot) =
  if(false):
    echo "Game ended in ",game_ended_event_for_bot.numberOfRounds
    echo "RESULTS ",game_ended_event_for_bot.results[]

method onTick(bot:NewBot, tick_event_for_bot:TickEventForBot) =
  if(true):
    echo "TICK:",tick_event_for_bot[]

method onGameAborted(bot:NewBot, game_aborted_event:GameAbortedEvent) =
  if(false):
    echo "Game aborted"

method onHitWall​(bot:NewBot, bot_hit_wall_event:BotHitWallEvent) = 
  if(false):
    echo "HIT WALL:",bot_hit_wall_event[]

method onHitByBullet(bot:NewBot, hit_by_bullet_event:HitByBulletEvent) = 
  if(true):
    echo "OUCH:",hit_by_bullet_event[]