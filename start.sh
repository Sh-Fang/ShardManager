#!/bin/bash

# ShardManager 交互式管理脚本
# 作者: ShardManager Team
# 版本: 1.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 清屏函数
clear_screen() {
    clear
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║                                                  ║"
    echo "║            ShardManager 管理工具                 ║"
    echo "║                                                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示菜单
show_menu() {
    echo ""
    echo -e "${BOLD}请选择操作:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} 启动/更新服务 (重新构建并启动)"
    echo -e "  ${GREEN}2)${NC} 快速启动 (使用现有镜像)"
    echo -e "  ${GREEN}3)${NC} 停止服务"
    echo -e "  ${GREEN}4)${NC} 重启服务"
    echo -e "  ${GREEN}5)${NC} 查看日志"
    echo -e "  ${GREEN}6)${NC} 查看状态"
    echo -e "  ${GREEN}7)${NC} 备份数据库"
    echo -e "  ${GREEN}8)${NC} 恢复数据库"
    echo -e "  ${GREEN}9)${NC} 清理悬空镜像"
    echo -e "  ${RED}10)${NC} 完全清理 (删除容器、镜像、数据)"
    echo -e "  ${BLUE}11)${NC} 打开浏览器"
    echo -e "  ${YELLOW}0)${NC} 退出"
    echo ""
    echo -ne "${BOLD}请输入选项 [0-11]: ${NC}"
}

# 暂停函数
pause() {
    echo ""
    echo -ne "${YELLOW}按回车键继续...${NC}"
    read
}

# 检查项目目录
check_project_dir() {
    if [ ! -f "podman-compose.yaml" ]; then
        echo -e "${RED}错误: 未找到 podman-compose.yaml 文件${NC}"
        echo "请在项目根目录下运行此脚本"
        exit 1
    fi
}

# 1. 启动/更新服务
start_service() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 启动/更新服务 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}[1/5] 停止旧容器...${NC}"
    podman-compose down
    
    echo ""
    echo -e "${YELLOW}[2/5] 清理悬空镜像...${NC}"
    podman image prune -f
    
    echo ""
    echo -e "${YELLOW}[3/5] 重新构建镜像...${NC}"
    podman-compose build
    
    echo ""
    echo -e "${YELLOW}[4/5] 启动容器...${NC}"
    podman-compose up -d
    
    echo ""
    echo -e "${YELLOW}[5/5] 等待服务就绪...${NC}"
    sleep 2
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ 启动完成！${NC}"
    echo ""
    echo -e "访问地址: ${CYAN}http://localhost:8080${NC}"
    
    pause
}

# 2. 快速启动
quick_start() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 快速启动 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}正在启动容器...${NC}"
    podman-compose up -d
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ 启动完成！${NC}"
    echo ""
    echo -e "访问地址: ${CYAN}http://localhost:8080${NC}"
    
    pause
}

# 3. 停止服务
stop_service() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 停止服务 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}正在停止容器...${NC}"
    podman-compose down
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ 已停止容器${NC}"
    
    pause
}

# 4. 重启服务
restart_service() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 重启服务 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}正在重启容器...${NC}"
    podman-compose restart
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ 重启完成！${NC}"
    
    pause
}

# 5. 查看日志
view_logs() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 查看日志 (Ctrl+C 退出) ===${NC}"
    echo ""
    
    sleep 1
    
    # 捕获 Ctrl+C 信号，防止退出整个脚本
    trap '' INT
    podman-compose logs -f
    trap - INT
    
    # 日志查看结束后暂停
    echo ""
    pause
}

