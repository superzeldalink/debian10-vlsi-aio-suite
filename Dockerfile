# Use the base image    
FROM debian:buster-slim AS tools-base
ENV DEBIAN_FRONTEND noninteractive

ARG VERSION=v1.0
ARG BUILD_NUMBER=0
ARG TARGETARCH

### COMMON
ADD quartus_22.1std.tgz /opt
ADD synopsys.tgz /usr
ADD vivado.tgz /tools
ADD quartus_13.tgz /opt
ADD oss-cad-suite-linux-${TARGETARCH}-20231005.tgz /tools

RUN dpkg --add-architecture amd64 \
    && dpkg --add-architecture i386
RUN apt -y update && apt -y upgrade
RUN apt install -y \
    lxde-core \
    xfce4-terminal

# Install required packages for RDP
RUN apt install -y sudo wget xorgxrdp xrdp \
    && apt remove -y light-locker xscreensaver \
    && apt autoremove -y

# Install VNC, SSH
RUN apt install -y --no-install-recommends x11vnc xvfb openssh-server novnc python3-websockify
RUN echo 'PermitRootLogin Yes' >> /etc/ssh/sshd_config \
    && echo 'X11Forwarding yes' >> /etc/ssh/sshd_config \
    && echo 'X11DisplayOffset 10' >> /etc/ssh/sshd_config \
    && echo 'X11UseLocalhost no' >> /etc/ssh/sshd_config

RUN apt install -y --no-install-recommends gcc make libc6-dev g++

# Install Firefox
RUN apt install -y firefox-esr

# Install additional utilities and locales
RUN echo "export TZ=Asia/Ho_Chi_Minh" > /etc/profile.d/env.sh
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
RUN apt install -y htop nano vim neovim tree locales mousepad git xterm tcl yad environment-modules 

# INSTALL QUARTUS
# Install dependencies
RUN apt install -y libc6:amd64 libglib2.0-0:amd64 libfontconfig1:amd64 libx11-xcb1:amd64 libxext6:amd64 libsm6:amd64 libdbus-1-3:amd64 libxft2:amd64

# Configure Quartus settings
RUN mkdir /root/.altera.quartus
RUN echo "[General 22.1]" > /root/.altera.quartus/quartus2.ini \
    && echo "LICENSE_FILE = LM_LICENSE_FILE" >> /root/.altera.quartus/quartus2.ini

# INSTALL SYNOPSYS
RUN mkdir -p /usr/local/flexlm/licenses/ \
    && mkdir -p /usr/tmp/.flexlm

# Install dependencies
RUN apt install -y libncurses5:amd64 libmng1:amd64 csh dc \
    libstdc++6:amd64 libxss1:amd64 libxt6:amd64 libxmu6:amd64 libnuma1:amd64 libxi6:amd64 libxrandr2:amd64 libtiff5:amd64 libgl1:amd64

# Copy Synopsys license file and daemons
COPY license.dat /usr/local/flexlm/licenses
COPY daemons/mgcld /usr/synopsys/11.9/amd64/bin
COPY libpng12.so.0.54.0 /usr/lib

# Create a symbolic link for libpng
RUN ln -s /usr/lib/libpng12.so.0.54.0 /usr/lib/libpng12.so.0

# Set bash as the default shell
RUN rm -f /usr/bin/sh && ln -s /usr/bin/bash /usr/bin/sh \
    && rm -f /bin/sh && ln -s /bin/bash /bin/sh

# Create a symbolic link for ld-linux
RUN ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3

# Create a symbolic link for libtiff3
RUN ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.3

# INSTALL VIVADO
RUN apt install -y libtinfo5:amd64 libxtst6:amd64 libasound2:amd64 libcom-err2:amd64 libkeyutils1:amd64 libpulse0:amd64 libqt5webenginewidgets5:amd64

# Install QUARTUS 13
RUN apt install -y libc6:i386 libx11-6:i386 libxext6:i386 libxft2:i386 libncurses5:i386 libsm6:i386

######### FINALIZE
# Add modules
COPY modules /usr/share/modules/modulefiles

