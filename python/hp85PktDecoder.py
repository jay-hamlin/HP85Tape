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
    prtLine = "Control reg=0x%02x "%value
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
        PrintControlRegister(value)
        
        temp = (value and 0b00011110) ## mask only the motor control bits
        
        if(temp==0x00): ## (
            transport.TapeTransportSetState(header.TRANSPORT_STATE_OFF,value)
        elif(temp==0x0E): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT | CONTROL_DIR_FWD_BIT)
            transport.TapeTransportSetState(header.TRANSPORT_STATE_FWD_SLOW,value)
        elif(temp==0x1E): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT |CONTROL_FAST_BIT)
            transport.TapeTransportSetState(header.TRANSPORT_STATE_FWD_FAST,value)
        if(temp==0x06): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT | (CONTROL_DIR_FWD_BIT))
            transport.TapeTransportSetState(header.TRANSPORT_STATE_RWD_SLOW,value)
        elif(temp==0x16): ## (CONTROL_POWER_UP_BIT | CONTROL_MOTOR_ON_BIT |CONTROL_FAST_BIT)
            transport.TapeTransportSetState(header.TRANSPORT_STATE_RWD_FAST,value)

        retValue = 1
    elif cmnd == header.PKT_RD_STATUS:
        header.controlRegister = value
        PrintStatusRegister(value)
        retValue = 1
    elif cmnd == header.PKT_RD_TACH:
        header.tachometer = value
        print("Tachometer set to %d"%value)
        retValue = 1
        
    return(retValue)
