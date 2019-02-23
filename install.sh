#!/system/bin/sh

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


# Change this path to wherever the keycheck binary is located in your installer
KEYCHECK=$INSTALLER/keycheck
chmod 755 $KEYCHECK
# get keycheck binary

# do we need this
keytest() {
    ui_print "- Power Key Test -"
    ui_print "   Press the Power Key:"
    (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep KEY_POWER | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
    return 0
}

choose() {
    #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep

    timeout 5 (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep KEY_POWER | /system/bin/grep " DOWN" > $INSTALLER/events);
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep KEY_POWER >/dev/null`); then
        return false
    else
        return true
    fi
}

ui_print " "
if [[ $NEWBOOTD == true ]]; then
    ui_print " "
    ui_print "- Select Option -"
    ui_print "   Push the Power button to NOT flash the custom kernel..."
    ui_print "   Only do this if you manually built without it!"
    ui_print "   Otherwise, wait for timeout."
    FUNCTION=choose

    if [[ $FUNCTION == false ]]; then
        $NEWBOOT=false
    fi
else
    ui_print "Using parameter NEWBOOT from ZIP name..."
fi

ui_print " "
if [[ $NEWANIMD == true ]]; then
    ui_print " "
    ui_print "- Select Option -"
    ui_print "   Push the Power button to NOT flash the new boot animation..."
    ui_print "   Otherwise, wait for timeout."
    FUNCTION=choose

    if [[ $FUNCTION == false ]]; then
        $NEWANIM=false
    fi
else
    ui_print "Using parameter NEWANIM from ZIP name..."
fi

ui_print " "
if [[ $VZWAPPSD == true ]]; then
    ui_print " "
    ui_print "- Select Option -"
    ui_print "   Push the Power button to install Verzion Apps..."
    ui_print "   Do this if you use Verizon's LTE!"
    ui_print "   Otherwise, wait for timeout."
    FUNCTION=choose

    if [[ $FUNCTION == false ]]; then
        $VZWAPPS=true
    fi
else
    ui_print "Using parameter VZWAPPS from ZIP name..."
fi

if $NEWBOOT; then
    dd if=/tmp/boot.img of=
fi

if $NEWANIM; then
    # mv -f /system/media/whatever
fi

if $VZWAPPS=false; then
    rm -rf /system/priv-app/ChargingApp-release
    rm -rf /system/priv-app/jumpstart-wear
    rm -rf /system/priv-app/MyVerizon
    rm -rf /system/priv-app/VZMessages-wear
fi
