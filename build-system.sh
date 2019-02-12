# /bin/bash
export DATE_TIME=$(date +"%m-%d-%Y_%H-%M-%S")
export branch=$(git symbolic-ref --short HEAD)

yes | cp -af system-new/* unpack/ # copy altered files to unpack dir

mkdir middleman

make_ext4fs -s -l 786432000 -a system system.img.new middleman #SHOULD be a sparse image!

./tools/img2sdat out/system.img.new -o aromainstaller -p system.new.dat #output system.new.dat to aroma zip for building

zip -j JareDav-$DATE_TIME-$branch aromainstaller/*
echo "ROM ZIP can be found at $(pwd)"
