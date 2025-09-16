# Arch Linux 기반의 Wine 빌드 환경 (모든 종속성 포함)
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
    # 4. 빌드에 필요한 모든 종속성 설치
    pacman -S --noconfirm --needed \
    #--- 기본 빌드 도구 및 코어 패키지 ---
    base-devel ca-certificates gnupg \
    #--- 64-bit 필수/권장 종속성 ---
    gcc-multilib mingw-w64-gcc alsa-lib libpulse dbus fontconfig freetype2 gnutls mesa libunwind libx11 libxcomposite libxcursor libxfixes libxi libxrandr libxrender libxext \
    gstreamer gst-plugins-base sdl2 systemd vulkan-icd-loader \
    libcups libgphoto2 sane krb5 samba ocl-icd libpcap libusb v4l-utils \
    #--- 32-bit 필수/권장 종속성 ---
    lib32-gcc-libs lib32-alsa-lib lib32-libpulse lib32-dbus lib32-fontconfig lib32-freetype2 lib32-gnutls lib32-mesa lib32-libunwind lib32-libx11 lib32-libxcomposite lib32-libxcursor lib32-libxfixes lib32-libxi lib32-libxrandr lib32-libxrender lib32-libxext \
    lib32-gstreamer lib32-gst-plugins-base lib32-sdl2 lib32-systemd \
    #--- 32-bit 선택적 종속성 (공식 저장소) ---
    lib32-zlib lib32-libcups lib32-krb5 lib32-ocl-icd lib32-libpcap lib32-libusb \
    #--- 추가된 선택적 종속성 (64-bit) ---
    opengl-man-pages rrdtool sndio nss-mdns python-dbus python-gobject python-twisted libwebp-utils ffmpeg qt5-base sdl \
    qt6-base qt6-5compat freeglut poppler-data sane-airscan a2jmidid libffado realtime-privileges \
    gst-plugin-pipewire pipewire-alsa pipewire-audio pipewire-docs pipewire-ffado pipewire-jack pipewire-libcamera pipewire-pulse pipewire-roc pipewire-session-manager pipewire-v4l2 pipewire-x11-bell pipewire-zeroconf rtkit \
    libwmf libopenraw libjxl librsvg webp-pixbuf-loader evince vulkan-mesa-layers openmp opencl-headers \
    #--- 추가된 선택적 종속성 (32-bit) ---
    lib32-alsa-plugins lib32-pipewire-jack lib32-pipewire-v4l2 lib32-vulkan-mesa-layers  lib32-pipewire lib32-libdecor lib32-vulkan-radeon lib32-vulkan-intel lib32-opencl-driver && \
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
