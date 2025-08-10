# ArduPilot SITL Docker Simulator for Cube Orange

The primary purpose of this repository is to provide a SITL (Software-in-the-Loop) simulator for an ArduPilot-powered flight controller like the Cube Orange, for use in other projects.

The Docker image contains the ArduPilot SITL environment integrated with Gazebo Harmonic for realistic physics-based simulation.

## Quick Start

You can pull the pre-built image directly from GitHub Container Registry:

```bash
docker pull ghcr.io/wkronmiller/flight-controller-sim:master
```

## Image Overview

This Docker image is designed to provide a complete and ready-to-use ArduPilot SITL simulation environment.

- **Base Image**: Built on `ghcr.io/wkronmiller/ardupilot:master`.
- **ArduPilot Vehicles**: Includes SITL executables for `Copter`, `Plane`, and `Rover`, compiled for the `sitl` board.
- **Gazebo Integration**: Comes with the ArduPilot Gazebo plugin pre-built for Gazebo Harmonic. It uses a JSON interface for communication between ArduPilot and Gazebo.
- **Process Management**: Uses `supervisord` to run the SITL process, with the default configuration set to launch the Rover simulation.
- **Networking**: The `compose.yml` is configured with `network_mode: host` to simplify connections with a GCS and a Gazebo instance running on the host or local network.

## How to Use

### With Docker Compose

The recommended way to run the simulator is with Docker Compose, as it uses the settings defined in `compose.yml`.

1.  **Start the Simulator:**
    ```bash
    docker-compose up
    ```
    If you haven't built the image locally, compose will pull it from the registry. This will start the simulator in the foreground. The `supervisord.conf` file is configured to start the Rover simulation by default with Gazebo integration enabled (`-f gazebo-rover --model JSON`).

2.  **Build Locally (Optional):**
    If you need to make changes to the `Dockerfile` or configuration, you can build the image locally:
    ```bash
    docker-compose build
    ```

### With Docker Run

If you prefer not to use Docker Compose, you can run the image directly. Using `host` networking is crucial for communication with Gazebo and your GCS.

```bash
docker run --rm -it --network=host ghcr.io/wkronmiller/flight-controller-sim:master
```

## Gazebo Integration

This container is designed to work with a Gazebo instance running Gazebo Harmonic. The integration includes:

- **ArduPilot Gazebo Plugin**: Pre-built and configured for seamless communication.
- **Physics Simulation**: Realistic vehicle dynamics through Gazebo's physics engine.

### Gazebo Setup

1. **Install Gazebo Harmonic** on your host system or another machine.
2. **Download ArduPilot Gazebo Models**:
   ```bash
   git clone https://github.com/ArduPilot/ardupilot_gazebo
   export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$(pwd)/ardupilot_gazebo/models:$(pwd)/ardupilot_gazebo/worlds
   ```
3. **Launch Gazebo** with an ArduPilot-compatible world:
   ```bash
   gz sim -v4 -r iris_runway.sdf
   ```

## Connecting to the Simulator

Once the container is running, the ArduPilot SITL instance will be waiting for connections.

### Ground Control Station (GCS) Connection
-   **Protocol:** UDP
-   **Host:** `localhost` (or the host IP if running Docker on a different machine)
-   **Port:** `14550`

You can use a GCS like [QGroundControl](http.qgroundcontrol.com/) or [Mission Planner](https://ardupilot.org/planner/) to connect to the running simulation.

### Gazebo Connection
The simulator automatically attempts to connect to a running Gazebo instance using:
-   **Protocol:** JSON over UDP
-   **Port:** `14551` (for internal communication to Gazebo)

### Complete Workflow
1. Start Gazebo with an ArduPilot world.
2. Launch this Docker container using `docker-compose up` or `docker run`.
3. Connect your GCS to `localhost:14550`.
4. The vehicle in Gazebo will respond to commands from your GCS with realistic physics.

## Customization

This simulator is configured to run ArduPilot Rover by default, but it can be adapted to run other vehicle types like Copter or Plane.

1.  **Verify the Build Target in `Dockerfile`:**
    The `Dockerfile` already compiles `rover`, `copter`, and `plane`. If you need another vehicle, you'll have to add it to the build steps.
    ```dockerfile
    # ...
    RUN --mount=type=cache,target=/home/ardupilot/.ccache \
        ./modules/waf/waf-light configure --board sitl \
     && ./modules/waf/waf-light rover \
     && ./modules/waf/waf-light copter \
     && ./modules/waf/waf-light plane
    # ...
    ```

2.  **Update `supervisord.conf`:**
    Modify the `supervisord.conf` file to launch your desired vehicle. For example, to switch from Rover to Copter, you would change the `[program:rover]` section.

    **Example for Copter with Gazebo:**
    ```ini
    [program:copter]
    command=bash -c "/ardupilot/source/Tools/autotest/sim_vehicle.py --vehicle=Copter --frame=gazebo-iris --console --out=0.0.0.0:14550 --no-mavproxy --no-rebuild --out=udp:127.0.0.1:14551 -f gazebo-iris --model JSON"
    autostart=true
    autorestart=true
    stdout_logfile=/dev/stdout
    stdout_logfile_maxbytes=0
    stderr_logfile=/tmp/Copter.log
    user=ardupilot
    ```

3.  **Rebuild and Run:**
    After modifying the configuration, rebuild the Docker image and restart the container:
    ```bash
    docker-compose build
    docker-compose up
    ```

## Troubleshooting

### Gazebo Connection Issues
- Ensure Gazebo is running before starting the container.
- Check that the Gazebo world contains ArduPilot-compatible models.
- Verify network connectivity if running Gazebo on a remote machine.
- Check container logs for JSON communication errors.

### Environment Variables
The container sets the following Gazebo-related environment variables:
- `GZ_VERSION=harmonic`: Specifies Gazebo Harmonic version.
- `GZ_SIM_SYSTEM_PLUGIN_PATH=/ardupilot/plugin/build`: Path to ArduPilot Gazebo plugin.
- `HEADLESS=1`: Runs in headless mode (no GUI).