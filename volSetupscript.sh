#!/bin/bash

echo "Show all block storage devices"
lsblk


sudo gdisk /dev/xvdb
sudo gdisk /dev/xvdc
sudo gdisk /dev/xvdd

