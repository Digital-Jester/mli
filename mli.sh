#!/bin/bash

# ==========================
# ====== GLOBAL STUFF ======
# ==========================

ver="0.2 Beta"

updated=0 # Used to cotrol apt update
system=0 # Used to control apt upgrade
distro=0 # Used to control apt upgrade

bashpath="$HOME/.bashrc"

dir=$(pwd)

info=$(tput setaf 2)  # Set terminal text colour
err=$(tput setaf 1)   # Set terminal text colour
msg=$(tput setaf 3)   # Set terminal text colour
rst=$(tput sgr0)      # Reset terminal text

# ======================================
# ====== INSTALL/UPDATE FUNCTIONS ======
# ======================================

function tools-install {
  tool=$(which $1)
  if [[ $tool == "" ]]; then
    echo "${info}Installing...${rst} $1"
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get install $1 -y > /dev/null 2>&1
    tool=$(which $1)
      if [[ $tool == "" ]]; then
        echo "${err}Failed...${rst} $1 not installed."
      else
        echo "${info}Success...${rst} $1 installed."
      fi    
  else
    echo "${msg}Already Installed!${rst} $1."
  fi
}

function update-system-packakges {
  if [[ $system == 0 ]]; then
    echo "${msg}Updating System Packages...${rst}"
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get full-upgrade -y > /dev/null 2>&1
    apt-get autoremove -y > /dev/null 2>&1
    system=1
    echo "${msg}Done Updating System Packages...${rst}"
  else
    echo "${msg}System Packages Up To Date...${rst}"
  fi
}

function update-system-distro {
  if [[ $distro == 0 ]]; then
    echo "${msg}Updating System Distro...${rst}"
    if [[ $updated == 0 ]]; then
      apt-get update > /dev/null 2>&1
      updated=1
    fi
    apt-get dist-upgrade -y > /dev/null 2>&1
    apt-get autoremove -y > /dev/null 2>&1
    distro=1
    echo "${msg}Done Updating System Disto...${rst}"
  else
    echo "${msg}System Distro Up To Date...${rst}"
  fi
}

function install-duino-coin {
    if [[ -e $dir/duino-coin/.git ]]; then
      whiptail --title "ERROR"  --yesno "\nDuino-Coin already installed.\n\nWould you like to update now?" 12 50
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
      whiptail --title "Confirmation"  --yesno "\nDo you want to start Dunio-Coin at boot?" 12 50
      case $? in
        0)
          cron=0
          #TO DO SELECT PC OR AVR MINER
          ;;
        1)
          cron=1
          ;;
      esac
      echo
      echo "${info}Starting...${rst} Dunio-Coin Setup."
      update-system-packakges
      echo
      echo "${msg}Installing...${rst} Required Packages."
      echo
      apt-get install python3 python3-pip git python3-pil python3-pil.imagetk -y
      echo
      echo "${msg}Pulling Repository....${rst}"
      echo
      git clone https://github.com/revoxhere/duino-coin
      echo
      echo "${msg}Installing...${rst} Duino-Coin PIP Requirements."
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

      # Dump current crontab to tmp file, empty if doesn't exist
        crontab -u $USER -l > ./cron.tmp
        # Add a cron job, If user wanted.
        if [[ $cron == 0 ]]; then
          # Install Screen if needed
          tools-install screen
          # Remove previous entry (in case it's an old version)
          /bin/sed -i~ "\~@reboot screen -dmS dcpc python3 $dir/duino-coin/PC_Miner.py~d" ./cron.tmp
          # Add xmrig to auto-load at boot if doesn't already exist in crontab
          if ! grep -q "screen -dmS dcpc" ./cron.tmp; then
            printf "\n@reboot screen -dmS dcpc python3 $dir/duino-coin/PC_Miner.py" >> ./cron.tmp
            cronupdate=1
          fi
        else
          # Just in case it was previously enabled, disable it
          # as this user requested not to auto-run
          /bin/sed -i~ "\~@reboot screen -dmS dcpc python3 $dir/duino-coin/PC_Miner.py~d" ./cron.tmp
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
      echo "${info}Finished...${rst} Dunio-Coin Setup."
      echo
      if [[ $addalias == 0 ]]; then
        source $bashpath
        echo "Alias Commands Added:"
        echo "====================="
        echo
        echo "  ${msg}pcminer${rst} = Starts Duino-Coin miner in PC mining mode."
        echo "  ${msg}avrminer${rst} = Starts Duino-Coin miner in AVR mining mode."
        #echo
        #echo "(Logout and Login required to start using alias command.)"
        echo
      fi
    fi
}

