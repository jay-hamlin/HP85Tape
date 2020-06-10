 ## obdMain.py
## obdCommunications test app
##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##

import sys
import threading
import time
import serial
import glob,os

import hp85Header  as header
import hp85Utilities  as utility
import hp85PktDecoder as packet

## global variables
kbdChoice = 0
keepLooping = 1

HP85_BAUD_RATE = 115200
HP85_PORT_NAME = "/dev/tty.usbserial-144101"

## A bunch of local functions...
## Open the serial port

def openSerialPort(baudRate,portName):
    global serialport
    
##  originalPath = os.getcwd()
    
        
    print("serial port name ="+portName)

    serialport = serial.Serial(portName,baudRate,timeout=0)
    if(serialport):
        serialport.flushInput()
    
##  os.chdir(originalPath)

    return;
    
def WritePacketAndEcho(pkt0, pkt1):
    wrStr = bytearray([pkt0,pkt1])
    serialport.write(wrStr)
    
    time.sleep(0.003)
    if pkt0 == header.PKT_WR_STATUS:
        wrStr = bytearray([header.PKT_RD_STATUS,0x00])
        serialport.write(wrStr)
    elif pkt0 == header.PKT_WR_CONTROL:
        wrStr = bytearray([header.PKT_RD_CONTROL,0x00])
        serialport.write(wrStr)

    return;

def uartMonitorLoop():
    global keepLooping
    global serialport

    newPkt = bytearray(2)
    index = 0
    emptyCycles = 0
    writeLine = ""
    
    while (keepLooping == 1):
        byteStr = serialport.read(1)
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
            time.sleep(0.00005)  ## we must sleep some or it will suck 100% o the cpu time.

    return;

def printMenu():
    print (30 * '-')
    print ("   M A I N - M E N U")
    print (30 * '-')
    print (" t. cartridge out")
    print (" T. cartridge in")
    print (" D. Write data register")
    print (30 * '-')
    try:
        ch = input('Enter your choice [A-S] : \n')
    except:
        ch = ""

    return(ch);

##  PROGRAM MAIN LOOP STARTS HERE
openSerialPort(HP85_BAUD_RATE,HP85_PORT_NAME)

monitor = threading.Thread(target=uartMonitorLoop)
monitor.daemon = True
monitor.start()

while (keepLooping ==1):
    time.sleep(0.050)  ## gives the prev command time to finish printing before we print the menu
    kbdChoice = printMenu()
    if kbdChoice == 't':  ## clear cartridge bit in status register
        header.statusRegister = utility.clearRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)
        WritePacketAndEcho(header.PKT_WR_STATUS,header.statusRegister)
        
    if kbdChoice == 'T':  ## set cartridge bit in status register
        header.statusRegister = utility.setRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)
        WritePacketAndEcho(header.PKT_WR_STATUS,header.statusRegister)

    if kbdChoice == 'x' or kbdChoice == 'X':
        keepLooping = 0
        print ("Exiting...")

##  PROGRAM MAIN LOOP ENDS HERE
serialport.close()
sys.exit()
