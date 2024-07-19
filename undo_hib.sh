#!/usr/bin/env bash
# Script to undo hibernation setup noninteractively

shopt -s nullglob extglob

lock() {
    local LOCK=/tmp/hibernator.lock
    if ! mkdir "$LOCK" 2> /dev/null; then
        echo "Working... $LOCK"
        exit
    fi
    trap "rm -rf $LOCK" EXIT
}

if [[ $EUID != 0 ]]; then
    echo "[hibernator-undo] must be run as root"
    exit 1
fi

remove_kernel_parameters() {
    if [ -e /etc/default/grub ]; then
        cp /etc/default/grub /etc/default/grub.old
        sed -i '/resume=/d' /etc/default/grub
        update-grub
    fi
    if [ -e /boot/refind_linux.conf ]; then
        cp /boot/refind_linux.conf /boot/refind_linux.conf.old
        sed -i '/resume=/d' /boot/refind_linux.conf
    fi
}

remove_resume_hook() {
    if grep -qs -e resume -e systemd /etc/mkinitcpio.conf; then
        cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.old
        sed -i '/resume/d' /etc/mkinitcpio.conf
        mkinitcpio -P
    fi
}

remove_swap_file() {
    if grep -qs '/swapfile' /etc/fstab; then
        sed -i '/\/swapfile/d' /etc/fstab
        swapoff /swapfile
        rm -f /swapfile
    fi
}

#############################
main() {
    lock

    echo "Removing kernel parameters from bootloaders" && remove_kernel_parameters
    echo "Removing resume hook from initramfs" && remove_resume_hook
    echo "Removing swapfile" && remove_swap_file
    echo "Hibernation setup has been undone."
}

main
