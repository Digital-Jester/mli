#!/bin/bash

ver="0.1 Beta"

updated=0 # Used to cotrol apt update
system=0 # Used to control apt upgrade
distro=0 # Used to control apt upgrade

bashpath="$HOME/.bashrc"

dir=$(pwd)

info=$(tput setaf 2)
err=$(tput setaf 160)
msg=$(tput setaf 214)
rst=$(tput sgr0)

if [[ $(id -u) -ne 0 ]]; then
  echo
  echo "${err}ERROR:${rst} mli.sh must be executed as root or using sudo."
  echo
  exit 99
fi

# ======================================
# ====== INSTALL/UPDATE FUNCTIONS ======
# ======================================

function tools-wget {
  wget=$(which wget)
  if [[ $wget == "" ]]; then
    printf "Installing wget... "
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get install wget -y > /dev/null 2>&1
    wget=$(which wget)
      if [[ $wget == "" ]]; then
        echo "${err}Failed.${rst} Install wget first."
      else
        echo "${info}Success.${rst} wget Installed."
      fi    
  fi
}

function tools-screen {
  screen=$(which screen)
  if [[ $screen == "" ]]; then
    printf "Installing screen... "
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get install screen -y > /dev/null 2>&1
    screen=$(which screen)
      if [[ $screen == "" ]]; then
        echo "${err}Failed.${rst} Install screen first."
      else
        echo "${info}Success.${rst} screen Installed."
      fi    
  fi
}

function tools-htop {
  htop=$(which htop)
  if [[ $htop == "" ]]; then
    printf "Installing htop... "
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get install htop -y > /dev/null 2>&1
    htop=$(which htop)
      if [[ $htop == "" ]]; then
        echo "${err}Failed${rst} To Install htop."
      else
        echo "${info}Success.${rst} htop Installed."
      fi    
  fi
}

function tools-neofetch {
  neofetch=$(which neofetch)
  if [[ $neofetch == "" ]]; then
    printf "Installing neofetch... "
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get install neofetch -y > /dev/null 2>&1
    neofetch=$(which neofetch)
      if [[ $neofetch == "" ]]; then
        echo "${err}Failed${rst} To Install neofetch."
      else
        echo "${info}Success.${rst} neofetch Installed."
      fi    
  fi
}

function tools-nmap {
  nmap=$(which nmap)
  if [[ $nmap == "" ]]; then
    printf "Installing nmap... "
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get install nmap -y > /dev/null 2>&1
    nmap=$(which nmap)
      if [[ $nmap == "" ]]; then
        echo "${err}Failed${rst} To Install nmap."
      else
        echo "${info}Success.${rst} nmap Installed."
      fi    
  fi
}

function update-system-packakges {
  if [[ $system == 0 ]]; then
    echo
    echo "${msg}Updating System Packages...${rst}"
    echo
      if [[ $updated == 0 ]]; then
        apt-get update > /dev/null 2>&1
        updated=1
      fi
      apt-get full-upgrade -y && apt-get autoremove -y
      system=1
    fi
}

function update-system-distro {
  if [[ $distro == 0 ]]; then
    echo
    echo "${msg}Updating System Distro...${rst}"
    echo
      if [[ $updated == 0 ]]; then
        apt-get update > /dev/null 2>&1
        updated=1
      fi
      apt-get dist-upgrade -y && apt-get autoremove -y
      distro=1
    fi
}

