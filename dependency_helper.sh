#!/bin/bash

# This is an debian dependency helper script for to help set up
# requirements for running make. Primarly this script is used by the CI,
# but is also useful when setting up a new env

# Before running it, you should export the desired PLATFORM environment
# variable ( one of pc, switch, 3ds, wii, wiiu, all )
#  eg. PLATFORM=switch ./dependency_helper.sh

# It may be easier to follow the README.md instructions for the
# desired target and platform that you want to build, but this script may
# help if you are interested in seeing how the dependencies come together
# on various platforms, or how the CI works

main_platform_logic () {
  case "${PLATFORM}" in
    pc)
        setup_deb_sdl_deps
      ;;
    # html5)
    #     apt-get -y install emscripten
    #   ;;
    switch) # uses libnx
        setup_dkp_repo
        ${DKP}pacman --noconfirm -S devkitA64 libnx switch-tools switch-curl switch-bzip2 switch-freetype switch-libjpeg-turbo switch-libwebp switch-sdl2 switch-sdl2_gfx switch-sdl2_image switch-sdl2_ttf switch-zlib switch-libpng switch-mesa switch-sdl2_mixer
      ;;
    3ds)    # uses libctru
        setup_dkp_repo
        ${DKP}pacman --noconfirm -S devkitARM libctru citro3d 3dstools 3ds-curl 3ds-mbedtls 3ds-cmake 3ds-mpg123 3ds-opusfile 3ds-libogg 3ds-libopus
        install_3ds_sdl2
      ;;
    wii)    # uses libogc
        setup_dkp_repo
        ${DKP}pacman --noconfirm -S devkitPPC libogc gamecube-tools wii-sdl2 wii-sdl2_gfx wii-sdl2_image wii-sdl2_ttf wii-sdl2_mixer ppc-zlib ppc-bzip2 ppc-freetype ppc-mpg123 ppc-libpng ppc-pkg-config ppc-libvorbisidec ppc-libjpeg-turbo libfat-ogc
        install_wii_curl
      ;;
    wiiu)   # uses wut
        setup_dkp_repo
        ${DKP}pacman --noconfirm -S wut wiiu-sdl2 devkitPPC wiiu-sdl2_gfx wiiu-sdl2_image wiiu-sdl2_ttf wiiu-sdl2_mixer ppc-zlib ppc-bzip2 ppc-freetype ppc-mpg123 ppc-libpng ppc-pkg-config wiiu-pkg-config wut-tools wut wiiu-curl
      ;;
  esac
}

install_wii_curl () {
  # curl on the wii uses three packages: libwiisocket, wii-curl, and wii-mbedtls
  # These are not (yet?) available upstream, so we need to build them ourselves
  # For more info, see: https://gitlab.com/4TU/wii-packages

  apt-get install -y cmake makepkg file git sudo
  ${DKP}pacman --noconfirm -S dkp-cmake-common-utils dkp-toolchain-vars wii-pkg-config wii-cmake

  git clone https://gitlab.com/4TU/wii-packages.git

  export PACMAN=${DKP}pacman
  export DEVKITPRO=/opt/devkitpro
  export DEVKITPPC=/opt/devkitpro/devkitPPC

  chown -R nobody:nogroup wii-packages

  cd wii-packages/libwiisocket
  sudo -E -u nobody makepkg -s --noconfirm
  ${PACMAN} --noconfirm -U libwiisocket-*.pkg.tar.gz
  cd ../wii-mbedtls
  sudo -E -u nobody makepkg -s --noconfirm
  ${PACMAN} --noconfirm -U wii-mbedtls-*.pkg.tar.gz
  cd ../wii-curl
  sudo -E -u nobody makepkg -s --noconfirm
  ${PACMAN} --noconfirm -U wii-curl-*.pkg.tar.gz
  cd ../..

  rm -rf wii-packages
}

install_3ds_sdl2 () {
  # https://wiki.libsdl.org/SDL2/README/n3ds

  apt-get install -y cmake makepkg file git sudo
  libs=("SDL" "SDL_ttf" "SDL_image")
  export DEVKITPRO=/opt/devkitpro
  export DEVKITARM=/opt/devkitpro/devkitARM

  for lib in "${libs[@]}"; do
      git clone --recursive https://github.com/libsdl-org/${lib}.git -b SDL2
      cd ${lib}
      cmake -S. -Bbuild -DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/3DS.cmake" -DCMAKE_BUILD_TYPE=Release
      cmake --build build
      cmake --install build
      cd ..
  done
}

install_container_deps () {
  apt-get update && apt-get -y install wget libxml2 xz-utils lzma build-essential haveged curl libbz2-dev
  haveged &
  touch /trustdb.gpg
}

setup_deb_sdl_deps () {
  apt-get -y install libsdl2-dev libsdl2-mixer-dev libsdl2-ttf-dev libsdl2-image-dev libsdl2-gfx-dev zlib1g-dev gcc g++ libcurl4-openssl-dev wget git

  # FYI for archlinux systems:
  # pacman --noconfirm -S sdl2 sdl2_image sdl2_gfx sdl2_ttf
}

export DKP=""
export PACMAN_CONFIGURED=""

cleanup_deps () {
  rm -rf /var/cache/pacman
}

setup_dkp_repo () {
  # if pacman repos have already been configured, don't do it again
  if [ ! -z $PACMAN_CONFIGURED ]; then return; fi
  PACMAN_CONFIGURED="true"

  # NOTICE: Check https://github.com/devkitPro/pacman/releases/ for the latest install instructions

  mkdir -p /usr/local/share/keyring/
  curl https://apt.devkitpro.org/devkitpro-pub.gpg > /usr/local/share/keyring/devkitpro-pub.gpg
  echo "deb [signed-by=/usr/local/share/keyring/devkitpro-pub.gpg] https://apt.devkitpro.org stable main" > /etc/apt/sources.list.d/devkitpro.list

  apt-get update && apt-get -y install devkitpro-pacman

  DKP="dkp-"

  dkp-pacman --noconfirm -Syu
}

# do this mtab symlink thing, if it doesn't exist
# https://github.com/microsoft/WSL/issues/3984#issuecomment-491684299
[ ! -f /etc/mtab ] && ln -s /proc/self/mounts /etc/mtab

install_container_deps
main_platform_logic

# handle the "all" target by looping through all platforms
all_plats=( pc wiiu switch 3ds wii )
if [[ $PLATFORM == "all" ]]; then
  for plat in "${all_plats[@]}"
  do
    PLATFORM=$plat
    main_platform_logic
  done

  # make sure our container was successful, by checking for the presence of a few essential packages
  # (only if we ran the "all" target)
  PKGNAMES=( wii-curl wii-sdl2 wiiu-curl wiiu-sdl2 switch-curl switch-sdl2 )
  for pkg in "${PKGNAMES[@]}"
  do
    if ! { ${DKP}pacman -Q $pkg > /dev/null; }; then
      echo "Error: $pkg was not installed"
      exit 1
    fi
  done
fi

cleanup_deps