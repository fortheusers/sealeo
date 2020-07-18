# spheal

By all accounts this project should be named Wailmer, yet here we are rolling with the punches!

## goal
Spheal's primary goal is to just bundle together all of the needed deps to build Chesto projects (such as hb-appstore) across multiple different platforms. These dependencies are rolled up katamari-style and are then available via CI or locally to any projects that may need them. This stems from a desire to just get one environment where we can build hb-appstore without having to worry about what is or isn't installed.

Building is deterministic since the deps are locked in, and also potentially faster as every single job no longer has to re-fetch its own dependencies.