function install-duino-coin {
    if [[ -e $dir/duino-coin/.git ]]; then
      whiptail --title "ERROR"  --yesno "\nDuino-Coin already installed.\nWould you like to update now?" 12 50
        case $? in
          0)
            update-duino-coin
            ;;
          1)
            menu-crypto
            ;;
        esac
    else
      #Ask user Questions
      whiptail --title "Confirmation"  --yesno "\nDo you want to add the recommend \$PATH to your $bashpath file?" 12 50
      case $? in
        0)
          addpath=0
          ;;
        1)
          addpath=1
          ;;
      esac
      whiptail --title "Confirmation"  --yesno "\nAdd an alias to your $bashpath?\n(For easier miner exceution.)" 12 50
      case $? in
        0)
          addalias=0
          ;;
        1)
          addalias=1
          ;;
      esac
      echo
      echo "Starting... Dunio-Coin Setup."
      update-system-packakges
      echo
      echo "Installing Required Packages..."
      echo
      apt-get install python3 python3-pip git python3-pil python3-pil.imagetk -y
      echo
      echo "Clone Duino-Coin Repo...."
      echo
      git clone https://github.com/revoxhere/duino-coin
      echo
      echo "Installing Duino-Coin PIP Requirements...."
      echo
      python3 -m pip install -r ./duino-coin/requirements.txt
      python3 -m pip install psutil
      # Add user options if required
      if [[ $addpath == 0 ]]; then
        pathstr="PATH=\$PATH:$HOME/.local/bin"
        #Check for existing path and add new ones if none exist
        if ! grep -q $pathstr $bashpath; then
          echo $pathstr >> $bashpath
        fi
      fi
      # Add user options if required
      if [[ $addalias == 0 ]]; then
        alias1="'python3 $dir/duino-coin/PC_Miner.py'"
        alias2="'python3 $dir/duino-coin/AVR_Miner.py'"
        # Replace existing alias or add new ones if none exist
        /bin/sed -i -- "/alias pcminer=/c\alias pcminer=$alias1" $bashpath
        if ! grep -q "alias pcminer=" $bashpath; then
          echo "alias pcminer="$alias1 >> $bashpath
        fi
        # Replace existing alias or add new ones if none exist
        /bin/sed -i -- "/alias avrminer=/c\alias avrminer=$alias2" $bashpath
        if ! grep -q "alias avrminer=" $bashpath; then
          echo "alias avrminer="$alias2 >> $bashpath
        fi
      fi
      # Print some finished text
      echo
      echo "${info}Finished... Dunio-Coin Setup.${rst}"
      echo
      if [[ $addalias == 0 ]]; then
        echo "Alias Commands Added:"
        echo "====================="
        echo
        echo "  ${msg}pcminer${rst} = Starts Duino-Coin miner in PC mining mode."
        echo "  ${msg}avrminer${rst} = Starts Duino-Coin miner in AVR mining mode."
        echo
        echo "(Logout and Login required to start using alias command.)"
        echo
      fi
    fi
}

function update-duino-coin {

      if [[ -e $dir/duino-coin/.git ]]; then
        echo
        echo "${info}Duino-Coin Install Found...${rst}"
        echo
        echo "${msg}Starting... Dunio-Coin Update.${rst}"
        echo
        cd $dir/duino-coin
        git pull
        echo
        echo "${info}Finished... Dunio-Coin Update.${rst}"
        echo
      else
        whiptail --title "ERROR"  --yesno "\nDid not find Duino-Coin installed.\nWould you like to install now?" 12 50
        case $? in
          0)
            install-duino-coin
            ;;
          1)
            menu-crypto
            ;;
        esac
      fi
}

