#!/bin/bash

# This is an ubuntu:kinetic dependency helper script for to help set up
# requirements for running make. Primarly this script is used by the CI,
# but is also useful when setting up a new env

# Before running it, you should export the desired PLATFORM environment
# variable ( one of pc, pc-sdl1, switch, 3ds, wii, wiiu, all )
#  eg. PLATFORM=switch ./dependency_helper.sh

# It's may be easier to follow the README.md instructions for the
# desired target and platform that you want to build, but this script may
# help if you are interested in seeing how the dependencies come together
# on various platforms, or how the CI works

main_platform_logic () {
  case "${PLATFORM}" in
    pc)
        setup_deb_sdl_deps
      ;;
    pc-sdl1)
        setup_deb_sdl_deps
      ;;
    switch) # uses libnx
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S devkitA64 libnx switch-tools switch-curl switch-bzip2 switch-freetype switch-libjpeg-turbo switch-libwebp switch-sdl2 switch-sdl2_gfx switch-sdl2_image switch-sdl2_ttf switch-zlib switch-libpng switch-mesa
      ;;
    3ds)    # uses libctru
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S devkitARM 3ds-sdl 3ds-sdl_image 3ds-sdl_mixer 3ds-sdl_gfx 3ds-sdl_ttf libctru citro3d 3dstools 3ds-curl 3ds-mbedtls
      ;;
    wii)    # uses libogc
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S devkitPPC libogc gamecube-tools wii-sdl wii-sdl_gfx wii-sdl_image wii-sdl_mixer wii-sdl_ttf ppc-zlib ppc-bzip2 ppc-freetype ppc-mpg123 ppc-libpng ppc-pkg-config ppc-libvorbisidec ppc-libjpeg-turbo libfat-ogc
      ;;
    wiiu)   # uses wut
        setup_dkp_repo
        sudo ${DKP}pacman --noconfirm -S wut-linux wiiu-sdl2 devkitPPC wiiu-libromfs wiiu-sdl2_gfx wiiu-sdl2_image wiiu-sdl2_ttf wiiu-sdl2_mixer ppc-zlib ppc-bzip2 ppc-freetype ppc-mpg123 ppc-libpng wiiu-curl-headers ppc-pkg-config wiiu-pkg-config wut-tools
      ;;
  esac
}

install_container_deps () {
  apt-get update && apt-get -y install wget sudo libxml2 xz-utils lzma build-essential haveged curl
  haveged &
  touch /trustdb.gpg
}

setup_deb_sdl_deps () {
  # Sets up both sdl1 and sdl2 requirements for ubuntu
  sudo apt-get -y install libsdl2-dev libsdl2-ttf-dev libsdl2-image-dev libsdl2-gfx-dev zlib1g-dev gcc g++ libcurl4-openssl-dev wget git libsdl1.2-dev libsdl-ttf2.0-dev libsdl-image1.2-dev libsdl-gfx1.2-dev

  # FYI for archlinux systems:
  # sudo pacman --noconfirm -S sdl2 sdl2_image sdl2_gfx sdl2_ttf sdl sdl_image sdl_gfx sdl_ttf
}

export DKP=""
export PACMAN_CONFIGURED=""

retry_pacman_sync () {
  # Some continuous integration IPs are blocked by the dkP pacman repo, so if
  # we get a connection error, retry using a different IP.
  # Since we're building a reusable container for the future, this isn't
  # going to overload their servers.
  apt-get -y install strongswan jq

  # load VPN info from environment secret
  declare -a INFO=($VPN_INFO)
  VPN_DATA=${INFO[0]}; VPN_CERT=${INFO[1]}; VPN_USER=${INFO[2]}; VPN_AUTH=${INFO[3]}
  VPN_SERVER=$(curl -s $VPN_DATA | jq -r -c "map(select(.features.ikev2) | .domain) | .[]" | sort -R | head -1)

  echo "$VPN_USER : EAP \"$VPN_AUTH\"" > /etc/ipsec.secrets 
  echo "conn VPN
          keyexchange=ikev2
          dpdaction=clear
          dpddelay=300s
          eap_identity=\"$VPN_USER\"
          leftauth=eap-mschapv2
          left=%defaultroute
          leftsourceip=%config
          right=${VPN_SERVER}
          rightauth=pubkey
          rightsubnet=0.0.0.0/0
          rightid=%${VPN_SERVER}
          rightca=/etc/ipsec.d/cacerts/VPN.pem
          type=tunnel
          auto=add
  " > /etc/ipsec.conf 

  mkdir -p /etc/ipsec.d/cacerts/
  wget $VPN_CERT -O /etc/ipsec.d/cacerts/VPN.der >/dev/null 2>&1
  openssl x509 -inform der -in /etc/ipsec.d/cacerts/VPN.der -out /etc/ipsec.d/cacerts/VPN.pem

  ipsec restart; sleep 5; ipsec up VPN >/dev/null 2>&1
}

cleanup_deps () {
  rm -rf /etc/ipsec.d
  rm -f /etc/ipsec.secrets*
  rm -f /etc/ipsec.conf*
  rm -rf /var/cache/pacman
}

setup_dkp_repo () {
  # if pacman repos have already been configured, don't do it again
  if [ ! -z $PACMAN_CONFIGURED ]; then return; fi
  PACMAN_CONFIGURED="true"

  # NOTICE: These direct URLs for dkp's pacman will become outdated, check https://github.com/devkitPro/pacman/releases/ for the latest install instructions

  mkdir -p /usr/local/share/keyring/
  curl https://apt.devkitpro.org/devkitpro-pub.gpg > /usr/local/share/keyring/devkitpro-pub.gpg
  echo "deb [signed-by=/usr/local/share/keyring/devkitpro-pub.gpg] https://apt.devkitpro.org stable main" > /etc/apt/sources.list.d/devkitpro.list

  apt-get update && apt-get -y install devkitpro-pacman

  DKP="dkp-"

  dkp-pacman --noconfirm -Syu || retry_pacman_sync
}

install_container_deps
main_platform_logic

# handle the "all" target by looping through all platforms
all_plats=( pc pc-sdl1 wiiu switch 3ds wii )
if [[ $PLATFORM == "all" ]]; then
  for plat in "${all_plats[@]}"
  do
    PLATFORM=$plat
    main_platform_logic
  done

  cleanup_deps
fi
