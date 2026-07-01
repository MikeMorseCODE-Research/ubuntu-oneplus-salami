cd $1
git clone https://github.com/jiganomegsdfdf/aston-mainline.git --depth 1 linux --branch aston-$2
cd linux
cp $1/sm8550-oneplus-salami.dts $1/linux/arch/arm64/boot/dts/qcom/sm8550-oneplus-salami.dts
python3 -c "
path='$1/linux/arch/arm64/boot/dts/qcom/Makefile'
content=open(path).read()
if 'salami' not in content:
    content=content.replace('sm8550-oneplus-aston.dtb', 'sm8550-oneplus-aston.dtb\ndtb-\$(CONFIG_ARCH_QCOM) += sm8550-oneplus-salami.dtb')
    open(path,'w').write(content)
"
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig sm8550.config
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
_kernel_version="$(make kernelrelease -s)"
sed -i "s/Version:.*/Version: ${_kernel_version}/" $1/linux-oneplus-aston/DEBIAN/control

chmod +x $1/mkbootimg

cat $1/linux/arch/arm64/boot/Image $1/linux/arch/arm64/boot/dts/qcom/sm8550-oneplus-aston.dtb > $1/linux/Image_w_dtb
gzip Image_w_dtb
$1/mkbootimg --header_version 4 --base 0x0 --os_version 15.0.0 --os_patch_level 2025-02 --kernel $1/linux/Image_w_dtb.gz -o $1/boot16G.img

cat $1/linux/arch/arm64/boot/Image $1/linux/arch/arm64/boot/dts/qcom/sm8550-oneplus-aston_16G_A14.dtb > $1/linux/Image_w_dtb
gzip Image_w_dtb
$1/mkbootimg --header_version 4 --base 0x0 --os_version 15.0.0 --os_patch_level 2025-02 --kernel $1/linux/Image_w_dtb.gz -o $1/boot16G_A14.img

cat $1/linux/arch/arm64/boot/Image $1/linux/arch/arm64/boot/dts/qcom/sm8550-oneplus-aston_12G.dtb > $1/linux/Image_w_dtb
gzip Image_w_dtb
$1/mkbootimg --header_version 4 --base 0x0 --os_version 15.0.0 --os_patch_level 2025-02 --kernel $1/linux/Image_w_dtb.gz -o $1/boot12G.img

rm $1/linux-oneplus-aston/usr/dummy
make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$1/linux-oneplus-aston/usr modules_install
rm $1/linux-oneplus-aston/usr/lib/modules/**/build

cat $1/linux/arch/arm64/boot/Image $1/linux/arch/arm64/boot/dts/qcom/sm8550-oneplus-salami.dtb > $1/linux/Image_w_dtb
gzip -f $1/linux/Image_w_dtb
$1/mkbootimg --header_version 4 --base 0x0 --os_version 15.0.0 --os_patch_level 2025-02 --kernel $1/linux/Image_w_dtb.gz --cmdline "earlycon=msm_geni_serial,0x994000 console=ttyMSM0,115200n8 rw loglevel=8 androidboot.selinux=permissive root=PARTLABEL=userdata rootfstype=ext4 rootwait rw" -o $1/boot_salami_8G.img
cd $1
rm -rf linux

dpkg-deb --build --root-owner-group linux-oneplus-aston
