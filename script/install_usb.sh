#!/bin/bash

# In order to run this script, make install_usb.sh runnable with "sudo chmod +x /share/install_usb.sh"
# then run "sudo /share/install_usb.sh"

if cat /boot/config.txt | grep dtoverlay=dwc2; then
  echo exists "dtoverlay=dwc2"
else
  echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
fi

if cat /etc/modules | grep dwc2; then
   echo "dwc2 exists in /etc/modules"
else
   echo "dwc2" | sudo tee -a /etc/modules
fi


if cat /etc/modules | grep libcomposite; then
  echo "libcomposite exists in /etc/modules"
else
  echo "libcomposite" | sudo tee -a /etc/modules
fi

sudo chmod +x /share/triple_usb_device.sh
sudo chmod +x /share/rasp_vusb_server.out
sudo chmod +x /share/uninstall_usb.sh

if systemctl | grep create-triple-usb; then
  echo "service exists create-triple-usb"
else
  sudo cp /share/create-triple-usb.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl start create-triple-usb
  sudo systemctl enable create-triple-usb
fi

if systemctl | grep usb_server; then
  echo "service exists usb_server"
else
  sudo cp /share/usb_server.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl start usb_server
  sudo systemctl enable usb_server
fi
