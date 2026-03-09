#!/bin/sh
function get_part(){
    # find uuid root and mount
    if [ "${root#UUID=}" != "$root" ]; then
        for dev in /sys/class/block/* ; do
            part="/dev/${dev##*/}"
            uuid=$(blkid -s UUID -o value "$part")
            if [ "${root#UUID=}" == "${uuid}" ] ; then
                echo "$part"
                break
            fi
        done
    fi
}

function init_top(){
    for mod in mmc_block sd_mod sr_mod nvme usb-storage ; do
        modprobe $mod || true
    done
    if [ "${root#UUID=}" != "$root" ]; then
        # mark as custom rootfs mount
        mkdir -p /rootfs
        rootfs=$(get_part)
        i=0
        while [ "$rootfs" == "" ] && [ $i -lt 10 ] ; do
            echo "Waiting for root: $root ($rootfs)"
            sleep 1
            i=$(($i+1))
            export rootfs=$(get_part)
        done
        export root="$rootfs"
    fi
    if [ "$rootfstype" == "" ] ; then
        rootfstype=ext4
    fi
    modprobe $rootfstype || true
    if command -v fsck.$rootfstype >/dev/null ; then
        yes "" | fsck.$rootfstype "$root" || true
    fi
}

function init_bottom(){
    if [ "${root#UUID=}" != "$root" ]; then
        if [ "$rootflags" == "" ] ; then
            rootflags="ro"
        fi
        if [ "$rootfstype" == "" ] ; then
            rootfstype=auto
        fi
        mount -t $rootfstype $(get_part) -o $rootflags /rootfs
    fi
}