# Add Desktop shortcuts
RUN mkdir /root/Desktop
COPY Desktop/* /root/Desktop
RUN find /root/Desktop -type f -exec chmod +x {} \; 

# Create symbolic links for shared folders
RUN mkdir /media/share \
    && ln -s /media/share /root/Desktop/Share\
    && ln -s /media/share /root/Share

# PCMAN bypass asking for execute
RUN mkdir -p /root/.config/libfm
RUN echo '[config]' > /root/.config/libfm/libfm.conf \
    && echo 'quick_exec = 1' >> /root/.config/libfm/libfm.conf

# Unlimited Scroll for XFCE Terminal
RUN mkdir -p /root/.config/xfce4/terminal
RUN echo '[Configuration]' > /root/.config/xfce4/terminal/terminalrc \
    && echo 'ScrollingUnlimited=TRUE' >> /root/.config/xfce4/terminal/terminalrc

# Add info.sh
COPY info /bin
COPY info_autostart.desktop /etc/xdg/autostart
RUN chmod +x /bin/info

RUN sed -i "s/;;VERSION/$VERSION/" /bin/info \
    && sed -i "s/;;BUILD_NUMBER/$BUILD_NUMBER/" /bin/info \
    && sed -i 's/;;BuiltAt/TXT+="\\tBuilt at `date`\\n\\n"/g' /bin/info

# Copy a custom script and set it as the entry point
COPY ./ubuntu-run.sh /usr/bin/
RUN mv /usr/bin/ubuntu-run.sh /usr/bin/run.sh \
    && chmod +x /usr/bin/run.sh

# Set the root password
RUN echo 'root:toor' | chpasswd

# Remove apt caches and /tmp
RUN rm -rf /var/cache/apt /var/lib/apt/lists
RUN rm -rf /tmp/*

## This stage is used on arm64"
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        ln -s /usr/synopsys/vc_static-O-2018.09-SP2-2/linux64 /usr/synopsys/vc_static-O-2018.09-SP2-2/aarch64; \
        ln -s /usr/synopsys/vc_static-O-2018.09-SP2-2/verdi/platform/linux64 /usr/synopsys/vc_static-O-2018.09-SP2-2/verdi/platform/aarch64; \
        ln -s /usr/synopsys/vc_static-O-2018.09-SP2-2/vcs-mx/linux64 /usr/synopsys/vc_static-O-2018.09-SP2-2/vcs-mx/aarch64; \
        ln -s /usr/synopsys/dc-L-2016.03-SP1/linux64 /usr/synopsys/dc-L-2016.03-SP1/linux; \
        ln -s /usr/synopsys/hspice-L-2016.06/hspice/linux64 /usr/synopsys/hspice-L-2016.06/hspice/linux; \
        ln -s /usr/synopsys/icc-L-2016.03-SP1/linux64 /usr/synopsys/icc-L-2016.03-SP1/linux; \
        ln -s /usr/synopsys/lc-M-2016.12/linux64 /usr/synopsys/lc-M-2016.12/aarch64; \
        sed -i 's|set OS=linux|set OS=linux64|' /usr/synopsys/fm-O-2018.06-SP1/bin/snps_platform; \
        sed -i 's|ARCH_64bit=unknown|ARCH_64bit=linux64|' /usr/synopsys/pt-M-2016.12-SP1/linux64/syn/bin/pt_shell; \
        sed '/case `uname -m` in/a \ \ aarch64)\n    ;;' /tools/Xilinx/Vivado/2023.1/bin/loader | sed '/case `uname -m` in/a \ \ x86_64)\n    ;;' > tmpfile && mv tmpfile /tools/Xilinx/Vivado/2023.1/bin/loader && chmod +x /tools/Xilinx/Vivado/2023.1/bin/loader; \
        sed '/case `uname -m` in/a \ \ aarch64)\n    ;;' /tools/Xilinx/Vitis_HLS/2023.1/bin/loader | sed '/case `uname -m` in/a \ \ x86_64)\n    ;;' > tmpfile && mv tmpfile /tools/Xilinx/Vitis_HLS/2023.1/bin/loader && chmod +x /tools/Xilinx/Vitis_HLS/2023.1/bin/loader; \
    ## This stage is used on amd64"
    else \ 
        sed -i '/-XX:ActiveProcessorCount=2/d' /opt/intelFPGA/22.1std/nios2eds/bin/eclipse_nios2/eclipse.ini; \
        sed -i 's/taskset -c 0-3 //' /root/Desktop/Vivado2023.1.desktop; \
        sed -i 's/taskset -c 4-7 //' /root/Desktop/VitisHLS2023.1.desktop; \
        sed -i 's/taskset -c 0-3 //' /root/Desktop/Quartus.desktop; \
        sed -i 's/taskset -c 0-3 //' /usr/share/modules/modulefiles/vivado; \
        sed -i 's/taskset -c 4-7 //' /usr/share/modules/modulefiles/vivado; \
        sed -i 's/taskset -c 0-3 //' /usr/share/modules/modulefiles/quartus/22.1std; \
        sed -i 's|Exec=/opt/altera/13.0sp1/quartus/bin/quartus|Exec=/opt/altera/13.0sp1/quartus/bin/quartus --64bit|' /root/Desktop/QuartusII.desktop; \
        sed -i 's/(32-bit)/(64-bit)/g' /root/Desktop/QuartusII.desktop; \
        echo 'set-alias quartus "quartus --64bit"' >> /usr/share/modules/modulefiles/quartus/13.0sp1; \
        sed -i 's/Apple Silicon Macs/x86_64 machines/' /bin/info; \
    fi

# Docker config
EXPOSE 3389
ENTRYPOINT ["/usr/bin/run.sh"]