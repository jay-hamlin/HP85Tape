##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##

LOOPS_PER_INCH = 32

TAPE_LENGTH_IN_FEET = 140.00
TAPE_LENGTH_IN_INCHES = (TAPE_LENGTH_IN_FEET*12.00)

## the tape length in loop counts at slow speed, high speed will be 1/6 of this
TAPE_LENGTH_IN_LOOPS = int(TAPE_LENGTH_IN_INCHES*LOOPS_PER_INCH) ## 140*12*320

TAPE_HOLE_WIDTH_IN_INCHES = 0.026  ## HP Journal, May 1976, page 9
TAPE_HOLE_WIDTH_IN_LOOPS = int(TAPE_HOLE_WIDTH_IN_INCHES*LOOPS_PER_INCH) ## 8

HOLE_PAIR_SPACE_IN_LOOPS = int(0.218*LOOPS_PER_INCH) ## 69

## See HP Journal, May 1976, page 9
##  BOT == Begining of Tape
##  EOT == End of Tape
##  Holes at the begining of the tape
##    There are 3 pairs of holes at the begining of the tape
##      pairs are at 24", 36" and 48"
##      holes within a pair are spaced 0.218" apart
##    And the Load Point hole at 72"
BOT_HOLE_P1_A = (24*LOOPS_PER_INCH)  ## BOT pair 1, hole A
BOT_HOLE_P1_B = (BOT_HOLE_P1_A + HOLE_PAIR_SPACE_IN_LOOPS) ## BOT pair 1, hole B
BOT_HOLE_P2_A = (36*LOOPS_PER_INCH)  ## BOT pair 1, hole A
BOT_HOLE_P2_B = (BOT_HOLE_P2_A + HOLE_PAIR_SPACE_IN_LOOPS) ## BOT pair 2, hole B
BOT_HOLE_P3_A = (48*LOOPS_PER_INCH)  ## BOT pair 1, hole A
BOT_HOLE_P3_B = (BOT_HOLE_P3_A + HOLE_PAIR_SPACE_IN_LOOPS) ## BOT pair 3, hole B
BOT_HOLE_LOAD_POINT = (72*LOOPS_PER_INCH)
##  Holes at the end of the tape
##    There are 4 holes at the end of the tape
##       (EOT-24"),(EOT-36"),(EOT-48"),(EOT-72")
##       The -72" hole is called the early warning hole.
EOT_HOLE_EARLY_WARNING = (TAPE_LENGTH_IN_LOOPS-(72*LOOPS_PER_INCH))
EOT_HOLE_C = (TAPE_LENGTH_IN_LOOPS-(48*LOOPS_PER_INCH))
EOT_HOLE_B = (TAPE_LENGTH_IN_LOOPS-(36*LOOPS_PER_INCH))
EOT_HOLE_A = (TAPE_LENGTH_IN_LOOPS-(24*LOOPS_PER_INCH))

tapeHoleArray = [BOT_HOLE_P1_A,\
                BOT_HOLE_P1_B,\
                BOT_HOLE_P2_A,\
                BOT_HOLE_P2_B,\
                BOT_HOLE_P3_A,\
                BOT_HOLE_P3_B,\
                BOT_HOLE_LOAD_POINT,\
                EOT_HOLE_EARLY_WARNING,\
                EOT_HOLE_C,\
                EOT_HOLE_B,\
                EOT_HOLE_A]
tapeHoleArraySize = 11
