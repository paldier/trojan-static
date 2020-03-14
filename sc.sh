#!/bin/bash

#ARCH=arm64
ARCH=arm
#ARCH=mips
#ARCH=mipsle
PWD=$(pwd)
#prefix asuswrt:/jffs/softcenter,openwrt:/usr

if [ "$ARCH" = "arm" ];then
#armv7l
export CFLAGS="-I $PWD/opt/cross/arm-linux-musleabi/arm-linux-musleabi/include -Os"
export CXXFLAGS="-I $PWD/opt/cross/arm-linux-musleabi/arm-linux-musleabi/include"
export CC=$PWD/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-gcc
export CXX=$PWD/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-g++
export CORSS_PREFIX=$PWD/opt/cross/arm-linux-musleabi/bin/arm-linux-musleabi-
export TARGET_CFLAGS=""
export BOOST_ABI=sysv
elif [ "$ARCH" = "arm64" ];then
export CFLAGS="-I $PWD/opt/cross/aarch64-linux-musl/aarch64-linux-musl/include -Os"
export CXXFLAGS="-I $PWD/opt/cross/aarch64-linux-musl/aarch64-linux-musl/include"
export CC=$PWD/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-gcc
export CXX=$PWD/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-g++
export CORSS_PREFIX=$PWD/opt/cross/aarch64-linux-musl/bin/aarch64-linux-musl-
export TARGET_CFLAGS=""
export BOOST_ABI=aapcs
elif [ "$ARCH" = "mips" ];then
#mips
export CFLAGS="-I $PWD/opt/cross/mips-linux-musl/mips-linux-musl/include -Os"
export CXXFLAGS="-I $PWD/opt/cross/mips-linux-musl/mips-linux-musl/include"
export CC=$PWD/opt/cross/mips-linux-musl/bin/mips-linux-musl-gcc
export CXX=$PWD/opt/cross/mips-linux-musl/bin/mips-linux-musl-g++
export CORSS_PREFIX=$PWD/opt/cross/mips-linux-musl/bin/mips-linux-musl-
export TARGET_CFLAGS=" -DBOOST_NO_FENV_H"
export BOOST_ABI=o32
export mipsarch=" architecture=mips32r2"
elif [ "$ARCH" = "mipsle" ];then
export CFLAGS="-I $PWD/opt/cross/mipsel-linux-musl/mipsel-linux-musl/include -Os"
export CXXFLAGS="-I $PWD/opt/cross/mipsel-linux-musl/mipsel-linux-musl/include"
export CC=$PWD/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-gcc
export CXX=$PWD/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-g++
export CORSS_PREFIX=$PWD/opt/cross/mipsel-linux-musl/bin/mipsel-linux-musl-
export TARGET_CFLAGS=" -DBOOST_NO_FENV_H"
export BOOST_ABI=o32
export mipsarch=" architecture=mips32r2"
fi

BASE=`pwd`
SRC=$BASE/src
WGET="wget --prefer-family=IPv4"
DEST=$BASE/opt
LDFLAGS="-L$DEST/lib -Wl,--gc-sections"
CPPFLAGS="-I$DEST/include"
CXXFLAGS="$CXXFLAGS $CFLAGS"
if [ "$ARCH" = "arm" ];then
CONFIGURE="linux-armv4 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "arm64" ];then
CONFIGURE="linux-aarch64 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "mips" ];then
CONFIGURE="linux-mips32 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "mipsle" ];then
CONFIGURE="linux-mips32 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
fi
MAKE="make"
mkdir -p bin/$ARCH
$CC -static versioncmp.c -o versioncmp
${CORSS_PREFIX}strip versioncmp
cp versioncmp bin/$ARCH
$CC -static base64.c -o base64_encode
${CORSS_PREFIX}strip base64_encode
cp base64_encode bin/$ARCH
$CC -static resolveip.c -o resolveip
${CORSS_PREFIX}strip resolveip
cp resolveip bin/$ARCH
cd httping-2.5
CFLAGS="-I$DEST/include -DENABLE_HELP -static $CFLAGS" LDFLAGS="-L$DEST/lib -Wl,--gc-sections" \
make 
${CORSS_PREFIX}strip httping
cd $BASE
cp httping-2.5/httping bin/$ARCH
