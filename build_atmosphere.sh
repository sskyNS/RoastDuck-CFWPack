#!/bin/bash
set -e

# 安装依赖
if ! command -v jq &> /dev/null; then
    echo "正在安装 jq..."
    sudo apt-get update
    sudo apt-get install -y jq unzip
fi

# 创建目录结构
WORK_DIR="SwitchSD"
[ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

mkdir -p {atmosphere/{config,hosts},switch/{DBI,Goldleaf,Checkpoint,.packages,.overlays},warmboot_mariko,themes,bootloader/{ini,res,payloads},config/{tesla,Tesla-Menu}}

# 获取当前日期
CURRENT_DATE=$(date +%Y%m%d)

# 下载 Atmosphere
echo "下载 Atmosphere..."
ATMOSPHERE_URL=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq -r '.[0].assets[0].browser_download_url')
curl -sL "$ATMOSPHERE_URL" -o atmosphere.zip
unzip -q atmosphere.zip
rm atmosphere.zip

# 下载 Hekate
echo "下载 Hekate..."
HEKATE_URL=$(curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest | jq -r '.assets[0].browser_download_url')
curl -sL "$HEKATE_URL" -o hekate.zip
unzip -q hekate.zip
rm hekate.zip



for url in "${COMPONENTS[@]}"; do
    filename=$(basename "$url")
    echo "下载 $filename..."
    curl -sL "$url" -o "$filename"
    if [[ $filename == *.zip ]]; then
        unzip -q "$filename"
        rm "$filename"
    fi
done


for url in "${APPS[@]}"; do
    filename=$(basename "$url")
    echo "下载 $filename..."
    curl -sL "$url" -o "$filename"
    if [[ $filename == *.nro ]]; then
        mv "$filename" switch/
    elif [[ $filename == *.star ]]; then
        mv "$filename" switch/DBI/
    fi
done

# 创建配置文件
echo "创建配置文件..."

# hekate_ipl.ini
cat > bootloader/hekate_ipl.ini << 'END'
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
{自动构建}

[大气层真实系统]
emummc_force_disable=1
fss0=atmosphere/package3
atmosphere=1
kip1=atmosphere/kips/loader.kip
icon=bootloader/res/icon_Atmosphere_sysnand.bmp
id=Atm-Sys
{自动构建}

[正版系统]
emummc_force_disable=1
fss0=atmosphere/package3
stock=1
icon=bootloader/res/icon_stock.bmp
id=OFW-SYS
{自动构建}
END

# exosphere.ini
cat > exosphere.ini << 'END'
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

# hosts 文件
cat > atmosphere/hosts/emummc.txt << 'END'
# Block Nintendo Servers
127.0.0.1 *nintendo.*
127.0.0.1 *nintendo-europe.com
127.0.0.1 *nintendoswitch.*
207.246.121.77 *conntest.nintendowifi.net
207.246.121.77 *ctest.cdn.nintendo.net
95.216.149.205 *conntest.nintendowifi.net
95.216.149.205 *ctest.cdn.nintendo.net
95.216.149.205 *90dns.test
END
cp atmosphere/hosts/emummc.txt atmosphere/hosts/sysmmc.txt

# 创建版本信息
echo "大气层整合包 - 自动构建" > version.txt
echo "构建日期: $(date +%Y-%m-%d)" >> version.txt
echo "包含组件: Atmosphere, Hekate, Tesla, DBI" >> version.txt

# 打包结果
cd ..
zip -r "SwitchSD_${CURRENT_DATE}.zip" SwitchSD
echo "构建完成: SwitchSD_${CURRENT_DATE}.zip"