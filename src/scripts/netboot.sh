init_top(){
    # busybox networking
    for dev in /sys/class/net/* ; do
        ip link set $dev up || true
        if [ "$dev" != lo ] ; then
            udhcpc -b -i $dev || true
        fi
    done
    if [ "${root#NBD=}" != "$root" ]; then
        mount_nbd
        root="/dev/nbd0"
        [ "${nbdroot}" != "" ] || root="${nbdroot}"
    fi
    [ "$rootfstype" == "" ] || rootfstype=auto
    [ "$rootflags" == "" ]  || rootflags="ro"
    if [ -b "$root" ] ; then
        mkdir -p /rootfs
        mount -t $rootfstype $root -o $rootflags /rootfs
    fi
}

mount_nbd(){
    modprobe nbd
    port=${root#*:}
    root=${root#NBD=}
    root=${root%:*}
    if [ "$port" == "" ] || [ "$port" == "$root" ] ;then
        port="10809"
    fi
    nbd-client "${root#NBD=}" /dev/nbd0 -p $port
}

init_bottom(){
    : empty
}