#!/bin/bash
mkdir unpack

if [ -f system.zip ]; then
unzip system.zip unpack/
echo "Zip unpacked to unpack directory"

elif [ -f system.img ]; then
mkdir rawimage
mkdir mountpoint
./tools/imgtool/imgtool systemraw.img rawimage
echo "We will now ask for sudo permission so that we can mount the raw image. Is that okay? (If not, you'll have to mount the image and extract the files yourself)"
read -p "Can we ask for sudo? (Y/n) " RESP
if [ "$RESP" = "y" ]; then
  sudo mount -t ext4 -o loop rawimage/systemraw.img mountpoint
cp -af mountpoint/* unpack/
sudo umount mountpoint
elif [ "$RESP" = "n" ]; then
  read -p "Chose not to grant sudo. Please mount the image and extract its contents to the unpack directory, then press enter."
else
echo "Invalid/empty response. Assuming yes."
 sudo mount -t ext4 -o loop rawimage/systemraw.img mountpoint
cp -af mountpoint/* unpack/
sudo umount mountpoint
fi

elif [ -f "system.new.dat" -a ! -f "system.transfer.list" ]; then
echo "Detected a system.new.dat but no system.transfer.list, exiting"
exit 1
elif [ ! -f "system.new.dat" -a -f "system.transfer.list" ]; then
echo "Detected a system.transfer.list but no system.new.dat, exiting"
exit 1
elif [ -f "system.new.dat" -a -f "system.transfer.list" ]; then
mkdir rawimage
mkdir mountpoint
./tools/sdat2img.py system.transfer.list system.new.dat rawimage/systemraw.img
echo "We will now ask for sudo permission so that we can mount the raw image. Is that okay? (If not, you'll have to mount the image and extract the files yourself)"
read -p "Can we ask for sudo? (Y/n) " RESP
if [ "$RESP" = "y" ]; then
  sudo mount -t ext4 -o loop rawimage/systemraw.img mountpoint
cp -af mountpoint/* unpack/
sudo umount mountpoint
elif [ "$RESP" = "n" ]; then
  read -p "Chose not to grant sudo. Please mount the image and extract its contents to the unpack directory, then press enter."
else
echo "Invalid/empty response. Assuming yes."
 sudo mount -t ext4 -o loop rawimage/systemraw.img mountpoint
cp -af mountpoint/* unpack/
sudo umount mountpoint
fi

else
echo "No system images detected. This script accepts sparse images, system.new.dat files, and .zip files. Please ensure one of those files exists in $(pwd). Thank you."
exit 1
fi
