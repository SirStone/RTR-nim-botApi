# import component
import Messages

type
  Bot* = ref object of RootObj
    # bot related
    name*,version*,description*,homepage*,secret*,platform*,programmingLang*:string
    gameTypes*,authors*,countryCodes*:seq[string]
    gameSetup*:GameSetup
    tick*:TickEventForBot
    myId*: int
    adjustGunForBodyTurn*,adjustRadarForBodyTurn*,adjustRadarForGunTurn*:bool
    rescan*,fireAssist*:bool
    bodyColor*,turretColor*,radarColor*,bulletColor*,scanColor*,tracksColor*,gunColor*:string
    intent*:BotIntent