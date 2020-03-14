#!/bin/bash

set -e
set -x

#ARCH=arm64
ARCH=arm
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
CONFIGURE="linux-armv4 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "arm64" ];then
CONFIGURE="linux-aarch64 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "mips" ];then
CONFIGURE="linux-mips32 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
elif [ "$ARCH" = "mipsle" ];then
CONFIGURE="linux-mips32 -Os -static --prefix=/opt zlib --with-zlib-lib=$DEST/lib --with-zlib-include=$DEST/include"
fi
MAKE="make"

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

[ ! -d "zlib-1.2.11" ] && tar xvJf zlib-1.2.11.tar.xz
cd zlib-1.2.11
if [ ! -f "stamp-h1" ];then
make clean
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
make clean
./Configure $CONFIGURE

make 
make install INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl
touch stamp-h1
fi

########### #################################################################
#  BOOST  # #################################################################
########### #################################################################

cd $BASE
[ ! -d "boost_1_71_0" ] && tar jxvf boost_1_71_0.tar.bz2
cd $BASE/boost_1_71_0
if [ ! -f "stamp-h1" ];then
rm -rf project-config.jam
rm -rf tools/build/src/user-config.jam
cd tools/build/src/engine
CC=/usr/bin/gcc \
CXX=/usr/bin/g++ \
CFLAGS="" \
CPPFLAGS="" \
CXXFLAGS="$CFLAGS" \
./build.sh gcc
cd $BASE/boost_1_71_0
cp -rf tools/build/src/engine/b2 ./b2
echo "using gcc : : ${CORSS_PREFIX}gcc : <compileflags>\"${TARGET_CFLAGS}\" <cxxflags>\" -std=gnu++14\" <linkflags>\" -pthread -lrt\" ;" > tools/build/src/user-config.jam
#./bootstrap.sh 
#sed -i 's/using gcc/using gcc: :${CORSS_PREFIX}gcc ;/g' project-config.jam
#cp -rf ../gcc.jam $BASE/boost_1_71_0/tools/build/src/tools/gcc.jam
CC=${CORSS_PREFIX}gcc \
CXX=${CORSS_PREFIX}g++ \
./b2 install --ignore-site-config --toolset=gcc --prefix=$DEST abi=$BOOST_ABI --no-cmake-config --layout=tagged --build-type=minimal link=static threading=multi runtime-link=static $mipsarch variant=release --disable-long-double -sNO_BZIP2=1 -sZLIB_INCLUDE=$DEST/include -sZLIB_LIBPATH=$DEST/lib --with-system --with-program_options --with-date_time
#--without-mpi --without-python --without-graph_parallel --without-test --without-serialization
mv $DEST/lib/libboost_date_time-*.a $DEST/lib/libboost_date_time.a 
mv $DEST/lib/libboost_program_options-*.a $DEST/lib/libboost_program_options.a 
mv $DEST/lib/libboost_system-*.a $DEST/lib/libboost_system.a 
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
# TROJAN  # #################################################################
########### #################################################################

cd $BASE
[ ! -d "trojan-1.14.1" ] && tar zxvf trojan-1.14.1.tar.gz
cd $BASE/trojan-1.14.1
rm -rf CMakeFiles
rm -rf CMakeCache.txt
cp -rf ../CMakeLists.txt ./CMakeLists.txt
export CMAKE_ROOT=$DEST/bin/cmake
CC=${CORSS_PREFIX}gcc \
CXX=${CORSS_PREFIX}g++ \
LDFLAGS=$LDFLAGS" -static" \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$DEST/bin/cmake/bin/cmake -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_VERSION=1 -DCMAKE_SYSTEM_PROCESSOR=$ARCH -DCMAKE_BUILD_TYPE=Release -DCMAKE_SOURCE_DIR=$DEST/bin/cmake -DENABLE_MYSQL=OFF -DENABLE_NAT=ON -DENABLE_REUSE_PORT=ON -DENABLE_SSL_KEYLOG=ON -DENABLE_TLS13_CIPHERSUITES=ON -DFORCE_TCP_FASTOPEN=OFF -DSYSTEMD_SERVICE=OFF -DOPENSSL_USE_STATIC_LIBS=TRUE -DBoost_DEBUG=ON -DBoost_NO_BOOST_CMAKE=ON -DLINK_DIRECTORIES=$DEST/lib -DCMAKE_FIND_ROOT_PATH=$DEST -DBOOST_ROOT=$DEST -DBoost_INCLUDE_DIR=$DEST/include -DBoost_LIBRARY_DIRS=$DEST/lib -DBOOST_LIBRARYDIR=$DEST/lib -DOPENSSL_CRYPTO_LIBRARY=$DEST/lib -DOPENSSL_INCLUDE_DIR=$DEST/include -DOPENSSL_SSL_LIBRARY=$DEST/lib -DBoost_USE_STATIC_LIBS=TRUE -DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE=$DEST/lib -DBoost_SYSTEM_LIBRARY_RELEASE=$DEST/lib -DCMAKE_SKIP_RPATH=NO -DDEFAULT_CONFIG=/jffs/softcenter/etc/trojan.json -DCMAKE_FIND_LIBRARY_SUFFIXES=.a
make
${CORSS_PREFIX}strip trojan
cd $BASE
mkdir -p bin/$ARCH
cp -rf $BASE/trojan-1.14.1/trojan bin/$ARCH
