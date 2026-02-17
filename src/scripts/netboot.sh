init_top(){
    # busybox networking
    for dev in /sys/class/net/* ; do
        ip link set $dev up || true
        if [ "$dev" != lo ] ; then
            udhcpc -b -i $dev || true
        fi
    done
    if [ "${nbd}" != "" ]; then
        connect_nbd
    fi
}

# example cmdline:
# root=/dev/nbd0p1 nbd=192.168.1.31:10809

mount_nbd(){
    # TODO: add multiple nbd support
    modprobe nbd nbds_max=1
    port=${nbd#*:}
    host=${nbd%:*}
    if [ "$port" == "" ] || [ "$port" == "$root" ] ;then
        port="10809"
    fi
    nbd-client $host /dev/nbd0 -p $port
}

init_bottom(){
    : empty
}