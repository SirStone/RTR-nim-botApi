# import component
import Messages

type
  Bot* = ref object of RootObj
    # filled from JSON
    name*,version*,description*,homepage*,secret*,serverConnectionURL*,platform*,programmingLang*:string
    gameTypes*,authors*,countryCodes*:seq[string]