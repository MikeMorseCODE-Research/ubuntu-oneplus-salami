#!/bin/sh
apt-get install -y busybox-static 2>/dev/null || true

WORK=$1/initramfs_build
OUTPUT=$1/initramfs.cpio.gz

rm -rf $WORK
mkdir -p $WORK/{bin,dev,proc,sys,mnt,usr/bin}

cat > $WORK/init << 'ENDINIT'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t configfs none /sys/kernel/config 2>/dev/null || true

echo "salami initramfs starting..."

# Set up USB RNDIS networking for remote access
mkdir -p /sys/kernel/config/usb_gadget/g1
echo "0x1d6b" > /sys/kernel/config/usb_gadget/g1/idVendor
echo "0x0104" > /sys/kernel/config/usb_gadget/g1/idProduct
mkdir -p /sys/kernel/config/usb_gadget/g1/strings/0x409
echo "OnePlus11" > /sys/kernel/config/usb_gadget/g1/strings/0x409/product
mkdir -p /sys/kernel/config/usb_gadget/g1/functions/rndis.usb0
mkdir -p /sys/kernel/config/usb_gadget/g1/configs/c.1
ln -s /sys/kernel/config/usb_gadget/g1/functions/rndis.usb0 /sys/kernel/config/usb_gadget/g1/configs/c.1/ 2>/dev/null || true
UDC=$(ls /sys/class/udc 2>/dev/null | head -1)
if [ -n "$UDC" ]; then
    echo "$UDC" > /sys/kernel/config/usb_gadget/g1/UDC
    ifconfig usb0 192.168.2.15 netmask 255.255.255.0 up 2>/dev/null || \
    ip addr add 192.168.2.15/24 dev usb0 && ip link set usb0 up
    echo "USB RNDIS up on 192.168.2.15"
fi

# Start telnet for debug access
telnetd -l /bin/sh -p 23 2>/dev/null || true

echo "Scanning for rootfs..."
sleep 3

for dev in /dev/sda* /dev/sdb* /dev/sdc* /dev/sdd* /dev/sde* /dev/sdf* /dev/sdg*; do
    if [ -b "$dev" ]; then
        echo "Trying $dev..."
        if mount -t ext4 -o ro "$dev" /mnt 2>/dev/null; then
            if [ -f /mnt/sbin/init ] || [ -f /mnt/bin/init ]; then
                echo "Found rootfs on $dev"
                mount -o remount,rw "$dev" /mnt
                mount --move /proc /mnt/proc 2>/dev/null || true
                mount --move /sys /mnt/sys 2>/dev/null || true
                mount --move /dev /mnt/dev 2>/dev/null || true
                exec switch_root /mnt /sbin/init
            fi
            umount /mnt 2>/dev/null
        fi
    fi
done

echo "No rootfs found - dropping to shell"
exec /bin/sh
ENDINIT

chmod +x $WORK/init

cp /bin/busybox $WORK/bin/busybox
for cmd in sh mount umount echo sleep chroot switch_root ifconfig ip telnetd; do
    ln -sf busybox $WORK/bin/$cmd 2>/dev/null || true
done

cd $WORK
find . | cpio -H newc -o | gzip > $OUTPUT
cd $1
echo "Built: $(ls -lh $OUTPUT)"
