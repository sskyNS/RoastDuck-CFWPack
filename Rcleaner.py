import os
import shutil
import time
import logging
import sys  # 添加 sys 模块导入
from datetime import datetime

def setup_logging():
    """设置日志记录"""
    if not os.path.exists('logs'):
        os.makedirs('logs')
    log_filename = datetime.now().strftime("%Y%m%d_%H%M%S") + ".log"
    log_path = os.path.join('logs', log_filename)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_path),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger()

def safe_input(prompt):
    """安全的输入函数，检查 stdin 是否可用"""
    if sys.stdin and not sys.stdin.closed:
        return input(prompt)
    else:
        # 创建备份输入方法
        print(prompt + " [使用备用输入]")
        with open(os.devnull, 'r') as devnull:
            sys.stdin = devnull
            return ""

def display_menu():
    """显示主菜单"""
    while True:
        print("\n\n" + "="*50)
        print(" "*12 + "🎮 [RDP-CFW Cleaner] 🎮")
        print("="*50)
        print("\n请选择操作：")
        print("1. 清理旧的烤鸭包文件并复制新文件")
        print("2. 重新选择目标磁盘")
        print("3. 退出程序")
        choice = safe_input("\n请输入操作的编号：")
        
        if choice == '1':
            sd_drive = safe_input("输入你的SD卡盘符（填入英文字母即可，回车键确定）:").upper()
            source_folder = safe_input("输入新文件的源文件夹路径:").strip()
            if sd_drive and source_folder:
                clean_and_copy_files(sd_drive, source_folder)
            else:
                print("无效的输入，请重新操作")
        elif choice == '2':
            sd_drive = safe_input("输入你的SD卡盘符（填入英文字母即可，回车键确定）:").upper()
            source_folder = safe_input("输入新文件的源文件夹路径:").strip()
            if sd_drive and source_folder:
                clean_and_copy_files(sd_drive, source_folder)
            else:
                print("无效的输入，请重新操作")
        elif choice == '3':
            print("退出程序！")
            break
        else:
            print("无效选择，请重新输入！")

