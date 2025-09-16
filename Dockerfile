# Arch Linux 기반의 Wine 빌드 환경
FROM archlinux:latest

ARG USERNAME=wine-builder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# 시스템 업데이트 및 기본 유틸리티 설치 (sudo, curl 등)
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed sudo curl

# 32-bit 아키텍처 (multilib 저장소) 활성화 및 시스템 재동기화
RUN sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf && \
    pacman -Syu --noconfirm

# non-root 사용자 생성
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# 빌드 필수 도구 그룹 설치
RUN pacman -S --noconfirm --needed base-devel

# 사용자 전환
USER $USERNAME
WORKDIR /home/$USERNAME

# Wine 빌드에 필요한 모든 종속성 설치
RUN sudo pacman -S --noconfirm --needed \
    ca-certificates gnupg \
    gcc-multilib mingw-w64-gcc alsa-lib libpulse dbus fontconfig freetype2 gnutls mesa libunwind libx11 libxcomposite libxcursor libxfixes libxi libxrandr libxrender libxext \
    gstreamer gst-plugins-base sdl2 systemd vulkan-icd-loader \
    libcups libgphoto2 sane krb5 samba ocl-icd libpcap libusb v4l-utils \
    lib32-gcc-libs lib32-alsa-lib lib32-libpulse lib32-dbus lib32-fontconfig lib32-freetype2 lib32-gnutls lib32-mesa lib32-libunwind lib32-libx11 lib32-libxcomposite lib32-libxcursor lib32-libxfixes lib32-libxi lib32-libxrandr lib32-libxrender lib32-libxext \
    lib32-gstreamer lib32-gst-plugins-base lib32-sdl2 lib32-systemd lib32-vulkan-icd-loader \
    lib32-libcups lib32-libgphoto2 lib32-sane lib32-krb5 lib32-ocl-icd lib32-libpcap lib32-libusb lib32-v4l-utils \
    lib32-zlib \
    && sudo pacman -Scc --noconfirm

# 빌드 스크립트 복사 및 권한 설정
COPY --chown=$USER_UID:$USER_GID build-wine.sh /build-wine.sh
RUN sudo chmod 777 /build-wine.sh

# 작업 디렉터리 설정
WORKDIR /wine-builder
RUN sudo chown $USER_UID:$USER_GID /wine-builder && \
    sudo chmod 777 /wine-builder

# 컨테이너 시작 시 빌드 스크립트 실행
ENTRYPOINT [ "/build-wine.sh" ]
