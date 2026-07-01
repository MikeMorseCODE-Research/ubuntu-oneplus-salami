#!/bin/sh
apt-get install -y busybox-static 2>/dev/null || true

WORK=$1/initramfs_build
OUTPUT=$1/initramfs.cpio.gz

rm -rf $WORK
mkdir -p $WORK/bin
mkdir -p $WORK/dev
mkdir -p $WORK/proc
mkdir -p $WORK/sys
mkdir -p $WORK/mnt

# Find busybox
BB=$(which busybox-static 2>/dev/null || which busybox 2>/dev/null || find /bin /usr/bin /sbin /usr/sbin -name "busybox*" 2>/dev/null | head -1)
echo "Found busybox at: $BB"

cat > $WORK/init << 'ENDINIT'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t configfs none /sys/kernel/config 2>/dev/null || true
echo "salami initramfs starting..."
mkdir -p /sys/kernel/config/usb_gadget/g1/strings/0x409
mkdir -p /sys/kernel/config/usb_gadget/g1/functions/rndis.usb0
mkdir -p /sys/kernel/config/usb_gadget/g1/configs/c.1
echo "0x1d6b" > /sys/kernel/config/usb_gadget/g1/idVendor 2>/dev/null || true
echo "0x0104" > /sys/kernel/config/usb_gadget/g1/idProduct 2>/dev/null || true
ln -s /sys/kernel/config/usb_gadget/g1/functions/rndis.usb0 /sys/kernel/config/usb_gadget/g1/configs/c.1/ 2>/dev/null || true
UDC=$(ls /sys/class/udc 2>/dev/null | head -1)
[ -n "$UDC" ] && echo "$UDC" > /sys/kernel/config/usb_gadget/g1/UDC 2>/dev/null || true
ip addr add 192.168.2.15/24 dev usb0 2>/dev/null || true
ip link set usb0 up 2>/dev/null || true
telnetd -l /bin/sh 2>/dev/null || true
echo "Scanning for rootfs..."
sleep 3
for dev in /dev/sda* /dev/sdb* /dev/sdc* /dev/sdd* /dev/sde* /dev/sdf* /dev/sdg*; do
    if [ -b "$dev" ]; then
        echo "Trying $dev..."
        if mount -t ext4 -o ro "$dev" /mnt 2>/dev/null; then
            if [ -f /mnt/sbin/init ] || [ -f /mnt/bin/init ]; then
                echo "Found rootfs on $dev"
                mount -o remount,rw "$dev" /mnt
                exec switch_root /mnt /sbin/init
            fi
            umount /mnt 2>/dev/null
        fi
    fi
done
echo "No rootfs found"
exec /bin/sh
ENDINIT

chmod +x $WORK/init

if [ -n "$BB" ] && [ -f "$BB" ]; then
    cp "$BB" $WORK/bin/busybox
    chmod +x $WORK/bin/busybox
    for cmd in sh mount umount echo sleep ip telnetd switch_root; do
        ln -sf busybox $WORK/bin/$cmd 2>/dev/null || true
    done
    echo "Busybox installed from $BB"
else
    echo "WARNING: busybox not found, initramfs will have no tools"
fi

cd $WORK
find . | cpio -H newc -o | gzip > $OUTPUT
cd $1
echo "Built: $(ls -lh $OUTPUT)"
