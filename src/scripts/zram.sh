#!/bin/ash

init_top(){
    if grep "boot=live" /proc/cmdline >/dev/null ; then
        : dont enable zram on live mode
    elif ! [[ -b /dev/zram0 ]] ; then
        cpus=$(nproc)
        memtot=$(cat /proc/meminfo | grep MemTotal | tr -s " " | cut -f2 -d" ")
        size=$(expr ${memtot} / ${cpus})
        size=$(expr ${size} / 2)
        modprobe zram num_devices=${cpus}
        for dev in $(seq 0 $(expr ${cpus} - 1)) ; do
             echo ${size}"K" > "/sys/block/zram$dev/disksize"
        done
        for dev in $(seq 0 $(expr ${cpus} - 1)) ; do
            mkswap /dev/zram$dev
            swapon /dev/zram$dev
        done
    fi
}

init_bottom(){
    :
}
