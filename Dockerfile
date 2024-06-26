FROM alpine:latest AS td_build

ARG OPENGFX_VERSION="7.1"
ARG OPENTTD_VERSION="13.3"

RUN apk update \
    && apk upgrade \
    && apk add \
    build-base \
    unzip \
    wget \
    git \
    libc-dev \
    cmake \
    patch \
    xz-dev \
    pkgconfig \
    zlib \
    libpng \
    lzo \
    ninja \
    musl-dev gcc nlohmann-json libcurl sdl2 libpng libgcc libtool linux-headers g++ curl

RUN mkdir -p /config \
    && mkdir -p /main

RUN mkdir -p /tmp/build
#COPY ${OPENTTD_SRC} /tmp/src
COPY --from=openttd . /tmp/src
WORKDIR /tmp/build

ARG TARGETPLATFORM
ARG TARGETARCH
RUN cd /tmp/build && \
    cmake \
    -B build \
    -D OPTION_DEDICATED=ON \
    -D OPTION_INSTALL_FHS=OFF \
    -D CMAKE_BUILD_TYPE=release \
    -D GLOBAL_DIR=/app \
    -D PERSONAL_DIR=/ \
    -D CMAKE_BINARY_DIR=bin \
    -D CMAKE_INSTALL_PREFIX=/app \
    -G Ninja \
    ../src 

RUN echo Num Processors: $(nproc)
RUN ninja -C build -j$(nproc) 
RUN ninja -C build install

# Add the latest graphics files
## Install OpenGFX
RUN mkdir -p /app/data/baseset/ \
    && cd /app/data/baseset/ \
    && wget -q https://cdn.openttd.org/opengfx-releases/${OPENGFX_VERSION}/opengfx-${OPENGFX_VERSION}-all.zip \
    && unzip opengfx-${OPENGFX_VERSION}-all.zip \
    && tar -xf opengfx-${OPENGFX_VERSION}.tar \
    && rm -rf opengfx-*.tar opengfx-*.zip


FROM alpine:latest
ARG OPENTTD_VERSION="13.3"
RUN mkdir -p /usr/games/openttd/ \
    && apk --no-cache add tini xz libstdc++ libgcc zlib musl

COPY --from=td_build /app /usr/games/openttd
COPY --chown=1000:1000 --chmod=+x openttd.sh /openttd.sh
RUN chmod +x /openttd.sh

ENV PUID=1000
ENV PGID=1000

EXPOSE 3979/tcp 3979/udp

ENTRYPOINT ["tini", "-vv", "--", "/openttd.sh"]
