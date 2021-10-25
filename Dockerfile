# -------------- Build-time variables --------------
ARG PLEROMA_VERSION=stable
ARG DATA=/var/lib/pleroma

ARG ALPINE_VERSION=edge
ARG HARDENED_MALLOC_VERSION=12

ARG UID=991
ARG GID=991
# ---------------------------------------------------
### Build Hardened Malloc
ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as build-malloc

ARG HARDENED_MALLOC_VERSION
ARG CONFIG_NATIVE=false

RUN apk --no-cache add build-base git gnupg && cd /tmp \
 && wget -q https://github.com/thestinger.gpg && gpg --import thestinger.gpg \
 && git clone --depth 1 --branch ${HARDENED_MALLOC_VERSION} https://github.com/GrapheneOS/hardened_malloc \
 && cd hardened_malloc && git verify-tag $(git describe --tags) \
 && make CONFIG_NATIVE=${CONFIG_NATIVE}

### Build Pleroma (production environment)
ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION} as pleroma

COPY --from=build-malloc /tmp/hardened_malloc/libhardened_malloc.so /usr/local/lib/

ARG PLEROMA_VERSION
ARG DATA

ARG UID
ARG GID

ENV MIX_ENV=prod \
    LD_PRELOAD="/usr/local/lib/libhardened_malloc.so"

WORKDIR /pleroma

# Install runtime dependencies
RUN apk --no-cache add \
    ca-certificates \
    ffmpeg \
    file \
    git \
    icu-libs \
    libidn \
    gcc \
    g++ \
    musl-dev \
    make \
    exiftool \
    elixir \
    erlang \
    tini \
    imagemagick \
    libmagic \
    ncurses \
    cmake \ 
    file-dev\
    libxml2 \
    unzip \
    libxslt \
    libpq \
    openssl \
    protobuf \
    s6 \
    tzdata \
    yaml \
    readline \
    gcompat \
# Install build dependencies
 && apk --no-cache add -t build-dependencies \
    build-base \
    icu-dev \
    libidn-dev \
    libtool \
    unzip \
    libxml2-dev \
    elixir \
    erlang \
    gcc \
    g++ \
    musl-dev \
    make \
    exiftool \
    elixir \
    erlang \
    imagemagick \
    libmagic \
    ncurses \
    cmake \ 
    file-dev\
    libxslt-dev \
    postgresql-dev \
    protobuf-dev \
# Install Pleroma
&& git clone -b develop https://git.pleroma.social/pleroma/pleroma.git /pleroma \
    && git checkout ${PLEROMA_VER} 
# Config
RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /pleroma
COPY ./config.exs /etc/pleroma/config.exs
# Prepare pleroma user
 && adduser -g ${GID} -u ${UID} --disabled-password --gecos "" pleroma \
 && chown -R pleroma:pleroma /pleroma
 && mkdir -p /etc/pleroma \
    && chown -R pleroma /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R pleroma ${DATA}
# Drop the bash script
COPY *.sh /pleroma
# Get Soapbox
ADD https://gitlab.com/api/v4/projects/17765635/jobs/artifacts/develop/download?job=build-production /tmp/soapbox-fe.zip
RUN chown pleroma /tmp/soapbox-fe.zip

ENTRYPOINT ["/sbin/tini", "--"]

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=2m \
    --interval=5m \
    CMD curl --fail http://localhost:4000/api/v1/instance || exit 1

CMD [ "/pleroma/run-pleroma.sh" ]
