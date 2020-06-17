##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##
import sys
import time
import threading
import serial

import hp85Utilities  as utility
import hp85PktDecoder as packet
import hp85Header     as header
import hp85Transport as transport

uartserialport =0
keepLooping = 1

    
def uartMonitorLoop():
    global keepLooping
    global uartserialport
    
    transportLoopTime = time.monotonic_ns()

    newPkt = bytearray(2)
    index = 0
    emptyCycles = 0
    writeLine = ""
    
    while ((keepLooping == 1) and (uartserialport)):
        byteStr = uartserialport.read(1)
        if (len(byteStr)>0):
            newPkt[index] = byteStr[0] ## chr(byteStr[0]) ##makeASCII(ch)
            index += 1
            if( index == 2):
                cmnd = ord(newPkt[0:1])
                value =ord(newPkt[1:2])
                index = 0
                ## PacketDecoder returns 1 if it handled the packet ok.
                if(packet.PacketDecoder(cmnd,value)==0):
                    print("0rx= "+ "%c"%cmnd+ " 0x%02x "%value)
                    
            emptyCycles = 10
        else:
                ## if 10 cycles go by without a char we clear the packet to re-sync
            if emptyCycles > 0:
                emptyCycles -= 1
            else:
                index = 0  ## when emptyCycles get to zero reset index
        
        ## a zero drift 3.125ms timer
        if(time.monotonic_ns() > transportLoopTime):
            transportLoopTime = transportLoopTime + 3125000   ## ns in 3.125ms = 320 loops per second
            transport.transportLoop()
            sys.stdout.flush()
                
        time.sleep(0.001)  ## we must sleep some or it will suck 100% o the cpu time.

    return;
    
def SetStatusRegisterBit(bit):

    header.statusRegister = utility.setRegBit(header.statusRegister,bit)
    WritePacketNoEcho(header.PKT_WR_STATUS,header.statusRegister)

    return
    
def ClearStatusRegisterBit(bit):

    header.statusRegister = utility.clearRegBit(header.statusRegister,bit)
    WritePacketNoEcho(header.PKT_WR_STATUS,header.statusRegister)

    return

def WritePacketAndEcho(pkt0, pkt1):
    global uartserialport

    wrStr = bytearray([pkt0,pkt1])
    uartserialport.write(wrStr)
    
    ## if this is a WRite operation then pkt0 is a lower case ascii (>96 decimal)
    ## so then we add the RD equivalent
    if(pkt0 > 96):
        time.sleep(0.000250)  
        pkt0 = (pkt0 & 0b11011111)
        wrStr = bytearray([pkt0,0x00])
        uartserialport.write(wrStr)

    return;
    
def WritePacketNoEcho(pkt0, pkt1):
    global uartserialport

    wrStr = bytearray([pkt0,pkt1])
    uartserialport.write(wrStr)

    return;

## Open the serial port
def openSerialPort(baudRate,portName):
    global uartserialport
    
    print("serial port name ="+portName)

    uartserialport = serial.Serial(portName,baudRate,timeout=0)
    if(uartserialport):
        uartserialport.flushInput()
        monitor = threading.Thread(target=uartMonitorLoop)
        monitor.daemon = True
        monitor.start()

    return(uartserialport);

