#!/bin/bash
set -e

# 配置文件路径
CONFIG_FILE="$HOME/.switchsd_updater"
WORK_DIR="SwitchSD"
CURRENT_DATE=$(date +%Y%m%d)
LAST_UPDATE_FILE="$HOME/.switchsd_last_update"

# 检查是否需要更新（每周一次）
check_update_frequency() {
    if [ -f "$LAST_UPDATE_FILE" ]; then
        last_update=$(cat "$LAST_UPDATE_FILE")
        current_week=$(date +%Y-%U)
        last_week=$(date -d "$last_update" +%Y-%U 2>/dev/null || echo "")
        
        if [ "$current_week" = "$last_week" ]; then
            echo "本周已更新过，跳过自动更新检查"
            echo "如需强制更新，请删除文件: $LAST_UPDATE_FILE"
            return 1
        fi
    fi
    return 0
}

# 记录更新日期
record_update_date() {
    date +%Y-%m-%d > "$LAST_UPDATE_FILE"
    echo "更新日期已记录: $(cat "$LAST_UPDATE_FILE")"
}

# 检查并更新脚本自身
self_update() {
    SCRIPT_URL="https://raw.githubusercontent.com/yourusername/switchsd-updater/main/updater.sh"  # 修改为你的脚本地址
    
    echo "检查脚本更新..."
    if ! command -v git &> /dev/null; then
        sudo apt-get install -y git curl
    fi
    
    # 这里可以添加检查GitHub是否有新版本的逻辑
    # 暂时跳过，你可以根据实际情况实现
    echo "跳过脚本自更新（需要配置GitHub仓库）"
}

# 安装依赖
install_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "正在安装 jq..."
        sudo apt-get update
        sudo apt-get install -y jq unzip curl git
    fi
}

# 清理工作目录
clean_work_dir() {
    [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
}

# 创建目录结构
create_directory_structure() {
    mkdir -p {atmosphere/{config,hosts},switch/{DBI,Goldleaf,Checkpoint,.packages,.overlays},warmboot_mariko,themes,bootloader/{ini,res,payloads},config/{tesla,Tesla-Menu}}
}

# 下载 Atmosphere
download_atmosphere() {
    echo "下载 Atmosphere..."
    ATMOSPHERE_URL=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq -r '.[0].assets[0].browser_download_url')
    ATMOSPHERE_VERSION=$(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq -r '.[0].tag_name')
    echo "Atmosphere 版本: $ATMOSPHERE_VERSION"
    
    curl -sL "$ATMOSPHERE_URL" -o atmosphere.zip
    unzip -q atmosphere.zip
    rm atmosphere.zip
}

# 下载 Hekate
download_hekate() {
    echo "下载 Hekate..."
    HEKATE_URL=$(curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest | jq -r '.assets[0].browser_download_url')
    HEKATE_VERSION=$(curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest | jq -r '.tag_name')
    echo "Hekate 版本: $HEKATE_VERSION"
    
    curl -sL "$HEKATE_URL" -o hekate.zip
    unzip -q hekate.zip
    rm hekate.zip
}