# 6. 查看状态
view_status() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 服务状态 ===${NC}"
    echo ""
    
    # 检查容器状态
    echo -e "${BOLD}容器状态:${NC}"
    if podman ps | grep -q shardmanager; then
        echo -e "${GREEN}✓ 运行中${NC}"
        echo ""
        podman ps | grep -E "CONTAINER|shardmanager"
        echo ""
        
        # 健康检查
        echo -e "${BOLD}健康检查:${NC}"
        if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
            echo -e "${GREEN}✓ API 响应正常${NC}"
            curl -s http://localhost:8080/api/health | python3 -m json.tool 2>/dev/null
        else
            echo -e "${RED}✗ API 未响应${NC}"
        fi
    else
        echo -e "${RED}✗ 未运行${NC}"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}镜像信息:${NC}"
    podman images | grep -E "REPOSITORY|shardmanager" || echo "未找到 shardmanager 镜像"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BOLD}数据卷信息:${NC}"
    podman volume ls | grep -E "DRIVER|shardmanager" || echo "未找到 shardmanager 数据卷"
    
    pause
}

# 7. 备份数据库
backup_database() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 备份数据库 ===${NC}"
    echo ""
    
    # 创建备份目录
    BACKUP_DIR="./backups"
    mkdir -p "$BACKUP_DIR"
    
    # 生成备份文件名
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/shardmanager_${TIMESTAMP}.db"
    
    echo -e "${YELLOW}正在备份数据库...${NC}"
    
    # 检查容器是否运行
    if podman ps | grep -q shardmanager; then
        podman cp shardmanager:/data/shardmanager.db "$BACKUP_FILE"
        if [ -f "$BACKUP_FILE" ]; then
            echo ""
            echo -e "${GREEN}${BOLD}✓ 备份成功！${NC}"
            echo ""
            echo -e "备份文件: ${CYAN}$BACKUP_FILE${NC}"
            echo -e "文件大小: $(du -h "$BACKUP_FILE" | cut -f1)"
        else
            echo -e "${RED}✗ 备份失败${NC}"
        fi
    else
        echo -e "${YELLOW}容器未运行，尝试从数据卷备份...${NC}"
        podman run --rm -v shardmanager-data:/data -v $(pwd):/backup alpine \
            cp /data/shardmanager.db /backup/$BACKUP_FILE 2>/dev/null
        
        if [ -f "$BACKUP_FILE" ]; then
            echo ""
            echo -e "${GREEN}${BOLD}✓ 备份成功！${NC}"
            echo ""
            echo -e "备份文件: ${CYAN}$BACKUP_FILE${NC}"
            echo -e "文件大小: $(du -h "$BACKUP_FILE" | cut -f1)"
        else
            echo -e "${RED}✗ 备份失败，数据库文件不存在${NC}"
        fi
    fi
    
    pause
}

