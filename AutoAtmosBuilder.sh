
# -------------------------------------------
### 自动安装 jq 依赖
if ! command -v jq &> /dev/null; then
    echo "正在安装 jq..."
    if [ "$(uname)" = "Linux" ]; then
        sudo apt-get update
        sudo apt-get install -y jq
    elif [ "$(uname)" = "Darwin" ]; then
        brew install jq
    else
        echo "错误：无法自动安装 jq，请手动安装"
        exit 1
    fi
fi

### 创建新文件夹
[ -d SwitchSD ] && rm -rf SwitchSD
[ -e description.txt ] && rm -f description.txt

mkdir -p ./SwitchSD/{atmosphere/{config,hosts},switch/{DBI,Goldleaf,Checkpoint,.packages,.overlays},warmboot_mariko,themes,bootloader/{ini,res,payloads},config/{tesla,Tesla-Menu}}
cd SwitchSD || exit 1


#!/bin/sh
set -e
# -------------------------------------------
### Install jq if not already installed
### if [ "$OSTYPE" = "msys" ]; then
  # Windows
  # @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
  # chocolatey install jq
# elif [ "$OSTYPE" = "darwin" ]; then
  # MacOS
  # brew install jq
# elif [ "$OSTYPE" = "linux-gnu" ]; then
  # Linux
  # sudo apt-get install jq
# fi


### Create a new folder for storing files
if [ -d SwitchSD ]; then
  rm -rf SwitchSD
fi
if [ -e description.txt ]; then
  rm -rf description.txt
fi
mkdir -p ./SwitchSD/atmosphere/config
mkdir -p ./SwitchSD/atmosphere/hosts
mkdir -p ./SwitchSD/switch/DBI
mkdir -p ./SwitchSD/switch/Goldleaf
mkdir -p ./SwitchSD/switch/Checkpoint
mkdir -p ./SwitchSD/switch
mkdir -p ./SwitchSD/switch/.packages
mkdir -p ./SwitchSD/warmboot_mariko
mkdir -p ./SwitchSD/themes
mkdir -p ./SwitchSD/bootloader
mkdir -p ./SwitchSD/bootloader/ini
mkdir -p ./SwitchSD/bootloader/res
mkdir -p ./SwitchSD/bootloader/payloads
mkdir -p ./SwitchSD/config/tesla
mkdir -p ./SwitchSD/config/Tesla-Menu/
mkdir -p ./SwitchSD/switch/.overlays
cd SwitchSD

#Fetch latest atmosphere from https://github.com/Atmosphere-NX/Atmosphere/releases
is_prerelease=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases \
  | jq '.[0].prerelease')
curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases \
  | jq '.[0].assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o atmosphere.zip
curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases \
  | jq -r '.[0].assets[] | select(.name == "fusee.bin") | .browser_download_url' \
  | xargs -I {} curl -sL {} -o fusee.bin
if [ $? -ne 0 ]; then
    echo "atmosphere download\033[31m failed\033[0m."
else
    echo "atmosphere download\033[32m success\033[0m."
    unzip -oq atmosphere.zip
    rm atmosphere.zip

    # 获取最新的Atmosphere版本号并写入description.txt
    curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases \
      | jq '.[0] | .name' \
      | xargs -I {} echo {} >> ../description.txt
fi

# curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/atmosphere_1.8.0_test.zip -o atmosphere_1.8.0_test.zip
# if [ $? -ne 0 ]; then
#     echo "atmosphere_1.8.0_test download\033[31m failed\033[0m."
# else
#     echo "atmosphere_1.8.0_test download\033[32m success\033[0m."
#     unzip -oq atmosphere_1.8.0_test.zip
#     rm atmosphere_1.8.0_test.zip
# fi

### Fetch latest Hekate + Nyx Chinese from https://github.com/easyworld/hekate/releases/latest
curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest \
  | jq '.name' \
  | xargs -I {} echo {} >> ../description.txt
curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o hekate.zip
if [ $? -ne 0 ]; then
    echo "Hekate + Nyx download\033[31m failed\033[0m."
else
    echo "Hekate + Nyx download\033[32m success\033[0m."
    unzip -oq hekate.zip
    rm hekate.zip
    mv fusee.bin ./bootloader/payloads
fi

### 仅当非预发布版时下载 MissionControl 和 ldn_mitm
if [ "$is_prerelease" = "true" ]; then
    echo "检测到 Atmosphere 预发布版本，跳过 MissionControl 和 ldn_mitm"
