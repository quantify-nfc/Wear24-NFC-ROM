#!/sbin/sh

# Get option from zip name if applicable
case $(basename "$ZIP") in
    *nonewboot*|*NoNewBoot*|*NONEWBOOT*)#
        NEWBOOT=false
        NEWBOOTD=false
        ;;
    *newboot*|*NewBoot*|*NEWBOOT*)
        NEWBOOT=true
        NEWBOOTD=false
        ;;
esac
case $(basename "$ZIP") in
    *nonewanim*|*NoNewAnim*|*NONEWANIM*)
        NEWANIM=false
        NEWANIMD=false
        ;;
    *newanim*|*NewAnim*|*NEWANIM*)
        NEWANIM=true
        NEWANIMD=false
        ;;
esac
case $(basename "$ZIP") in
    *vzwapps*|*VzwApps*|*VZWAPPS*)
        VZWAPPS=true
        VZWAPPSD=false
        ;;
        #NOVZWAPPS
esac

# THIS IS MESSY. +1 Dunno how else to do it.

# default options for installer
NEWBOOT=true
NEWANIM=true
VZWAPPS=false

# Tells installer whether defaults are still selected
NEWBOOTD=true
NEWANIMD=true
VZWAPPSD=true

choose() {
    #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep

    timeout 5 /system/bin/getevent -lc 1 2>&1 | /system/bin/grep KEY_POWER | /system/bin/grep " DOWN" > /tmp/events
    if (cat /tmp/events 2>/dev/null | /system/bin/grep KEY_POWER >/dev/null); then
	rm -f /tmp/events
        return 1
    else
        return 0
    fi
}

ui_print " "
if [ $NEWBOOTD = true ]; then
    ui_print " "
    ui_print "- Select Option -"
    ui_print "   Push the Power button to NOT flash the custom kernel..."
    ui_print "   Only do this if you manually built without it!"
    ui_print "   Otherwise, wait for timeout."
    FUNCTION=choose

    if [ $FUNCTION = 1 ]; then
        NEWBOOT=false
    fi
else
    ui_print "Using parameter NEWBOOT from ZIP name..."
fi

ui_print " "
if [ $NEWANIMD = true ]; then
    ui_print " "
    ui_print "- Select Option -"
    ui_print "   Push the Power button to NOT flash the new boot animation..."
    ui_print "   Otherwise, wait for timeout."
    FUNCTION=choose

    if [ $FUNCTION = 1 ]; then
        NEWANIM=false
    fi
else
    ui_print "Using parameter NEWANIM from ZIP name..."
fi

ui_print " "
if [ $VZWAPPSD = true ]; then
    ui_print " "
    ui_print "- Select Option -"
    ui_print "   Push the Power button to install Verzion Apps..."
    ui_print "   Do this if you use Verizon's LTE!"
    ui_print "   Otherwise, wait for timeout."
    FUNCTION=choose

    if [ $FUNCTION = 1 ]; then
        VZWAPPS=true
    fi
else
    ui_print "Using parameter VZWAPPS from ZIP name..."
fi

if [ $NEWBOOT = true ]; then
    ui_print "Flashing boot image..."
    dd if=/tmp/boot.img of=/dev/block/platform/soc/7824900.sdhci/by-name/system || abort "Failed to flash boot image..."
fi

(if [ $NEWANIM = true ]; then
    ui_print "Moving new boot animation..."
    mv -f /tmp/bootanimation.zip /system/media/bootanimation.zip || ui_print "Couldn't overwrite boot image, continuing..." && exit
    chmod 0644 /system/media/bootanimation.zip || ui_print "Couldn't change permissions for boot animation..."
fi)

if [ $VZWAPPS = false ]; then
    rm -rf /system/priv-app/ChargingApp-release || ui_print "Couldn't remove ChargingApp"
    rm -rf /system/priv-app/jumpstart-wear "Couldn't remove jumpstart"
    rm -rf /system/priv-app/MyVerizon "Couldn't remove MyVerizon"
    rm -rf /system/priv-app/VZMessages-wear "Couldn't remove VZMessages"
fi
