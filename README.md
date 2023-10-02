# debian10-rtl-suite Docker Image

This repository contains a Docker image generation script for creating a Debian 10-based Docker image that includes various tools commonly used in RTL (Register-Transfer Level) design. Please note that this repository only provides the script to generate the Docker image, and you will need to download, install, and generate the required RTL design tools yourself. After obtaining these tools, you can create a tar.gz archive to be used in the Docker image.

## Included RTL Design Tools

The Debian 10-based Docker image generated using this script includes the following RTL design tools:

1. **Quartus Prime + QuestaSim (quartus_22.1std.tar.gz)**
  - Version: 22.1std
  - Load Module Command: `module load quartus/22.1std`

2. **Quartus II + ModelSim (quartus_13.tar.gz)**
  - Version: 13.0sp1
  - Load Module Command: `module load quartus/13.0sp1`

3. **Vivado ML Standard Edition (vivado.tar.gz)**
  - Version: 2023.1
  - Load Module Command: `module load vivado`

4. **oss-cad-suite (oss-cad-suite-linux-x64-20230922.tgz)**
  - Version: 20230922
  - Load Module Command: `module load oss-cad-suite`

5. **Synopsys Tools (synopsys.tar.gz)**
  - Load Module Command: `module load synopsys`
    - **Design Compiler**
      - Version: L-2016.03-SP1
    - **VCS MX**
      - Version: O-2018.09-SP2-2
    - **Verdi**
      - Version: O-2018.09-SP2-2
    - **VC Static**
      - Version: O-2018.09-SP2-2
    - **Formality**
      - Version: O-2018.06-SP1
    - **Library Compiler**
      - Version: M-2016.12
    - **PrimeTime**
      - Version: M-2016.12-SP1
    - **IC Compiler**
      - Version: L-2016.03-SP1
    - **HSPICE**
      - Version: L-2016.06-SP1
    - **CustomExplorer**
      - Version: K-2015.06

## Usage

### Building Image

To create the Debian 10-based Docker image with these RTL design tools, follow these steps:

1. Download and install the required RTL design tools mentioned above. Ensure that they are working correctly on your system.

2. Generate a tar.gz archive containing these tools. You can use the following command as a reference:

   ```bash
   tar -czvf rtl-tools.tar.gz /path/to/rtl-tools
   ```

   Replace `/path/to/rtl-tools` with the actual path to the directory containing the RTL design tools.

3. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/superzeldalink/debian10-rtl-suite.git
   ```

4. Copy the `rtl-tools.tar.gz` archive generated in step 2 into the cloned repository directory.

5. Build the Docker image using:

   ```bash
   make build
   ```

6. Once the Docker image is built, you can run a container using it:

   ```bash
   make run
   ```

   You now have access to the RTL design tools within the Docker container.

Please note that this Docker image is a starting point, and you may need to customize it further to suit your specific requirements or add additional RTL design tools as needed.

### Run
#### Available Modes

- RDP + SSH (default): Port 3309.
- VNC + SSH: Specify vnc as the mode, with ports 5900 and 5901 for VNC (novnc).
  - Default resolution: 1920x1080x24.
  - Custom resolution: Append the desired resolution to the vnc mode, e.g., vnc=1280x720x24 (width x height x color depth).
- SSH only: Specify ssh as the mode, with port 22.
- SSH also supports X11 Forwarding. Use the following command to connect via SSH:

    ```bash
    ssh -Y root@localhost -p <port>
    ```

Please replace <port> with the appropriate port number based on your chosen mode.

#### Running the container

##### Running with RDP and SSH (Default)

This command runs the container with RDP, VNC, and SSH enabled (default mode). Replace `<path-to-share>` with the path to your shared volume.

```bash
docker run -it -d --name rtl-suite \
    --mac-address 02:42:ac:11:00:02 -p 3389:3389 \
    -v <path-to-share>:/media/share \
    superzeldalink/debian10-rdp-rtl-suite:latest <root-password>
```

##### Running with VNC and SSH

This command runs the container with VNC and SSH enabled. It exposes VNC ports (5900 and 5901) for remote desktop access. Replace `<path-to-share>` with your shared volume path.

```bash
docker run -it -d --name rtl-suite \
    --mac-address 02:42:ac:11:00:02 -p 5900:5900 -p 5901:5901 \
    -v <path-to-share>:/media/share \
    superzeldalink/debian10-rdp-rtl-suite:latest <root-password> vnc
```

##### Running with SSH Only

This command runs the container with SSH only, exposing SSH port 2222. You can access the container via SSH. Replace `<path-to-share>` with your shared volume path.

```bash
docker run -it -d --name rtl-suite \
    --mac-address 02:42:ac:11:00:02 -p 2222:22 \
    -v <path-to-share>:/media/share \
    superzeldalink/debian10-rdp-rtl-suite:latest <root-password> ssh
```

After running one of these commands, the container named `rtl-suite` will be started with the specified mode. You can access the container based on the chosen mode as described in the README file.

##### Notes
- The image is optimized for Apple Silicon Macs by default. If you are running this on the x86_64 machines, add `amd64` to the `docker run` command.