else
    echo "下载 MissionControl..."
    mission_release=$(curl -sL https://api.github.com/repos/ndeadly/MissionControl/releases/latest)
    mission_tag=$(echo "$mission_release" | jq -r '.tag_name')
    echo "MissionControl $mission_tag" >> ../description.txt
    
    mission_url=$(echo "$mission_release" | jq -r '.assets[0].browser_download_url')
    curl -sL "$mission_url" -o MissionControl.zip
    
    if [ $? -eq 0 ]; then
        unzip -oq MissionControl.zip
        rm MissionControl.zip
        echo "MissionControl 下载\033[32m成功\033[0m"
    else
        echo "MissionControl 下载\033[31m失败\033[0m"
    fi

    echo "下载 ldn_mitm..."
    ldn_release=$(curl -sL https://api.github.com/repos/spacemeowx2/ldn_mitm/releases/latest)
    ldn_tag=$(echo "$ldn_release" | jq -r '.tag_name')
    echo "ldn_mitm $ldn_tag" >> ../description.txt
    
    ldn_url=$(echo "$ldn_release" | jq -r '.assets[0].browser_download_url')
    curl -sL "$ldn_url" -o ldn_mitm.zip
    
    if [ $? -eq 0 ]; then
        unzip -oq ldn_mitm.zip
        rm ldn_mitm.zip
        echo "ldn_mitm 下载\033[32m成功\033[0m"
    else
        echo "ldn_mitm 下载\033[31m失败\033[0m"
    fi
fi

# ### Fetch latest MissionControl from https://api.github.com/repos/ndeadly/MissionControl/releases/latest
# curl -sL https://api.github.com/repos/ndeadly/MissionControl/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo MissionControl {} >> ../description.txt
# curl -sL https://api.github.com/repos/ndeadly/MissionControl/releases/latest \
#   | jq '.assets' | jq '.[0].browser_download_url' \
#   | xargs -I {} curl -sL {} -o MissionControl.zip
# if [ $? -ne 0 ]; then
#     echo "MissionControl download\033[31m failed\033[0m."
# else
#     echo "MissionControl download\033[32m success\033[0m."
#     unzip -oq MissionControl.zip
#     rm MissionControl.zip
# fi

# ### Fetch latest ldn_mitm from https://api.github.com/repos/spacemeowx2/ldn_mitm/releases/latest
# curl -sL https://api.github.com/repos/spacemeowx2/ldn_mitm/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo ldn_mitm {} >> ../description.txt
# curl -sL https://api.github.com/repos/spacemeowx2/ldn_mitm/releases/latest \
#   | jq '.assets' | jq '.[0].browser_download_url' \
#   | xargs -I {} curl -sL {} -o ldn_mitm.zip
# if [ $? -ne 0 ]; then
#     echo "ldn_mitm download\033[31m failed\033[0m."
# else
#     echo "ldn_mitm download\033[32m success\033[0m."
#     unzip -oq ldn_mitm.zip
#     rm ldn_mitm.zip
# fi

### Fetch latest ldn_mitm from https://api.github.com/repos/masagrator/SaltyNX/releases/latest
curl -sL https://api.github.com/repos/masagrator/SaltyNX/releases/latest \
  | jq '.name' \
  | xargs -I {} echo {} >> ../description.txt
curl -sL https://api.github.com/repos/masagrator/SaltyNX/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o SaltyNX.zip
if [ $? -ne 0 ]; then
    echo "SaltyNX download\033[31m failed\033[0m."
else
    echo "SaltyNX download\033[32m success\033[0m."
    unzip -oq SaltyNX.zip
    rm SaltyNX.zip
fi

### Fetch latest SysDVR from hhttps://github.com/exelix11/SysDVR
curl -sL https://api.github.com/repos/exelix11/SysDVR/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo SysDVR {} >> ../description.txt
curl -sL https://api.github.com/repos/exelix11/SysDVR/releases/latest \
  | jq '.assets' | jq '.[7].browser_download_url' \
  | xargs -I {} curl -sL {} -o SysDVR.zip
if [ $? -ne 0 ]; then
    echo "SysDVR download\033[31m failed\033[0m."
else
    echo "SysDVR download\033[32m success\033[0m."
    unzip -oq SysDVR.zip
    rm SysDVR.zip
fi

### Fetch lastest sys-clk from https://api.github.com/repos/retronx-team/sys-clk/releases/latest
curl -sL https://api.github.com/repos/retronx-team/sys-clk/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo sys-clk {} >> ../description.txt
curl -sL https://api.github.com/repos/retronx-team/sys-clk/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o sys_clk.zip
if [ $? -ne 0 ]; then
    echo "sys-clk download\033[31m failed\033[0m."
else
    echo "sys-clk download\033[32m success\033[0m."
    unzip -oq sys_clk.zip
    rm sys_clk.zip
fi


curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/Tesla.zip -o Tesla.zip
if [ $? -ne 0 ]; then
    echo "Tesla download\033[31m failed\033[0m."
else
    echo "Tesla download\033[32m success\033[0m."
    unzip -oq Tesla.zip
    rm Tesla.zip
fi

# ### Fetch lastest Ultrahand-Overlay from https://github.com/ppkantorski/Ultrahand-Overlay/releases/latest
# curl -sL https://api.github.com/repos/ppkantorski/Ultrahand-Overlay/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo Ultrahand-Overlay {} >> ../description.txt
# curl -sL https://api.github.com/repos/ppkantorski/Ultrahand-Overlay/releases/latest \
#   | jq '.assets' | jq '.[1].browser_download_url' \
#   | xargs -I {} curl -sL {} -o ovlmenu.ovl
# if [ $? -ne 0 ]; then
#     echo "Ultrahand-Overlay download\033[31m failed\033[0m."
# else
#     echo "Ultrahand-Overlay download\033[32m success\033[0m."
#     mv ovlmenu.ovl ./switch/.overlays
# fi

### Fetch latest boot.dat-Resources from https://github.com/naixue666/SwitchScript
curl -sL https://raw.github.com/naixue666/naixue_nx_atm_Auto_Script/main/resources/boot.dat -o boot.dat
if [ $? -ne 0 ]; then
    echo "boot.dat-Resources download\033[31m failed\033[0m."
else
    echo "boot.dat-Resources download\033[32m success\033[0m."
fi
### Fetch latest SigPatches.zip from https://raw.github.com/naixue666/naixue_nx_atm_Auto_Script/main/resources/
curl -sL https://sigmapatches.su/sigpatches.zip?16.10.2024 -o sigpatches.zip
if [ $? -ne 0 ]; then
    echo "SigPatches download\033[31m failed\033[0m."
else
    echo "SigPatches download\033[32m success\033[0m."
    unzip -oq sigpatches.zip
    rm sigpatches.zip
fi
### Fetch latest Bootloader-Resources from https://github.com/naixue666/SwitchScript
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/bootloader.zip -o bootloader.zip
if [ $? -ne 0 ]; then
    echo "Bootloader-Resources download\033[31m failed\033[0m."
else
    echo "Bootloader-Resources download\033[32m success\033[0m."
    unzip -oq bootloader.zip
    rm bootloader.zip
fi
### Fetch latest picofly_toolbox_0.2.bin from
curl -sL https://raw.github.com/Ansem-SoD/Picofly/main/Firmwares/picofly_toolbox_0.2.bin -o picofly_toolbox_0.2.bin
if [ $? -ne 0 ]; then
    echo "picofly_toolbox download\033[31m failed\033[0m."
else
    echo "picofly_toolbox download\033[32m success\033[0m."
    mv picofly_toolbox_0.2.bin ./bootloader/payloads
    echo "picofly_toolbox_0.2" >> ../description.txt
fi

# ### Fetch latest Lockpick_RCM.bin from https://github.com/Decscots/Lockpick_RCM/releases/latest
# curl -sL https://api.github.com/repos/Decscots/Lockpick_RCM/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo Lockpick_RCM {} >> ../description.txt
# curl -sL https://api.github.com/repos/Decscots/Lockpick_RCM/releases/latest \
#   | jq '.assets' | jq '.[0].browser_download_url' \
#   | xargs -I {} curl -sL {} -o Lockpick_RCM.bin
# if [ $? -ne 0 ]; then
#     echo "Lockpick_RCM download\033[31m failed\033[0m."
# else
#     echo "Lockpick_RCM download\033[32m success\033[0m."
#     mv Lockpick_RCM.bin ./bootloader/payloads
# fi

### Fetch latest hwfly_toolbox.bin from https://github.com/hwfly-nx/hwfly-toolbox/releases/latest
curl -sL https://api.github.com/repos/hwfly-nx/hwfly-toolbox/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo hwfly-toolbox {} >> ../description.txt
curl -sL https://api.github.com/repos/hwfly-nx/hwfly-toolbox/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o hwfly_toolbox.bin
if [ $? -ne 0 ]; then
    echo "hwfly-toolbox download\033[31m failed\033[0m."
else
    echo "hwfly-toolbox download\033[32m success\033[0m."
    mv hwfly_toolbox.bin ./bootloader/payloads
fi

# ### Fetch latest TegraExplorer.bin form https://github.com/zdm65477730/TegraExplorer/releases
# curl -sL https://api.github.com/repos/zdm65477730/TegraExplorer/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo TegraExplorer {} >> ../description.txt
# curl -sL https://api.github.com/repos/zdm65477730/TegraExplorer/releases/latest \
#   | jq '.assets' | jq '.[0].browser_download_url' \
#   | xargs -I {} curl -sL {} -o TegraExplorer.bin
# if [ $? -ne 0 ]; then
#     echo "TegraExplorer download\033[31m failed\033[0m."
# else
#     echo "TegraExplorer download\033[32m success\033[0m."
#     mv TegraExplorer.bin ./bootloader/payloads
# fi

### Fetch latest CommonProblemResolver.bin form https://github.com/zdm65477730/CommonProblemResolver/releases
curl -sL https://api.github.com/repos/zdm65477730/CommonProblemResolver/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo CommonProblemResolver {} >> ../description.txt
curl -sL https://api.github.com/repos/zdm65477730/CommonProblemResolver/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o CommonProblemResolver.bin
if [ $? -ne 0 ]; then
    echo "CommonProblemResolver download\033[31m failed\033[0m."
else
    echo "CommonProblemResolver download\033[32m success\033[0m."
    mv CommonProblemResolver.bin ./bootloader/payloads
fi


### Fetch lastest wiliwili from https://github.com/xfangfang/wiliwili/releases/latest
curl -sL https://api.github.com/repos/xfangfang/wiliwili/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo wiliwili {} >> ../description.txt
curl -sL https://api.github.com/repos/xfangfang/wiliwili/releases/latest \
  | jq '.assets' | jq '.[9].browser_download_url' \
  | xargs -I {} curl -sL {} -o wiliwili-NintendoSwitch.zip
if [ $? -ne 0 ]; then
    echo "wiliwili download\033[31m failed\033[0m."
else
    echo "wiliwili download\033[32m success\033[0m."
    unzip -oq wiliwili-NintendoSwitch.zip
    mkdir -p ./switch/wiliwili
    mv wiliwili/wiliwili.nro ./switch/wiliwili
    rm -rf wiliwili
    rm wiliwili-NintendoSwitch.zip
fi


### Fetch lastest HB-Appstore from https://github.com/fortheusers/hb-appstore/releases/latest
curl -sL https://api.github.com/repos/fortheusers/hb-appstore/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo HB-Appstore {} >> ../description.txt
curl -sL https://api.github.com/repos/fortheusers/hb-appstore/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o appstore.nro
if [ $? -ne 0 ]; then
    echo "HB-Appstore download\033[31m failed\033[0m."
else
    echo "HB-Appstore download\033[32m success\033[0m."
    mv appstore.nro ./switch
fi

### Fetch lastest Goldleaf from https://github.com/XorTroll/Goldleaf/releases/latest
curl -sL https://api.github.com/repos/XorTroll/Goldleaf/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo Goldleaf {} >> ../description.txt
curl -sL https://api.github.com/repos/XorTroll/Goldleaf/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o Goldleaf.nro
if [ $? -ne 0 ]; then
    echo "Goldleaf download\033[31m failed\033[0m."
else
    echo "Goldleaf download\033[32m success\033[0m."
    mv Goldleaf.nro ./switch/Goldleaf
fi

### Fetch lastest Switch_90DNS_tester from https://github.com/meganukebmp/Switch_90DNS_tester/releases/latest
curl -sL https://api.github.com/repos/meganukebmp/Switch_90DNS_tester/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo Switch_90DNS_tester {} >> ../description.txt
curl -sL https://api.github.com/repos/meganukebmp/Switch_90DNS_tester/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o Switch_90DNS_tester.nro
if [ $? -ne 0 ]; then
    echo "Switch_90DNS_tester download\033[31m failed\033[0m."
else
    echo "Switch_90DNS_tester download\033[32m success\033[0m."
    mv Switch_90DNS_tester.nro ./switch
fi

### Fetch lastest Checkpoint from https://github.com/BernardoGiordano/Checkpoint/releases/latest
curl -sL https://api.github.com/repos/BernardoGiordano/Checkpoint/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo Checkpoint {} >> ../description.txt
curl -sL https://api.github.com/repos/BernardoGiordano/Checkpoint/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o Checkpoint.nro
if [ $? -ne 0 ]; then
    echo "Checkpoint download\033[31m failed\033[0m."
else
    echo "Checkpoint download\033[32m success\033[0m."
    mv Checkpoint.nro ./switch/Checkpoint
fi

### Fetch lastest DBI from https://github.com/rashevskyv/dbi/releases/latest
#curl -sL https://api.github.com/repos/rashevskyv/dbi/releases/latest \
  #| jq '.name' \
  #| xargs -I {} echo {} >> ../description.txt
#curl -sL https://api.github.com/repos/rashevskyv/dbi/releases/latest \
  #| jq '.assets' | jq '.[1].browser_download_url' \
  #| xargs -I {} curl -sL {} -o DBI.nro
#if [ $? -ne 0 ]; then
   # echo "DBI download\033[31m failed\033[0m."
#else
    #echo "DBI download\033[32m success\033[0m."
    #mv DBI.nro ./switch/DBI
#fi

curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/DBI.nro -o DBI.nro
if [ $? -ne 0 ]; then
    echo "DBI.nro download\033[31m failed\033[0m."
else
    echo "DBI.nro download\033[32m success\033[0m."
    mv DBI.nro ./switch/DBI
fi
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/.DBI.nro.star -o .DBI.nro.star
if [ $? -ne 0 ]; then
    echo ".DBI.nro.star download\033[31m failed\033[0m."
else
    echo ".DBI.nro.star download\033[32m success\033[0m."
    mv .DBI.nro.star ./switch/DBI
fi
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/linkalho.nro -o linkalho.nro
if [ $? -ne 0 ]; then
    echo "linkalho.nro download\033[31m failed\033[0m."
else
    echo "linkalho.nro download\033[32m success\033[0m."
    mv linkalho.nro ./switch
fi
### Fetch lastest Awoo Installer from https://github.com/dragonflylee/Awoo-Installer/releases/latest
curl -sL https://api.github.com/repos/dragonflylee/Awoo-Installer/releases/latest \
  | jq '.name' \
  | xargs -I {} echo {} >> ../description.txt
curl -sL https://api.github.com/repos/dragonflylee/Awoo-Installer/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o Awoo-Installer.zip
if [ $? -ne 0 ]; then
    echo "Awoo Installer download\033[31m failed\033[0m."
else
    echo "Awoo Installer download\033[32m success\033[0m."
    unzip -oq Awoo-Installer.zip
    rm Awoo-Installer.zip
fi

### Fetch lastest Hekate-toolbox from https://github.com/WerWolv/Hekate-Toolbox/releases/latest
curl -sL https://api.github.com/repos/WerWolv/Hekate-Toolbox/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo HekateToolbox {} >> ../description.txt
curl -sL https://api.github.com/repos/WerWolv/Hekate-Toolbox/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o HekateToolbox.nro
if [ $? -ne 0 ]; then
    echo "HekateToolbox download\033[31m failed\033[0m."
else
    echo "HekateToolbox download\033[32m success\033[0m."
    mv HekateToolbox.nro ./switch
fi

### Fetch lastest NX-Activity-Log from https://github.com/zdm65477730/NX-Activity-Log/releases/latest
curl -sL https://api.github.com/repos/zdm65477730/NX-Activity-Log/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo NX-Activity-Log {} >> ../description.txt
curl -sL https://api.github.com/repos/zdm65477730/NX-Activity-Log/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o NX-Activity-Log.nro
if [ $? -ne 0 ]; then
    echo "NX-Activity-Log download\033[31m failed\033[0m."
else
    echo "NX-Activity-Log download\033[32m success\033[0m."
    # unzip -oq NX-Activity-Log.zip
    # rm NX-Activity-Log.zip
    mv NX-Activity-Log.nro ./switch
fi

### Fetch lastest NXThemesInstaller from https://github.com/exelix11/SwitchThemeInjector/releases/latest
curl -sL https://api.github.com/repos/exelix11/SwitchThemeInjector/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo NXThemesInstaller {} >> ../description.txt
curl -sL https://api.github.com/repos/exelix11/SwitchThemeInjector/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o NXThemesInstaller.nro
if [ $? -ne 0 ]; then
    echo "NXThemesInstaller download\033[31m failed\033[0m."
else
    echo "NXThemesInstaller download\033[32m success\033[0m."
    mv NXThemesInstaller.nro ./switch
fi
### Fetch lastest Moonlight-Switch from https://github.com/XITRIX/Moonlight-Switch/releases/tag/v1.0.0
curl -sL https://api.github.com/repos/XITRIX/Moonlight-Switch/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo Moonlight-Switch {} >> ../description.txt
curl -sL https://api.github.com/repos/XITRIX/Moonlight-Switch/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o Moonlight-Switch.nro
if [ $? -ne 0 ]; then
    echo "Moonlight-Switch download\033[31m failed\033[0m."
else
    echo "Moonlight-Switch download\033[32m success\033[0m."
    mv Moonlight-Switch.nro ./switch
fi
### Fetch lastest JKSV from https://github.com/J-D-K/JKSV/releases/latest
curl -sL https://api.github.com/repos/J-D-K/JKSV/releases/latest \
  | jq '.name' \
  | xargs -I {} echo JKSV {} >> ../description.txt
curl -sL https://api.github.com/repos/J-D-K/JKSV/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o JKSV.nro
if [ $? -ne 0 ]; then
    echo "JKSV download\033[31m failed\033[0m."
else
    echo "JKSV download\033[32m success\033[0m."
    mv JKSV.nro ./switch
fi

### Fetch lastest tencent-switcher-gui from https://github.com/CaiMiao/Tencent-switcher-GUI/releases/latest
curl -sL https://api.github.com/repos/CaiMiao/Tencent-switcher-GUI/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo tencent-switcher-gui {} >> ../description.txt
curl -sL https://api.github.com/repos/CaiMiao/Tencent-switcher-GUI/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o tencent-switcher-gui.nro
if [ $? -ne 0 ]; then
    echo "tencent-switcher-gui download\033[31m failed\033[0m."
else
    echo "tencent-switcher-gui download\033[32m success\033[0m."
    mv tencent-switcher-gui.nro ./switch
fi

### Fetch lastest Breeze from https://github.com/tomvita/Breeze-Beta/releases/latest
curl -sL https://api.github.com/repos/tomvita/Breeze-Beta/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo Breeze {} >> ../description.txt
curl -sL https://api.github.com/repos/tomvita/Breeze-Beta/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o Breeze.zip
if [ $? -ne 0 ]; then
    echo "Breeze download\033[31m failed\033[0m."
else
    echo "Breeze download\033[32m success\033[0m."
    unzip -oq Breeze.zip
    rm Breeze.zip
fi

### Fetch lastest AtmoPackUpdater from https://github.com/PoloNX/AtmoPackUpdater/releases
curl -sL https://api.github.com/repos/PoloNX/AtmoPackUpdater/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo AtmoPackUpdater {} >> ../description.txt
curl -sL https://api.github.com/repos/PoloNX/AtmoPackUpdater/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o AtmoPackUpdater.nro
if [ $? -ne 0 ]; then
    echo "AtmoPackUpdater download\033[31m failed\033[0m."
else
    echo "AtmoPackUpdater download\033[32m success\033[0m."
    mv AtmoPackUpdater.nro ./switch
fi

### Fetch lastest SwitchTime from https://github.com/3096/switch-time/releases
curl -sL https://api.github.com/repos/3096/switch-time/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo switch-time {} >> ../description.txt
curl -sL https://api.github.com/repos/3096/switch-time/releases/latest \
  | jq '.assets' | jq '.[0].browser_download_url' \
  | xargs -I {} curl -sL {} -o switch-time.nro
if [ $? -ne 0 ]; then
    echo "switch-time download\033[31m failed\033[0m."
else
    echo "switch-time download\033[32m success\033[0m."
    mv switch-time.nro ./switch
fi

### Fetch QuickNTP
curl -sL https://raw.githubusercontent.com/huangqian8/SwitchPlugins/main/plugins/QuickNTP.zip -o QuickNTP.zip
if [ $? -ne 0 ]; then
    echo "QuickNTP download\033[31m failed\033[0m."
else
    echo "QuickNTP download\033[32m success\033[0m."
    unzip -oq QuickNTP.zip
    rm QuickNTP.zip
fi

### Fetch lastest theme-patches from https://github.com/exelix11/theme-patches
git clone https://github.com/exelix11/theme-patches
if [ $? -ne 0 ]; then
    echo "theme-patches download\033[31m failed\033[0m."
else
    echo "theme-patches download\033[32m success\033[0m."
    mv -f theme-patches/systemPatches themes/
    rm -rf theme-patches
fi

### Rename hekate_ctcaer_*.bin to payload.bin
find . -name "*hekate_ctcaer*" -exec mv {} payload.bin \;
if [ $? -ne 0 ]; then
    echo "Rename hekate_ctcaer_*.bin to payload.bin\033[31m failed\033[0m."
else
    echo "Rename hekate_ctcaer_*.bin to payload.bin\033[32m success\033[0m."
fi

### Write hekate_ipl.ini in /bootloader/ directory
cat > ./bootloader/hekate_ipl.ini << ENDOFFILE
[config]
autoboot=0
autoboot_list=0
bootwait=3
verification=1
backlight=100
autohosoff=0
autonogc=1
updater2p=1

[大气层虚拟系统]
emummcforce=1
fss0=atmosphere/package3
atmosphere=1
kip1=atmosphere/kips/loader.kip
icon=bootloader/res/icon_Atmosphere_emunand.bmp
id=Atm-Emu
{烤鸭包的自动构建}

[大气层真实系统]
emummc_force_disable=1
fss0=atmosphere/package3
atmosphere=1
kip1=atmosphere/kips/loader.kip
icon=bootloader/res/icon_Atmosphere_sysnand.bmp
id=Atm-Sys
{烤鸭包的自动构建}

[正版系统]
emummc_force_disable=1
fss0=atmosphere/package3
stock=1
icon=bootloader/res/icon_stock.bmp
id=OFW-SYS
{烤鸭包的自动构建}

[大气层自动识别]
payload=bootloader/payloads/fusee.bin
icon=bootloader/res/icon_ams.bmp
id=Atm-Auto
{烤鸭包的自动构建}
[RCM提取密钥]
payload=bootloader/payloads/Lockpick_RCM.bin
icon=bootloader/res/icon_lockpick.bmp
id=RCM-Keys
{烤鸭包的自动构建}
[安全模式]
fss0=atmosphere/package3
emummc_force_disable=1
cal0blank=0
{烤鸭包的自动构建}
ENDOFFILE
if [ $? -ne 0 ]; then
    echo "Writing hekate_ipl.ini in ./bootloader/ directory\033[31m failed\033[0m."
else
    echo "Writing hekate_ipl.ini in ./bootloader/ directory\033[32m success\033[0m."
fi

### Write nyx.ini in /bootloader/ directory
cat > ./bootloader/nyx.ini << ENDOFFILE
[config]
themebg=2d2d2d
themecolor=320
entries5col=0
timeoff=edbe80
homescreen=0
verification=1
umsemmcrw=0
jcdisable=0
jcforceright=0
bpmpclock=1
ENDOFFILE
if [ $? -ne 0 ]; then
    echo "Writing nyx.ini in ./bootloader/ directory\033[31m failed\033[0m."
else
    echo "Writing nyx.ini in ./bootloader/ directory\033[32m success\033[0m."
fi

### write exosphere.ini in root of SD Card
cat > ./exosphere.ini << ENDOFFILE
[exosphere]
debugmode=1
debugmode_user=0
disable_user_exception_handlers=0
enable_user_pmu_access=0
blank_prodinfo_sysmmc=1
blank_prodinfo_emummc=1
allow_writing_to_cal_sysmmc=0
log_port=0
log_baud_rate=115200
log_inverted=0
ENDOFFILE
if [ $? -ne 0 ]; then
    echo "Writing exosphere.ini in root of SD card\033[31m failed\033[0m."
else
    echo "Writing exosphere.ini in root of SD card\033[32m success\033[0m."
fi


### Write emummc.txt in /atmosphere/hosts
cat > ./atmosphere/hosts/emummc.txt << ENDOFFILE
# Block Nintendo Servers
127.0.0.1 *nintendo.*
127.0.0.1 *nintendo-europe.com
127.0.0.1 *nintendoswitch.*
207.246.121.77 *conntest.nintendowifi.net
207.246.121.77 *ctest.cdn.nintendo.net
69.25.139.140 *ctest.cdn.n.nintendoswitch.cn
95.216.149.205 *conntest.nintendowifi.net
95.216.149.205 *ctest.cdn.nintendo.net
95.216.149.205 *90dns.test
ENDOFFILE
cp ./atmosphere/hosts/emummc.txt ./atmosphere/hosts/sysmmc.txt
if [ $? -ne 0 ]; then
    echo "Writing emummc.txt and sysmmc.txt in ./atmosphere/hosts\033[31m failed\033[0m."
else
    echo "Writing emummc.txt and sysmmc.txt in ./atmosphere/hosts\033[32m success\033[0m."
fi

### Write boot.ini in root of SD Card
if [ $? -ne 0 ]; then
    echo "Writing boot.ini in root of SD card\033[31m failed\033[0m."
else
    echo "Writing boot.ini in root of SD card\033[32m success\033[0m."
fi

### Write system_settings.ini in /atmosphere/config
cat > ./atmosphere/config/system_settings.ini << ENDOFFILE
[eupld]
; 禁用将错误报告上传到任天堂
upload_enabled = u8!0x0

[ro]
; 控制 RO 是否应简化其对 NRO 的验证。
; （注意：这通常不是必需的，可以使用 IPS 补丁。
ease_nro_restriction = u8!0x1

[atmosphere]
; 是否自动开启所有金手指。0=关。1=开。
dmnt_cheats_enabled_by_default = u8!0x0

; 如果你希望大气记住你上次金手指状态，请删除下方；号
; dmnt_always_save_cheat_toggles = u8!0x1

; 如果大气崩溃，10秒后自动重启
; 1秒=1000毫秒，转换16进制
fatal_auto_reboot_interval = u64!0x2710

; 使电源菜单的“重新启动”按钮重新启动到payload
; 设置"normal"正常重启l 设置"rcm"重启RCM，
; power_menu_reboot_function = str!payload

; 启动90DNS与任天堂服务器屏蔽
enable_dns_mitm = u8!0x1
add_defaults_to_dns_hosts = u8!0x1

; 是否将蓝牙配对数据库用与虚拟系统
enable_external_bluetooth_db = u8!0x1

[usb]
; 开启USB3.0   尾数改为0是关闭
usb30_force_enabled = u8!0x1

[tc]
sleep_enabled = u8!0x0
holdable_tskin = u32!0xEA60
tskin_rate_table_console = str!”[[-1000000, 28000, 0, 0], [28000, 42000, 0, 51], [42000, 48000, 51, 102], [48000, 55000, 102, 153], [55000, 60000, 153, 255], [60000, 68000, 255, 255]]”
tskin_rate_table_handheld = str!”[[-1000000, 28000, 0, 0], [28000, 42000, 0, 51], [42000, 48000, 51, 102], [48000, 55000, 102, 153], [55000, 60000, 153, 255], [60000, 68000, 255, 255]]”
ENDOFFILE
if [ $? -ne 0 ]; then
    echo "Writing system_settings.ini in ./atmosphere/config\033[31m failed\033[0m."
else
    echo "Writing system_settings.ini in ./atmosphere/config\033[32m success\033[0m."
fi



### Fetch lastest Ultrahand-Overlay from https://github.com/ppkantorski/Ultrahand-Overlay/releases/latest
# curl -sL https://api.github.com/repos/ppkantorski/Ultrahand-Overlay/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo Ultrahand-Overlay {} >> ../description.txt
# curl -sL https://api.github.com/repos/ppkantorski/Ultrahand-Overlay/releases/latest \
#   | jq '.assets' | jq '.[1].browser_download_url' \
#   | xargs -I {} curl -sL {} -o ovlmenu.ovl
# if [ $? -ne 0 ]; then
#     echo "Ultrahand-Overlay download\033[31m failed\033[0m."
# else
#     echo "Ultrahand-Overlay download\033[32m success\033[0m."
#     mv ovlmenu.ovl ./switch/.overlays
# fi

# curl -sL https://api.github.com/repos/ndeadly/MissionControl/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo MissionControl {} >> ../description.txt

# curl -sL https://api.github.com/repos/ndeadly/MissionControl/releases/latest \
#   | jq '.assets' | jq '.[0].browser_download_url' \
#   | xargs -I {} curl -sL {} -o MissionControl.zip

# if [ $? -ne 0 ]; then
#     echo "MissionControl download\033[31m failed\033[0m."
# else
#     echo "MissionControl download\033[32m success\033[0m."
#     unzip -oq MissionControl.zip
#     rm MissionControl.zip
# fi



# ### Write config.ini in Ultrahand-Overlay
# mkdir -p config/ultrahand
# cat > ./config/ultrahand/config.ini << ENDOFFILE
# [ultrahand]
# default_lang = zh-cn
# default_menu = overlays
# last_menu = overlays
# in_overlay = false
# key_combo = L+DDOWN
# hide_user_guide = false
# clean_version_labels = true
# hide_overlay_versions = false
# hide_package_versions = false
# datetime_format = '%a %T'
# hide_clock = false
# hide_battery = true
# hide_pcb_temp = true
# hide_soc_temp = true
# ENDOFFILE
# if [ $? -ne 0 ]; then
#     echo "Write config.ini in Ultrahand-Overlay\033[31m failed\033[0m."
# else
#     echo "Write config.ini in Ultrahand-Overlay\033[32m success\033[0m."
# fi

###
cat >> ../description.txt << ENDOFFILE
DBI 647 中文版
EdiZon
HekateToolbox
ovl-sysmodules
ovlloader
ovlmenu
ReverseNX-RT
StatusMonitor
sys-con
tencent-switcher-gui
Tinfoil-17v3
ENDOFFILE

### Fetch lastest Zing from https://github.com/tomvita/Zing/releases/latest
curl -sL https://api.github.com/repos/tomvita/Zing/releases/latest \
  | jq '.tag_name' \
  | xargs -I {} echo Zing {} >> ../description.txt
curl -sL https://api.github.com/repos/tomvita/Zing/releases/latest \
  | jq '.assets' | jq '.[1].browser_download_url' \
  | xargs -I {} curl -sL {} -o Zing.ovl
if [ $? -ne 0 ]; then
    echo "Zing download\033[31m failed\033[0m."
else
    echo "Zing download\033[32m success\033[0m."
    mv Zing.ovl ./switch/.overlays
fi


### Fetch sys-tune
curl -sL https://raw.githubusercontent.com/huangqian8/SwitchPlugins/main/plugins/sys-tune.zip -o sys-tune.zip
if [ $? -ne 0 ]; then
    echo "sys-tune download\033[31m failed\033[0m."
else
    echo "sys-tune download\033[32m success\033[0m."
    unzip -oq sys-tune.zip
    rm sys-tune.zip
fi

### Fetch sys-patch
curl -sL https://raw.githubusercontent.com/huangqian8/SwitchPlugins/main/plugins/sys-patch.zip -o sys-patch.zip
if [ $? -ne 0 ]; then
    echo "sys-patch download\033[31m failed\033[0m."
else
    echo "sys-patch download\033[32m success\033[0m."
    unzip -oq sys-patch.zip
    rm sys-patch.zip
fi

### Fetch Ultra_Tuner
# curl -sL https://raw.github.com/烤鸭包的2025/SwitchScript/main/plugins/Ultrahand/Ultra_Tuner.zip -o Ultra_Tuner.zip
# if [ $? -ne 0 ]; then
#     echo "Ultra_Tuner download\033[31m failed\033[0m."
# else
#     echo "Ultra_Tuner download\033[32m success\033[0m."
#     unzip -oq Ultra_Tuner.zip
#     rm Ultra_Tuner.zip
# fi

## Fetch Switch-OC-Suite(hnayzdf ver.) from https://www.tekqart.com/thread-370908-1-1.html
# curl -sL https://raw.github.com/烤鸭包的2025/SwitchScript/main/plugins/Switch-OC-Suite.zip -o Switch-OC-Suite.zip
# if [ $? -ne 0 ]; then
#    echo "Switch-OC-Suite download\033[31m failed\033[0m."
# else
#    echo "Switch-OC-Suite download\033[32m success\033[0m."
#    unzip -oq Switch-OC-Suite.zip
#    rm Switch-OC-Suite.zip
# fi

# ### Fetch lastest Switch-OC-Suite from https://github.com/hanai3Bi/Switch-OC-Suite/releases/latest
# curl -sL https://api.github.com/repos/hanai3Bi/Switch-OC-Suite/releases/latest \
#   | jq '.tag_name' \
#   | xargs -I {} echo Switch-OC-Suite {} >> ../description.txt
# curl -sL https://api.github.com/repos/hanai3Bi/Switch-OC-Suite/releases/latest \
#   | jq '.assets' | jq '.[0].browser_download_url' \
#   | xargs -I {} curl -sL {} -o AIO.zip
# if [ $? -ne 0 ]; then
#     echo "Switch-OC-Suite download\033[31m failed\033[0m."
# else
#     echo "Switch-OC-Suite download\033[32m success\033[0m."
#     unzip -oq AIO.zip
#     rm AIO.zip
# fi


# 写入到 "烤鸭包的自动构建.txt" 文件中
cat ../description.txt > 烤鸭包的自动构建.txt << ENDOFFILE
$atmosphere_name+$hekate_name
ENDOFFILE
if [ $? -ne 0 ]; then
    echo "Writing 烤鸭包的自动构建.txt\033[31m failed\033[0m."
else
    echo "Writing 烤鸭包的自动构建.txt\033[32m success\033[0m."
fi

### Fetch Chinese lang
mkdir -p switch/.overlays/lang/fastCFWswitch
curl -sL https://raw.githubusercontent.com/zdm65477730/fastCFWswitch/master/lang/zh-Hans.json -o switch/.overlays/lang/fastCFWswitch/zh-Hans.json
curl -sL https://raw.githubusercontent.com/zdm65477730/fastCFWswitch/master/lang/zh-Hant.json -o switch/.overlays/lang/fastCFWswitch/zh-Hant.json
mkdir -p switch/.overlays/lang/QuickNTP
curl -sL https://raw.githubusercontent.com/zdm65477730/QuickNTP/master/lang/zh-Hans.json -o switch/.overlays/lang/QuickNTP/zh-Hans.json
curl -sL https://raw.githubusercontent.com/zdm65477730/QuickNTP/master/lang/zh-Hant.json -o switch/.overlays/lang/QuickNTP/zh-Hant.json
mkdir -p switch/.overlays/lang/sys-clk
curl -sL https://raw.githubusercontent.com/zdm65477730/sys-clk/develop/overlay/lang/zh-Hans.json -o switch/.overlays/lang/sys-clk/zh-Hans.json
curl -sL https://raw.githubusercontent.com/zdm65477730/sys-clk/develop/overlay/lang/zh-Hant.json -o switch/.overlays/lang/sys-clk/zh-Hant.json
mkdir -p config/ultrahand/lang
curl -sL https://raw.githubusercontent.com/ppkantorski/Ultrahand-Overlay/main/lang/zh-cn.json -o config/ultrahand/lang/zh-cn.json

### Write sort.cfg in /config/Tesla-Menu/sort.cfg
cat > ./config/Tesla-Menu/sort.cfg << ENDOFFILE
EdiZon
ovl-sysmodules
StatusMonitor
sys-clk-overlay
ReverseNX-RT
fastcfwswitch
ldn_mitm
emuiibo
QuickNTP
Zing
sys-patch
linkalho
ENDOFFILE

# -------------------------------------------

echo ""
echo "\033[32mYour Switch SD card is prepared! 烤鸭包的的自动构建已经完成\033[0m"
