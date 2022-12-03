# this enumeration contains all the types of Messages that exist
type
  Message = enum
    botHandshake,
    # serverHandshake,
    # botReady,
    # botIntent,
    # gameStartedEventForBot,
    # gameEndedEventForBot,
    # gameAbortedEvent,
    # roundStartedEvent,
    # roundEndedEvent,
    # botDeathEvent,
    # botHitBotEvent,
    # botHitWallEvent,
    # bulletFiredEvent,
    # bulletHitBotEvent,
    # bulletHitBulletEvent,
    # bulletHitWallEvent,
    # hitByBulletEvent,
    # scannedBotEvent,
    # skippedTurnEvent,
    # tickEventForBot,
    # wonRoundEvent,

  ServerHandshake* = ref object
    case kind: Message
    of botHandshake:
        sessionId: string #Unique session id used for identifying the caller client (bot, controller, observer) connection.
        name: string #Name of server, e.g. John Doe's RoboRumble Server
        variant: string #Game variant, e.g. 'Tank Royale' for Robocode Tank Royale
        version: string #Game version, e.g. '1.0.0' using Semantic Versioning (https://semver.org/)
        gameTypes: seq #Game types running at this server, e.g. "melee" and "1v1"

  
  