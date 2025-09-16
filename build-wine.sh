#!/bin/sh

# 사용 가능한 CPU 코어 수를 가져와 빌드 스레드 수로 설정 (기본값: nproc 결과)
BUILD_THREADS="${BUILD_THREADS:-$(nproc)}"

echo "빌드를 위해 $BUILD_THREADS 개의 스레드를 사용합니다."

# 빌드 환경 준비 (wine 소스 코드는 ../wine-src 에 있다고 가정)
mkdir -p wine32-build wine64-build

#
# 모든 종속성은 Dockerfile에서 미리 설치해야 합니다.
# 따라서 스크립트 내의 패키지 설치 명령어는 제거되었습니다.
#

# 64비트 Wine 빌드
echo "--- 64비트 Wine 구성 시작 ---"
cd wine64-build
../wine-src/configure --prefix=/wine-builder/wine-src/wine-install --enable-win64

echo "--- 64비트 Wine 빌드 시작 ---"
make -j$BUILD_THREADS
cd ..


# 32비트 Wine 빌드
echo "--- 32비트 Wine 구성 시작 ---"
cd wine32-build

# Arch Linux의 32비트 pkg-config 경로 설정
export PKG_CONFIG_PATH=/usr/lib32/pkgconfig
../wine-src/configure --with-wine64=../wine64-build --prefix=/wine-builder/wine-src/wine-install

echo "--- 32비트 Wine 빌드 시작 ---"
make -j$BUILD_THREADS
cd ..

# Wine 설치 (32비트와 64비트 모두)
echo "--- Wine 설치 시작 ---"
cd wine32-build
sudo make install
cd ..

cd wine64-build
sudo make install
cd ..

echo "빌드가 완료되었습니다. 최종 결과물은 '/wine-builder/wine-src/wine-install' 디렉터리에 있습니다."
