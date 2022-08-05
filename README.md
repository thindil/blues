Blues is a simple shell script to manipulate Bluetooth audio devices FreeBSD.
It allows enabling and disabling the selected device. The script should be run by
normal users, not the root user. Also, it requires writing some configuration
to it. Please, read further to get more details about it.  If you read this
file on GitHub: **please don't send pull requests here**. All will be
automatically closed. Any code propositions should go to the
[Fossil](https://www.laeran.pl/repositories/blues) repository.

### Dependencies

The standard dependencies for running a Bluetooth device on FreeBSD:

* virtual\_oss package: `pkg install virtual_oss`
* if you use Intel Bluetooth device to connect, package iwmbt-firmware:
  `pkg install iwmbt-firmware`
* enabled **cuse** kernel module: `kldload cuse` and permanent:
  `sysrc kld_list+="cuse"`

The script has also its own dependencies:

* zenity package for ask for password and show notifications:
  `pkg install zenity`
* sudo package, installed and configured, so the user can create a virtual
  device, `pkg install sudo` and `visudo` and proper changes in the
  configuration.

### Installation

* Put the *blues.sh* script when anywhere it will be accessible by the selected
  user.
* If you want to use the script from GUI (as designed), put the desktop file
  *blues.desktop* in */home/user/.local/share/applications* folder and edit the
  line which starts with `Exec=` to provide the full path to the *blues.sh*
  script. Thus, if you installed the script in directory */home/myuser/bin*,
  the whole line should look: `Exec=sh /home/myuser/bin/blues.sh`

### Configuration

There are a few things to configure, before the script starts working. Please,
open it with your favorite text editor and read the first lines of the script,
where the configuration section is. There is everything explained. The most
important setting is the Bluetooth address of the device to install.

### Usage

* If you use the script from the console, just execute it without any
  arguments, for example `./blues.sh` from the directory where the file is. It
  can automatically detect if the device is connected or not and do the proper
  action.
* If you use a desktop integration *blues.desktop*, run the program's menu
  entry. It should be in *Settings* menu.

### License

The project is released under 3-Clause BSD license.

---
That's all for now, as usual, I have probably forgotten about something important ;)

Bartek thindil Jasicki
