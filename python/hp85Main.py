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

## cartridge in
header.statusRegister = utility.setRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)

while (uart.keepLooping ==1):
    kbdChoice = printMenu()
    transport.printTransportStats()
    if kbdChoice == 't':  ## toggle cartridge bit in status register
        if(utility.testRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)):
            header.statusRegister = utility.clearRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)
        else:
            header.statusRegister = utility.setRegBit(header.statusRegister,header.STATUS_CASSETTE_IN_BIT)
            
        uart.WritePacketAndEcho(header.PKT_WR_STATUS,header.statusRegister)
        
    if kbdChoice == 's':  ## read status register
        uart.WritePacketAndEcho(header.PKT_WR_STATUS,header.statusRegister)

    if kbdChoice == 'c':  ## read control register
        uart.WritePacketAndEcho(header.PKT_RD_CONTROL,0x00)
        
    if kbdChoice == 'a':  ## tach +1
        tachSpeed += 1
        if(tachSpeed > 255):
            tachSpeed = 255
        uart.WritePacketAndEcho(header.PKT_WR_TACH,tachSpeed)
        print("Tach Speed = %d"%tachSpeed)
    if kbdChoice == 'b':  ## tach -1
        tachSpeed -= 1
        if(tachSpeed < 0):
            tachSpeed = 0
        uart.WritePacketAndEcho(header.PKT_WR_TACH,tachSpeed)
        print("Tach Speed = %d"%tachSpeed)
    if kbdChoice == 'd':  ## hole 0
            uart.WritePacketAndEcho(header.PKT_WR_HOLE,(0))
    if kbdChoice == 'e':  ## hole 8 tachs
            uart.WritePacketAndEcho(header.PKT_WR_HOLE,(8))
    if kbdChoice == 'f':  ## hole 16 tachs
            uart.WritePacketAndEcho(header.PKT_WR_HOLE,(16))
            
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
