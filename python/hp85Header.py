##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##

## tape drive register images
statusRegister = 0 ## Everett's emulator inits status at 0240 Octal= 0xA0
controlRegister = 0
tachometer = 0

##     Tape Control Chip status register
##     HP-85 bus address 0xFF08  // Octal 177410
##     This register is read only from the HP-85
##
STATUS_CASSETTE_IN_BIT = 0  ## Cassette in
STATUS_STALL_BIT = 1        ## Tape stalled
STATUS_ILIM_BIT = 2         ## Overcurrent
STATUS_WRITE_EN_BIT = 3     ## Write enabled
STATUS_HOLE_BIT = 4         ## Hole detected
STATUS_GAP_BIT = 5          ## Gap detected
STATUS_TACH_BIT = 6         ## Tachometer tick
STATUS_READY_BIT = 7        ## Ready -meaning, there is a DATA byte available to read.


##     Tape Control Chip control register
##     HP-85 bus address 0xFF08  // Octal 177410
##     This register is write only from the HP-85
##
CONTROL_TRACK_NO_BIT =   0   ## Track selection
CONTROL_POWER_UP_BIT =   1   ## Tape controller power up
CONTROL_MOTOR_ON_BIT =   2   ## Motor control
CONTROL_DIR_FWD_BIT =    3   ## Tape direction = forward
CONTROL_FAST_BIT =       4   ## Speed = fast
CONTROL_WRITE_DATA_BIT = 5   ## Write data
CONTROL_WRITE_SYNC_BIT = 6   ## Write SYNC
CONTROL_WRITE_GAP_BIT =  7   ## Write gap
##
##

PKT_RD_STATUS  = ord('S')  ##    --> Read status register.
PKT_WR_STATUS  = ord('s')  ##    --> Write status register. second byte it write value
PKT_RD_CONTROL = ord('C')  ##    --> Read control register.
PKT_WR_CONTROL = ord('c')  ##    --> Write control register. second byte it write value
PKT_RD_DATA    = ord('D')  ##    --> Read data register.
PKT_WR_DATA    = ord('d')  ##    --> Write data register. second byte it write value
PKT_RD_MISC    = ord('M')  ##    --> Read misc. status and error codes. TBD
PKT_WR_MISC    = ord('m')  ##    --> write misc. contorl codes. TBD
PKT_RD_TACH    = ord('T')  ##    --> Read tach. status and error codes. TBD
PKT_WR_TACH    = ord('t')  ##    --> write tach. contorl codes. TBD
PKT_RD_HOLE    = ord('H')  ##    --> Read hole. status and error codes. TBD
PKT_WR_HOLE    = ord('h')  ##    --> write hole. contorl codes. TBD

TRANSPORT_STATE_OFF         = 0
TRANSPORT_STATE_FWD_SLOW    = 1
TRANSPORT_STATE_FWD_FAST    = 2
TRANSPORT_STATE_RWD_SLOW    = 3
TRANSPORT_STATE_RWD_FAST    = 4

## each tach count is 35us but there is a 1/16 divide in the HP controller chip.
TACHOMETER_OFF_COUNTS      = 0
TACHOMETER_SLOW_COUNTS      = (16*6)
TACHOMETER_FAST_COUNTS      = (16)


