FROM ghcr.io/wkronmiller/ardupilot:master

USER root

# Install Gazebo dependencies
RUN echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/gazebo-stable.list
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -

# Install Gazebo dependencies and supervisor
RUN apt-get update && \
  apt-get install -y \
  supervisor \
  libgz-sim8-dev rapidjson-dev \
  libopencv-dev libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-libav gstreamer1.0-gl \
  && rm -rf /var/lib/apt/lists/*

USER ardupilot

RUN mkdir -p /ardupilot
WORKDIR /ardupilot


# Set up Ardupilot simulator
RUN git clone --depth 1 https://github.com/ArduPilot/ardupilot.git source && cd source && git submodule update --init --recursive --depth 1

# Set up Gazebo plugin
RUN git clone --depth 1 https://github.com/ArduPilot/ardupilot_gazebo plugin
ENV GZ_VERSION=harmonic
RUN cd plugin && mkdir build && cd build && \
  cmake .. -DMAKE_BUILD_TYPE=RelWithDebInfo \
   && make -j$(nproc)
ENV GZ_SIM_SYSTEM_PLUGIN_PATH=/ardupilot/plugin/build

WORKDIR /ardupilot/source

# Use BuildKit cache for ccache between builds
RUN --mount=type=cache,target=/home/ardupilot/.ccache \
    ./modules/waf/waf-light configure --board sitl \
 && ./modules/waf/waf-light rover \
 && ./modules/waf/waf-light copter \
 && ./modules/waf/waf-light plane

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV HEADLESS=1
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
