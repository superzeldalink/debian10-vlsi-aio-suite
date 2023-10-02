# Use the base image    
FROM amd64/debian:buster-slim
ENV DEBIAN_FRONTEND noninteractive

# Copy Quartus and Synopsys installation files
ADD quartus_22.1std.tar.gz /opt
ADD synopsys.tar.gz /usr
ADD vivado.tar.gz /tools
ADD quartus_13.tar.gz /opt
ADD oss-cad-suite-linux-x64-20230922.tgz /tools

ENV TZ="Asia/Ho_Chi_Minh"
# Update and upgrade system packages
RUN apt -y update && apt -y upgrade

# Locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

RUN apt install -y \
    lxde-core \
    # xfce4 \
    # xfce4-clipman-plugin \
    # xfce4-cpugraph-plugin \
    # xfce4-netload-plugin \
    # xfce4-screenshooter \
    # xfce4-taskmanager \
    xfce4-terminal
    # xfce4-xkb-plugin \
    # dbus-x11

# Install required packages for RDP
RUN apt install -y sudo wget xorgxrdp xrdp \
    && apt remove -y light-locker xscreensaver \
    && apt autoremove -y

########## INSTALL QUARTUS
# Configure Quartus settings
RUN mkdir /root/.altera.quartus
RUN echo "[General 22.1]" > /root/.altera.quartus/quartus2.ini \
    && echo "LICENSE_FILE = LM_LICENSE_FILE" >> /root/.altera.quartus/quartus2.ini

##########  INSTALL SYNOPSYS
RUN mkdir -p /usr/local/flexlm/licenses/ \
    && mkdir -p /usr/tmp/.flexlm

# Install dependencies
RUN apt install -y libncurses5 libmng1 csh dc

# Copy Synopsys license file and daemons
COPY license.dat /usr/local/flexlm/licenses
COPY daemons/mgcld /usr/synopsys/11.9/amd64/bin
COPY libpng12.so.0.54.0 /usr/lib

# Create a symbolic link for libpng
RUN ln -s /usr/lib/libpng12.so.0.54.0 /usr/lib/libpng12.so.0

# Create a symbolic link for ld-linux
RUN ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3

# Create a symbolic link for libtiff3
RUN ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.5 /usr/lib/x86_64-linux-gnu/libtiff.so.3

# Set bash as the default shell
RUN rm -f /usr/bin/sh && ln -s /usr/bin/bash /usr/bin/sh \
    && rm -f /bin/sh && ln -s /bin/bash /bin/sh

RUN echo "export TZ=Asia/Ho_Chi_Minh" > /etc/profile.d/env.sh

######### Install VIVADO
RUN apt install -y libtinfo5

######### Install QUARTUS 13
RUN dpkg --add-architecture i386 && apt update
RUN apt install -y libc6:i386 libx11-6:i386 libxext6:i386 libxft2:i386 libncurses5:i386 libsm6:i386

######### FINALIZE
# Install Firefox
RUN apt install -y firefox-esr

# Install additional utilities
RUN apt install -y htop nano vim neovim tree locales mousepad git xterm tcl yad environment-modules 

# Install VNC, SSH
RUN apt install -y --no-install-recommends x11vnc xvfb openssh-server novnc python3-websockify
RUN echo 'PermitRootLogin Yes' >> /etc/ssh/sshd_config \
    && echo 'X11Forwarding yes' >> /etc/ssh/sshd_config \
    && echo 'X11DisplayOffset 10' >> /etc/ssh/sshd_config \
    && echo 'X11UseLocalhost no' >> /etc/ssh/sshd_config

RUN apt install -y --no-install-recommends gcc make libc6-dev g++

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

ARG VERSION=v1.0
ARG BUILD_NUMBER=0
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

# Docker config
EXPOSE 3389
ENTRYPOINT ["/usr/bin/run.sh"]