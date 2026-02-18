copy_modules nbd
copy_module_tree kernel/drivers/net/ethernet

install $basedir/data/udhcpc.sh $work/etc/udhcpc.sh

if command -v nbd-client >/dev/null ; then
    copy_binary nbd-client
fi