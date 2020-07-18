FROM archlinux

WORKDIR /code
COPY dependency_helper.sh /code

ARG VPN_INFO
ENV PLATFORM all

RUN ./dependency_helper.sh

CMD make
