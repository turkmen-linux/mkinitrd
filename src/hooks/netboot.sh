copy_modules nbd
copy_module_tree kernel/drivers/net/ethernet
mkdir -p $work/usr/share/udhcpc/
if [ -f /usr/share/udhcpc/default.script ] ; then
    copy_files /usr/share/udhcpc/default.script
else
cat > $work/usr/share/udhcpc/default.script <<EOF
#!/bin/busybox ash
busybox ip addr add \$ip/\$mask dev \$interface

if [ "\$router" ]; then
  busybox ip route add default via \$router dev \$interface
fi
for i in \$dns ; do
	echo "Adding DNS server \$i"
	echo "nameserver \$i" >> /etc/resolv.conf
done
EOF
fi
chmod 755 $work/usr/share/udhcpc/default.script