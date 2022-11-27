# Robocode Tankroyale bot library written in NIM
This project has two independent goals:
1. creating a bot library that allows me (and others) to build bots in NIM
1. learning NIM. In this very moment I'm writing this README my exprience in writing NIM code is the basic "hello world"

## This document
I'm going to use this README for taking notes and instructions both.

## NOTES
### inspirational message
This is the inspirational message given to me from [Flemming N. Larsen](https://github.com/flemming-n-larsen) the author of the legendary (for me) [Robocode](https://robocode.sourceforge.io/) and the new promising [Robocode Tank Royale](https://robocode-dev.github.io/tank-royale/) abot how to head a project that aims to build a new bot library, discussion [here](https://github.com/robocode-dev/tank-royale/discussions/52):

>...bot might be as simple as the BaseBot from the JVM and .Net APIs. That is a thin layer on top of a web socket.
>
>In order to make a Bot API, all aspects involving a "bot" with the schemas must be implemented, which is not very complicated.
>
>Basically, a bot must:
>- Connect to the server via a WebSocket
>- Receive the server handshake and send its own handshake
>- When a start-game event is received, the bot must reply with a bot-ready
>- After this, the bot will receive tick-events with the game state, but only containing information visible for its perspective
>- The bot must send a bot-intent before turn-timeout with its new turn rates, target speed etc.
>- A battle-ended is received when the game is over.
>
>You can decide how the API must be, but the ones provided for JVM (Java) and .Net should serve as good sources of inspiration.
>
>Btw. there is no need for reverse engineering in the current Bot APIs, as the sources are provided as Open Source, and they have been kept as simple and straightforward as possible. At least that has been the intention...

### Bot interactions TODO (taken from [Schemas](https://github.com/robocode-dev/tank-royale/tree/master/schema/schemas#readme))
- [ ] Joining a Server
    - [ ] connect WebSocket
    - [ ] receive [server-handshake](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/server-handshake.yaml) from Server
    - [ ] send [bot-handshake](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-handshake.yaml) to Server
- [ ] Leaving a Server
    - [ ] disconnect WebSocket
- [ ] Partecipating in a Game
    - [ ] receive [game-started-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/game-started-event-for-bot.yaml) from Server
    - [ ] send [bot-ready](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-ready.yaml) to Server
- [ ] Running turns of the game
    - [ ] receive [round-started-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/round-started-event.yaml) from Server
    - [ ] receive [round-ended-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/round-ended-event.yaml) from Server
    - [ ] receive [tick-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/tick-event-for-bot.yaml) from Server
    - receive [skipped-turn-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/skipped-turn-event.yaml) from Server
    - [ ] send [bot-intent](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-intent.yaml) to Server
- [ ] end of the Game
    - [ ] receive [game-ended-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/game-ended-event-for-bot.yaml)
    - [ ] receive [won-round-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/won-round-event.yaml)
- [ ] in-game events
    - receive [game-aborted-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/game-aborted-event.yaml) from Server
    - [ ] receive [bot-death-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-death-event.yaml) from Server when a bot dies
    - [ ] receive [bot-hit-bot-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-hit-bot-event.yaml) from Server when our bot collides with another bot
    - [ ] receive [bot-hit-wall-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bot-hit-wall-event.yaml) from Server when our bot collides with a wall
    - [ ] receive [bullet-fired-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-fired-event.yaml) from Server when our bot fires a bullet
    - [ ] receive [bullet-hit-bot-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-hit-bot-event.yaml) from Server when our bullet has hit a bot
    - [ ] receive [bullet-hit-bullet-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-hit-bullet-event.yaml) from Server when our bullet collided with another bullet
    - [ ] receive [bullet-hit-wall-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/bullet-hit-wall-event.yaml) from Server when our bullet has hit the wall
    - [ ] receive [hit-by-bullet-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/hit-by-bullet-event.yaml) from Server when our bot has been hit by a bullet
    - [ ] receive [scanned-bot-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/scanned-bot-event.yaml) from Server when our bot has scanned another bot
    - [ ] receive [skipped-turn-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/skipped-turn-event.yaml) from Server when our bot skipped a turn (the intent was not received at the server in time)
    - [ ] receive [tick-event-for-bot](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/tick-event-for-bot.yaml) from Server when a new turn is about to begin
    - [ ] receive [won-round-event](https://github.com/robocode-dev/tank-royale/blob/master/schema/schemas/won-round-event.yaml) from Server 