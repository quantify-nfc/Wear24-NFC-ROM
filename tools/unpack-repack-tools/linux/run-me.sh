#!/bin/bash

export dir_dat2ext4=output_converted_dat_to_ext4
export dir_folder2ext4=output_converted_folder_to_ext4
export dir_dattransferfilelist=place_dat_transfer_list_file_context_here
export dir_systemimg=extract_system_img_here

introMsg() {
    echo " ============================================================================== "
    echo " ==                      Android 7.x.x System Tools                          == "
    echo " ==                           by Karen Sangaj                                == "
    echo " ==                 Ported to bash by davwheat and Jared                     == "
    echo " ============================================================================== "
    echo ""
    echo "                             Run at "$(date +%Y-%m-%d)"                         "
    echo ""
}

setUpDirectories() {
    clear
    introMsg

    echo "Continuing will PERMANENTLY erase the following folders AND their contents:"
    echo "  $dir_dat2ext4"
    echo "  $dir_folder2ext4"
    echo "  $dir_dattransferfilelist"
    echo "  $dir_systemimg"

    read -p "Continue? [y/N]"  shouldContinue

    if [[ "$shouldContinue" != "y" && "$shouldContinue" != "Y" ]]; then
        return
    else
        # Remove old directories

        rm -rf "$dir_dat2ext4"
        rm -rf "$dir_folder2ext4"
        rm -rf "$dir_dattransferfilelist"
        rm -rf "$dir_systemimg"

        mkdir "$dir_dat2ext4"
        mkdir "$dir_folder2ext4"
        mkdir "$dir_dattransferfilelist"
        mkdir "$dir_systemimg"

        cd "$dir_systemimg"
        mkdir "system"
        cd ..

        echo ""
        echo "Done! (press any key to continue)"
        read -n1
    fi
}

menu() {
    clear
    introMsg

    echo "Menu:"
    echo ""

    echo "0. Exit"
    echo "1. Create required directories (and remove old ones if exist)"
    echo "2. System tools menu"

    echo ""
    read -p "Please choose an option (0-2): " MenuSelect

    case "$MenuSelect" in 
        "0")
            return
            ;;
        "1")
            setUpDirectories
            menu
            ;;
        "2")
            sysMenu
            ;;
        *)
            menu
            ;;
    esac
}

sysMenu() {
    clear
    introMsg

    echo "System Tools Menu:"
    echo ""

    echo "0. Back"
    echo "1. Enter size in bytes"
    echo "2. Convert 'system.new.dat' to 'system.img'"
    echo "3. Unpack 'system.img'"
    echo "4. Pack 'system' folder to 'systemraw.img'"
    echo "5. Convert 'systemraw.img' to 'systemsparse.img'"
    echo "6. Convert 'systemsparse.img' to 'system.new.dat'"

    echo ""
    read -p "Please choose an option (1-1): " MenuSelect

    case "$MenuSelect" in 
        "0")
            menu
            ;;
        "1")
            rm -f temp_size.txt
            read -p "Enter size in bytes: " ByteSize
            echo "$ByteSize" > "temp_size.txt"
            sysMenu
            ;;
        "2")
            sysMenu
            ;;
        *)
            menu
            ;;
    esac
}

menu
