FROM archlinux

WORKDIR /code
COPY dependency_helper.sh /code

ENV PLATFORM all

RUN ./dependency_helper.sh

CMD make