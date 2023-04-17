#!/usr/bin/env bash

flutter packages pub get

VERSION=$(dart version.dart)

flutter clean

flutter build linux

if [ -e deb_builder ]; then
    rm -rf deb_builder
fi


mkdir "deb_builder"

cp -r debian deb_builder/DEBIAN
chmod -R 755 deb_builder/DEBIAN

cp LICENSE deb_builder/DEBIAN/copyright

echo "设置版本号为: $VERSION"

echo Version: "$VERSION" >> deb_builder/DEBIAN/control

mkdir -p deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/

cp -r dde_package_info/* deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/

ARCH="x64"

if [[ $(uname -m) == aarch64 ]]; then
  ARCH="arm64"
  sed -i "s/amd64/$ARCH/g" deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/info
  sed -i "s/amd64/$ARCH/g" deb_builder/DEBIAN/control
fi

cp -r build/linux/"$ARCH"/release/bundle deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/files

mkdir -p deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/entries/icons/hicolor/512x512/apps/

cp logo.png deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/entries/icons/hicolor/512x512/apps/dde_qrcode_detector.png

sed -i "s/VERSION/$VERSION/g" deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/info

sed -i "s/VERSION/$VERSION/g" deb_builder/opt/apps/com.debuggerx.dde-qrcode-detector/entries/applications/com.debuggerx.dde-qrcode-detector.desktop

echo "开始打包 $ARCH deb"

fakeroot dpkg-deb -b deb_builder

if [[ $ARCH == "x64" ]]; then
    ARCH="amd64"
fi

mv deb_builder.deb com.debuggerx.dde-qrcode-detector_"$VERSION"_"$ARCH".deb

echo "打包完成！"