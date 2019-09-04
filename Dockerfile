FROM alpine:3.8.4 AS build_stage

MAINTAINER dewaldabrie@gmail.com

# Install pandoc - required by the latest version of pgbouncer
RUN apk update \
  && apk add ca-certificates wget \
  && wget -O /tmp/pandoc.tar.gz https://github.com/jgm/pandoc/releases/download/2.2.3.2/pandoc-2.2.3.2-linux.tar.gz \
  && tar xvzf /tmp/pandoc.tar.gz --strip-components 1 -C /usr/local/ \
  && update-ca-certificates \
  && apk del wget \
  && rm /tmp/pandoc.tar.gz

ARG PUID=1005
ARG PGID=1005

RUN addgroup -g ${PGID} pandoc \
 && adduser -D -u ${PUID} -G pandoc pandoc

WORKDIR /
RUN apk --update add git python py-pip build-base automake libtool m4 autoconf libevent-dev openssl-dev c-ares-dev
RUN pip install docutils
RUN git clone https://github.com/pgbouncer/pgbouncer.git src
WORKDIR /src
RUN git checkout tags/pgbouncer_1_11_0

WORKDIR /bin
RUN ln -s ../usr/bin/rst2man.py rst2man

WORKDIR /src
RUN mkdir /pgbouncer
RUN git submodule init
RUN git submodule update
RUN ./autogen.sh
RUN	./configure --prefix=/pgbouncer --with-libevent=/usr/lib
RUN make
RUN make install
RUN ls -R /pgbouncer

FROM alpine:latest
RUN apk --update add libevent openssl c-ares
WORKDIR /
COPY --from=build_stage /pgbouncer /pgbouncer
ADD entrypoint.sh ./
ENTRYPOINT ["./entrypoint.sh"]
