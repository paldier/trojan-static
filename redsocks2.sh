#!/bin/bash

set -e
set -x

ARCH=arm64
#ARCH=arm
#ARCH=mips
#ARCH=mipsle
PWD=`pwd`
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
CONFIGURE="linux-armv4 -Os -static --prefix=/opt zlib enable-ssl3 enable-ssl3-method enable-tls1_3 --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
ARCHBUILD=arm
elif [ "$ARCH" = "arm64" ];then
CONFIGURE="linux-aarch64 -Os -static --prefix=/opt zlib enable-ssl3 enable-ssl3-method enable-tls1_3 --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
ARCHBUILD=aarch64
elif [ "$ARCH" = "mips" ];then
CONFIGURE="linux-mips32 -Os -static --prefix=/opt zlib enable-ssl3 enable-ssl3-method enable-tls1_3 --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
ARCHBUILD=mips
elif [ "$ARCH" = "mipsle" ];then
CONFIGURE="linux-mips32 -Os -static --prefix=/opt zlib enable-ssl3 enable-ssl3-method enable-tls1_3--with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
ARCHBUILD=mipsle
fi
MAKE="make"

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

[ ! -d "zlib-1.2.11" ] && tar xvJf zlib-1.2.11.tar.xz
cd zlib-1.2.11
if [ ! -f "stamp-h1" ];then
CC=${CORSS_PREFIX}gcc \
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
CROSS_PREFIX=${CORSS_PREFIX} \
./configure \
--prefix=/opt \
--static

$MAKE
make install DESTDIR=$BASE
touch stamp-h1
fi

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

cd $BASE
[ ! -d "openssl-1.1.1d" ] && tar zxvf openssl-1.1.1d.tar.gz
cd $BASE/openssl-1.1.1d
if [ ! -f "stamp-h1" ];then
./Configure $CONFIGURE

make 
make install INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl
touch stamp-h1
fi

########### #################################################################
#  CMAKE  # #################################################################
########### #################################################################

cd $BASE
[ ! -d "cmake-3.13.2" ] && tar zxvf cmake-3.13.2.tar.gz
cd $BASE/cmake-3.13.2
if [ ! -f "stamp-h1" ];then
CC=/usr/bin/gcc \
CXX=/usr/bin/g++ \
CFLAGS="-I /usr/include" \
CPPFLAGS="-I /usr/include" \
CXXFLAGS="$CFLAGS" \
./bootstrap --prefix=$DEST/bin/cmake
make
make install
touch stamp-h1
fi

########### #################################################################
# LIBEVENT# #################################################################
########### #################################################################
cd $BASE
[ ! -d "libevent-2.1.11-stable" ] && tar zxvf libevent-2.1.11-stable.tar.gz
cd $BASE/libevent-2.1.11-stable
if [ ! -f "stamp-h1" ];then
./configure --disable-debug-mode --disable-samples --disable-libevent-regress --prefix=/opt --host=$ARCHBUILD-linux && make
#cp -rf .libs/libevent*.a $DEST/lib
make install DESTDIR=$BASE
fi
########### #################################################################
#  PDNSD  # #################################################################
########### #################################################################
cd $BASE
[ ! -d "pdnsd-1.2.9b-par" ] && tar zxvf pdnsd-1.2.9b-par.tar.gz
cd $BASE/pdnsd-1.2.9b-par
if [ ! -f "stamp-h1" ];then
CC=${CORSS_PREFIX}gcc \
LDFLAGS=$LDFLAGS" -static" \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
CROSS_PREFIX=${CORSS_PREFIX} \
./configure --with-cachedir=/var/pdnsd --with-target=Linux --host=$ARCHBUILD-linux
make
${CORSS_PREFIX}strip src/pdnsd-ctl/pdnsd-ctl
cd $BASE
mkdir -p bin/$ARCH
cp -rf $BASE/pdnsd-1.2.9b-par/src/pdnsd-ctl/pdnsd-ctl bin/$ARCH/pdnsd
fi
########### #################################################################
#redsocks2# #################################################################
########### #################################################################

cd $BASE
[ ! -d "redsocks2-0.67" ] && tar zxvf redsocks2-0.67.tar.gz
cd $BASE/redsocks2-0.67
ENABLE_STATIC=y \
DISABLE_SHADOWSOCKS=y \
CC=${CORSS_PREFIX}gcc \
LDFLAGS=$LDFLAGS" -static" \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
CROSS_PREFIX=${CORSS_PREFIX} \
make
#make
${CORSS_PREFIX}strip redsocks2
cd $BASE
mkdir -p bin/$ARCH
cp -rf $BASE/redsocks2-0.67/redsocks2 bin/$ARCH
