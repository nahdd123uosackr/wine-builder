# Arch Linux 기반의 Wine 빌드 환경
FROM archlinux:latest

ARG USERNAME=wine-builder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# 시스템 설정 및 모든 종속성 설치를 하나의 RUN 명령으로 통합
RUN \
    # 1. 시스템 전체 업데이트 및 필수 유틸리티 설치
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed sudo curl && \
    \
    # 2. echo를 사용하여 multilib 저장소 설정 추가
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    \
    # 3. multilib 활성화 후 데이터베이스 강제 재동기화
    pacman -Syu --noconfirm && \
    \
    # 4. 빌드에 필요한 모든 종속성 설치 (AUR 패키지인 lib32-libgphoto2, lib32-sane 제거)
    pacman -S --noconfirm --needed \
    base-devel ca-certificates gnupg \
    gcc-multilib mingw-w64-gcc alsa-lib libpulse dbus fontconfig freetype2 gnutls mesa libunwind libx11 libxcomposite libxcursor libxfixes libxi libxrandr libxrender libxext \
    gstreamer gst-plugins-base sdl2 systemd vulkan-icd-loader \
    libcups libgphoto2 sane krb5 samba ocl-icd libpcap libusb v4l-utils \
    lib32-gcc-libs lib32-alsa-lib lib32-libpulse lib32-dbus lib32-fontconfig lib32-freetype2 lib32-gnutls lib32-mesa lib32-libunwind lib32-libx11 lib32-libxcomposite lib32-libxcursor lib32-libxfixes lib32-libxi lib32-libxrandr lib32-libxrender lib32-libxext \
    lib32-gstreamer lib32-gst-plugins-base lib32-sdl2 lib32-systemd \
    lib32-zlib lib32-libcups lib32-krb5 lib32-ocl-icd lib32-libpcap lib32-libusb && \
    \
    # 5. 이미지 용량 최적화를 위해 패키지 캐시 정리
    pacman -Scc --noconfirm

# non-root 사용자 생성 (모든 패키지 설치 후)
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# 빌드 스크립트 복사 및 권한 설정
COPY --chown=$USER_UID:$USER_GID build-wine.sh /build-wine.sh
RUN chmod 777 /build-wine.sh

# 작업 디렉터리 생성 및 권한 설정
RUN mkdir /wine-builder && \
    chown $USER_UID:$USER_GID /wine-builder

# 사용자 전환 및 작업 디렉터리 이동
USER $USERNAME
WORKDIR /wine-builder

# 컨테이너 시작 시 빌드 스크립트 실행
ENTRYPOINT [ "/build-wine.sh" ]
