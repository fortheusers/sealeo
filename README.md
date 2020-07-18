# spheal
By all accounts this project should be named Wailmer, yet here we are rolling with the punches!

![baby](https://cdn.bulbagarden.net/upload/thumb/9/9f/363Spheal.png/100px-363Spheal.png)

Spheal's primary goal is to just bundle together all of the needed deps to build Chesto projects (such as hb-appstore) across multiple different platforms. These dependencies are rolled up katamari-style in a docker image and are then available via CI or locally to any projects that may need them. This stems from a desire to just get one environment where hb-appstore can be built cross-platform without having to worry about what is or isn't installed.

Building is deterministic since the deps are locked into the image, and also potentially faster as every single job in a CI context no longer has to re-fetch its own dependencies.

## usage
Can be executed from the root of your [chesto](https://gitlab.com/4tu/chesto) git project. Export the PLATFORM env variable to point to the target that you want to build for.

**TODO:** add an `all` makefile target that goes through all the other ones

```
export PLATFORM=switch    # or wiiu, 3ds, wii, pc, pc-sdl1
docker run -v $(pwd):/code -it registry.gitlab.com/4tu/spheal "cd /code && make -f Makefile.$PLATFORM"
```

## what's inside
The image is based on `archlinux`, inside is the following:
- sdl1 deps/portlibs for PC, 3ds, wii
- sdl2 deps/portlibs for PC, wiiu, switch
- pacman configured with fling and dkP's repos
- dkP toolchains: devkitA64, devkitARM, devkitPPCt
- platform libs: libnx, libctru, libogc, wut

If you don't need all of the above in one image, you're better off trying out one of [dkP's own containers](https://hub.docker.com/u/devkitpro/). If it doesn't have all the tools in it that you need, it could be used as a base for your own image that you can use in your own CI. Spheal does not use this approach in favor of using arch's native pacman, and being able to control more about what makes it into the image in the future.
