from bitstring import BitArray
import serial
import time


def write(data,header):
    if "method" in header and header["method"] == "serial":
        r = write_serial(data,header)
    else:
        r = {
        "msg"   :   "No data written as method not found",
        "err"   :   True,
        "data"  :   ""
    }
    return r


def write_serial(data,header):
    #Process header
    #Open serial port
    portName = header["port"]
    baudrate = header["baudrate"]
    waitTime = 0.1
    response = {
        "msg"   :   "",
        "err"   :   False,
        "data"  :   ""
    }
    try:
        ser = serial.Serial(portName,baudrate,timeout=waitTime)
        #ser.open()
    except serial.SerialException:
        # print("Unable to open",portName,". Exiting...")
        response["msg"] = "Unable to open %s." % portName
        response["err"] = True
        return response
        
    #Flush buffer
    ser.flushInput()
    ser.flushOutput()
    
    #Write data
    x = ser.write(data)

    if header["mode"] == "read":
        #Read data
        time.sleep(waitTime)
        try:
            tmp = ser.read(4)
            if not tmp:
                print("No data received")
                response["msg"] = "Waited for data, but no response from %s." % portName
                response["err"] = True
                response["data"] = ""
            else:
                tmp2 = BitArray(tmp)
                tmp2.byteswap()
                response["data"] = [tmp2.hex]
        except Exception:
            print(
                "main: error: exception for\n",
                "{}".format(traceback.format_exc()),
                )
            response["msg"] = "Unable to read from %s." % portName
            # response["msg"] = "Exception when reading:\n" + f"{traceback.format_exc()}"
            response["err"] = True
            
    #Close serial port
    ser.close()
    return response
        


    
        
