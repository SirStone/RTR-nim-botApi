SRC_DIR="src/RTR_nim_botApi/SampleBots/Walls"
OUT_DIR="out/SampleBots/Walls"

# nim c --threads:on  --gc:orc --outdir:$OUT_DIR $SRC_DIR/Walls.nim # for debugging
nim c --threads:on --gc:orc -d:release --outdir:$OUT_DIR $SRC_DIR/Walls.nim #for release

# GOING FORWARD ONLY IF COMPILE IS OK
if [ $? -eq 0 ]; then
    cp $SRC_DIR/Walls.json $OUT_DIR
    cp $SRC_DIR/Walls.sh $OUT_DIR

    # bash $OUT_DIR/Walls.sh -u "127.0.0.1:1536" -s botssecret
fi