FROM ghcr.io/wkronmiller/ardupilot:master

USER root
RUN apt-get update && apt-get install -y supervisor && rm -rf /var/lib/apt/lists/*
USER ardupilot

RUN mkdir -p /ardupilot
WORKDIR /ardupilot
RUN git clone https://github.com/ArduPilot/ardupilot.git source && cd source && git submodule update --init --recursive

WORKDIR /ardupilot/source

# Use BuildKit cache for ccache between builds
RUN --mount=type=cache,target=/home/ardupilot/.ccache \
    ./modules/waf/waf-light configure --board sitl \
 && ./modules/waf/waf-light rover \
 && ./modules/waf/waf-light copter \
 && ./modules/waf/waf-light plane

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
