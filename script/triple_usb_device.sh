#!/bin/bash

GADGETS_DIR="gadget1"

# Make sure to change USB_PID if you enable different USB functionality in order
# to force Windows to enumerate the device again
USB_VID="0x1d6b"        # Vendor ID
USB_PID="0x013c"        # Product ID

# configure USB gadget to provide (RNDIS like) ethernet interface
# see http://isticktoit.net/?p=1383
# ----------------------------------------------------------------

modprobe dwc2
modprobe libcomposite

cd /sys/kernel/config/usb_gadget
mkdir -p $GADGETS_DIR
cd $GADGETS_DIR

# configure gadget details
# =========================
# set Vendor ID
echo $USB_VID > idVendor # RNDIS
# set Product ID
echo $USB_PID > idProduct # RNDIS
# set device version 1.0.0
echo 0x0100 > bcdDevice
# set USB mode to USB 2.0
echo 0x0200 > bcdUSB

# composite class / subclass / proto (needs single configuration)
echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

# set device descriptions
mkdir -p strings/0x409 # English language strings
# set serial
echo "deadbeefdeadbeef" > strings/0x409/serialnumber
# set manufacturer
echo "christophrus" > strings/0x409/manufacturer
# set product
echo "christophrus gadget" > strings/0x409/product

# create configuration instance (for RNDIS, ECM and HDI in a SINGLE CONFIGURATION to support Windows composite device enumeration)
mkdir -p configs/c.1/strings/0x409
echo "Config 1: RNDIS network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
echo 0x80 > configs/c.1/bmAttributes #  USB_OTG_SRP | USB_OTG_HNP

# create RNDIS function
mkdir -p functions/rndis.usb0
# set up mac address of remote device
echo "42:63:65:13:34:56" > functions/rndis.usb0/host_addr
# set up local mac address
echo "42:63:65:66:43:21" > functions/rndis.usb0/dev_addr

# create HID function
mkdir -p functions/hid.g1
PATH_HID_KEYBOARD="/sys/kernel/config/usb_gadget/$GADGETS_DIR/functions/hid.g1/dev"
echo 1 > functions/hid.g1/protocol
echo 1 > functions/hid.g1/subclass
echo 8 > functions/hid.g1/report_length
echo -ne \\x05\\x01\\x09\\x06\\xa1\\x01\\x85\\x01\\x05\\x07\\x19\\xe0\\x29\\xe7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x95\\x01\\x75\\x08\\x81\\x03\\x95\\x05\\x75\\x01\\x05\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03\\x91\\x03\\x95\\x05\\x75\\x08\\x15\\x00\\x25\\x65\\x05\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xc0\\x05\\x01\\x09\\x02\\xa1\\x01\\x09\\x01\\xa1\\x00\\x85\\x02\\x05\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x95\\x03\\x75\\x01\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x15\\x81\\x25\\x7f\\x75\\x08\\x95\\x02\\x81\\x06\\xc0\\xc0\\x05\\x01\\x09\\x02\\xa1\\x01\\x09\\x01\\xa1\\x00\\x85\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x15\\x00\\x26\\xff\\x7f\\x75\\x10\\x95\\x02\\x81\\x02\\x09\\x38\\x15\\x81\\x25\\x7f\\x75\\x08\\x95\\x01\\x81\\x06\\xc0\\xc0   > functions/hid.g1/report_desc

# add OS specific device descriptors to force Windows to load RNDIS drivers
mkdir -p os_desc
echo 1 > os_desc/use
echo 0xbc > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

mkdir -p functions/rndis.usb0/os_desc/interface.rndis
echo RNDIS > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

# bind function instances to respective configuration
ln -s functions/rndis.usb0 configs/c.1/ # RNDIS on config 1 # RNDIS has to be the first interface on Composite device
ln -s functions/hid.g1 configs/c.1/ # HID on config 1

ln -s configs/c.1/ os_desc # add config 1 to OS descriptors

# check for first available UDC driver
UDC_DRIVER=$(ls /sys/class/udc | cut -f1 | head -n 1)
# bind USB gadget to this UDC driver
echo $UDC_DRIVER > UDC

# time to breath
sleep 0.2

ls -la /dev/hidg*

# store device names to file
udevadm info -rq name  /sys/dev/char/$(cat $PATH_HID_KEYBOARD) > /tmp/device_hid_keyboard

ls -la /dev/hidg*

ifconfig usb0 up
