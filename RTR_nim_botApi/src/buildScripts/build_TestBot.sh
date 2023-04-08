NAME="TestBot"
SRC_DIR="tests/$NAME"
OUT_DIR="out/tests/$NAME"

# nim c --threads:on  --gc:orc --outdir:$OUT_DIR $SRC_DIR/$NAME.nim # for debugging
nim c --threads:on -d:release -d:danger --gc:orc --outdir:$OUT_DIR $SRC_DIR/$NAME.nim #for release

# GOING FORWARD ONLY IF COMPILE IS OK
if [ $? -eq 0 ]; then
    cp $SRC_DIR/$NAME.json $OUT_DIR
    cp $SRC_DIR/$NAME.sh $OUT_DIR
fi