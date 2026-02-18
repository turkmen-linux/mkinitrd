init_top(){
    # busybox networking
    for dev in /sys/class/net/* ; do
        dev=${dev##*/}
        ip link set $dev up || true
        if [ "$dev" != lo ] ; then
            udhcpc -b -i $dev -s /etc/udhcpc.sh || true
        fi
    done
    if [ "${nbd}" != "" ]; then
        mount_nbd
    fi
    if [ "${netinit}" != "" ]; then
        wget -O /netinit.sh ${netinit}
        ash -c "source /netinit.sh ; init_top"
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
    if [ "${netinit}" != "" ]; then
        wget -O /netinit.sh ${netinit}
        ash -c "source /netinit.sh ; init_bottom"
    fi
}