#++++++++ GAME PHYSICS ++++++++#
# bots accelerate at the rate of 1 unit per turn but decelerate at the rate of 2 units per turn
let ACCELERATION*:float = 1
let DECELERATION*:float = -2

# The speed can never exceed 8 units per turn
let MAX_SPEED*:float = 8

# If standing still (0 units/turn), the maximum rate is 10° per turn
let MAX_TURN_RATE*:float = 10

# The maximum rate of rotation is 20° per turn. This is added to the current rate of rotation of the bot
let MAX_GUN_TURN_RATE*:float = 20

# The maximum rate of rotation is 45° per turn. This is added to the current rate of rotation of the gun
let MAX_RADAR_TURN_RATE*:float = 45

# The maximum firepower is 3 and the minimum firepower is 0.1
let MAX_FIRE_POWER*:float = 3
let MIN_FIRE_POWER*:float = 0.1