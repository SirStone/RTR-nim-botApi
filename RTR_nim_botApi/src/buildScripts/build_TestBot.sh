NAME="TestBot"
SRC_DIR="tests/$NAME"
OUT_DIR="out/tests/$NAME"

# nim c -d:release -d:danger --outdir:$OUT_DIR $SRC_DIR/$NAME.nim #for release
nim c --threads:on --cg:arc --outdir:$OUT_DIR $SRC_DIR/$NAME.nim #for debug

# GOING FORWARD ONLY IF COMPILE IS OK
if [ $? -eq 0 ]; then
    cp $SRC_DIR/$NAME.json $OUT_DIR
    cp $SRC_DIR/$NAME.sh $OUT_DIR
fi