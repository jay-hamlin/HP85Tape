##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##
import sys
import time
import serial

utilserialport =0

def toHEX(writeLine):
    outStr = ""
    sz= len(writeLine)
    i=0;
    while(i<sz):
        outStr = outStr + " 0x%02x "%ord(writeLine[i:(i+1)])
        i = i + 1

    return(outStr);

def clearRegBit(regVal,bitNum):
    bitValue = ~(1 << bitNum)
    regVal = (regVal & bitValue)
    return(regVal)
    
def setRegBit(regVal,bitNum):
    bitValue = (1 << bitNum)
    regVal = (regVal | bitValue)
    return(regVal)

def testRegBit(regVal,bitNum):
    bitValue = (1 << bitNum)
    if ((bitValue & regVal) == 0):
        retVal = 0
    else:
        retVal = 1
    return(retVal)


def WritePacketAndEcho(pkt0, pkt1):
    global utilserialport

    wrStr = bytearray([pkt0,pkt1])
    utilserialport.write(wrStr)
    
    ## if this is a WRite operation then pkt0 is a lower case ascii (>96 decimal)
    ## so then we add the RD equivalent
    if(pkt0 > 96):
        time.sleep(0.000250)  
        pkt0 = (pkt0 & 0b11011111)
        wrStr = bytearray([pkt0,0x00])
        utilserialport.write(wrStr)

    return;

## Open the serial port
def openSerialPort(baudRate,portName):
    global utilserialport
    
##  originalPath = os.getcwd()
    
        
    print("serial port name ="+portName)

    utilserialport = serial.Serial(portName,baudRate,timeout=0)
    if(utilserialport):
        utilserialport.flushInput()
    
##  os.chdir(originalPath)

    return(utilserialport);
