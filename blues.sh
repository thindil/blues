#!/bin/sh
# Copyright © 2022 Bartek Jasicki <thindil@laeran.pl>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS ''AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#################
# Configuration #
#################
# The Bluetooth address of the sound device which will be used. It can be also
# th name of device set in /etc/bluetooth/hosts. If you don't know the addres,
# you can use the script with the argument "probe" to obtain information about
# all available Bluetooth devices.
BD_ADDR=headphones
# Do the script should manage (start and stop) the services related to the
# Bluetooth stack. Set it to 1 (default) if yes, otherwise set it to 0
start_services=1
# Do you need the support for PulseAudio. Set it to 1 if yes, otherwise
# (default) set it to 0.
pulseaudio_support=0

# Ask for password to execute sudo command via zenity password dialog
pass="$(zenity --password --title="Bluetooth sound")"

# If the user entered an empty password, or cancelled the password dialog,
# show the error dialog and stop the script.
if [ -z $pass ]
then
   zenity --error --text="Cancelled." --title="Bluetooth sound"
   return 1
fi

# Enable Bluetooth services, if the script should take care of them, and set
# some needed kernel settings
enable_bluetooth () {
   if [ $start_services -eq 1 ]; then
      result=1
      until [ $result -lt 1 ]; do
         echo $pass | sudo -S service bluetooth start ubt0
         result=$?
      done
      echo $pass | sudo -S service hcsecd onestart
   fi
   echo $pass | sudo -S sysctl hw.snd.basename_clone=1
}

# Disable Bluetooth services, if the script should take care of them, and set
# some needed kernel settings
disable_bluetooth () {
   if [ $start_services -eq 1 ]; then
      echo $pass | sudo -S service bluetooth stop ubt0
      echo $pass | sudo -S service hcsecd stop
   fi
   # For some reason, hw.snd.basename_clone is reseted to 0 which can cause
   # problems when using the sound device with speakers (for example,
   # with sndio). Thus, let to be sure that the setting is properly set.
   echo $pass | sudo -S sysctl hw.snd.basename_clone=1
}

# Find enabled Bluetooth devices around and print to the console the received
# information. IMPORTAMT: this action may take a few seconds, so don't stop
# the script
if [ "$1" = "probe" ]; then
   enable_bluetooth
   hccontrol -n ubt0hci inquiry
   disable_bluetooth
   exit
fi

# Turn off the Bluetooth sound device, restore volume level for the standard
# speakers and bring back any other settings if needed.
if [ "$(cat /dev/sndstat | grep 'dsp: <Virtual OSS')" = "dsp: <Virtual OSS> (play/rec)" ]; then
   # Stop PulseAudio if needed
   if [ $pulseaudio_support -eq 1 ]; then
      killall pacat
   fi
   # Turn off the Bluetooth device
   echo $pass | sudo -S /usr/bin/killall virtual_oss
   # Disable Bluetooth services if needed
   disable_bluetooth
   # Unmute the speakers
   mixer pcm 100
   # Show notification about finished the script
   zenity --notification --text="Bluetooth sound device disabled"
   # Exit from the script
   exit
fi

# Turn on the Bluetooth sound device, mute speakers and set all needed
# settings
# Mute the standard speakers
mixer pcm 0
# Enable Bluetooth services if needed
enable_bluetooth
# Connect to the Bluetooth device
echo $pass | sudo -S hccontrol -n ubt0hci create_connection $BD_ADDR
# Start virtual sound device
echo $pass | sudo -S virtual_oss -T /dev/sndstat -C 2 -c 2 -r 48000 -b 16 -s 20ms -P /dev/bluetooth/$BD_ADDR -R /dev/null -w vdsp.ctl -d dsp -l mixer &
# Start PulseAudio support if needed
if [ $pulseaudio_support -eq 1 ]; then
   pacat --record -d oss_output.dsp2.monitor > /dev/dsp &
fi
# Show notification about finished the script
zenity --notification --text="Bluetooth sound device enabled"
