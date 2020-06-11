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
import hp85Transport as transport

## global variables
kbdChoice = 0
keepLooping = 1
serialport = 0

HP85_BAUD_RATE = 115200
HP85_PORT_NAME = "/dev/tty.usbserial-144101"

## A bunch of local functions...
    
def uartMonitorLoop():
    global keepLooping
    global serialport

    newPkt = bytearray(2)
    index = 0
    emptyCycles = 0
    writeLine = ""
    
    while ((keepLooping == 1) and (serialport)):
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
serialport = utility.openSerialPort(HP85_BAUD_RATE,HP85_PORT_NAME)

monitor = threading.Thread(target=uartMonitorLoop)
monitor.daemon = True
monitor.start()

transport.TapeTransportInit()

while (keepLooping ==1):
    time.sleep(0.050)  ## gives the prev command time to finish printing before we print the menu
    kbdChoice = printMenu()
    if kbdChoice == 't':  ## clear cartridge bit in status register
        header.statusRegister = utility.clearRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)
        utility.WritePacketAndEcho(header.PKT_WR_STATUS,header.statusRegister)
        
    if kbdChoice == 'T':  ## set cartridge bit in status register
        header.statusRegister = utility.setRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)
        utility.WritePacketAndEcho(header.PKT_WR_STATUS,header.statusRegister)

    if kbdChoice == 'x' or kbdChoice == 'X':
        keepLooping = 0
        print ("Exiting...")

##  PROGRAM MAIN LOOP ENDS HERE
serialport.close()
sys.exit()
