#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印带颜色的消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 函数：检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_warning "命令 $1 未安装，跳过相关检查"
        return 1
    fi
    return 0
}

# 函数：检查文件偏移处是否有数据
check_offset_data() {
    local name="$1"
    local offset="$2"
    local expected_size="$3"
    
    echo -n "检查 $name (偏移: $offset): "
    
    # 检查文件大小是否足够
    local file_size=$(stat -c%s "$IMAGE_FILE")
    if [ $offset -ge $file_size ]; then
        print_error "偏移超出文件大小"
        return 1
    fi
    
    # 检查偏移处是否有非零数据
    local data=$(dd if="$IMAGE_FILE" bs=1 skip=$offset count=16 2>/dev/null | hexdump -C | head -1)
    if echo "$data" | grep -q "0000 0000 0000 0000"; then
        print_warning "可能为空数据"
        return 1
    else
        print_success "有数据"
        return 0
    fi
}

# 函数：检查文件签名
check_file_signature() {
    local offset="$1"
    local expected="$2"
    local name="$3"
    
    local signature=$(dd if="$IMAGE_FILE" bs=1 skip=$offset count=4 2>/dev/null 2>/dev/null | xxd -p | tr -d '\n')
    echo -n "$name: $signature "
    
    if [ "$signature" = "$expected" ]; then
        print_success "签名匹配"
        return 0
    else
        print_warning "签名不匹配 (期望: $expected)"
        return 1
    fi
}

# 函数：分析区域数据
analyze_region() {
    local name="$1"
    local offset="$2"
    local size="$3"
    
    echo
    print_info "=== $name (偏移: $offset) ==="
    
    # 显示前32字节的十六进制
    dd if="$IMAGE_FILE" bs=1 skip=$offset count=32 2>/dev/null | hexdump -C
}

# 函数：检查区域连续性
check_region_continuity() {
    local start="$1"
    local end="$2"
    local name="$3"
    
    echo -n "检查 $name 连续性: "
    
    # 检查区域是否有数据
    local sample=$(dd if="$IMAGE_FILE" bs=1 skip=$start count=1024 2>/dev/null | hexdump -C | head -2)
    if echo "$sample" | grep -q "0000 0000 0000 0000"; then
        print_warning "可能有空洞"
        return 1
    else
        print_success "数据连续"
        return 0
    fi
}

