#!/bin/sh
set -e

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

# -------------------------------------------
### 获取 Atmosphere
echo "正在下载 Atmosphere..."
atmosphere_release=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases)
is_prerelease=$(echo "$atmosphere_release" | jq '.[0].prerelease')

# 下载 Atmosphere
atmosphere_url=$(echo "$atmosphere_release" | jq -r '.[0].assets[0].browser_download_url')
curl -sL "$atmosphere_url" -o atmosphere.zip

# 下载 Fusee
fusee_url=$(echo "$atmosphere_release" | jq -r '.[0].assets[] | select(.name == "fusee.bin") | .browser_download_url')
curl -sL "$fusee_url" -o fusee.bin

if [ $? -ne 0 ]; then
    echo "Atmosphere 下载\033[31m失败\033[0m"
else
    echo "Atmosphere 下载\033[32m成功\033[0m"
    unzip -oq atmosphere.zip
    rm atmosphere.zip
    
    # 记录版本信息
    echo "$atmosphere_release" | jq -r '.[0].name' >> ../description.txt
fi

# -------------------------------------------
### 获取 Hekate + Nyx 中文版
echo "正在下载 Hekate + Nyx 中文版..."
hekate_release=$(curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest)
hekate_name=$(echo "$hekate_release" | jq -r '.name')

# 记录版本信息
echo "$hekate_name" >> ../description.txt

