#!/bin/sh
# Minimal initramfs for salami mainline boot
mkdir -p initramfs/{bin,dev,proc,sys,mnt,usr/bin,usr/lib}

# Minimal init script
cat > initramfs/init << 'ENDINIT'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "Scanning for rootfs..."
sleep 2

# Try to mount userdata
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

echo "No rootfs found, dropping to shell"
exec /bin/sh
ENDINIT

chmod +x initramfs/init

# Copy busybox for shell and utils
if which busybox-static 2>/dev/null; then
    cp $(which busybox-static) initramfs/bin/busybox
elif which busybox 2>/dev/null; then
    cp $(which busybox) initramfs/bin/busybox
fi

for cmd in sh mount umount echo sleep chroot; do
    ln -s busybox initramfs/bin/$cmd 2>/dev/null || true
done

# Pack it
cd initramfs
find . | cpio -H newc -o | gzip > ../initramfs.cpio.gz
cd ..
echo "Initramfs built: $(ls -lh initramfs.cpio.gz)"