# 8. 恢复数据库
restore_database() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 恢复数据库 ===${NC}"
    echo ""
    
    BACKUP_DIR="./backups"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo -e "${RED}错误: 未找到备份文件${NC}"
        echo "请先执行备份操作"
        pause
        return
    fi
    
    echo -e "${BOLD}可用的备份文件:${NC}"
    echo ""
    
    # 列出备份文件
    backups=($(ls -t $BACKUP_DIR/*.db 2>/dev/null))
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${RED}未找到备份文件${NC}"
        pause
        return
    fi
    
    for i in "${!backups[@]}"; do
        filename=$(basename "${backups[$i]}")
        filesize=$(du -h "${backups[$i]}" | cut -f1)
        echo -e "  ${GREEN}$((i+1)))${NC} $filename (${filesize})"
    done
    
    echo ""
    echo -ne "${BOLD}请选择要恢复的备份 [1-${#backups[@]}] (0取消): ${NC}"
    read choice
    
    if [ "$choice" == "0" ]; then
        echo "已取消"
        pause
        return
    fi
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#backups[@]}" ]; then
        RESTORE_FILE="${backups[$((choice-1))]}"
        
        echo ""
        echo -e "${RED}${BOLD}警告: 此操作将覆盖当前数据库！${NC}"
        echo -ne "${YELLOW}确认恢复? (yes/no): ${NC}"
        read confirm
        
        if [ "$confirm" != "yes" ]; then
            echo "已取消"
            pause
            return
        fi
        
        echo ""
        echo -e "${YELLOW}正在恢复数据库...${NC}"
        
        if podman ps | grep -q shardmanager; then
            podman cp "$RESTORE_FILE" shardmanager:/data/shardmanager.db
            podman restart shardmanager
            echo ""
            echo -e "${GREEN}${BOLD}✓ 恢复成功！容器已重启${NC}"
        else
            echo -e "${RED}错误: 容器未运行，请先启动服务${NC}"
        fi
    else
        echo -e "${RED}无效的选择${NC}"
    fi
    
    pause
}

# 9. 清理悬空镜像
clean_dangling() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 清理悬空镜像 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}正在清理悬空镜像...${NC}"
    podman image prune -f
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ 清理完成${NC}"
    
    pause
}

# 10. 完全清理
full_cleanup() {
    clear_screen
    show_banner
    echo -e "${BOLD}${RED}=== 完全清理 ===${NC}"
    echo ""
    
    echo -e "${RED}${BOLD}警告: 此操作将删除以下内容:${NC}"
    echo "  • 容器"
    echo "  • 镜像"
    echo "  • 数据卷 (包括所有历史记录)"
    echo ""
    echo -e "${YELLOW}建议先执行备份操作！${NC}"
    echo ""
    echo -ne "${RED}${BOLD}确认清理? 输入 'yes' 继续: ${NC}"
    read confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "已取消"
        pause
        return
    fi
    
    echo ""
    echo -e "${YELLOW}[1/4] 停止并删除容器...${NC}"
    podman-compose down
    
    echo ""
    echo -e "${YELLOW}[2/4] 删除镜像...${NC}"
    podman rmi shardmanager:latest 2>/dev/null || echo "镜像不存在，跳过"
    
    echo ""
    echo -e "${YELLOW}[3/4] 删除数据卷...${NC}"
    podman volume rm shardmanager-data 2>/dev/null || echo "数据卷不存在，跳过"
    
    echo ""
    echo -e "${YELLOW}[4/4] 清理系统...${NC}"
    podman system prune -f
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ 清理完成！${NC}"
    
    pause
}

# 11. 打开浏览器
open_browser() {
    clear_screen
    show_banner
    echo -e "${BOLD}${BLUE}=== 打开浏览器 ===${NC}"
    echo ""
    
    URL="http://localhost:8080"
    
    # 检查服务是否运行
    if ! podman ps | grep -q shardmanager; then
        echo -e "${RED}错误: 服务未运行${NC}"
        echo "请先启动服务"
        pause
        return
    fi
    
    echo -e "正在打开浏览器: ${CYAN}$URL${NC}"
    echo ""
    
    # 在 WSL 中打开 Windows 浏览器
    if command -v cmd.exe &> /dev/null; then
        cmd.exe /c start $URL
        echo -e "${GREEN}✓ 已在 Windows 浏览器中打开${NC}"
    elif command -v wslview &> /dev/null; then
        wslview $URL
        echo -e "${GREEN}✓ 已打开浏览器${NC}"
    elif command -v xdg-open &> /dev/null; then
        xdg-open $URL
        echo -e "${GREEN}✓ 已打开浏览器${NC}"
    else
        echo -e "${YELLOW}无法自动打开浏览器${NC}"
        echo -e "请手动访问: ${CYAN}$URL${NC}"
    fi
    
    pause
}

# 主循环
main() {
    # 检查项目目录
    check_project_dir
    
    while true; do
        clear_screen
        show_banner
        show_menu
        
        read choice
        
        case $choice in
            1) start_service ;;
            2) quick_start ;;
            3) stop_service ;;
            4) restart_service ;;
            5) view_logs ;;
            6) view_status ;;
            7) backup_database ;;
            8) restore_database ;;
            9) clean_dangling ;;
            10) full_cleanup ;;
            11) open_browser ;;
            0)
                clear_screen
                echo ""
                echo -e "${CYAN}感谢使用 ShardManager！再见！${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选项，请重新选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 运行主程序
main

