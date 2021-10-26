ARG PLEROMA_VERSION=stable
ARG DATA=/var/lib/pleroma

ARG HARDENED_MALLOC_VERSION=8

ARG UID=991
ARG GID=991

####################################################################################################
## Build Hardened Malloc
####################################################################################################
FROM alpine:edge as build-malloc

ARG HARDENED_MALLOC_VERSION
ARG CONFIG_NATIVE=false

RUN apk --no-cache add build-base git gnupg && cd /tmp \
    && wget -q https://github.com/thestinger.gpg && gpg --import thestinger.gpg \
    && git clone --depth 1 --recursive --branch ${HARDENED_MALLOC_VERSION} https://github.com/GrapheneOS/hardened_malloc \
    && cd hardened_malloc && git verify-tag $(git describe --tags) \
    && make CONFIG_NATIVE=${CONFIG_NATIVE}


####################################################################################################
## Builder
####################################################################################################
FROM alpine:edge as build

COPY --from=build-malloc /tmp/hardened_malloc/libhardened_malloc.so /usr/local/lib/

ARG PLEROMA_VERSION
ARG DATA

WORKDIR /pleroma


# Install build dependencies
RUN apk --no-cache add -t build-dependencies \
    ca-certificates \
    ffmpeg \
    file \
    libstdc++ \
    libgcc \
    tini \
    openssl \
    git \
    build-base \
    bash \
    libidn-dev \
    libtool \
    curl \
    unzip \
    libxml2-dev \
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
    file-dev \
    libxslt-dev \ 
    protobuf-dev

ENV MIX_ENV=prod \
    LD_PRELOAD="/usr/local/lib/libhardened_malloc.so"  

# Download Pleroma
RUN git clone -b develop https://git.pleroma.social/pleroma/pleroma.git /pleroma \
    && git checkout ${PLEROMA_VERSION}

# Build
RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /pleroma


####################################################################################################
## Final image
####################################################################################################
FROM alpine:edge

COPY --from=build-malloc /tmp/hardened_malloc/libhardened_malloc.so /usr/local/lib/

COPY --from=build /pleroma /pleroma

ARG DATA

ARG UID
ARG GID

WORKDIR /pleroma

# Install runtime dependencies
RUN apk --no-cache add \
    ca-certificates \
    ffmpeg \
    file \
    libstdc++ \
    libgcc \
    git \
    bash \
    musl-dev \
    postgresql-client \
    make \
    exiftool \
    elixir \
    erlang \
    tini \
    curl \
    imagemagick \
    ncurses \
    cmake \ 
    file-dev \
    unzip \
    openssl

ENV MIX_ENV=prod \
    LD_PRELOAD="/usr/local/lib/libhardened_malloc.so"  

COPY ./config.exs /etc/pleroma/config.exs

# Prepare pleroma user
RUN adduser -g $GID -u $UID --disabled-password --gecos "" pleroma
RUN chown -R pleroma:pleroma /pleroma \
    && mkdir -p /etc/pleroma \
    && chown -R pleroma /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R pleroma ${DATA}

# Drop the bash script
COPY *.sh /pleroma
RUN chmod 777 /pleroma/run-pleroma.sh

# Get Soapbox
ADD https://gitlab.com/api/v4/projects/17765635/jobs/artifacts/develop/download?job=build-production /tmp/soapbox-fe.zip
RUN chown pleroma /tmp/soapbox-fe.zip

ENTRYPOINT ["/sbin/tini", "--"]

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=1m \
    --interval=3m \
    CMD curl --fail http://localhost:4000/api/v1/instance || exit 1

CMD [ "/pleroma/run-pleroma.sh" ]
