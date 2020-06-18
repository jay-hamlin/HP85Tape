 ## obdMain.py
## obdCommunications test app
##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##

import sys
import time
import select
import tty
import termios

import hp85Header  as header
import hp85Utilities  as utility
import hp85Transport as transport
import hp85Uart as uart
import hp85PktDecoder as packet

## global variables
kbdChoice = 0
serialport = 0

HP85_BAUD_RATE = 115200
HP85_PORT_NAME = "/dev/tty.usbserial-144101"

## A bunch of local functions...

def isData():
    return select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], [])

def printMenu():
    print (30 * '-')
    print ("   M A I N - M E N U")
    print (30 * '-')
    print (" t. cartridge in/out")
    print (" s. read status")
    print (" c. read control")
    print (30 * '-')

    ch = ""
    while(ch == ""):
        if isData():
            ch = sys.stdin.read(1)
        else:
            time.sleep(0.050)

    return(ch);

##  PROGRAM MAIN LOOP STARTS HERE
serialport = uart.openSerialPort(HP85_BAUD_RATE,HP85_PORT_NAME)

transport.TapeTransportInit()

tachSpeed = 0

while (uart.keepLooping ==1):
    kbdChoice = printMenu()
    transport.printTransportStats()

    if kbdChoice == 'r':  ## reset
        transport.tapePosition = (32*100)
        transport.TapeTransportInit()
 
    if kbdChoice == 'c':  ## read control register
        uart.WritePacketAndEcho(header.PKT_RD_CONTROL,0x00)        
            
    if kbdChoice == 'z':  ## rewind
            packet.PacketDecoder(0x43,0x16)
    if kbdChoice == 'y':  ## stop
            packet.PacketDecoder(0x43,0x00)

    if kbdChoice == 'x' or kbdChoice == 'X':
        uart.keepLooping = 0
        print ("Exiting...")
        time.sleep(0.050)

##  PROGRAM MAIN LOOP ENDS HERE
serialport.close()
sys.exit()
