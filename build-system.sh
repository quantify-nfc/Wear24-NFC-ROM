# /bin/bash
export DATE_TIME=$(date +"%m-%d-%Y_%H-%M-%S")
export branch=$(git symbolic-ref --short HEAD)

# in the future, uncomment these lines to back up stock files that are modified by us
# ---------------------------------------------------------------
# mkdir oldfiles
# echo "Backing up unmodified files to oldfiles"
# yes | cp -af system-deodexed-stock/{[INSERT FILES HERE]} oldfiles # back up stock files that are being modified

echo "Copying new/modified files to stock directory..."
yes | cp -af system-new/* system-deodexed-stock/ # copy altered files to stock dir

mkdir out
echo "Making sparse image to out using make_ext4fs"
make_ext4fs -s -l 786432000 -a system out/system.img.new #SHOULD be a sparse image!

echo "Converting sparse image to .new.dat"
./tools/img2sdat/img2sdat.py out/system.img.new -o aromainstaller #output system.new.dat to aroma zip for building
rm -f out/system.img.new

if [ ! -f aromainstaller/boot.img ]; then
    echo "Boot image was not found at build time, AROMA does not include kernel."
    echo "The custom kernel will need to be flashed for NFC to work."
    echo "It is recommended to fix this by placing your kernel into aromainstaller and renaming it to boot.img"
    echo "In order for AROMA to successfully flash your system, ensure the boot image option is unchecked."
else
    echo "Boot image was built into AROMA sucessfully. No additional flash is required."
    echo "Ensure the boot image option is checked in AROMA to flash it."
fi

cd aromainstaller
echo "Zipping AROMA..."
zip -r ../Quantify-$DATE_TIME-$branch.zip *
cd ..
echo "ROM ZIP can be found at $(pwd)"
