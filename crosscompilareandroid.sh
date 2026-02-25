# procudera per compilare i binari per android!

1. scarica mevacoin: 

git clone --recursive https://github.com/pasqualelembo78/mevacoin
cd mevacoin

2. crea toolchain (file già scaricato con git clone)

3. installa boost per android. Segui la procedura di https://github.com/pasqualelembo78/Boost-for-Android.git

4. Installazione librerie.

Openssl

THREADS=16
OPENSSL_VERSION=3.0.5
OPENSSL_HASH=aa7d8d9bef71ad6525c55ba11e5f4397889ce49c2c9349dcea6d3e4f0b024a7a
ANDROID_NDK_ROOT=/root/Android/Sdk/ndk/25.2.9519653
PREFIX=/opt/openssl/android/arm64-v8a

mkdir -p $PREFIX && cd /tmp \
&& curl -LO https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
&& echo "${OPENSSL_HASH}  openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
&& tar xf openssl-${OPENSSL_VERSION}.tar.gz \
&& cd openssl-${OPENSSL_VERSION} \
&& export PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH \
&& ./Configure android-arm64 \
       -D__ANDROID_API__=28 \
       -static \
       no-shared no-tests \
       --prefix=${PREFIX} --openssldir=${PREFIX} \
&& make -j${THREADS} \
&& make install_sw \
&& rm -rf /tmp/openssl-${OPENSSL_VERSION}

----

Installa expat

# Variabili principali
export NDK=/root/Android/Sdk/ndk/25.2.9519653
export API=28
export TARGET=aarch64-linux-android
export PREFIX=/opt/expat/android/arm64-v8a
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
export PATH=$TOOLCHAIN/bin:$PATH
export CC=$TOOLCHAIN/bin/${TARGET}${API}-clang
export CXX=$TOOLCHAIN/bin/${TARGET}${API}-clang++
export AR=$TOOLCHAIN/bin/llvm-ar
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export THREADS=16

# Comando unico
mkdir -p $PREFIX && cd /tmp && \
wget https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz && \
tar xf expat-2.5.0.tar.gz && cd expat-2.5.0 && \
./configure --host=aarch64-linux-android --prefix=$PREFIX --enable-static --disable-shared \
            CC=$CC CXX=$CXX AR=$AR RANLIB=$RANLIB && \
make -j$THREADS && \
make install && \
rm -rf /tmp/expat-2.5.0 /tmp/expat-2.5.0.tar.gz