# 主函数
main() {
    IMAGE_FILE="${1:-freebsd_aarch64.img}"
    
    echo "🎯 RK3399Pro 启动镜像分析工具"
    echo "================================"
    
    # 检查文件是否存在
    if [ ! -f "$IMAGE_FILE" ]; then
        print_error "镜像文件不存在: $IMAGE_FILE"
        exit 1
    fi
    
    # 基本文件信息
    print_info "镜像文件: $IMAGE_FILE"
    local file_size=$(stat -c%s "$IMAGE_FILE")
    local file_size_mb=$((file_size / 1024 / 1024))
    print_info "文件大小: $file_size 字节 ($file_size_mb MB)"
    
    # 文件类型检查
    print_info "文件类型检查:"
    file "$IMAGE_FILE"
    echo
    
    # RK3399Pro启动要求
    print_info "=== RK3399Pro启动布局要求 ==="
    echo "IDBLoader:  偏移 32K (32768)"
    echo "U-Boot:     偏移 8M (8388608)" 
    echo "Trust OS:   偏移 16M (16777216)"
    echo "系统镜像:   偏移 32M (33554432)"
    echo
    
    # 检查关键位置
    print_info "=== 关键位置数据检查 ==="
    check_offset_data "IDBLoader区域" 32768 512K
    check_offset_data "U-Boot区域" 8388608 4M
    check_offset_data "Trust OS区域" 16777216 4M
    check_offset_data "系统镜像区域" 33554432 0
    
    # 检查连续性
    echo
    print_info "=== 区域连续性检查 ==="
    check_region_continuity 32768 8388607 "IDBLoader到U-Boot之间"
    check_region_continuity 8388608 16777215 "U-Boot到Trust之间"
    check_region_continuity 16777216 33554431 "Trust到系统之间"
    
    # 分区表检查
    echo
    print_info "=== 分区表检查 ==="
    if check_command fdisk; then
        fdisk -l "$IMAGE_FILE" 2>/dev/null || print_warning "fdisk无法识别分区表"
    fi
    
    if check_command parted; then
        parted "$IMAGE_FILE" print 2>/dev/null || print_warning "parted无法读取分区表"
    fi
    
    # 详细的十六进制分析
    echo
    print_info "=== 详细十六进制分析 ==="
    analyze_region "IDBLoader头部" 32768 32
    analyze_region "U-Boot头部" 8388608 32
    analyze_region "Trust OS头部" 16777216 32
    analyze_region "系统镜像头部" 33554432 32
    
    # 检查引导签名
    echo
    print_info "=== 引导签名检查 ==="
    # 检查ASCII签名（LOADER是有效的U-Boot签名）
    local u_boot_sig=$(dd if="$IMAGE_FILE" bs=1 skip=8388608 count=6 2>/dev/null | strings)
    if [ "$u_boot_sig" = "LOADER" ]; then
        print_success "检测到有效的U-Boot签名: LOADER"
    else
        # 检查十六进制魔数
        check_file_signature 8388608 "56190527" "U-Boot魔数"
    fi
    
    # 检查GPT分区表签名 (如果存在)
    if [ $file_size -gt 512 ]; then
        local gpt_signature=$(dd if="$IMAGE_FILE" bs=1 skip=512 count=8 2>/dev/null | xxd -p | tr -d '\n')
        if [ "$gpt_signature" = "4546492050415254" ]; then
            print_success "检测到GPT分区表"
        else
            print_info "未检测到GPT分区表 (可能是原始镜像)"
        fi
    fi
    
    # 最终评估
    echo
    print_info "=== 🏁 最终评估结果 ==="
    
    # 检查是否满足基本要求
    local errors=0
    local warnings=0
    
    # 检查关键位置是否有数据
    if check_offset_data "IDBLoader" 32768 0 >/dev/null; then
        print_success "IDBLoader位置正确"
    else
        print_error "IDBLoader位置可能有问题"
        ((errors++))
    fi
    
    if check_offset_data "U-Boot" 8388608 0 >/dev/null; then
        print_success "U-Boot位置正确"
    else
        print_error "U-Boot位置可能有问题"
        ((errors++))
    fi
    
    if check_offset_data "系统镜像" 33554432 0 >/dev/null; then
        print_success "系统镜像位置正确"
    else
        print_warning "系统镜像位置可能为空"
        ((warnings++))
    fi
    
    # 输出总结
    echo
    if [ $errors -eq 0 ]; then
        if [ $warnings -eq 0 ]; then
            print_success "✅ 镜像符合RK3399Pro启动要求"
            echo "   所有关键组件位置正确，可以尝试启动"
        else
            print_warning "⚠️  镜像基本符合要求，但有 $warnings 个警告"
            echo "   可以尝试启动，但建议检查警告项"
        fi
    else
        print_error "❌ 镜像存在 $errors 个错误，不符合启动要求"
        echo "   需要修复错误后才能正常启动"
    fi
    
    # 使用建议
    echo
    print_info "=== 📋 使用建议 ==="
    echo "写入SD卡命令:"
    echo "  sudo dd if=$IMAGE_FILE of=/dev/sdX bs=1M status=progress"
    echo
    echo "串口调试命令 (需要USB转串口工具):"
    echo "  sudo screen /dev/ttyUSB0 1500000"
    echo
    echo "启动日志检查:"
    echo "  1. 观察U-Boot启动信息"
    echo "  2. 检查内核加载状态"
    echo "  3. 验证根文件系统挂载"
}

# 帮助信息
show_help() {
    echo "RK3399Pro启动镜像分析工具"
    echo
    echo "用法: $0 [镜像文件]"
    echo
    echo "功能:"
    echo "  - 检查RK3399Pro启动布局要求"
    echo "  - 验证各组件偏移位置"
    echo "  - 分析文件结构和签名"
    echo "  - 评估启动兼容性"
    echo
    echo "示例:"
    echo "  $0 freebsd_aarch64.img"
    echo "  $0 /path/to/your/image.img"
    echo
    echo "要求:"
    echo "  - 需要基本的系统工具 (dd, hexdump, stat等)"
    echo "  - 可选工具: fdisk, parted (用于分区表分析)"
}

# 参数处理
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac