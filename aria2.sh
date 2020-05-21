#!/bin/bash

set -e
set -x
#ARCH=arm64
#ARCH=arm
#ARCH=mips
ARCH=mipsle
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
CFLAGS="-I $PWD/opt/cross/mipsel-linux-musl/mipsel-linux-musl/include -Os"	
CXXFLAGS=$CFLAGS
if [ "$ARCH" = "arm" ];then
CONFIGURE="./configure --prefix=/opt --host=arm-linux"
CONFIGURE1="./Configure linux-armv4 -static --prefix=$PREFIX zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "arm64" ];then
CONFIGURE="./configure --prefix=/opt --host=aarch64-linux"
CONFIGURE1="./Configure linux-aarch64 -static --prefix=$PREFIX zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "mips" ];then
CONFIGURE="./configure --prefix=/opt --host=mips-linux"
CONFIGURE1="./Configure linux-mips32 -static -mtune=mips32 -mips32 --prefix=$PREFIX zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "mipsle" ];then
CONFIGURE="./configure --prefix=/opt --host=mipsel-linux"
CONFIGURE1="./Configure linux-mips32 -static -mtune=mips32 -mips32 --prefix=$PREFIX zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
fi
MAKE="make -j`nproc`"

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
[ ! -d "openssl-1.0.2n" ] && tar zxvf openssl-1.0.2n.tar.gz
cd $BASE/openssl-1.0.2n
if [ ! -f "stamp-h1" ];then
$CONFIGURE1

make 
make install INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl
touch stamp-h1
fi

########## ##################################################################
# SQLITE # ##################################################################
########## ##################################################################
cd $BASE
[ ! -d "sqlite-autoconf-3081101" ] && tar zxvf sqlite-autoconf-3081101.tar.gz
cd sqlite-autoconf-3081101
if [ ! -f "stamp-h1" ];then
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE

make
make install DESTDIR=$BASE
touch stamp-h1
fi

########### #################################################################
# LIBXML2 # #################################################################
########### #################################################################
cd $BASE
[ ! -d "libxml2-2.9.3" ] && tar zxvf libxml2-2.9.3.tar.gz
cd libxml2-2.9.3
if [ ! -f "stamp-h1" ];then
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS="" \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
 --enable-shared=no \
 --enable-static \
 --with-c14n \
 --without-catalog \
 --without-docbook \
 --with-html \
 --without-ftp \
 --without-http \
 --without-iconv \
 --without-iso8859x \
 --without-legacy \
 --with-output \
 --without-pattern \
 --without-push \
 --without-python \
 --with-reader \
 --without-readline \
 --without-regexps \
 --with-sax1 \
 --with-schemas \
 --with-threads \
 --with-tree \
 --with-valid \
 --with-writer \
 --with-xinclude \
 --with-xpath \
 --with-xptr \
 --with-zlib=$DEST \
 --without-lzma

$MAKE LIBS="-lz"
make install DESTDIR=$BASE
touch stamp-h1
fi
########## ##################################################################
# C-ARES # ##################################################################
########## ##################################################################
cd $BASE
[ ! -d "c-ares-1.14.0" ] && tar zxvf c-ares-1.14.0.tar.gz
cd c-ares-1.14.0
if [ ! -f "stamp-h1" ];then
LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS="" \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE

$MAKE
make install DESTDIR=$BASE
touch stamp-h1
fi
######### ###################################################################
# ARIA2 # ###################################################################
######### ###################################################################
cd $BASE
[ ! -d "aria2-1.33.0" ] && tar xvJf aria2-1.33.0.tar.xz
cd aria2-1.33.0 && sed -i "s/LIBXML2_LIBS = -lxml2 -lz -lm -llzma/LIBXML2_LIBS = -lxml2 -lz -lm/g" src/Makefile && sed -i "s/-lxml2 -lz -lm -llzma/-lxml2 -lz -lm/g" src/Makefile && sed -i "s/LIBXML2_LIBS = -lxml2 -lz -lm -llzma/LIBXML2_LIBS = -lxml2 -lz -lm/g" src/includes/Makefile && sed -i "s/LIBXML2_LIBS = -lxml2 -lz -lm -llzma/LIBXML2_LIBS = -lxml2 -lz -lm/g" Makefile
LDFLAGS="-zmuldefs $LDFLAGS" \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--enable-libaria2 \
--enable-static \
--disable-shared \
--without-libuv \
--without-appletls \
--without-gnutls \
--without-libnettle \
--without-libgmp \
--without-libgcrypt \
--without-libexpat \
--with-xml-prefix=$DEST \
ZLIB_CFLAGS="-I$DEST/include" \
ZLIB_LIBS="-L$DEST/lib" \
OPENSSL_CFLAGS="-I$DEST/include" \
OPENSSL_LIBS="-L$DEST/lib" \
SQLITE3_CFLAGS="-I$DEST/include" \
SQLITE3_LIBS="-L$DEST/lib" \
LIBCARES_CFLAGS="-I$DEST/include" \
LIBCARES_LIBS="-L$DEST/lib" \
ARIA2_STATIC=yes

$MAKE LIBS="-lz -lssl -lcrypto -lsqlite3 -lcares -lxml2"
${CORSS_PREFIX}strip aria2c
