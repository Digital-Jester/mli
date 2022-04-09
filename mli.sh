#!/bin/bash

# ==========================
# ====== GLOBAL STUFF ======
# ==========================

ver="0.3 Beta"

updated=0 # Used to cotrol apt update
system=0 # Used to control apt upgrade
distro=0 # Used to control apt upgrade

bashpath="$HOME/.bashrc"

dir=$(pwd)

info=$(tput setaf 2)  # Set terminal text colour
err=$(tput setaf 1)   # Set terminal text colour
msg=$(tput setaf 3)   # Set terminal text colour
rst=$(tput sgr0)      # Reset terminal text

xinfo=0 # Show more terminal output

xmrigconfig="/xmrig/build/config.json"
xmriggit="/xmrig/.git"

# ======================================
# ====== INSTALL/UPDATE FUNCTIONS ======
# ======================================

function tools-install {
  tool=$(which $1)
  if [[ $tool == "" ]]; then
    echo "${info}Installing...${rst} $1"
    if [[ $updated == 0 ]]; then
      if [[ $xinfo == 0 ]]; then
        apt-get update > /dev/null 2>&1
      else
        apt-get update
      fi
      updated=1
    fi
    if [[ $xinfo == 0 ]]; then
      apt-get install $1 -y > /dev/null 2>&1
    else
      apt-get install $1 -y
    fi
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
      if [[ $xinfo == 0 ]]; then
        apt-get update > /dev/null 2>&1
      else
        apt-get update
      fi
      updated=1
    fi
      if [[ $xinfo == 0 ]]; then
        apt-get upgrade -y > /dev/null 2>&1
        apt-get autoremove -y > /dev/null 2>&1
      else
        apt-get upgrade -y
        apt-get autoremove -y
      fi
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
      if [[ $xinfo == 0 ]]; then
        apt-get update > /dev/null 2>&1
      else
        apt-get update
      fi
      updated=1
    fi
    if [[ $xinfo == 0 ]]; then
      apt-get dist-upgrade -y > /dev/null 2>&1
      apt-get autoremove -y > /dev/null 2>&1
    else
      apt-get dist-upgrade -y
      apt-get autoremove -y
    fi
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
      if [[ $xinfo == 0 ]]; then
        apt-get install python3 python3-pip git python3-pil python3-pil.imagetk -y > /dev/null 2>&1
      else
        apt-get install python3 python3-pip git python3-pil python3-pil.imagetk -y
      fi
      echo
      echo "${msg}Pulling Repository....${rst}"
      echo
      if [[ $xinfo == 0 ]]; then
        git clone https://github.com/revoxhere/duino-coin > /dev/null 2>&1
      else
        git clone https://github.com/revoxhere/duino-coin
      fi
      echo
      echo "${msg}Installing...${rst} Duino-Coin PIP Requirements."
      echo
      if [[ $xinfo == 0 ]]; then
        python3 -m pip install -r ./duino-coin/requirements.txt > /dev/null 2>&1
        python3 -m pip install psutil > /dev/null 2>&1
      else
        python3 -m pip install -r ./duino-coin/requirements.txt
        python3 -m pip install psutil
      fi
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
        if [[ $xinfo == 0 ]]; then
          git pull > /dev/null 2>&1
        else
          git pull
        fi
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
  if [[ -e $dir$xmriggit ]]; then
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
      if [[ $xinfo == 0 ]]; then
        apt-get install git build-essential cmake libuv1-dev libssl-dev libhwloc-dev -y > /dev/null 2>&1
      else
        apt-get install git build-essential cmake libuv1-dev libssl-dev libhwloc-dev -y
      fi
      echo
      echo "${msg}Pulling Repository....${rst}"
      echo
      if [[ $xinfo == 0 ]]; then
        git clone https://github.com/xmrig/xmrig.git > /dev/null 2>&1
      else
        git clone https://github.com/xmrig/xmrig.git
      fi
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
      if [[ $xinfo == 0 ]]; then
        cmake .. > /dev/null 2>&1 && make > /dev/null 2>&1
      else
        cmake .. && make
      fi
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
        if [[ $xinfo == 0 ]]; then
          cmake .. -DXMRIG_DEPS=scripts/deps > /dev/null 2>&1 && make > /dev/null 2>&1
        else
          cmake .. -DXMRIG_DEPS=scripts/deps && make
        fi
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
              tools-install jq 
              jq '.["donate-level"]=0' $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
              jq '.["donate-over-proxy"]=0' $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
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
            printf "\n@reboot screen -dmS xmrig $dir/xmrig/build/xmrig\n" >> ./cron.tmp
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
          echo "   nano $dir$xmrigconfig"
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

      if [[ -e $dir$xmriggit ]]; then
        current=$($dir/xmrig/build/xmrig --version | grep XMRig | sed "s/XMRig //")
        echo
        echo "${info}Found...${rst} XMRig Install."
        echo
        echo "${msg}Pulling...${rst} XMRig Update."
        echo
        cd $dir/xmrig
        if [[ $xinfo == 0 ]]; then
          git pull > /dev/null 2>&1
        else
          git pull
        fi
        cd $dir/xmrig/build
        echo "${msg}Compiling...${rst} XMRig"
        echo
        if [[ $xinfo == 0 ]]; then
          cmake .. > /dev/null 2>&1
          make > /dev/null 2>&1
        else
          cmake .. && make
        fi
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

function xmrig-config {
  if [[ -e $dir/xmrig/build/xmrig ]]; then
    if [[ -e $dir$xmrigconfig ]]; then
      whiptail --title "config.json Found" --yesno "Would You Like To Backup config.json First?" 15 48
      if [ $? == 0 ]; then
        cp $dir$xmrigconfig $dir$xmrigconfig.backup
      fi
    else
      cp $dir/xmrig/src/config.json .
    fi
    
    workerID=$(whiptail --inputbox "Enter Rig/Worker ID?" 8 39 --title "Miner ID" 3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
      workerID=$(hostname)
    fi

    donate=$(whiptail --inputbox "Enter Donate Level (0-100)?" 8 39 --title "Donate Level" 3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
      donate=0
    else
      if [ $donate < 0]; then
        donate=0
      fi
      if [ $donate >= 100]; then
        donate=5
        whiptail --title "Donate Level" --msgbox "Donate Level Too High. Reduced To 5." 15 48
      fi
      if [ $donate > 10]; then
        whiptail --title "Donate Level" --yesno "Donate Level Seems High At $donate.\nAre You Sure?" 15 48
        if [ $? != 0 ]; then
          donate=10
          whiptail --title "Donate Level" --msgbox "Donate Level Reduced To 10." 15 48
        fi
      fi
    fi

    exec 3>&1
    result=$(whiptail --title "Mining Pool Select" \
         --menu "Choose Your Mining Pool:" 20 50 10 \
         "0" "nanopool" \
         "1" "unMineable" \
       2>&1 1>&3);
    case $result in
      0)
        pool="nano"
        ;;
      1)
        pool="unmine"
        ;;
      *)
        pool="nano"
        ;;
    esac
    exec 3>&1
    if [ $pool == "unmine" ]; then
      result=$(whiptail --title "Coin Select" \
         --menu "Choose Your Coin:" 20 50 10 \
         "0" "Monero (XMR)" \
         "1" "Cardano (ADA)" \
       2>&1 1>&3);
    fi
    if [ $pool == "nano" ]; then
      result=$(whiptail --title "Coin Select" \
         --menu "Choose Your Coin:" 20 50 10 \
         "0" "Monero (XMR)" \
       2>&1 1>&3);
    fi
    case $result in
      0)
        coin="XMR"
        coinlong="monero"
        ;;
      1)
        coin="ADA"
        coinlong="cardano"
        ;;
      *)
        coin="XMR"
        coinlong="monero"
        ;;
    esac

    algo="rx/0"

    if [[ $pool == "nano" ]] && [[ $coin=="XMR" ]]; then
      result=$(whiptail --title "Server Select" \
         --menu "Choose Your Nanopool Server:" 20 50 10 \
         "0" "xmr-au1.nanopool.org" \
         "1" "xmr-jp1.nanopool.org" \
         "2" "xmr-asia1.nanopool.org" \
         "3" "xmr-us-east1.nanopool.org" \
         "4" "xmr-us-west1.nanopool.org" \
         "5" "xmr-eu1.nanopool.org" \
         "6" "xmr-eu2.nanopool.org" \
       2>&1 1>&3);
      case $result in
        0)
          url="xmr-au1.nanopool.org"
          ;;
        1)
          url="xmr-jp1.nanopool.org"
          ;;
        2)
          url="xmr-asia1.nanopool.org"
          ;;
        3)
          url="xmr-us-east1.nanopool.org"
          ;;
        4)
          url="xmr-us-west1.nanopool.org"
          ;;
        5)
          url="xmr-eu1.nanopool.org"
          ;;
        6)
          url="xmr-eu2.nanopool.org"
          ;;
        *)
          url="xmr-au1.nanopool.org"
          ;;
      esac
      result=$(whiptail --title "Port Select" \
         --menu "Choose Your Server Port:" 20 50 10 \
         "0" "SSL Stratum Port" \
         "1" "Stratum Port" \
       2>&1 1>&3);
      case $result in
        0)
          port="14433"
          ;;
        1)
          port="14444"
          ;;
        *)
          port="14433"
          ;;
      esac 
    fi

    if [ $pool == "unmine" ]; then
      url="rx.unmineable.com"
      result=$(whiptail --title "Port Select" \
         --menu "Choose Your Server Port:" 20 50 10 \
         "0" "Normal (Default) Port" \
         "1" "Alternative Port" \
       2>&1 1>&3);
      case $result in
        0)
          port="3333"
          ;;
        1)
          port="13333"
          ;;
        *)
          port="3333"
          ;;
      esac

      whiptail --title "Donate Level" --yesno "Do you have a refrral code?" 15 48
        if [ $? == 0 ]; then
          referral=$(whiptail --inputbox "Enter Referral Code?" 8 39 --title "Referral Code" 3>&1 1>&2 2>&3)
          if [ $? != 0 ]; then
            if [$coin=="XMR"]; then
              referral="ijlk-8ozk"
            fi
            if [$coin=="ADA"]; then
              referral="jj3b-h73g"
            fi
          fi 
        else
          if [$coin=="XMR"]; then
            referral="ijlk-8ozk"
          fi
          if [$coin=="ADA"]; then
            referral="jj3b-h73g"
          fi
        fi
    fi

    if [ $coin == "XMR" ]; then
      wallet=$(whiptail --inputbox "Monero (XMR) Wallet Address?" 8 39 --title "Wallet Address" 3>&1 1>&2 2>&3)
      if [ $? != 0 ]; then
        wallet="4BAco3fES2cXfymfx7NVd62Z6EfgXNvaZg3tba8jWjvHR52cHDbmkiT5iEm3Kxq4XhbCeFEacCJzkBYtHpXwwGbJ2d7FWwr"
      fi
    fi

    if [ $coin == "ADA" ]; then
      wallet=$(whiptail --inputbox "Cardano (ADA) Wallet Address?" 8 39 --title "Wallet Address" 3>&1 1>&2 2>&3)
      if [ $? != 0 ]; then
        wallet="DdzFFzCqrhszQLpR2TYjrTcDxbj2HggiUUJxeN22aohkMHk5F3LTbCTCwpSWFetrduaEjFP16uHxRAvVEbaAE92H1B6X8sCnDJjr8a44"
      fi
    fi

    #MSR
    tools-install msr-tools

    tools-install jq
    #jq '.api["worker-id"]="NewGuy"' config.json
    #jq '.pools[0].url = "xmr-au1.nanopool.org:14433"' config.json
    #jq '.["donate-level"]' config.json

    cmd=".api[\"worker-id\"]=\"$workerID\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig

    cmd=".[\"donate-level\"]=\"$donate\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
    cmd=".[\"donate-over-proxy\"]=\"$donate\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
    
    cmd=".pools[0].algo=\"$algo\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
    cmd=".pools[0].coin=\"$coinlong\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
    cmd=".pools[0].url=\"$url:$port\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
    if [ $pool == "nano" ]; then
      cmd=".pools[0].user=\"$wallet.$workerID\""
    fi
    if [ $pool == "unmine" ]; then
      cmd=".pools[0].user=\"$coin:$wallet.$workerID#$referral\""
    fi
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig
    cmd=".pools[0].rig-id=\"$workerID\""
    jq $cmd $dir$xmrigconfig > tmp.json && mv tmp.json $dir$xmrigconfig

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
         "3" "XMRig (config.json Tool)" \
         "4" "Duino Coin (Install)" \
         "5" "Duino Coin (Update)" \
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
      #XMRig config.json Tool
      xmrig-config
      ;;
    4)
      #Install Duino-Coin
      install-duino-coin
      ;;
    5)
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
         --menu "Choose packakge type:" 20 50 10 \
         "0" "Pentesting/Security" \
         "1" "System" \
       2>&1 1>&3);

  case $result in
    0)
      #Install screen
      menu-cli-pentest
      ;;
    1)
      #Install screen
      menu-cli-system
      ;;
    *)
      #Back To Main Menu
      menu-main
      ;;
  esac
}

