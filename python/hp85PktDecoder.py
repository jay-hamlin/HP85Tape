##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##

import sys
import time
import serial

import hp85Header     as header
import hp85Utilities  as utility
import hp85PktDecoder as packet
import hp85Transport as transport

def PrintControlRegister(value):
    prtLine = "\nControl reg=0x%02x "%value
    if(utility.testRegBit(value,header.CONTROL_TRACK_NO_BIT)):
       prtLine = prtLine + "TRACK_NO "
    if(utility.testRegBit(value,header.CONTROL_POWER_UP_BIT)):
       prtLine = prtLine + "POWER_UP "
    if(utility.testRegBit(value,header.CONTROL_MOTOR_ON_BIT)):
       prtLine = prtLine + "MOTOR_ON "
    if(utility.testRegBit(value,header.CONTROL_DIR_FWD_BIT)):
       prtLine = prtLine + "FWD "
    if(utility.testRegBit(value,header.CONTROL_FAST_BIT)):
       prtLine = prtLine + "FAST "
    if(utility.testRegBit(value,header.CONTROL_WRITE_DATA_BIT)):
       prtLine = prtLine + "WR_DATA "
    if(utility.testRegBit(value,header.CONTROL_WRITE_SYNC_BIT)):
       prtLine = prtLine + "WR_SYNC "
    if(utility.testRegBit(value,header.CONTROL_WRITE_GAP_BIT)):
       prtLine = prtLine + "WR_GAP "
       
 ##   print (prtLine,end=" ")
    print (prtLine)

    return
    
def PrintStatusRegister(value):
    prtLine = "Status reg=0x%02x "%value
    if(utility.testRegBit(value,header.STATUS_CASSETTE_IN_BIT)):
        prtLine = prtLine + "TAPE_IN "
        print("Cartridge IN")
    else:
        print("Cartridge OUT")
    if(utility.testRegBit(value,header.STATUS_STALL_BIT)):
        prtLine = prtLine + "STALL "
    if(utility.testRegBit(value,header.STATUS_ILIM_BIT)):
        prtLine = prtLine + "ILIM "
    if(utility.testRegBit(value,header.STATUS_WRITE_EN_BIT)):
        prtLine = prtLine + "WR_EN "
    if(utility.testRegBit(value,header.STATUS_HOLE_BIT)):
        prtLine = prtLine + "HOLE "
    if(utility.testRegBit(value,header.STATUS_GAP_BIT)):
        prtLine = prtLine + "GAP "
    if(utility.testRegBit(value,header.STATUS_TACH_BIT)):
        prtLine = prtLine + "TACH "
    if(utility.testRegBit(value,header.STATUS_READY_BIT)):
        prtLine = prtLine + "READY "
      
##   print (prtLine,end=" ")
    print (prtLine)

    return

def PacketDecoder(cmnd,value):
    global statusRegister
    global controlRegister
    
    retValue = 0

    if cmnd == header.PKT_RD_CONTROL:
        header.controlRegister = value
        ## PrintControlRegister(value)
        
        ##  These constants were found in the HP-85's rom
        ##  values sent to the command register
        ##  command register bytes sent
        ##  0x06 = 006   SREV COMMAND
        ##  0x0E = 016   SFWD COMMAND
        ##  0x16 = 026   FREV COMMAND
        ##  0x1E = 036   FFWD COMMAND
        ##  0x02 = 002    STOP!
        ##  0xC2 = 302    In rewind routine "find 2 holes"
        ##  0x15 = 025
        ##  0x10 = 020
        
        if((value==0x00)or(value==0x02)): ## (
            transport.TapeTransportSetState(header.TRANSPORT_STATE_OFF,value)
        elif(value==0x0E): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT | CONTROL_DIR_FWD_BIT)
            transport.TapeTransportSetState(header.TRANSPORT_STATE_FWD_SLOW,value)
        elif(value==0x1E): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT |CONTROL_FAST_BIT)
            transport.TapeTransportSetState(header.TRANSPORT_STATE_FWD_FAST,value)
        elif(value==0x06): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT | (CONTROL_DIR_FWD_BIT))
            transport.TapeTransportSetState(header.TRANSPORT_STATE_RWD_SLOW,value)
        elif(value==0x16): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT |CONTROL_FAST_BIT)
            transport.TapeTransportSetState(header.TRANSPORT_STATE_RWD_FAST,value)
        elif(value==0xC2): ## (
            transport.TapeTransportSetState(header.TRANSPORT_STATE_SLOW_2HOLE,value)

        retValue = 1
    elif cmnd == header.PKT_RD_STATUS:
        header.statusRegister = value
        PrintStatusRegister(value)
        retValue = 1
    elif cmnd == header.PKT_RD_TACH:
        header.tachometer = value
        print("\nTachometer set to %d"%value)
        retValue = 1
        
    return(retValue)
