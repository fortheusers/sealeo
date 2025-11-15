FROM ghcr.io/fortheusers/sealeo:latest
# base ourselves off the "full" sealeo image, and then update it (evolve it?)
RUN dkp-pacman -Syu --noconfirm