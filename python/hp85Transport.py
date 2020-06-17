##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##

import sys
import threading
import time
import serial
import glob,os

import hp85Header     as header
import hp85Utilities  as utility
import hp85PktDecoder as packet
import hp85Uart       as uart
import hp85Uart       as uart
import hp85TapeConstants  as tape

##
## There are 32 tach pulse per inch of tape.
## Look in romsys2.lst for tape routines
## The tape holes are described on page 9 of the May 1976 HP Journal
##
## Eg: IRG is 32 tachs (1”)
## IFG is 80 tachs(2.5”)
## BOT/EOT     is 400 tachs(12.5”)
## double hole is 7 tachs (0.218”)
##

## with 32 tachs per inch..
## slow = 10"/s or 320 tachs per second
## fast = 60-"/s or 1920 tachs per second
##  loop time = 0.03125s
##       loops/inch  tachs/loop
##  SLOW  32          1
##  FAST  1920        6
LOOP_DELAY_TIME = 0.003125
LOOPS_PER_INCH_SLOW = 32
TACHS_PER_LOOP_SLOW = 1
LOOPS_PER_INCH_HIGH = (LOOPS_PER_INCH_SLOW/6)
TACHS_PER_LOOP_HIGH = (TACHS_PER_LOOP_SLOW*6)

tapePosition = (LOOPS_PER_INCH_SLOW*100)

tapeInches = 0
prevTapeInches = 0
msStartTime = 0

prevStatusRegister = 0
prevControlRegister = 0

transportState = 0
transportTime  = 0

## there are 11 holes in the tape.
## we check the tape position and set the hole flag in the status register as needed
def checkForTapeHoles(position,speed):

    index = 0;
    while(index< tape.tapeHoleArraySize):
        if((position>=tape.tapeHoleArray[index][0]) and (position<=tape.tapeHoleArray[index][0]-speed)):
            index = tape.tapeHoleArraySize             ## in the hole
        index +=1
        
    if(index == (tape.tapeHoleArraySize+1)):
        ## check to see if the hole bit is clear so we don't send a zillion packets.
        if(utility.testRegBit(header.statusRegister,header.STATUS_HOLE_BIT)==0):
            utility.setRegBit(header.statusRegister,header.STATUS_HOLE_BIT)
            uart.WritePacketNoEcho(header.PKT_WR_HOLE,0x02)  ## hole set for 2 tachs
    else:
        if(utility.testRegBit(header.statusRegister,header.STATUS_HOLE_BIT)==1):
            utility.clearRegBit(header.statusRegister,header.STATUS_HOLE_BIT)
            uart.ClearStatusRegisterBit(header.STATUS_HOLE_BIT)
        
    return
    
def printTapeArray():
    print("Tape hole locations in loop counts")
    print("  P1_A   %6d"%tape.tapeHoleArray[0][0]+" ,%6d"%tape.tapeHoleArray[0][1])
    print("  P1_B   %6d"%tape.tapeHoleArray[1][0]+" ,%6d"%tape.tapeHoleArray[1][1])
    print("  P2_A   %6d"%tape.tapeHoleArray[2][0]+" ,%6d"%tape.tapeHoleArray[2][1])
    print("  P2_B   %6d"%tape.tapeHoleArray[3][0]+" ,%6d"%tape.tapeHoleArray[3][1])
    print("  P3_A   %6d"%tape.tapeHoleArray[4][0]+" ,%6d"%tape.tapeHoleArray[4][1])
    print("  P3_B   %6d"%tape.tapeHoleArray[5][0]+" ,%6d"%tape.tapeHoleArray[5][1])
    print("  BOT_LP %6d"%tape.tapeHoleArray[6][0]+" ,%6d"%tape.tapeHoleArray[6][1])

    print("  EOT_EW %6d"%tape.tapeHoleArray[7][0]+" ,%6d"%tape.tapeHoleArray[7][1])
    print("  EOT_C  %6d"%tape.tapeHoleArray[8][0]+" ,%6d"%tape.tapeHoleArray[8][1])
    print("  EOT_B  %6d"%tape.tapeHoleArray[9][0]+" ,%6d"%tape.tapeHoleArray[9][1])
    print("  EOT_A  %6d"%tape.tapeHoleArray[10][0]+" ,%6d"%tape.tapeHoleArray[10][1])

    return
    