----(
Install libunbound (dopo openssl) 
export NDK=/root/Android/Sdk/ndk/25.2.9519653 \
API=28 \
TARGET=aarch64-linux-android \
OPENSSL_DIR=/opt/openssl/android/arm64-v8a \
EXPAT_DIR=/opt/expat/android/arm64-v8a \
PREFIX=/opt/unbound/android/arm64-v8a \
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64 && \
export CC=$TOOLCHAIN/bin/${TARGET}${API}-clang \
CXX=$TOOLCHAIN/bin/${TARGET}${API}-clang++ \
AR=$TOOLCHAIN/bin/llvm-ar \
RANLIB=$TOOLCHAIN/bin/llvm-ranlib \
PATH=$TOOLCHAIN/bin:$PATH && \
apt update && apt install -y git autoconf automake libtool pkg-config make perl wget && \
# ================== installa expat ==================
mkdir -p $EXPAT_DIR && cd /tmp && \
wget https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz && \
tar xf expat-2.5.0.tar.gz && cd expat-2.5.0 && \
./configure --host=aarch64-linux-android --prefix=$EXPAT_DIR --enable-static --disable-shared \
            CC=$CC CXX=$CXX AR=$AR RANLIB=$RANLIB && \
make -j$(nproc) && make install && \
rm -rf /tmp/expat-2.5.0 /tmp/expat-2.5.0.tar.gz && \
# ================== installa Unbound ==================
cd /usr/src && rm -rf unbound && \
git clone https://github.com/NLnetLabs/unbound.git -b release-1.16.1 && \
cd unbound && \
test "$(git rev-parse HEAD)" = "903538c76e1d8eb30d0814bb55c3ef1ea28164e8" && \
autoreconf -fi && \
./configure \
  --host=aarch64-linux-android \
  --prefix=$PREFIX \
  --enable-static \
  --disable-shared \
  --disable-flto \
  --with-ssl=$OPENSSL_DIR \
  --with-libexpat=$EXPAT_DIR \
  CC=$CC CXX=$CXX AR=$AR RANLIB=$RANLIB && \
make -j$(nproc) && make install


------------ 
installa libsodium
mkdir /root/libsodium
cd /root/libsodium
make distclean || truecmake .. \
  Install libsodium

cd /root/libsodium

# Pulisci la compilazione precedente
make distclean 2>/dev/null || true

export ANDROID_NDK=/root/Android/android-ndk-r26b
export TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
export TARGET=aarch64-linux-android24

export CC=$TOOLCHAIN/bin/$TARGET-clang
export CXX=$TOOLCHAIN/bin/$TARGET-clang++
export AR=$TOOLCHAIN/bin/llvm-ar
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

export CFLAGS="--target=$TARGET --sysroot=$TOOLCHAIN/sysroot"
export CXXFLAGS="--target=$TARGET --sysroot=$TOOLCHAIN/sysroot"
export LDFLAGS="--target=$TARGET --sysroot=$TOOLCHAIN/sysroot"

./configure \
  --host=aarch64-linux-android \
  --prefix=/opt/libsodium/android/arm64-v8a \
  --enable-static \
  --disable-shared

make -j$(nproc)
make install

 # ho notato che il file finsodium.cmake nella cartella /mevacoin/cmake ha dei problemi.
sostituisci completametne il suot contenuto. usa questo per farlo:

cat > ~/mevacoin/cmake/FindSodium.cmake << 'EOF'
# FindSodium.cmake - versione per cross-compilation Android

if (NOT DEFINED sodium_USE_STATIC_LIBS)
    option(sodium_USE_STATIC_LIBS "enable to statically link against sodium" OFF)
endif()

# SOLO_HOST evita che il toolchain Android reindirizzi nel sysroot NDK
find_path(sodium_INCLUDE_DIR sodium.h
    HINTS ${sodium_DIR}/include
    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
)

if(sodium_USE_STATIC_LIBS)
    find_library(sodium_LIBRARY_RELEASE libsodium.a
        HINTS ${sodium_DIR}/lib
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
    find_library(sodium_LIBRARY_DEBUG libsodium.a
        HINTS ${sodium_DIR}/lib
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
else()
    find_library(sodium_LIBRARY_RELEASE sodium
        HINTS ${sodium_DIR}/lib
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
    find_library(sodium_LIBRARY_DEBUG sodium
        HINTS ${sodium_DIR}/lib
        NO_DEFAULT_PATH
        NO_CMAKE_FIND_ROOT_PATH
    )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Sodium
    REQUIRED_VARS
        sodium_LIBRARY_RELEASE
        sodium_LIBRARY_DEBUG
        sodium_INCLUDE_DIR
)

if(Sodium_FOUND)
    set(sodium_LIBRARIES optimized ${sodium_LIBRARY_RELEASE} debug ${sodium_LIBRARY_DEBUG})
    if(NOT TARGET sodium)
        if(sodium_USE_STATIC_LIBS)
            add_library(sodium STATIC IMPORTED)
            set_target_properties(sodium PROPERTIES
                INTERFACE_COMPILE_DEFINITIONS "SODIUM_STATIC"
            )
        else()
            add_library(sodium SHARED IMPORTED)
        endif()
        set_target_properties(sodium PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${sodium_INCLUDE_DIR}"
            IMPORTED_LINK_INTERFACE_LANGUAGES "C"
            IMPORTED_LOCATION "${sodium_LIBRARY_RELEASE}"
            IMPORTED_LOCATION_DEBUG "${sodium_LIBRARY_DEBUG}"
        )
    endif()
endif()

mark_as_advanced(sodium_INCLUDE_DIR sodium_LIBRARY_DEBUG sodium_LIBRARY_RELEASE)
EOF




------------
cd mevacoin
mkdir build-android
cd build-android

cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=../android-toolchain.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_ANDROID_NDK="$ANDROID_NDK" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DOPENSSL_ROOT_DIR=/opt/openssl/android/arm64-v8a \
  -DOPENSSL_INCLUDE_DIR=/opt/openssl/android/arm64-v8a/include \
  -DOPENSSL_CRYPTO_LIBRARY=/opt/openssl/android/arm64-v8a/lib/libcrypto.a \
  -DOPENSSL_SSL_LIBRARY=/opt/openssl/android/arm64-v8a/lib/libssl.a \
  -DUNBOUND_ROOT=/opt/unbound/android/arm64-v8a \
  -DUNBOUND_INCLUDE_DIR=/opt/unbound/android/arm64-v8a/include \
  -DUNBOUND_LIBRARIES=/opt/unbound/android/arm64-v8a/lib/libunbound.a \
  -DBOOST_ROOT=/opt/boost/build/out/arm64-v8a \
  -DBoost_INCLUDE_DIR=/opt/boost/build/out/arm64-v8a/include/boost-1_85 \
  -DBoost_LIBRARY_DIR=/opt/boost/build/out/arm64-v8a/lib \
  -DBoost_USE_STATIC_LIBS=ON \
  -DBoost_USE_MULTITHREADED=ON \
  -DBoost_NO_SYSTEM_PATHS=ON \
  -DBoost_NO_BOOST_CMAKE=ON \
  -Dsodium_USE_STATIC_LIBS=ON \
  -Dsodium_DIR=/opt/libsodium/android/arm64-v8a \
  -DENABLE_UNBOUND=ON \
  -DENABLE_HIDAPI=OFF \