function update-duino-coin {

      if [[ -e $dir/duino-coin/.git ]]; then
        echo
        echo "${info}Found...${rst} Duino-Coin Install."
        echo
        echo "${msg}Starting...${rst} Dunio-Coin Update."
        echo
        cd $dir/duino-coin
        git pull > /dev/null 2>&1
        echo "${info}Finished...${rst} Dunio-Coin Update."
        echo
      else
        whiptail --title "ERROR"  --yesno "\nDid not find Duino-Coin installed.\n\nWould you like to install now?" 12 50
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
      whiptail --title "ERROR"  --yesno "\nXMRig already installed.\n\nWould you like to update now?" 12 50
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
      echo "${info}Starting...${rst} XMRig Setup From Source."
      update-system-packakges
      echo
      echo "${msg}Installing...${rst} Required Packages."
      echo
      apt-get install git build-essential cmake libuv1-dev libssl-dev libhwloc-dev -y > /dev/null 2>&1
      echo
      echo "${msg}Pulling Repository....${rst}"
      echo
      git clone https://github.com/xmrig/xmrig.git > /dev/null 2>&1
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
        echo "${err}Opps...${rst} Something Went Wrong."
        echo
        echo "${msg}Retrying...${rst} Building With Advanced Build Options."
        echo
        echo "${msg}Backing Up...${rst} CMakeList.txt File."
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
            if [[ $donate == 0 ]]; then
              /bin/sed -i -- "/\"donate-level\": 1,/c\    \"donate-level\": 0," "$dir/xmrig/build/config.json"
              /bin/sed -i -- "/\"donate-over-proxy\": 1,/c\    \"donate-over-proxy\": 0," "$dir/xmrig/build/config.json"
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
          tools-install screen
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
        echo "${info}Finished...${rst} XMRig Setup From Source."
        echo
        if [[ $addpath == 0 ]]; then
          source $bashpath
          echo "${msg}XMRig added to \$PATH, no need to navigate to build dir to run miner${rst}"
          echo
        fi
        if [[ $config != 2 ]]; then
          echo "${msg}Don't forget to edit you config.json file.${rst}"
          echo "   nano $dir/xmrig/build/config.json"
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
        current=$($dir/xmrig/build/xmrig --version | grep XMRig | sed "s/XMRig //")
        echo
        echo "${info}Found...${rst} XMRig Install."
        echo
        echo "${msg}Pulling...${rst} XMRig Update."
        echo
        cd $dir/xmrig
        git pull > /dev/null 2>&1
        cd $dir/xmrig/build
        echo "${msg}Compiling...${rst} XMRig"
        echo
        cmake .. > /dev/null 2>&1
        make > /dev/null 2>&1
        new=$($dir/xmrig/build/xmrig --version | grep XMRig | sed "s/XMRig //")
        if [[ $current == $new ]]; then
          echo "${msg}XMRig. Already Up To Date.${rst}"
          echo
        fi
        if [[ $current < $new ]]; then
          echo "${info}XMRig.${rst} Update Succes."
          echo "   $current >> $new"
          echo
        fi
      else
        whiptail --title "ERROR"  --yesno "\nDid not find XMRig installed.\n\nWould you like to install now?" 12 50
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
  whiptail --title "WARNING"  --yesno "\nIt is recomended to install OMV on a fresh distro install.\n\nDo you want to continue?" 12 50
  case $? in
    0)
      installomv=0
      ;;
    1)
      installomv=1
      ;;
  esac
  if [[ $installomv == 0 ]]; then
    echo
    echo "${info}Starting...${rst} OMV Setup."
    update-system-packakges
    tools-install wget
    sudo wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
    # Print some finished text
    echo
    echo "${info}Finished...${rst} OMV Setup."
    echo
  else
    menu-main
  fi
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
         "3" "CLI Packakge Installers" \
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
    3)
      #CLI Tools Install
      menu-cli
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

function menu-cli {
  # Crypto Miner Install Menu
  exec 3>&1
  result=$(whiptail --title "CLI Packakge" \
         --menu "Choose packakge to install:" 20 50 10 \
         "1" "screen" \
         "2" "htop" \
         "3" "neofetch" \
         "4" "nmap" \
         "5" "wget" \
         "6" "tar" \
         "7" "git" \
       2>&1 1>&3);

  case $result in
    1)
      #Install screen
      tools-install screen
      ;;
    2)
      #Install htop
      tools-install htop
      ;;
    3)
      #Install neofetch
      tools-install neofetch
      ;;
    4)
      #Install nmap
      tools-install nmap
      ;;
    5)
      #Install wget
      tools-install wget
      ;;
    6)
      #Install tar
      tools-install tar
      ;;
    7)
      #Install git
      tools-install git
      ;;
    *)
      #Back To Main Menu
      menu-main
      ;;
  esac
}

# ==========================
# ====== THE MAIN BIT ======
# ==========================

# Make sure user has permison
if [[ $(id -u) -ne 0 ]]; then
  echo
  echo "${err}ERROR:${rst} mli.sh must be executed as ${msg}root${rst} or using ${msg}sudo${rst}."
  echo
  exit 99
fi

# Script requires whiptail
whiptail=$(which whiptail)
if [[ $whiptail == "" ]]; then
  echo "${msg}Installing...${rst} Required Package whiptail."
  if [[ $updated == 0 ]]; then
    apt-get update > /dev/null 2>&1
    updated=1
  fi
  apt-get install whiptail -y > /dev/null 2>&1
  whiptail=$(which whiptail)
  if [[ $whiptail == "" ]]; then
    echo "${err}Failed...${rst} whiptail is required. Install first."
    echo "${msg}Aborting...${rst}"
    exit 0
  else
    echo "${info}Success...${rst}"
  fi
fi

# Start with a splash scrren
whiptail --title "My Linux Installer v$ver" \
--msgbox "
      My Linux Installer
      ------------------

        Version: $ver

          by Digital Jester

    https://github.com/Digital-Jester/mli
" 15 48

# Load Main Menu
menu-main

exit 0