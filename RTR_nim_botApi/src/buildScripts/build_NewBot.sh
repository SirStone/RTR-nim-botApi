# nim c --threads:on --outdir:RTR_nim_botApi/out/NewBot RTR_nim_botApi/src/NewBot/NewBot.nim # for debugging
nim c --threads:on -d:release --outdir:RTR_nim_botApi/out/NewBot RTR_nim_botApi/src/NewBot/NewBot.nim #for release

# GOING FORWARD ONLY IF COMPILE IS OK
if [ $? -eq 0 ]; then
    echo "OK"
    cp RTR_nim_botApi/src/NewBot/NewBot.json RTR_nim_botApi/out/NewBot
    cp RTR_nim_botApi/src/NewBot/NewBot.sh RTR_nim_botApi/out/NewBot

    bash RTR_nim_botApi/out/NewBot/NewBot.sh -u "127.0.0.1:7353" -s botssecret
fi