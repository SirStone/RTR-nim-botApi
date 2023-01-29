nim c --outdir:RTR_nim_botApi/out/NewBot RTR_nim_botApi/src/NewBot/NewBot.nim # for debugging
# nim  c -d:release --outdir:RTR_nim_botApi/out/NewBot RTR_nim_botApi/src/NewBot/NewBot.nim #for release

cp RTR_nim_botApi/src/NewBot/NewBot.json RTR_nim_botApi/out/NewBot
cp RTR_nim_botApi/src/NewBot/NewBot.sh RTR_nim_botApi/out/NewBot