# 下载其他组件
download_components() {
    COMPONENTS=(
        "https://github.com/WerWolv/Tesla-Menu/releases/latest/download/ovlmenu.zip"
        "https://github.com/WerWolv/nx-ovlloader/releases/latest/download/ovlloader.zip"
        "https://github.com/rashevskyv/dbi/releases/latest/download/DBI.zip"
        "https://github.com/exelix11/SwitchThemeInjector/releases/latest/download/NXThemesInstaller.nro"
    )
    
    echo "下载其他组件..."
    for url in "${COMPONENTS[@]}"; do
        filename=$(basename "$url")
        component_name=$(basename "$url" | cut -d. -f1)
        echo "下载 $component_name..."
        
        # 获取版本信息
        if [[ $url == *github.com* ]]; then
            repo_url=$(echo "$url" | sed 's|/releases/latest/download/.*||g')
            version=$(curl -sL "$repo_url/releases/latest" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
            echo "  └─ 版本: $version"
        fi
        
        curl -sL "$url" -o "$filename"
        if [[ $filename == *.zip ]]; then
            unzip -q "$filename"
            rm "$filename"
        elif [[ $filename == *.nro ]]; then
            mv "$filename" switch/
        fi
    done
}

# 创建配置文件
create_config_files() {
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

[大气层真实系统]
emummc_force_disable=1
fss0=atmosphere/package3
atmosphere=1
kip1=atmosphere/kips/loader.kip
icon=bootloader/res/icon_Atmosphere_sysnand.bmp
id=Atm-Sys

[正版系统]
emummc_force_disable=1
fss0=atmosphere/package3
stock=1
icon=bootloader/res/icon_stock.bmp
id=OFW-SYS
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
}

# 创建版本信息
create_version_info() {
    echo "大气层整合包 - 自动构建" > version.txt
    echo "构建日期: $(date +%Y-%m-%d)" >> version.txt
    echo "更新时间: $(date +%Y-%m-%d\ %H:%M:%S)" >> version.txt
    echo "包含组件:" >> version.txt
    echo "- Atmosphere: $(curl -sL https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases | jq -r '.[0].tag_name')" >> version.txt
    echo "- Hekate: $(curl -sL https://api.github.com/repos/easyworld/hekate/releases/latest | jq -r '.tag_name')" >> version.txt
    echo "- Tesla-Menu: $(curl -sL https://api.github.com/repos/WerWolv/Tesla-Menu/releases/latest | jq -r '.tag_name')" >> version.txt
    echo "- DBI: $(curl -sL https://api.github.com/repos/rashevskyv/dbi/releases/latest | jq -r '.tag_name')" >> version.txt
}

# 打包结果
package_result() {
    cd ..
    OUTPUT_FILE="SwitchSD_${CURRENT_DATE}.zip"
    zip -r "$OUTPUT_FILE" SwitchSD
    
    # 计算文件大小
    file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "========================================"
    echo "构建完成!"
    echo "输出文件: $OUTPUT_FILE"
    echo "文件大小: $file_size"
    echo "构建时间: $(date +%Y-%m-%d\ %H:%M:%S)"
    echo "========================================"
}

# 显示更新日志
show_changelog() {
    echo "========================================"
    echo "           更新日志"
    echo "========================================"
    echo "本次更新包含以下组件:"
    
    # 这里可以添加获取各个组件更新日志的逻辑
    # 例如从GitHub API获取最新的release notes
    echo "查看详细更新日志:"
    echo "- Atmosphere: https://github.com/Atmosphere-NX/Atmosphere/releases"
    echo "- Hekate: https://github.com/easyworld/hekate/releases"
    echo "========================================"
}

# 主函数
main() {
    echo "SwitchSD 自动构建脚本"
    echo "========================"
    
    # 检查更新频率
    if check_update_frequency; then
        echo "开始检查并下载更新..."
    else
        read -p "本周已更新过，是否强制重新构建? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "取消构建。"
            exit 0
        fi
        echo "开始强制重新构建..."
    fi
    
    # 更新脚本自身
    self_update
    
    # 安装依赖
    install_dependencies
    
    # 清理工作目录
    clean_work_dir
    
    # 创建目录结构
    create_directory_structure
    
    # 下载各个组件
    download_atmosphere
    download_hekate
    download_components
    
    # 创建配置文件
    create_config_files
    
    # 创建版本信息
    create_version_info
    
    # 打包结果
    package_result
    
    # 显示更新日志
    show_changelog
    
    # 记录更新日期
    record_update_date
    
    # 提示信息
    echo ""
    echo "提示: 下次自动更新将在下周进行"
    echo "如需手动更新，请删除: $LAST_UPDATE_FILE"
    echo "或运行: rm -f $LAST_UPDATE_FILE && ./$(basename $0)"
}

# 运行主函数
main "$@"