def clean_and_copy_files(sd_drive, source_folder):
    """清理旧文件并复制新文件"""
    logger = setup_logging()
    logger.info("="*50)
    logger.info("开始清理和复制操作")
    logger.info(f"目标磁盘: {sd_drive}:\\")
    logger.info(f"源文件夹: {source_folder}")
    
    safe_input("\n按任意键开始清理并复制新文件...")
    
    start_time = time.time()
    
    remove_folders = [
        r'\atmosphere\exefs_patches\bluetooth_patches',
        r'\atmosphere\exefs_patches\btm_patches',
        r'\atmosphere\exefs_patches\boot_logo',
        r'\atmosphere\exefs_patches\disable_remap_dialog',
        r'\atmosphere\exefs_patches\es_patches',
        r'\atmosphere\exefs_patches\NxThemesInstaller',
        r'\atmosphere\exefs_patches\nfim_ctest',
        r'\atmosphere\exefs_patches\vi_patches',
        r'\atmosphere\exefs_patches\hid_patches',
        r'\atmosphere\exefs_patches\nvnflinger_cmu',

        r'\atmosphere\fatal_errors',
        r'\atmosphere\flags',
        r'\atmosphere\hbl_html',
        r'\atmosphere\kip_patches',
        r'\atmosphere\logs',
        r'\atmosphere\automatic_backups',
        r'\atmosphere\config_templates',
        r'\atmosphere\kips',
        r'\atmosphere\hosts',
        r'\atmosphere\config',
        r'\atmosphere\erpt_reports',
        r'\atmosphere\contents\0100000000000F12',
        r'\atmosphere\contents\0100E95004038000',
        r'\atmosphere\contents\4200000000000FFF',
        r'\atmosphere\contents\420000000000000B',
        r'\atmosphere\contents\00FF747765616BFF',
        r'\atmosphere\contents\00FF0000A53BB665',
        r'\atmosphere\contents\00FF0000636C6BFF',
        r'\atmosphere\contents\0000000000534C56',
        r'\atmosphere\contents\010000000000bd00',
        r'\atmosphere\contents\420000000007E51A',
        r'\atmosphere\contents\0100000000000352',
        r'\atmosphere\contents\0100000000001000',
        r'\atmosphere\contents\690000000000000D',
        r'\atmosphere\contents\4200000000000000',
        r'\atmosphere\contents\0100000000000811',
        r'\atmosphere\contents\4200000000000010',
        r'\atmosphere\contents\0100000000000039',
        r'\atmosphere\contents\0100000000001000',
        r'\atmosphere\contents\0100000000001007',
        r'\atmosphere\contents\0100000000001013',
        r'\atmosphere\contents\0100F2C0115B6000',
        r'\atmosphere\contents\01007EF00011E000',
        r'\atmosphere\contents\420000000000000E',
        r'\atmosphere\contents\010000000000000D',
        r'\exosphere.bin',
        r'\bootloader',
        r'\BCAT',
        r'\argon',
        r'\avatars',
        r'\switch',
        r'\mods\en',
        r'\mods\zhCN',
        r'\mods\219',
        r'\mods\ttf mod rdp',
        r'\mods\extranro',
        r'\mods\ultra',
        r'\mods\ttf mod common',
        r'\mods\zhTW',
        r'\mods\21;9',
        r'\mod\en',
        r'\mod\zhCN',
        r'\mod\219',
        r'\mod\ttf mod rdp',
        r'\mod\extranro',
        r'\mod\ultra',
        r'\mod\ttf mod common',
        r'\mod\zhTW',
        r'\mod\21;9',
        r'\config\aio-switch-updater',
        r'\config\Fizeau',
        r'\config\sys-patch',
        r'\config\NX-FanControl',
        r'\config\ReverseNXRT',
        r'\config\Reyes',
        r'\config\sys-tune-overlay',
        r'\config\sys-tune',
        r'\config\MissionControl',
        r'\config\NX-Activity-Log',
        r'\config\nx-hbmenu',
        r'\config\ovl-sysmodules',
        r'\config\SimpleModManager',
        r'\config\sky-stars',
        r'\config\UpcomingSwitchGames',
        r'\config\sys-ftpd',
        r'\config\4IFIR',
        r'\config\sys-tune',
        r'\config\sys-patch',
        r'\config\status-monitor',
        r'\config\sys-clk',
        r'\config\sphaira',
        r'\config\sys-clk-oc',
        r'\config\ultrahand',
        r'\config\tesla',
        r'\config\edizon',
        r'\config\uberhand',
        r'\SaltySD',
        r'\themes',
        r'\warmboot_mariko',
        r'\themes\systemPatches',
        r'\themes\systemData',
        r'\warmboot_mariko'
    ]
    
    remove_files = [
        r'\atmosphere\hbl.nsp',
        r'\atmosphere\bluetooth_devices.db',
        r'\atmosphere\package3',
        r'\atmosphere\reboot_payload.bin',
        r'\atmosphere\stratosphere.romfs',
        r'\boot.dat',
        r'\boot.dat',
        r'\hbmenu.nsp',
        r'\mc-mitm.log',
        r'\exosphere.ini',
        r'\hbmenu.nro',
        r'\hbmenu.nsp',
        r'\payload.bin',
        r'\sdloader.enc',
        r'\update.bin'
    ]
    
    # 删除旧文件夹
    for folder in remove_folders:
        path = f"{sd_drive}:{folder}"
        try:
            if os.path.exists(path):
                shutil.rmtree(path)
                logger.info(f"已删除文件夹: {path}")
            else:
                logger.warning(f"文件夹不存在: {path}")
        except Exception as e:
            logger.error(f"删除文件夹失败 {path}: {str(e)}")
    
    # 删除旧文件
    for file in remove_files:
        path = f"{sd_drive}:{file}"
        try:
            if os.path.exists(path):
                os.remove(path)
                logger.info(f"已删除文件: {path}")
            else:
                logger.warning(f"文件不存在: {path}")
        except Exception as e:
            logger.error(f"删除文件失败 {path}: {str(e)}")
    
    # 复制新文件夹
    for folder in remove_folders:
        src_path = os.path.join(source_folder, folder.strip('\\'))
        dst_path = f"{sd_drive}:{folder}"
        try:
            if os.path.exists(src_path):
                shutil.copytree(src_path, dst_path)
                logger.info(f"已复制文件夹: {src_path} 到 {dst_path}")
            else:
                logger.warning(f"源文件夹不存在: {src_path}")
        except Exception as e:
            logger.error(f"复制文件夹失败 {src_path} 到 {dst_path}: {str(e)}")
    
    # 复制新文件
    for file in remove_files:
        src_file = os.path.join(source_folder, file.strip('\\'))
        dst_file = f"{sd_drive}:{file}"
        try:
            if os.path.exists(src_file):
                shutil.copy2(src_file, dst_file)
                logger.info(f"已复制文件: {src_file} 到 {dst_file}")
            else:
                logger.warning(f"源文件不存在: {src_file}")
        except Exception as e:
            logger.error(f"复制文件失败 {src_file} 到 {dst_file}: {str(e)}")
    
    # 计算并记录操作耗时
    end_time = time.time()
    elapsed_time = end_time - start_time
    logger.info(f"操作完成! 总耗时: {elapsed_time:.2f}秒")
    logger.info("="*50)
    
    print(f"\n操作完成! 总耗时: {elapsed_time:.2f}秒")
    print("旧文件已全部清除，新文件已复制完成，快去更新新版本吧！")
    print(f"详细日志已保存到 logs 文件夹")

if __name__ == "__main__":
    display_menu()