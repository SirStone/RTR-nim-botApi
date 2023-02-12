# nim c --threads:on --outdir:RTR_nim_botApi/out/NewBot RTR_nim_botApi/src/SampleBots/Walls/Walls.nim # for debugging
nim c --threads:on -d:release --outdir:RTR_nim_botApi/out/SampleBots/Walls RTR_nim_botApi/src/SampleBots/Walls/Walls.nim #for release

# GOING FORWARD ONLY IF COMPILE IS OK
if [ $? -eq 0 ]; then
    cp RTR_nim_botApi/src/SampleBots/Walls/Walls.json RTR_nim_botApi/out/SampleBots/Walls
    cp RTR_nim_botApi/src/SampleBots/Walls/Walls.sh RTR_nim_botApi/out/SampleBots/Walls

    bash RTR_nim_botApi/out/SampleBots/Walls/Walls.sh -u "127.0.0.1:7338" -s botssecret
fi