# 下载 Hekate
hekate_url=$(echo "$hekate_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$hekate_url" -o hekate.zip

if [ $? -ne 0 ]; then
    echo "Hekate + Nyx 下载\033[31m失败\033[0m"
else
    echo "Hekate + Nyx 下载\033[32m成功\033[0m"
    unzip -oq hekate.zip
    rm hekate.zip
    mv fusee.bin ./bootloader/payloads/
fi

# -------------------------------------------
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

# -------------------------------------------
### 其他组件下载
echo "下载 SaltyNX..."
salty_release=$(curl -sL https://api.github.com/repos/masagrator/SaltyNX/releases/latest)
salty_name=$(echo "$salty_release" | jq -r '.name')
echo "$salty_name" >> ../description.txt

salty_url=$(echo "$salty_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$salty_url" -o SaltyNX.zip
if [ $? -eq 0 ]; then
    unzip -oq SaltyNX.zip
    rm SaltyNX.zip
    echo "SaltyNX 下载\033[32m成功\033[0m"
else
    echo "SaltyNX 下载\033[31m失败\033[0m"
fi

echo "下载 SysDVR..."
sysdvr_release=$(curl -sL https://api.github.com/repos/exelix11/SysDVR/releases/latest)
sysdvr_tag=$(echo "$sysdvr_release" | jq -r '.tag_name')
echo "SysDVR $sysdvr_tag" >> ../description.txt

sysdvr_url=$(echo "$sysdvr_release" | jq -r '.assets[7].browser_download_url')
curl -sL "$sysdvr_url" -o SysDVR.zip
if [ $? -eq 0 ]; then
    unzip -oq SysDVR.zip
    rm SysDVR.zip
    echo "SysDVR 下载\033[32m成功\033[0m"
else
    echo "SysDVR 下载\033[31m失败\033[0m"
fi

echo "下载 sys-clk..."
sysclk_release=$(curl -sL https://api.github.com/repos/retronx-team/sys-clk/releases/latest)
sysclk_tag=$(echo "$sysclk_release" | jq -r '.tag_name')
echo "sys-clk $sysclk_tag" >> ../description.txt

sysclk_url=$(echo "$sysclk_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$sysclk_url" -o sys_clk.zip
if [ $? -eq 0 ]; then
    unzip -oq sys_clk.zip
    rm sys_clk.zip
    echo "sys-clk 下载\033[32m成功\033[0m"
else
    echo "sys-clk 下载\033[31m失败\033[0m"
fi

echo "下载 Tesla..."
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/Tesla.zip -o Tesla.zip
if [ $? -eq 0 ]; then
    unzip -oq Tesla.zip
    rm Tesla.zip
    echo "Tesla 下载\033[32m成功\033[0m"
else
    echo "Tesla 下载\033[31m失败\033[0m"
fi

echo "下载 boot.dat..."
curl -sL https://raw.github.com/naixue666/naixue_nx_atm_Auto_Script/main/resources/boot.dat -o boot.dat
if [ $? -eq 0 ]; then
    echo "boot.dat 下载\033[32m成功\033[0m"
else
    echo "boot.dat 下载\033[31m失败\033[0m"
fi

echo "下载 SigPatches..."
curl -sL "https://sigmapatches.su/sigpatches.zip?$(date +%d.%m.%Y)" -o sigpatches.zip
if [ $? -eq 0 ]; then
    unzip -oq sigpatches.zip
    rm sigpatches.zip
    echo "SigPatches 下载\033[32m成功\033[0m"
else
    echo "SigPatches 下载\033[31m失败\033[0m"
fi

echo "下载 Bootloader 资源..."
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/bootloader.zip -o bootloader.zip
if [ $? -eq 0 ]; then
    unzip -oq bootloader.zip
    rm bootloader.zip
    echo "Bootloader 资源下载\033[32m成功\033[0m"
else
    echo "Bootloader 资源下载\033[31m失败\033[0m"
fi

echo "下载 picofly_toolbox..."
curl -sL https://raw.github.com/Ansem-SoD/Picofly/main/Firmwares/picofly_toolbox_0.2.bin -o picofly_toolbox_0.2.bin
if [ $? -eq 0 ]; then
    mv picofly_toolbox_0.2.bin ./bootloader/payloads
    echo "picofly_toolbox 下载\033[32m成功\033[0m"
    echo "picofly_toolbox_0.2" >> ../description.txt
else
    echo "picofly_toolbox 下载\033[31m失败\033[0m"
fi

echo "下载 hwfly-toolbox..."
hwfly_release=$(curl -sL https://api.github.com/repos/hwfly-nx/hwfly-toolbox/releases/latest)
hwfly_tag=$(echo "$hwfly_release" | jq -r '.tag_name')
echo "hwfly-toolbox $hwfly_tag" >> ../description.txt

hwfly_url=$(echo "$hwfly_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$hwfly_url" -o hwfly_toolbox.bin
if [ $? -eq 0 ]; then
    mv hwfly_toolbox.bin ./bootloader/payloads
    echo "hwfly-toolbox 下载\033[32m成功\033[0m"
else
    echo "hwfly-toolbox 下载\033[31m失败\033[0m"
fi

echo "下载 CommonProblemResolver..."
cpr_release=$(curl -sL https://api.github.com/repos/zdm65477730/CommonProblemResolver/releases/latest)
cpr_tag=$(echo "$cpr_release" | jq -r '.tag_name')
echo "CommonProblemResolver $cpr_tag" >> ../description.txt

cpr_url=$(echo "$cpr_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$cpr_url" -o CommonProblemResolver.bin
if [ $? -eq 0 ]; then
    mv CommonProblemResolver.bin ./bootloader/payloads
    echo "CommonProblemResolver 下载\033[32m成功\033[0m"
else
    echo "CommonProblemResolver 下载\033[31m失败\033[0m"
fi

echo "下载 wiliwili..."
wiliwili_release=$(curl -sL https://api.github.com/repos/xfangfang/wiliwili/releases/latest)
wiliwili_tag=$(echo "$wiliwili_release" | jq -r '.tag_name')
echo "wiliwili $wiliwili_tag" >> ../description.txt

wiliwili_url=$(echo "$wiliwili_release" | jq -r '.assets[9].browser_download_url')
curl -sL "$wiliwili_url" -o wiliwili-NintendoSwitch.zip
if [ $? -eq 0 ]; then
    unzip -oq wiliwili-NintendoSwitch.zip
    mkdir -p ./switch/wiliwili
    mv wiliwili/wiliwili.nro ./switch/wiliwili
    rm -rf wiliwili
    rm wiliwili-NintendoSwitch.zip
    echo "wiliwili 下载\033[32m成功\033[0m"
else
    echo "wiliwili 下载\033[31m失败\033[0m"
fi

echo "下载 HB-Appstore..."
appstore_release=$(curl -sL https://api.github.com/repos/fortheusers/hb-appstore/releases/latest)
appstore_tag=$(echo "$appstore_release" | jq -r '.tag_name')
echo "HB-Appstore $appstore_tag" >> ../description.txt

appstore_url=$(echo "$appstore_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$appstore_url" -o appstore.nro
if [ $? -eq 0 ]; then
    mv appstore.nro ./switch
    echo "HB-Appstore 下载\033[32m成功\033[0m"
else
    echo "HB-Appstore 下载\033[31m失败\033[0m"
fi

echo "下载 Goldleaf..."
goldleaf_release=$(curl -sL https://api.github.com/repos/XorTroll/Goldleaf/releases/latest)
goldleaf_tag=$(echo "$goldleaf_release" | jq -r '.tag_name')
echo "Goldleaf $goldleaf_tag" >> ../description.txt

goldleaf_url=$(echo "$goldleaf_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$goldleaf_url" -o Goldleaf.nro
if [ $? -eq 0 ]; then
    mv Goldleaf.nro ./switch/Goldleaf
    echo "Goldleaf 下载\033[32m成功\033[0m"
else
    echo "Goldleaf 下载\033[31m失败\033[0m"
fi

echo "下载 Switch_90DNS_tester..."
dns_tester_release=$(curl -sL https://api.github.com/repos/meganukebmp/Switch_90DNS_tester/releases/latest)
dns_tester_tag=$(echo "$dns_tester_release" | jq -r '.tag_name')
echo "Switch_90DNS_tester $dns_tester_tag" >> ../description.txt

dns_tester_url=$(echo "$dns_tester_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$dns_tester_url" -o Switch_90DNS_tester.nro
if [ $? -eq 0 ]; then
    mv Switch_90DNS_tester.nro ./switch
    echo "Switch_90DNS_tester 下载\033[32m成功\033[0m"
else
    echo "Switch_90DNS_tester 下载\033[31m失败\033[0m"
fi

echo "下载 Checkpoint..."
checkpoint_release=$(curl -sL https://api.github.com/repos/BernardoGiordano/Checkpoint/releases/latest)
checkpoint_tag=$(echo "$checkpoint_release" | jq -r '.tag_name')
echo "Checkpoint $checkpoint_tag" >> ../description.txt

checkpoint_url=$(echo "$checkpoint_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$checkpoint_url" -o Checkpoint.nro
if [ $? -eq 0 ]; then
    mv Checkpoint.nro ./switch/Checkpoint
    echo "Checkpoint 下载\033[32m成功\033[0m"
else
    echo "Checkpoint 下载\033[31m失败\033[0m"
fi

echo "下载 DBI..."
curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/DBI.nro -o DBI.nro
if [ $? -eq 0 ]; then
    mv DBI.nro ./switch/DBI
    echo "DBI.nro 下载\033[32m成功\033[0m"
else
    echo "DBI.nro 下载\033[31m失败\033[0m"
fi

curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/.DBI.nro.star -o .DBI.nro.star
if [ $? -eq 0 ]; then
    mv .DBI.nro.star ./switch/DBI
    echo ".DBI.nro.star 下载\033[32m成功\033[0m"
else
    echo ".DBI.nro.star 下载\033[31m失败\033[0m"
fi

curl -sL https://raw.github.com/naixue666/AutoAtmosBuilder/main/resources/linkalho.nro -o linkalho.nro
if [ $? -eq 0 ]; then
    mv linkalho.nro ./switch
    echo "linkalho.nro 下载\033[32m成功\033[0m"
else
    echo "linkalho.nro 下载\033[31m失败\033[0m"
fi

echo "下载 Awoo Installer..."
awoo_release=$(curl -sL https://api.github.com/repos/dragonflylee/Awoo-Installer/releases/latest)
awoo_name=$(echo "$awoo_release" | jq -r '.name')
echo "$awoo_name" >> ../description.txt

awoo_url=$(echo "$awoo_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$awoo_url" -o Awoo-Installer.zip
if [ $? -eq 0 ]; then
    unzip -oq Awoo-Installer.zip
    rm Awoo-Installer.zip
    echo "Awoo Installer 下载\033[32m成功\033[0m"
else
    echo "Awoo Installer 下载\033[31m失败\033[0m"
fi

echo "下载 HekateToolbox..."
hekate_toolbox_release=$(curl -sL https://api.github.com/repos/WerWolv/Hekate-Toolbox/releases/latest)
hekate_toolbox_tag=$(echo "$hekate_toolbox_release" | jq -r '.tag_name')
echo "HekateToolbox $hekate_toolbox_tag" >> ../description.txt

hekate_toolbox_url=$(echo "$hekate_toolbox_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$hekate_toolbox_url" -o HekateToolbox.nro
if [ $? -eq 0 ]; then
    mv HekateToolbox.nro ./switch
    echo "HekateToolbox 下载\033[32m成功\033[0m"
else
    echo "HekateToolbox 下载\033[31m失败\033[0m"
fi

echo "下载 NX-Activity-Log..."
nx_activity_release=$(curl -sL https://api.github.com/repos/zdm65477730/NX-Activity-Log/releases/latest)
nx_activity_tag=$(echo "$nx_activity_release" | jq -r '.tag_name')
echo "NX-Activity-Log $nx_activity_tag" >> ../description.txt

nx_activity_url=$(echo "$nx_activity_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$nx_activity_url" -o NX-Activity-Log.nro
if [ $? -eq 0 ]; then
    mv NX-Activity-Log.nro ./switch
    echo "NX-Activity-Log 下载\033[32m成功\033[0m"
else
    echo "NX-Activity-Log 下载\033[31m失败\033[0m"
fi

echo "下载 NXThemesInstaller..."
nx_themes_release=$(curl -sL https://api.github.com/repos/exelix11/SwitchThemeInjector/releases/latest)
nx_themes_tag=$(echo "$nx_themes_release" | jq -r '.tag_name')
echo "NXThemesInstaller $nx_themes_tag" >> ../description.txt

nx_themes_url=$(echo "$nx_themes_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$nx_themes_url" -o NXThemesInstaller.nro
if [ $? -eq 0 ]; then
    mv NXThemesInstaller.nro ./switch
    echo "NXThemesInstaller 下载\033[32m成功\033[0m"
else
    echo "NXThemesInstaller 下载\033[31m失败\033[0m"
fi

echo "下载 Moonlight-Switch..."
moonlight_release=$(curl -sL https://api.github.com/repos/XITRIX/Moonlight-Switch/releases/latest)
moonlight_tag=$(echo "$moonlight_release" | jq -r '.tag_name')
echo "Moonlight-Switch $moonlight_tag" >> ../description.txt

moonlight_url=$(echo "$moonlight_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$moonlight_url" -o Moonlight-Switch.nro
if [ $? -eq 0 ]; then
    mv Moonlight-Switch.nro ./switch
    echo "Moonlight-Switch 下载\033[32m成功\033[0m"
else
    echo "Moonlight-Switch 下载\033[31m失败\033[0m"
fi

echo "下载 JKSV..."
jksv_release=$(curl -sL https://api.github.com/repos/J-D-K/JKSV/releases/latest)
jksv_name=$(echo "$jksv_release" | jq -r '.name')
echo "$jksv_name" >> ../description.txt

jksv_url=$(echo "$jksv_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$jksv_url" -o JKSV.nro
if [ $? -eq 0 ]; then
    mv JKSV.nro ./switch
    echo "JKSV 下载\033[32m成功\033[0m"
else
    echo "JKSV 下载\033[31m失败\033[0m"
fi

echo "下载 tencent-switcher-gui..."
tencent_release=$(curl -sL https://api.github.com/repos/CaiMiao/Tencent-switcher-GUI/releases/latest)
tencent_tag=$(echo "$tencent_release" | jq -r '.tag_name')
echo "tencent-switcher-gui $tencent_tag" >> ../description.txt

tencent_url=$(echo "$tencent_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$tencent_url" -o tencent-switcher-gui.nro
if [ $? -eq 0 ]; then
    mv tencent-switcher-gui.nro ./switch
    echo "tencent-switcher-gui 下载\033[32m成功\033[0m"
else
    echo "tencent-switcher-gui 下载\033[31m失败\033[0m"
fi

echo "下载 Breeze..."
breeze_release=$(curl -sL https://api.github.com/repos/tomvita/Breeze-Beta/releases/latest)
breeze_tag=$(echo "$breeze_release" | jq -r '.tag_name')
echo "Breeze $breeze_tag" >> ../description.txt

breeze_url=$(echo "$breeze_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$breeze_url" -o Breeze.zip
if [ $? -eq 0 ]; then
    unzip -oq Breeze.zip
    rm Breeze.zip
    echo "Breeze 下载\033[32m成功\033[0m"
else
    echo "Breeze 下载\033[31m失败\033[0m"
fi

echo "下载 AtmoPackUpdater..."
atmo_updater_release=$(curl -sL https://api.github.com/repos/PoloNX/AtmoPackUpdater/releases/latest)
atmo_updater_tag=$(echo "$atmo_updater_release" | jq -r '.tag_name')
echo "AtmoPackUpdater $atmo_updater_tag" >> ../description.txt

atmo_updater_url=$(echo "$atmo_updater_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$atmo_updater_url" -o AtmoPackUpdater.nro
if [ $? -eq 0 ]; then
    mv AtmoPackUpdater.nro ./switch
    echo "AtmoPackUpdater 下载\033[32m成功\033[0m"
else
    echo "AtmoPackUpdater 下载\033[31m失败\033[0m"
fi

echo "下载 SwitchTime..."
switch_time_release=$(curl -sL https://api.github.com/repos/3096/switch-time/releases/latest)
switch_time_tag=$(echo "$switch_time_release" | jq -r '.tag_name')
echo "switch-time $switch_time_tag" >> ../description.txt

switch_time_url=$(echo "$switch_time_release" | jq -r '.assets[0].browser_download_url')
curl -sL "$switch_time_url" -o switch-time.nro
if [ $? -eq 0 ]; then
    mv switch-time.nro ./switch
    echo "switch-time 下载\033[32m成功\033[0m"
else
    echo "switch-time 下载\033[31m失败\033[0m"
fi

echo "下载 QuickNTP..."
curl -sL https://raw.githubusercontent.com/huangqian8/SwitchPlugins/main/plugins/QuickNTP.zip -o QuickNTP.zip
if [ $? -eq 0 ]; then
    unzip -oq QuickNTP.zip
    rm QuickNTP.zip
    echo "QuickNTP 下载\033[32m成功\033[0m"
else
    echo "QuickNTP 下载\033[31m失败\033[0m"
fi

echo "下载 theme-patches..."
git clone -q https://github.com/exelix11/theme-patches
if [ $? -eq 0 ]; then
    mv -f theme-patches/systemPatches themes/
    rm -rf theme-patches
    echo "theme-patches 下载\033[32m成功\033[0m"
else
    echo "theme-patches 下载\033[31m失败\033[0m"
fi

# -------------------------------------------
### 配置文件处理
echo "重命名 hekate_ctcaer 文件..."
find . -name "*hekate_ctcaer*" -exec mv {} payload.bin \;
if [ $? -eq 0 ]; then
    echo "重命名成功"
else
    echo "重命名失败"
fi

echo "创建 hekate_ipl.ini..."
cat > ./bootloader/hekate_ipl.ini << 'END'
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
END

echo "创建 nyx.ini..."
cat > ./bootloader/nyx.ini << 'END'
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
END

echo "创建 exosphere.ini..."
cat > ./exosphere.ini << 'END'
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
END

echo "创建 hosts 文件..."
cat > ./atmosphere/hosts/emummc.txt << 'END'
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
END
cp ./atmosphere/hosts/emummc.txt ./atmosphere/hosts/sysmmc.txt

echo "创建 system_settings.ini..."
cat > ./atmosphere/config/system_settings.ini << 'END'
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

; 使电源菜单的"重新启动"按钮重新启动到payload
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
tskin_rate_table_console = str!"[[-1000000, 28000, 0, 0], [28000, 42000, 0, 51], [42000, 48000, 51, 102], [48000, 55000, 102, 153], [55000, 60000, 153, 255], [60000, 68000, 255, 255]]"
tskin_rate_table_handheld = str!"[[-1000000, 28000, 0, 0], [28000, 42000, 0, 51], [42000, 48000, 51, 102], [48000, 55000, 102, 153], [55000, 60000, 153, 255], [60000, 68000, 255, 255]]"
END

# -------------------------------------------
### 其他组件
echo "添加描述信息..."
cat >> ../description.txt << 'END'
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
END

echo "下载 Zing..."
zing_release=$(curl -sL https://api.github.com/repos/tomvita/Zing/releases/latest)
zing_tag=$(echo "$zing_release" | jq -r '.tag_name')
echo "Zing $zing_tag" >> ../description.txt

zing_url=$(echo "$zing_release" | jq -r '.assets[1].browser_download_url')
curl -sL "$zing_url" -o Zing.ovl
if [ $? -eq 0 ]; then
    mv Zing.ovl ./switch/.overlays
    echo "Zing 下载\033[32m成功\033[0m"
else
    echo "Zing 下载\033[31m失败\033[0m"
fi

echo "下载 sys-tune..."
curl -sL https://raw.githubusercontent.com/huangqian8/SwitchPlugins/main/plugins/sys-tune.zip -o sys-tune.zip
if [ $? -eq 0 ]; then
    unzip -oq sys-tune.zip
    rm sys-tune.zip
    echo "sys-tune 下载\033[32m成功\033[0m"
else
    echo "sys-tune 下载\033[31m失败\033[0m"
fi

echo "下载 sys-patch..."
curl -sL https://raw.githubusercontent.com/huangqian8/SwitchPlugins/main/plugins/sys-patch.zip -o sys-patch.zip
if [ $? -eq 0 ]; then
    unzip -oq sys-patch.zip
    rm sys-patch.zip
    echo "sys-patch 下载\033[32m成功\033[0m"
else
    echo "sys-patch 下载\033[31m失败\033[0m"
fi

# -------------------------------------------
### 语言文件
echo "下载中文语言文件..."
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

echo "创建 Tesla-Menu 排序配置..."
cat > ./config/Tesla-Menu/sort.cfg << 'END'
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
END

# -------------------------------------------
### 完成
echo "创建构建信息文件..."
cat ../description.txt > "烤鸭包的自动构建.txt"

echo ""
echo "\033[32m您的 Switch SD 卡已准备就绪! 烤鸭包的自动构建已完成\033[0m"
echo "包含以下组件:"
cat ../description.txt
