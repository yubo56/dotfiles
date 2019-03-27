#!/bin/bash
# on OS X, /usr/lib/systemd/system-sleep

PCI_DEV="0000:00:14.0"

case $1/$2 in
  pre/*)
    # echo "Going to $2..."
    echo "$PCI_DEV" > /sys/bus/pci/drivers/xhci_hcd/unbind
    ;;
  post/*)
    # echo "Waking up from $2..."
    echo "$PCI_DEV" > /sys/bus/pci/drivers/xhci_hcd/bind
    ;;
esac
