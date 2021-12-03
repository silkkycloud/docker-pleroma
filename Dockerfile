ARG PLEROMA_VERSION=2.4.1

####################################################################################################
## Builder
####################################################################################################
FROM elixir:1.12-alpine AS builder

ARG PLEROMA_VERSION

ENV MIX_ENV=prod \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    PLEROMA_CONFIG_PATH=/etc/pleroma/config.exs
  
RUN apk add --no-cache \
    ca-certificates \
    git \
    gcc \
    g++ \
    tar \
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

ADD https://git.pleroma.social/pleroma/pleroma/-/archive/v${PLEROMA_VERSION}/pleroma-v${PLEROMA_VERSION}.tar.gz /tmp/pleroma-v${PLEROMA_VERSION}.tar.gz
RUN tar xvfz /tmp/pleroma-v${PLEROMA_VERSION}.tar.gz -C /tmp \
    && cp -r /tmp/pleroma-v${PLEROMA_VERSION}/. /pleroma

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

ARG DATA=/var/lib/pleroma

ENV MIX_ENV=prod \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    PLEROMA_CONFIG_PATH=/etc/pleroma/config.exs 

RUN apk --no-cache add \
    ca-certificates \
    tini \
    ffmpeg \
    postgresql-client \
    exiftool \
    elixir \
    erlang \
    imagemagick \
    libmagic \
    bash \
    unzip

WORKDIR /pleroma

COPY --from=builder /pleroma /pleroma

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
# This config will be imported
COPY ./config.exs /var/lib/pleroma/config.exs

COPY ./run-pleroma.sh /pleroma/run-pleroma.sh
RUN chmod +x /pleroma/run-pleroma.sh

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home pleroma \
    && chown -R pleroma:pleroma /pleroma \
    && chown -R pleroma:pleroma /etc/pleroma \
    && chown -R pleroma:pleroma ${DATA}

ENTRYPOINT ["/sbin/tini", "--"]

USER pleroma

CMD ["/pleroma/run-pleroma.sh"]

# VOLUME /var/lib/pleroma/static
VOLUME /var/lib/pleroma/uploads

EXPOSE 4000

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=30s \
    --interval=1m \
    --timeout=5s \
    CMD wget --spider --q http://localhost:4000/api/v1/instance || exit 1
