# ArduPilot SITL Docker Simulator with Gazebo Integration

This project provides a Dockerized environment for running the ArduPilot Software-in-the-Loop (SITL) simulator with Gazebo integration. It simplifies the setup process and allows you to run the simulator in a containerized and reproducible way while connecting to a remote Gazebo instance for realistic physics simulation.

The current configuration is set up to simulate an ArduPilot Rover with Gazebo physics integration.

## Prerequisites

Before you begin, ensure you have the following installed:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Gazebo Harmonic](https://gazebosim.org/docs/harmonic/install) (for physics simulation)

## Gazebo Integration

This container is designed to work with a remote Gazebo instance running Gazebo Harmonic. The integration includes:

- **ArduPilot Gazebo Plugin**: Pre-built and configured for seamless communication
- **Gazebo Harmonic Support**: Compatible with the latest Gazebo version
- **JSON Model Interface**: Uses JSON protocol for vehicle state communication
- **Physics Simulation**: Realistic vehicle dynamics through Gazebo's physics engine

### Gazebo Setup

1. **Install Gazebo Harmonic** on your host system or another machine
2. **Download ArduPilot Gazebo Models**: 
   ```bash
   git clone https://github.com/ArduPilot/ardupilot_gazebo
   export GZ_SIM_RESOURCE_PATH=$GZ_SIM_RESOURCE_PATH:$(pwd)/ardupilot_gazebo/models:$(pwd)/ardupilot_gazebo/worlds
   ```
3. **Launch Gazebo** with an ArduPilot-compatible world:
   ```bash
   gz sim -v4 -r iris_runway.sdf
   ```

### Network Configuration

The container expects Gazebo to be accessible for JSON communication. If running Gazebo on a different machine, ensure network connectivity between the container and Gazebo host.

## How to Use

1.  **Build the Docker image:**
    ```bash
    docker-compose build
    ```
    This command builds the Docker image using the provided `Dockerfile`. It will download the ArduPilot source code and compile the SITL executables for Rover, Copter, and Plane.

2.  **Run the Simulator:**
    ```bash
    docker-compose up
    ```
    This will start the simulator in the foreground. The `supervisord.conf` file is configured to start the Rover simulation by default with Gazebo integration enabled (`-f gazebo-rover --model JSON`).

## Connecting to the Simulator

Once the container is running, the ArduPilot SITL instance will be waiting for connections from both a Ground Control Station (GCS) and Gazebo.

### Ground Control Station Connection
-   **Protocol:** UDP
-   **Host:** `localhost`
-   **Port:** `14550`

You can use a GCS like [QGroundControl](http://qgroundcontrol.com/) or [Mission Planner](https://ardupilot.org/planner/) to connect to the running simulation.

### Gazebo Connection
The simulator automatically connects to Gazebo using:
-   **Protocol:** JSON over UDP
-   **Port:** `14551` (internal communication)
-   **Frame:** `gazebo-rover` (configured for Gazebo physics integration)

### Complete Workflow
1. Start Gazebo with an ArduPilot world
2. Launch this Docker container
3. Connect your GCS to `localhost:14550`
4. The vehicle in Gazebo will respond to commands from your GCS with realistic physics

## Customization

This simulator is configured to run ArduPilot Rover by default, but it can be adapted to run other vehicle types like Copter or Plane.

1.  **Verify the Build Target in `Dockerfile`:**
    First, ensure that the desired vehicle type is being compiled in the `Dockerfile`. This project's `Dockerfile` already compiles `rover`, `copter`, and `plane`:
    ```dockerfile
    # ...
    RUN --mount=type=cache,target=/home/ardupilot/.ccache \
        ./modules/waf/waf-light configure --board sitl \
     && ./modules/waf/waf-light rover \
     && ./modules/waf/waf-light copter \
     && ./modules/waf/waf-light plane
    # ...
    ```
    If your desired vehicle is not listed here, you will need to add it.

2.  **Update `supervisord.conf`:**
    Modify the `supervisord.conf` file to launch your desired vehicle. For example, to switch from Rover to Copter, you would change the `[program:rover]` section to something like this:

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

    **Example for Plane with Gazebo:**
    ```ini
    [program:plane]
    command=bash -c "/ardupilot/source/Tools/autotest/sim_vehicle.py --vehicle=Plane --frame=gazebo-zephyr --console --out=0.0.0.0:14550 --no-mavproxy --no-rebuild --out=udp:127.0.0.1:14551 -f gazebo-zephyr --model JSON"
    autostart=true
    autorestart=true
    stdout_logfile=/dev/stdout
    stdout_logfile_maxbytes=0
    stderr_logfile=/tmp/Plane.log
    user=ardupilot
    ```

    **Key Gazebo Integration Parameters:**
    - `-f gazebo-[vehicle]`: Specifies the Gazebo frame type
    - `--model JSON`: Uses JSON protocol for Gazebo communication
    - `--out=udp:127.0.0.1:14551`: Internal communication port for Gazebo

3.  **Rebuild and Run:**
    After modifying the configuration, rebuild the Docker image and restart the container for the changes to take effect:
    ```bash
    docker-compose build
    docker-compose up
    ```

## Troubleshooting

### Gazebo Connection Issues
- Ensure Gazebo is running before starting the container
- Check that the Gazebo world contains ArduPilot-compatible models
- Verify network connectivity if running Gazebo on a remote machine
- Check container logs for JSON communication errors

### Environment Variables
The container sets the following Gazebo-related environment variables:
- `GZ_VERSION=harmonic`: Specifies Gazebo Harmonic version
- `GZ_SIM_SYSTEM_PLUGIN_PATH=/ardupilot/plugin/build`: Path to ArduPilot Gazebo plugin
- `HEADLESS=1`: Runs in headless mode (no GUI)

### Plugin Dependencies
The container includes all necessary Gazebo dependencies:
- `libgz-sim8-dev`: Gazebo simulation library
- `rapidjson-dev`: JSON parsing for communication
- OpenCV and GStreamer libraries for advanced features