function menu-cli-pentest {
  # Crypto Miner Install Menu
  exec 3>&1
  result=$(whiptail --title "CLI Packakge" \
         --menu "Choose packakge to install:" 20 50 10 \
         "1" "nmap" \
         "2" "hydra" \
         "3" "exploitdb" \
         "4" "metasploit" \
         "5" "wireshark" \
         "A" "Install All" \
       2>&1 1>&3);

  case $result in
    1)
      #Install nmap
      tools-install nmap
      ;;
    2)
      #Install hydra
      tools-install hydra
      ;;
    3)
      #Install exploitdb
      tools-install exploitdb
      ;;
    4)
      #Install metasploit-framework
      tools-install metasploit-framework
      ;;
    5)
      #Install wireshark
      tools-install wireshark
      ;;
    A)
      #Install ALL
      tools-install nmap
      tools-install hydra
      tools-install exploitdb
      tools-install metasploit-framework
      tools-install wireshark
      ;;
    *)
      #Back To CLI Menu
      menu-cli
      ;;
  esac
}

function menu-cli-system {
  # CLI System Install Menu
  exec 3>&1
  result=$(whiptail --title "CLI Packakge" \
         --menu "Choose packakge to install:" 20 50 10 \
         "1" "screen" \
         "2" "htop" \
         "3" "neofetch" \
         "4" "wget" \
         "5" "tar" \
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
      #Install wget
      tools-install wget
      ;;
    5)
      #Install tar
      tools-install tar
      ;;
    *)
      #Back To CLI Menu
      menu-cli
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

