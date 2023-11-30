import Monsoon.HVPM as HVPM
import Monsoon.pmapi as pmapi
import fire


def power_on(serial_no='30975', voltage=4.2,  protocol=pmapi.USB_protocol()): #30966
    Mon = HVPM.Monsoon()
    Mon.setup_usb(serial_no, protocol)
    Mon.fillStatusPacket()
    Mon.calibrateVoltage()
    print(f"set HVPM (Serial number {Mon.getSerialNumber()}) vout to {voltage}V")
    Mon.setVout(voltage)
    Mon.closeDevice()

def power_off(serial_no='30975', protocol=pmapi.USB_protocol()):
    Mon = HVPM.Monsoon()
    Mon.setup_usb(serial_no, protocol)
    print(f"disable HVPM (Serial number {Mon.getSerialNumber()}) vout")
    Mon.fillStatusPacket()
    Mon.setVout(0)
    Mon.closeDevice()

if __name__ == "__main__":
    fire.Fire()
