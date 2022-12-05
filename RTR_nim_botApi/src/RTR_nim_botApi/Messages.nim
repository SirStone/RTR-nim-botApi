type
  Type* = enum
    botHandshake = "BotHandshake",
    serverHandshake = "ServerHandshake"

  Message* = ref object of RootObj
    `type`*: Type

  InitialPosition* = ref object of RootObj
    x,y, angle: float #The x,y and angle coordinate. When it is not set, a random value will be used

  ServerHandshake* = ref object of Message
    sessionId*: string #Unique session id used for identifying the caller client (bot, controller, observer) connection.
    name*: string #Name of server, e.g. John Doe's RoboRumble Server
    variant*: string #Game variant, e.g. 'Tank Royale' for Robocode Tank Royale
    version*: string #Game version, e.g. '1.0.0' using Semantic Versioning (https://semver.org/)
    gameTypes*: seq[string] #Game types running at this server, e.g. "melee" and "1v1"

  BotHandshake* = ref object of Message
    sessionId*: string #Unique session id that must match the session id received from the server handshake
    name*: string #Name of bot, e.g. Killer Bee
    version*: string #Bot version, e.g. 1.0
    authors*: seq[string] #Name of authors, e.g. John Doe (john_doe@somewhere.net)
    description*: string #Short description of the bot, preferable a one-liner
    homepage*: string #URL to a home page for the bot
    countryCodes*: seq[string] #2-letter country code(s) defined by ISO 3166-1, e.g. "UK"
    gameTypes*: seq[string] #Game types supported by this bot (defined elsewhere), e.g. "classic", "melee" and "1v1"
    platform*: string #Platform used for running the bot, e.g. JVM 17 or .NET 5
    programmingLang*: string #Language used for programming the bot, e.g. Java 17 or C# 10
    initialPosition*: InitialPosition #Initial start position of the bot used for debugging
    secret*: string #Secret used for access control with the server
  