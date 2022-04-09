# My Linux Installer (mli.sh)
 
If your like me and love a good terminal screen, but hate typing the same command over and over again. You put it in an automatic helper bash script right? So here is my bash script for Debian based Linux distro's, enjoy.

Script now also supports command line arguments
  
Script currently includes;
- Crypto Miner Installers
- Config Helper For XMRig
- Open Media Vault (OMV) Install
- CLI Package Installers

## Usage (Basic)

Download and make the script executable.

- `wget https://raw.githubusercontent.com/Digital-Jester/mli/main/mli.sh && chmod +x mli.sh`

Run the script (sudo not needed if logged in as root).

- `sudo ./mli.sh`

## Usage (Command Line Arguments)

Command line arguments are as follows;

- `sudo ./mli.sh -i`
- `sudo ./mli.sh -h`
- `sudo ./mli.sh -p [directory]`
- `sudo ./mli.sh -b [bashrc-file-path]`

You can also combine arguments, but if -h (help) is used mli will just print help message and then exit.

- `sudo ./mli.sh -i -p [directory] -b [bashrc-file-path]`
