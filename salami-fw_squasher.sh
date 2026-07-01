git clone https://github.com/linux-msm/pil-squasher --depth 1
cd pil-squasher
make install

/usr/local/bin/pil-squasher $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/adsp.mbn $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/adsp.mdt
rm -rf $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/adsp.mdt $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/adsp.b*

cat $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b23_1 $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b23_2 > $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b23
cat $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b24_1 $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b24_2 > $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b24
/usr/local/bin/pil-squasher $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.mbn $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.mdt
rm -rf $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.mdt $1/firmware-oneplus-salami/usr/lib/firmware/qcom/sm8550/salami/modem.b*

cd $1
dpkg-deb --build --root-owner-group firmware-oneplus-salami