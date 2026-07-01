#!/bin/sh
apt-get install -y busybox-static 2>/dev/null || true

mkdir -p initramfs/{bin,dev,proc,sys,mnt}

cat > initramfs/init << 'ENDINIT'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
echo "Scanning for rootfs..."
sleep 2
for dev in /dev/sda* /dev/sdb* /dev/sdc* /dev/sdd* /dev/sde* /dev/sdf*; do
    if [ -b "$dev" ]; then
        echo "Trying $dev..."
        if mount -t ext4 -o ro "$dev" /mnt 2>/dev/null; then
            if [ -f /mnt/sbin/init ] || [ -f /mnt/bin/init ]; then
                echo "Found rootfs on $dev"
                mount --move /mnt /
                exec chroot / /sbin/init
            fi
            umount /mnt 2>/dev/null
        fi
    fi
done
echo "No rootfs found"
exec /bin/sh
ENDINIT

chmod +x initramfs/init
cp /bin/busybox initramfs/bin/busybox
for cmd in sh mount umount echo sleep chroot; do
    ln -sf busybox initramfs/bin/$cmd
done

cd initramfs
find . | cpio -H newc -o | gzip > ../initramfs.cpio.gz
cd ..
echo "Built: $(ls -lh initramfs.cpio.gz)"
