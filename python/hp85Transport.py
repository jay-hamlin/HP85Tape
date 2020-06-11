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

transportState = 0
transportTime  = 0

def transportLoop():
    global  transportState
    global  transportTime
    
    while (1):
        if(transportState == header.TRANSPORT_STATE_OFF):
            if(transportTime == 0):
                ## turn tachometer off
                utility.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_OFF_COUNTS)
                print("MOTOR STOP")
            
        elif(transportState == header.TRANSPORT_STATE_FWD_SLOW):
            if(transportTime == 0):
                ## turn tachometer on slow speed
                utility.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_SLOW_COUNTS)
                print("Forward SLOW")
        elif(transportState == header.TRANSPORT_STATE_FWD_FAST):
            if(transportTime == 0):
                ## turn tachometer on fast speed
                utility.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_FAST_COUNTS)
                print("Forward FAST")
        elif(transportState == header.TRANSPORT_STATE_RWD_SLOW):
            if(transportTime == 0):
                ## turn tachometer on slow speed
                utility.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_SLOW_COUNTS)
                print("Rewind SLOW")
        elif(transportState == header.TRANSPORT_STATE_RWD_FAST):
            if(transportTime == 0):
                ## turn tachometer on fast speed
                utility.WritePacketAndEcho(header.PKT_WR_TACH,header.TACHOMETER_FAST_COUNTS)
                print("Rewind FAST")
    
        transportTime += 1
        time.sleep(0.001)  ## 1ms ok?
     
    return

def TapeTransportSetState(state,value):
    global  transportState
    global  transportTime

    transportState = state
    transportTime = 0
    return

def TapeTransportInit():

    TapeTransportSetState(header.TRANSPORT_STATE_OFF,0)

    monitor = threading.Thread(target=transportLoop)
    monitor.daemon = True
    monitor.start()
    return
    

