init_top(){
    : empty
}

init_bottom(){
    # hide hardware info
    mount --make-private -t tmpfs -o ro tmpfs /sys/class/dmi || true
    mount --make-private -t tmpfs -o ro tmpfs /sys/devices/virtual/dmi || true
    # hide boot_id
    mount --make-private --bind /proc/sys/kernel/random/uuid \
        /proc/sys/kernel/random/boot_id || true
}