function install-xmrig-source {
  if [[ -e $dir/xmrig/.git ]]; then
      whiptail --title "ERROR"  --yesno "\nXMRig already installed.\nWould you like to update now?" 12 50
        case $? in
          0)
            update-xmrig-source
            ;;
          1)
            menu-crypto
            ;;
        esac
    else
      #64bit OS Check
      kernel=$(uname -a)
      if [[ ! "$kernel" == *"amd64"* ]] && [[ ! "$kernel" == *"arm64"* ]] && [[ ! "$kernel" == *"aarch64"* ]] && [[ ! "$kernel" == *"x86_64"* ]]; then
        whiptail --title "WARNING" \
          --msgbox "WARNING: 32-Bit OS a 64-Bit OS is required!\n\nUpgrade your distro to 64-bit." 13 50
        menu-crypto
      fi

      #Ask user Questions
      whiptail --title "Confirmation"  --yesno "\nDo you want to turn off Developer Donate?" 12 50
      case $? in
        0)
          donate=0
          ;;
        1)
          donate=1
          ;;
      esac
      whiptail --title "Confirmation"  --yesno "\nDo you want to add the XMRig \$PATH to your $bashpath file?\n(For easier miner exceution.)" 12 50
      case $? in
        0)
          addpath=0
          ;;
        1)
          addpath=1
          ;;
      esac
      exec 3>&1
      result=$(whiptail --title "XMRig Config File" \
         --menu "A config.json file aids miner start up.\nChoose your config file option:" 20 50 10 \
         "1" "Default Sample Config File" \
         "2" "No Config File (CLI Args)" \
         "3" "Raspberry Pi Optimised Sample" \
         "4" "PC Extented Config Sample" \
       2>&1 1>&3);
      case $result in
      1)
        #Default config
        config=1
        ;;
      2)
        #No config
        config=2
        ;;
      3)
        #RPi config
        config=3
        ;;
      4)
        #PC config
        config=4
        ;;
      *)
        #No config
        config=2
        ;;
      esac
      whiptail --title "Confirmation"  --yesno "\nDo you want to start XMRig at boot?" 12 50
      case $? in
        0)
          cron=0
          ;;
        1)
          cron=1
          ;;
      esac
      echo
      echo "${info}Starting... XMRig Setup From Source.${rst}"
      update-system-packakges
      echo
      echo "${msg}Installing Required Packages...${rst}"
      echo
      apt-get install git build-essential cmake libuv1-dev libssl-dev libhwloc-dev -y
      echo
      echo "${msg}Clone XMRig Repo....${rst}"
      echo
      git clone https://github.com/xmrig/xmrig.git
      if [[ $donate == 0 ]]; then
        echo
        echo "${msg}Disabling  Developer Donation....${rst}"
        echo
        /bin/sed -i -- "/constexpr const int kDefaultDonateLevel =/c\constexpr const int kDefaultDonateLevel = 0;" "$dir/xmrig/src/donate.h"
        /bin/sed -i -- "/constexpr const int kMinimumDonateLevel =/c\constexpr const int kMinimumDonateLevel = 0;" "$dir/xmrig/src/donate.h"
      fi
      echo
      echo "${msg}Building Directories....${rst}"
      echo
      mkdir xmrig/build && cd xmrig/build
      echo
      echo "${msg}Compiling XMRig....${rst}"
      echo
      cmake .. && make

      if [[ ! -e $dir/xmrig/build/xmrig ]]; then
        echo
        echo "${err}Opps... Something Went Wrong.${rst}"
        echo
        echo "${msg}Retrying... Building With Advanced Build Options.${rst}"
        echo
        echo "${msg}Backing Up... CMakeList.txt File.${rst}"
        echo
        cp $dir/xmrig/CMakeLists.txt $dir/xmrig/CMakeLists.txt.backup
        /bin/sed -i -- "/option(WITH_GHOSTRIDER/c\option(WITH_GHOSTRIDER      \"Enable GhostRider algorithm\" OFF)" "$dir/xmrig/CMakeLists.txt"
        /bin/sed -i -- "/include(cmake\/ghostrider.cmake)/c\#include(cmake\/ghostrider.cmake)" "$dir/xmrig/CMakeLists.txt"
        /bin/sed -i -- "/target_link_libraries(/c\target_link_libraries(\${CMAKE_PROJECT_NAME} \${XMRIG_ASM_LIBRARY} \${OPENSSL_LIBRARIES} \${UV_LIBRARIES} \${EXTRA_LIBS} \${CPUID_LIB} \${ARGON2_LIBRARY} \${ETHASH_LIBRARY})" "$dir/xmrig/CMakeLists.txt"
        cd $dir/xmrig/scripts
        ./build_deps.sh
        cd $dir/xmrig/build
        echo
        echo "${msg}Retrying XMRig Compile....${rst}"
        echo
        cmake .. -DXMRIG_DEPS=scripts/deps && make
      fi

      if [[ -e $dir/xmrig/build/xmrig ]]; then
        #TEST FOR VERSION
        echo
        echo "${info}Build Sucessful...${rst}"
        echo
        ./xmrig --version
        echo

        # Add config.json, If user wanted.
        if [[ $config != 2 ]]; then
          echo "${msg}Applying config.json To XMRig....${rst}"
          echo
          if [[ $config == 1 ]]; then
            cp $dir/xmrig/src/config.json .
          else
            wget=$(which wget)
            if [[ $wget == "" ]]; then
              tools-wget
            else
              if [[ $config == 3 ]]; then
                wget "https://idiy.duckdns.org/linux/config/xmrig/rpi/config.json"
              fi
              if [[ $config == 4 ]]; then
                wget "https://idiy.duckdns.org/linux/config/xmrig/default/config.json"
              fi
            fi
          fi
        fi

        # Add xmrig build dir to $PATH, If user wanted.
        if [[ $addpath == 0 ]]; then
          pathstr="PATH=\$PATH:$dir/xmrig/build"
          #Check for existing path and add new ones if none exist
          if ! grep -q $pathstr $bashpath; then
            echo $pathstr >> $bashpath
          fi
        fi

        
        # Dump current crontab to tmp file, empty if doesn't exist
        crontab -u $USER -l > ./cron.tmp
        # Add a cron job, If user wanted.
        if [[ $cron == 0 ]]; then
          # Install Screen if needed
          tools-screen
          # Remove previous entry (in case it's an old version)
          /bin/sed -i~ "\~@reboot screen -dmS xmrig $dir/xmrig/build/xmrig~d" ./cron.tmp
          # Add xmrig to auto-load at boot if doesn't already exist in crontab
          if ! grep -q "screen -dmS xmrig" ./cron.tmp; then
            printf "\n@reboot screen -dmS xmrig $dir/xmrig/build/xmrig" >> ./cron.tmp
            cronupdate=1
          fi
        else
          # Just in case it was previously enabled, disable it
          # as this user requested not to auto-run
          /bin/sed -i~ "\~@reboot screen -dmS xmrig $dir/xmrig/build/xmrig~d" ./cron.tmp
          cronupdate=1
        fi
        # Import revised crontab
        if [[ $cronupdate == 1 ]]; then
          crontab -u $USER ./cron.tmp
        fi
        # Remove temp file
        rm ./cron.tmp
        # Be nice and reset the directory.
        cd $dir

        # Print some finished text
        echo
        echo "Finished... XMRig Setup From Source."
        echo
        if [[ $addpath == 0 ]]; then
          echo "${msg}XMRig added to \$PATH, no need to navigate to build dir to run miner${rst}"
          echo
        fi
        if [[ $config != 2 ]]; then
          echo "${msg}Don't forget to edit you config.json file.${rst}"
          echo "   nano ./xmrig/build/config.json"
          echo
          echo "${msg}Configuration Wizard for config.json can be found at;${rst}"
          echo "   https://xmrig.com/wizard"
          echo
        fi

      else
        echo
        echo "${err}Build Failed.${rst} Something Went Really Wrong!"
        echo
      fi      
    fi
}

