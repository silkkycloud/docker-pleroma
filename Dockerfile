ARG HARDENED_MALLOC_VERSION=9
ARG PLEROMA_VERSION=stable
# you can use stable branch as well, if you don't like develop one

####################################################################################################
## Builder of Hardened Malloc
####################################################################################################
FROM alpine:3.15 as build-malloc

ARG HARDENED_MALLOC_VERSION
ARG CONFIG_NATIVE=false

RUN apk --no-cache add build-base git gnupg libgcc libstdc++ && cd /tmp \
 && wget -q https://github.com/thestinger.gpg && gpg --import thestinger.gpg \
 && git clone --depth 1 --branch ${HARDENED_MALLOC_VERSION} https://github.com/GrapheneOS/hardened_malloc \
 && cd hardened_malloc && git verify-tag $(git describe --tags) \
 && make CONFIG_NATIVE=${CONFIG_NATIVE}

####################################################################################################
## Builder
####################################################################################################
FROM elixir:1.13-alpine AS builder

ARG PLEROMA_VERSION
  
RUN apk add --no-cache \
    ca-certificates \
    git \
    gcc \
    g++ \
    tar \
    libgcc \
    libstdc++ \
    curl \
    musl-dev \
    make \
    cmake \
    file-dev \
    file \
    exiftool \
    imagemagick \
    libmagic \
    ncurses \
    ffmpeg

WORKDIR /pleroma

ADD https://git.pleroma.social/pleroma/pleroma/-/archive/${PLEROMA_VERSION}/pleroma-${PLEROMA_VERSION}.tar.gz /tmp/pleroma-${PLEROMA_VERSION}.tar.gz
RUN tar xvfz /tmp/pleroma-${PLEROMA_VERSION}.tar.gz -C /tmp \
    && cp -r /tmp/pleroma-${PLEROMA_VERSION}/. /pleroma

ENV MIX_ENV=prod \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LD_PRELOAD="/usr/local/lib/libhardened_malloc.so" \
    PLEROMA_CONFIG_PATH=/etc/pleroma/config.exs

COPY --from=build-malloc /tmp/hardened_malloc/libhardened_malloc.so /usr/local/lib/
RUN update-ca-certificates

# Build Pleroma
RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /pleroma

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.15

ARG PLEROMA_VERSION
ARG DATA=/var/lib/pleroma

RUN apk --no-cache add \
    ca-certificates \
    tini \
    ffmpeg \
    postgresql-client \
    exiftool \
    elixir \
    libgcc \
    libstdc++ \
    erlang \
    imagemagick \
    libmagic \
    bash \
    unzip

WORKDIR /pleroma

ENV MIX_ENV=prod \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LD_PRELOAD="/usr/local/lib/libhardened_malloc.so" \
    PLEROMA_CONFIG_PATH=/etc/pleroma/config.exs

COPY --from=build-malloc /tmp/hardened_malloc/libhardened_malloc.so /usr/local/lib/
COPY --from=builder /pleroma /pleroma
RUN update-ca-certificates

# Create persistent data directories
RUN mkdir -p /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static

# Install Soapbox frontend
ADD https://gitlab.com/api/v4/projects/17765635/jobs/artifacts/develop/download?job=build-production /tmp/soapbox-fe.zip
RUN unzip -o /tmp/soapbox-fe.zip -d /var/lib/pleroma \
    && rm -rf /tmp/soapbox-fe.zip

COPY ./Soapbox/. /var/lib/pleroma/static

# Secrets can't be in the docker image, so this config generates them at runtime.
COPY ./docker-config.exs /etc/pleroma/config.exs

COPY ./run-pleroma.sh /pleroma/run-pleroma.sh
RUN chmod +x /pleroma/run-pleroma.sh

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home pleroma \
    && chown -R pleroma:pleroma /pleroma \
    && chown -R pleroma:pleroma /etc/pleroma \
    && chown -R pleroma:pleroma ${DATA}

ENTRYPOINT ["/sbin/tini", "--", "/pleroma/run-pleroma.sh"]

USER pleroma

# VOLUME /var/lib/pleroma/static
VOLUME /var/lib/pleroma/uploads

EXPOSE 4000

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=30s \
    --interval=1m \
    --timeout=5s \
    CMD wget --spider --q http://localhost:4000/api/v1/instance || exit 1

# Image metadata
LABEL org.opencontainers.image.version=${PLEROMA_VERSION}
LABEL org.opencontainers.image.title=Pleroma
LABEL org.opencontainers.image.description="Pleroma is a Twitter-style microblogging server that federates (= exchange messages with) with other servers like Mastodon. So you can stay in control of your online identity, but still talk with people on larger servers."
LABEL org.opencontainers.image.url=https://social.silkky.cloud
LABEL org.opencontainers.image.vendor="Silkky.Cloud"
LABEL org.opencontainers.image.licenses=Unlicense
LABEL org.opencontainers.image.source="https://github.com/silkkycloud/docker-pleroma"
