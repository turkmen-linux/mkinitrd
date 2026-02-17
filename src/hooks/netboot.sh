copy_modules nbd
copy_module_tree kernel/drivers/net/ethernet
if [ -f /usr/share/udhcpc/default.script ] ; then
    copy_files /usr/share/udhcpc/default.script
fi
