#!/bin/sh

BIN=kerberos.bin
RELDIR=kerberos

if [ -d "$RELDIR" ]
then
    read -p "[*] Release directory exists. Clean release [y/n]? " yn
    while true; do
	case $yn in
	    [Yy]* ) rm -rf $RELDIR; break;;
	    [Nn]* ) echo "[*] Abort"; exit;;
	    * ) echo "Please answer yes or no [y/n].";;
	esac
    done
fi

echo "[*] Building application"
make

if [ $? -eq 0 ]
then
    echo "[*] Build successful"
    echo "[*] Creating release subdirectories"
    mkdir -p $RELDIR
    mkdir -p $RELDIR/bin
    mkdir -p $RELDIR/lib

    echo "[*] Copying files"
    echo "$BIN --> $RELDIR/bin"
    cp kerberos.bin $RELDIR/bin

    LIBS=`ldd kerberos.bin | grep -e Qt -e icu -e gcc -e stdc++ -e pthread -e png | awk '{print $3}'`    
    for LIB in $LIBS; do
	echo "$LIB --> $RELDIR/lib"
	cp $LIB $RELDIR/lib
    done

    SCRIPT=$RELDIR/kerberos.sh
    echo "[*] Creating startup script $SCRIPT"
    touch $SCRIPT
    echo '#/bin/sh' >> $SCRIPT
    echo 'export LD_LIBRARY_PATH="'`pwd`/$RELDIR/lib'${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"' >> $SCRIPT
    echo "bin/$BIN" '$@' >> $SCRIPT
    chmod u+x $SCRIPT
else
    echo "[*] Could not build application"
fi
 
