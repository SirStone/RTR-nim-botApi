# build the test bot first
NAME="TestBot"
SRC_DIR="tests/$NAME"
OUT_DIR="out/tests/$NAME"

nim c --threads:on  --gc:orc --outdir:$OUT_DIR $SRC_DIR/$NAME.nim # for debugging
# nim c --threads:on --gc:orc -d:release --outdir:$OUT_DIR $SRC_DIR/$NAME.nim #for release

# GOING FORWARD ONLY IF COMPILE IS OK
if [ $? -eq 0 ]; then
    cp $SRC_DIR/$NAME.json $OUT_DIR
    cp $SRC_DIR/$NAME.sh $OUT_DIR

    # bash $OUT_DIR/Walls.sh -u "127.0.0.1:1536" -s botssecret
fi

# run the tests
nimble test --threads:on --gc:orc --verbose