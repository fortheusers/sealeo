# sealeo
A docker image to facilitate building homebrew apps across multi-platforms. Based on [Spheal](https://gitlab.com/4tu/spheal), but has support for both amd64 and arm64 architectures.

<img src="https://user-images.githubusercontent.com/2467473/186280808-80ce15d7-f6d7-454a-82cb-21226a598a31.png" alt="baby" width="200" />

Sealeo's primary goal is to just bundle together all of the needed deps to build [Chesto](https://github.com/fortheusers/chesto) projects (such as [hb-appstore](http://github.com/fortheusers/hb-appstore)) across multiple different platforms. These dependencies are rolled up katamari-style in a docker image and are then available via CI or locally to any projects that may need them. This stems from a desire to just get one environment where hb-appstore can be built cross-platform without having to worry about what is or isn't installed.

Building is deterministic since the deps are locked into the image, and also potentially faster as every single job in a CI context no longer has to re-fetch its own dependencies.

## usage
Can be executed from the root of your [chesto](https://github.com/fortheusers/chesto) git project. Export the PLATFORM env variable to point to the target that you want to build for.

```
export PLATFORM=switch    # or wiiu, 3ds, wii, pc, pc-sdl1
docker run -v $(pwd):/code -it ghcr.io/fortheusers/sealeo "make $PLATFORM"
```

On Windows, you may need to replace `$(pwd)` with `${PWD}`, or `%CD%`.

To enter a shell in the container without running make, you can run bash:
```
docker run -v $(pwd):/code -it ghcr.io/fortheusers/sealeo /bin/bash
```

This can be useful for non-Chesto projects or to debug code interactively.

## what's inside
The image is based on `debian`, inside is the following:
- sdl1 deps/portlibs for PC, 3ds, wii
- sdl2 deps/portlibs for PC, wiiu, switch
- dkp-pacman configured with dkP's repos
- dkP toolchains: devkitA64, devkitARM, devkitPPC
- platform libs: libnx, libctru, libogc, wut

If you don't need all of the above in one image, you're better off trying out one of [dkP's own containers](https://hub.docker.com/u/devkitpro/) and using that as a base. Sealeo does not use this approach in favor of working across multiple architectures, having all toolchains in one image, and being able to control more about what makes it into the image in the future.

The homebrew targets are only possible thanks to dkP's toolchains, you can [support them on Patreon](https://www.patreon.com/devkitPro) for their efforts.