def printTransportStats():
    global tapePosition
    global tapeInches
    global transportState
    global transportTime
    
    print("tape position=%d"%tapePosition+" counts, %d"%tapeInches+" inches")
    print("transport state=%d"%transportState+", time=%d"%transportTime)
    print("Status reg=0x%02x "%header.statusRegister+" Control reg=0x%02x "%header.controlRegister)

    return

def updateTapePosition(increment):
    global  tapePosition
    
    if(increment ==0):
        tapePosition += increment  ### ???
    else:
        tapePosition += increment
        ## check if the tape is at the end stops
        if(tapePosition<0):
            uart.SetStatusRegisterBit(header.STATUS_STALL_BIT)
            tapePosition = 0
            TapeTransportSetState(header.TRANSPORT_STATE_OFF,0)
        elif(tapePosition>tape.TAPE_LENGTH_IN_LOOPS):
            uart.SetStatusRegisterBit(header.STATUS_STALL_BIT)
            tapePosition = tape.TAPE_LENGTH_IN_LOOPS
        else:
        ## we know the tape is moving.
            checkForTapeHoles(tapePosition,increment)
    return
    

def printTapeInches():
    global tapePosition
    global tapeInches
    global prevTapeInches
    
    ## calc the tape position in inches
    tapeInches = int(float(tapePosition)/float(LOOPS_PER_INCH_SLOW))
    if(tapeInches != prevTapeInches):
        if((tapeInches%10)==0):
            print(" %d"%tapeInches+"%c"%chr(0x22))
        else:
            print(" %d"%tapeInches+"%c"%chr(0x22),end=" ")
        prevTapeInches = tapeInches
    
        
    return
    
def printStatusChanges():
    global prevStatusRegister
    global prevControlRegister
    
    printit = 0

    if(header.statusRegister != prevStatusRegister):
        prevStatusRegister = header.statusRegister
        printit = 1
    if(header.controlRegister != prevControlRegister):
        prevControlRegister = header.controlRegister
        printit = 1
    if(printit == 1):
        printTransportStats()
    
    return

def transportLoop():
    global  transportState
    global  transportTime
    global  tapePosition
    
    
##    while (1):
    
    printTapeInches()
    printStatusChanges()
    
    if(transportState == header.TRANSPORT_STATE_OFF):
        if(transportTime == 0):
            ## turn tachometer off
            uart.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_OFF_COUNTS)
            uart.ClearStatusRegisterBit(header.STATUS_STALL_BIT)
            print("MOTOR STOP")
        else:
            updateTapePosition(0)

    elif(transportState == header.TRANSPORT_STATE_FWD_SLOW):
        if(transportTime == 0):
            ## turn tachometer on slow speed
            uart.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_SLOW_COUNTS)
            print("Forward SLOW")
        else:
            updateTapePosition(+1)

    elif(transportState == header.TRANSPORT_STATE_FWD_FAST):
        if(transportTime == 0):
            ## turn tachometer on fast speed
            uart.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_FAST_COUNTS)
            print("Forward FAST")
        else:
            updateTapePosition(+6)
            
    elif(transportState == header.TRANSPORT_STATE_RWD_SLOW):
        if(transportTime == 0):
            ## turn tachometer on slow speed
            uart.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_SLOW_COUNTS)
            print("Rewind SLOW")
        else:
            updateTapePosition(-1)

    elif(transportState == header.TRANSPORT_STATE_RWD_FAST):
        if(transportTime == 0):
            ## turn tachometer on fast speed
            uart.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_FAST_COUNTS)
            print("Rewind FAST")
        else:
            updateTapePosition(-6)

    transportTime += 1
 ##       time.sleep(LOOP_DELAY_TIME)
     
    return

def TapeTransportSetState(state,value):
    global  transportState
    global  transportTime
    global  msStartTime
    
    ms = int(time.monotonic_ns()/1000000) - msStartTime
    print("time=%d"%ms+"ms")
    
    transportState = state
    transportTime = 0
    return

def TapeTransportInit():
    global  msStartTime
    
    msStartTime = int(time.monotonic_ns()/1000000)

    printTapeArray()

    TapeTransportSetState(header.TRANSPORT_STATE_OFF,0)

##    monitor = threading.Thread(target=transportLoop)
##    monitor.daemon = True
##    monitor.start()
    return
    

