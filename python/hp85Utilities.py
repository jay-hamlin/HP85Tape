##
## Created: 3/8/19 07:00:00 AM
## Author :Jay Hamlin
##
import sys
import time

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
