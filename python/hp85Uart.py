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

    index = 0
    
    dbgWr0x22 = bytearray([0x22])
    dbgWr0x55 = bytearray([0x55])
    dbgWr0xAA = bytearray([0xAA])

    while ((keepLooping == 1) and (uartserialport)):
        uartserialport.write(dbgWr0x22)
        iw = uartserialport.inWaiting()
        if(iw>1):
            uartserialport.write(dbgWr0x55)

            byteStr = uartserialport.read(iw)
            if(byteStr):
                uartserialport.write(dbgWr0xAA)
                cmnd = byteStr[0]
                value =byteStr[1]
                ## PacketDecoder returns 1 if it handled the packet ok.
                if(packet.PacketDecoder(cmnd,value)==0):
                    print("0rx= "+ "%c"%cmnd+ " 0x%02x "%value)

        
        ## a zero drift 3.125ms timer
        if(time.monotonic_ns() > transportLoopTime):
            transportLoopTime = transportLoopTime + 3125000   ## ns in 3.125ms = 320 loops per second
            transport.transportLoop()
            sys.stdout.flush()
                
        time.sleep(0.001)  ## we must sleep some or it will suck 100% o the cpu time.

    return;
    
def SetStatusRegister(value):
    header.statusRegister = value
    WritePacketNoEcho(header.PKT_WR_STATUS,header.statusRegister)

    return

def SetStatusRegisterBits(bits):

    header.statusRegister = (header.statusRegister | bits)
    WritePacketNoEcho(header.PKT_WR_STATUS,header.statusRegister)

    return
    
def ClearStatusRegisterBits(bits):

    header.statusRegister = (header.statusRegister & (~bits))
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