# Check CLI Arguments
while [ "$1" ]
do
    #echo "$1"
  case $1 in
    "-i")
      #interactive mode
      xinfo=1
      ;;
    "-p")
      #set install path
      shift
      if [[ -e $1 ]]; then
        dir=$1
      fi
      ;;
    "-b")
      #set bashrc path
      shift
      if [[ -e $1 ]]; then
        bashpath=$1
      fi
      ;;
    "-h")
      #Help
      echo
      echo "${info}My Linux Installer v$ver${rst}"
      echo
      echo "${msg}USAGE:${rst} ./mli.sh [OPTIONS]"
      echo "${msg}EXAMPLE:${rst} sudo ./mli.sh -i"
      echo 
      echo "${msg}OPTIONS:${rst}"
      echo "-i   Interactive Mode."
      echo "-h   Show help."
      echo "-p [PATH]   Set install path"
      echo "-b [PATH]   Set bashrc file path"
      echo
      exit 99
      ;;
    esac

    shift
done

# Script requires whiptail
whiptail=$(which whiptail)
if [[ $whiptail == "" ]]; then
  echo "${msg}Installing...${rst} Required Package whiptail."
  if [[ $updated == 0 ]]; then
    if [[ $xinfo == 0 ]]; then
      apt-get update > /dev/null 2>&1
    else
      apt-get update
    fi
    updated=1
  fi
  if [[ $xinfo == 0 ]]; then
    apt-get install whiptail -y > /dev/null 2>&1
  else
    apt-get install whiptail -y
  fi
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
