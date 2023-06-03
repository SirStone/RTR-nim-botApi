%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#f9898b',
      'primaryTextColor': '#000',
      'primaryBorderColor': '#7C0000',
      'lineColor': '#F8B229',
      'secondaryColor': '#006100',
      'tertiaryColor': '#fff',
      'edgeLabelBackground': '#ffffff00'
    },
    'flowchart': { 'curve': 'basis' }
  }
}%%
graph LR
    main[MAIN]
    listenGS((Listen to Game<br>Server until<br>disconnection)):::loop
    runAsync((run until<br>connected)):::loop
    botRun((custom RUN*)):::loop
    buffer[(message<br>buffer)]:::object
    bot[(BOT)]:::object
    connect[connect to GS]
    readBuffer((try pop a message<br>until connected)):::loop
    ws[(WebSocket)]:::object
    botHandshake>BotHandshake]
    botIntent>BotIntent]
    updateIntent[update intent with<br>any set... function]
    blockingFunction[update intent with<br>a blocking function]
    Y>Y]
    go[go]
    autoGo((automatic go)):::loop
    consumed((intent<br>exhausted?)):::loop

    main --> connect ==>|async| listenGS -->|on message| convertToObject -.->|put| buffer
             connect ==>|async| readBuffer
             connect ==>|async| runAsync -->|bot running| botRun
             botRun -->|or| go --> botRun

             botRun -->|or| updateIntent --> botRun

             botRun -->|or| blockingFunction --> consumed
             consumed -->|yes| botRun
             consumed -->|no| go --> consumed

             botRun -->|or<br>end| autoGo

             autoGo -->|bot running| go --> autoGo
             autoGo -->|else| runAsync
             
             go -.->|BotIntent| buffer
             updateIntent -.->|update| bot
             bot -.-> go
             
             connect -.->|create| ws
             runAsync -->|bot not running<br>wait 1ms| runAsync 
             buffer -.->|pop| readBuffer
             readBuffer -->|else<br>wait 1ms| readBuffer
             readBuffer -->|got message| handleMessage
             handleMessage -->|serverHandShake| botHandshake
             handleMessage -->|BotIntent| botIntent
             handleMessage -->|X| Y
             
             handleMessage -->|set action triggered| updateIntent --> handleMessage
             
             
             handleMessage -->|blocking action triggered| blockingFunction --> consumed
             consumed -->|yes| handleMessage
             consumed -->|no| go --> consumed

             bot -.-> handleMessage
             ws -.-> listenGS
             ws -.-> handleMessage
             ws -.-> runAsync

    main --> createBot -.->|save| bot

classDef object stroke-width: 4px
classDef loop stroke: black,stroke-width: 4px, color: black, back, fill: white
linkStyle 1,4,5 stroke: green,color: green
linkStyle 7,8 stroke: purple,color: purple
linkStyle 9,10 stroke: blue,color: blue
linkStyle 11,12,13,14,15 stroke: red,color: red
linkStyle 17,18 stroke: black,color: black
linkStyle 31,32 stroke: lime,color: lime