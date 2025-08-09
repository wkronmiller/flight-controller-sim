# ArduPilot SITL Docker Simulator

This project provides a Dockerized environment for running the ArduPilot Software-in-the-Loop (SITL) simulator. It simplifies the setup process and allows you to run the simulator in a containerized and reproducible way.

The current configuration is set up to simulate an ArduPilot Rover.

## Prerequisites

Before you begin, ensure you have the following installed:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

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
    This will start the simulator in the foreground. The `supervisord.conf` file is configured to start the Rover simulation by default.

## Connecting to the Simulator

Once the container is running, the ArduPilot SITL instance will be waiting for a Ground Control Station (GCS) connection.

-   **Protocol:** UDP
-   **Host:** `localhost`
-   **Port:** `14550`

You can use a GCS like [QGroundControl](http://qgroundcontrol.com/) or [Mission Planner](https://ardupilot.org/planner/) to connect to the running simulation. Simply configure it to connect to the UDP port specified above.

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

    **Example for Copter:**
    ```ini
    [program:copter]
    command=bash -c "/ardupilot/source/Tools/autotest/sim_vehicle.py --vehicle=Copter --frame=quad --console --out=0.0.0.0:14550 --no-mavproxy --no-rebuild"
    autostart=true
    autorestart=true
    stdout_logfile=/dev/stdout
    stdout_logfile_maxbytes=0
    stderr_logfile=/tmp/Copter.log
    user=ardupilot
    ```

3.  **Rebuild and Run:**
    After modifying the configuration, rebuild the Docker image and restart the container for the changes to take effect:
    ```bash
    docker-compose build
    docker-compose up
    ```

