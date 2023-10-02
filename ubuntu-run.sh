#!/bin/bash

PASSWD=$1
VNC_RESOLUTION=1920x1080x24
REMOTE_PROTOCOL=rdp

start_xrdp_services() {
    cp /etc/X11/xrdp/xorg.conf /etc/X11
    sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config
    sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini

    # Preventing xrdp startup failure
    rm -rf /var/run/xrdp-sesman.pid
    rm -rf /var/run/xrdp.pid
    rm -rf /var/run/xrdp/xrdp-sesman.pid
    rm -rf /var/run/xrdp/xrdp.pid

    # Use exec ... to forward SIGNAL to child processes
    xrdp-sesman && exec xrdp -n
}

start_vnc_services() {
    Xvfb :99 -ac -listen tcp -screen 0 1920x1080x24 &
    sleep 1
    export DISPLAY=:99
    /usr/bin/startlxde &
    sleep 1


    openssl req -new -x509 -days 36500 -nodes -batch -out /root/noVNC.pem -keyout /root/noVNC.pem
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html
    websockify -D --web=/usr/share/novnc/ --cert=/root/novnc.pem 5901 0.0.0.0:5900
    
    x11vnc -display :99.0 -forever -noxdamage -passwd $PASSWD &> vnc.log
}

stop_xrdp_services() {
    xrdp --kill
    xrdp-sesman --kill
    exit 0
}

stop_vnc_services() {
    x11vnc -R stop
    exit 0
}

echo root:$PASSWD | chpasswd

echo Entryponit script is Running...
echo

echo "export LD_LIBRARY_PATH=/usr/lib" >> /root/.bashrc
echo "source /etc/profile.d/modules.sh" >> /root/.bashrc
echo "alias ls='ls $LS_OPTIONS'" >> /root/.bashrc
echo "alias ll='ls $LS_OPTIONS -l'" >> /root/.bashrc
echo "alias l='ls $LS_OPTIONS -lA'" >> /root/.bashrc

mv /usr/synopsys/cx-K-2015.06/platforms/linux64/lib/libstdc++.so.6 /usr/synopsys/cx-K-2015.06/platforms/linux64/lib/libstdc++.so.6_bak
ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/synopsys/cx-K-2015.06/platforms/linux64/lib/libstdc++.so.6
mv /usr/synopsys/vc_static-O-2018.09-SP2-2/verdi/etc/lib/libstdc++/LINUXAMD64/libtinfo.so.5 /usr/synopsys/vc_static-O-2018.09-SP2-2/verdi/etc/lib/libstdc++/LINUXAMD64/libtinfo.so.5_bak
ln -s c /usr/synopsys/vc_static-O-2018.09-SP2-2/verdi/etc/lib/libstdc++/LINUXAMD64/libtinfo.so.5
cp -r /lib/terminfo/* /usr/share/terminfo/ 2> /dev/null
/usr/synopsys/11.9/amd64/bin/lmgrd -c /usr/local/flexlm/licenses/license.dat >> /root/startup_run.log

# Loop through all script arguments
for arg in "$@"; do
  if [[ "$arg" =~ ^(amd64|x86|x64|x86_64)$ ]]; then
    # Perform some patches for "amd64"
    echo "Performing patches for amd64..."
    
    # Patch eclipse.ini for Quartus
    sed -i '/-XX:ActiveProcessorCount=2/d' /opt/intelFPGA/22.1std/nios2eds/bin/eclipse_nios2/eclipse.ini

    # Patch desktop files
    sed -i 's/taskset -c 0-3 //' /root/Desktop/Vivado2023.1.desktop
    sed -i 's/taskset -c 4-7 //' /root/Desktop/VitisHLS2023.1.desktop
    sed -i 's/taskset -c 0-3 //' /root/Desktop/Quartus.desktop
    sed -i 's/taskset -c 0-3 //' /usr/share/modules/modulefiles/vivado
    sed -i 's/taskset -c 4-7 //' /usr/share/modules/modulefiles/vivado
    sed -i 's/taskset -c 0-3 //' /usr/share/modules/modulefiles/quartus/22.1std

    sed -i 's|Exec=/opt/altera/13.0sp1/quartus/bin/quartus|Exec=/opt/altera/13.0sp1/quartus/bin/quartus --64bit|' /root/Desktop/QuartusII.desktop
    sed -i 's/(32-bit)/(64-bit)/g' /root/Desktop/QuartusII.desktop

    # Patch modules
    echo 'set-alias quartus "quartus --64bit"' >> /usr/share/modules/modulefiles/quartus/13.0sp1

    # Patch info
    sed -i 's/Apple Silicon Macs/x86_64 machines/' /bin/info
  elif [[ "$arg" =~ ^(vnc=)(.*)$ ]]; then
    REMOTE_PROTOCOL=vnc
    VNC_RESOLUTION=${BASH_REMATCH[2]}
    echo "Setting resolution to $VNC_RESOLUTION"
  elif [[ "$arg" == "vnc" ]]; then
    REMOTE_PROTOCOL=vnc
    echo "Setting resolution to default $VNC_RESOLUTION"
  elif [[ "$arg" == "ssh" ]]; then
    REMOTE_PROTOCOL=ssh
  fi
done

echo -e "This script is ended\n"

# Start SSH
service ssh start

if [[ "$REMOTE_PROTOCOL" = "rdp" ]]; then
    echo -e "starting xrdp services...\n"
    trap "stop_xrdp_services" SIGKILL SIGTERM SIGHUP SIGINT EXIT
    start_xrdp_services
elif [[ "$REMOTE_PROTOCOL" = "vnc" ]]; then
    echo -e "starting vnc services...\n"
    trap "stop_vnc_services" SIGKILL SIGTERM SIGHUP SIGINT EXIT
    start_vnc_services
elif [[ "$REMOTE_PROTOCOL" = "ssh" ]]; then
    trap : TERM INT; sleep infinity & wait
fi