function update-xmrig-source {

      if [[ -e $dir/xmrig/.git ]]; then
        xmrig-current-ver=$($dir/xmrig/build/xmrig --version | grep XMRig | sed "s/XMRig //")
        echo
        echo "${info}XMRig Install Found...${rst}"
        echo
        echo "${msg}Starting... XMRig Update.${rst}"
        echo
        cd $dir/xmrig
        git pull
        cd $dir/xmrig/build
        echo
        echo "${info}Finished... XMRig Update.${rst}"
        echo
        echo "${msg}Compiling XMRig....${rst}"
        echo
        cmake .. && make
      else
        whiptail --title "ERROR"  --yesno "\nDid not find XMRig installed.\nWould you like to install now?" 12 50
        case $? in
          0)
            install-xmrig-source
            ;;
          1)
            menu-crypto
            ;;
        esac
      fi
}

function install-omv {
  echo
  echo "${info}Starting...${rst} OMV Setup."
  update-system-packakges
  echo
  wget=$(which wget)
  if [[ $wget == "" ]]; then
    tools-wget
  fi
  sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
  # Print some finished text
  echo
  echo "${info}Finished...${rst} OMV Setup."
  echo
}

# ============================
# ====== MENU FUNCTIONS ======
# ============================

function menu-main {
  # Main Menu
  exec 3>&1
  result=$(whiptail --title "MLI Main Menu" \
         --menu "Choose your option:" 20 50 10 \
         "1" "Crypto Miner Installers" \
         "2" "Open Media Vault (OMV) Install" \
       2>&1 1>&3);

  case $result in
    1)
      #Crypto Install Menu
      menu-crypto
      ;;
    2)
      #OMV Install
      install-omv
      ;;
    *)
      echo
      echo "Exit... My Linux Installer v$ver."
      echo
      exit 0
      ;;
  esac
}

function menu-crypto {
  # Crypto Miner Install Menu
  exec 3>&1
  result=$(whiptail --title "Crypto Miners" \
         --menu "Choose your crypto miner:" 20 50 10 \
         "1" "XMRig (Install-Build from Source)" \
         "2" "XMRig (Update-Build from Source)" \
         "3" "Duino Coin (Install)" \
         "4" "Duino Coin (Update)" \
       2>&1 1>&3);

  case $result in
    1)
      #Install XMRig from sorce
      install-xmrig-source
      ;;
    2)
      #Update XMRig from sorce
      update-xmrig-source
      ;;
    3)
      #Install Duino-Coin
      install-duino-coin
      ;;
    4)
      #Update Duino-Coin
      update-duino-coin
      ;;
    *)
      #Back To Main Menu
      menu-main
      ;;
  esac
}

# Script requires whiptail
whiptail=$(which whiptail)
if [[ $whiptail == "" ]]; then
  printf "Installing whiptail... "
  if [[ $updated == 0 ]]; then
    apt-get update > /dev/null 2>&1
    updated=1
  fi
  apt-get install whiptail -y > /dev/null 2>&1
  whiptail=$(which whiptail)
  if [[ $whiptail == "" ]]; then
    echo "${err}Failed. Aborting.${rst} Install whiptail first."
    exit 0
  else
    echo "${info}Success.${rst}"
  fi
fi

# Start with a splash scrren
whiptail --title "My Linux Installer v$ver" \
--msgbox "
      My Linux Installer
      ------------------

        Version: $ver

          by Digital Jester

       https://idiy.duckdns.org
" 15 48

# Load Main Menu
menu-main
