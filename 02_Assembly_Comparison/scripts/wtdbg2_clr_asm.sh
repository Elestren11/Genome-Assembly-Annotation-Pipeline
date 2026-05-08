#!/bin/bash
#$ -S /bin/bash
#$ -N wtdbg2_clr
#$ -cwd
#$ -j y
#$ -pe smp 16
#$ -l h_vmem=8G

# === 环境设置 ===
export PATH="/d3/scratch/fanxl/miniconda3/envs/genome_analysis/bin:$PATH"
export CONDA_PREFIX="/d3/scratch/fanxl/miniconda3/envs/genome_analysis"

echo "=========================================="
echo "wtdbg2 CLR数据组装开始: $(date)"
echo "作业ID: $JOB_ID"
echo "工作目录: $(pwd)"
echo "=========================================="

# === 修复：设置线程数 ===
if [ -n "$NSLOTS" ]; then
    THREADS=$NSLOTS
else
    THREADS=8  # 直接运行时的默认线程数
    echo "注意: 直接运行模式，使用默认线程数: $THREADS"
fi

echo "使用线程数: $THREADS"

# 验证环境
echo "=== 环境验证 ==="
command -v wtdbg2 >/dev/null 2>&1 || { echo "错误: wtdbg2不可用"; exit 1; }
command -v wtpoa-cns >/dev/null 2>&1 || { echo "错误: wtpoa-cns不可用"; exit 1; }
echo "✓ 所有工具可用"

# 检查输入文件
echo "=== 输入文件检查 ==="
if [ ! -f "CLR.fastq" ]; then
    echo "错误: CLR.fastq 文件不存在"
    exit 1
fi
echo "✓ CLR.fastq 文件存在"
echo "文件大小: $(ls -lh CLR.fastq | awk '{print $5}')"
echo "序列数量: $(($(wc -l < CLR.fastq)/4))"

# === 修复：清理可能存在的旧文件 ===
echo ""
echo "=== 清理旧文件 ==="
rm -f clr_wtdbg.ctg.fasta  # 删除可能存在的旧共识序列文件

# wtdbg2组装
echo ""
echo "=== 开始wtdbg2组装 ==="
echo "时间: $(date)"
wtdbg2 -x rs -i CLR.fastq -o clr_wtdbg -t $THREADS

if [ $? -ne 0 ]; then
    echo "错误: wtdbg2组装失败"
    exit 1
fi

# === 修复：解压.lay.gz文件 ===
echo ""
echo "=== 解压布局文件 ==="
if [ -f "clr_wtdbg.ctg.lay.gz" ]; then
    echo "解压 clr_wtdbg.ctg.lay.gz..."
    gunzip -f clr_wtdbg.ctg.lay.gz  # 使用-f强制覆盖
    if [ $? -ne 0 ]; then
        echo "错误: 解压失败"
        exit 1
    fi
    echo "✓ 解压完成"
elif [ -f "clr_wtdbg.ctg.lay" ]; then
    echo "✓ 布局文件已存在"
else
    echo "错误: 布局文件不存在"
    exit 1
fi

# 生成共识序列
echo ""
echo "=== 生成共识序列 ==="
echo "时间: $(date)"
if [ -f "clr_wtdbg.ctg.lay" ]; then
    # 使用-f参数强制覆盖输出文件
    wtpoa-cns -i clr_wtdbg.ctg.lay -o clr_wtdbg.ctg.fasta -t $THREADS -f
    if [ $? -ne 0 ]; then
        echo "错误: 共识序列生成失败"
        exit 1
    fi
else
    echo "错误: clr_wtdbg.ctg.lay 文件不存在，无法生成共识序列"
    exit 1
fi

# 结果统计
echo ""
echo "=== 组装结果统计 ==="
if [ -f "clr_wtdbg.ctg.fasta" ]; then
    contig_count=$(grep -c ">" clr_wtdbg.ctg.fasta)
    total_length=$(grep -v ">" clr_wtdbg.ctg.fasta | tr -d '\n' | wc -c)
    echo "Contig数量: $contig_count"
    echo "总长度: $total_length bp"
    
    # 计算N50
    echo "计算N50..."
    if command -v seqtk >/dev/null 2>&1; then
        seqtk comp clr_wtdbg.ctg.fasta | awk '{print $2}' | sort -nr > contig_lengths.txt
        total_bp=$(awk '{sum+=$1} END {print sum}' contig_lengths.txt)
        half_total=$((total_bp / 2))
        cumulative=0
        n50=0
        while read length; do
            cumulative=$((cumulative + length))
            if [ $cumulative -ge $half_total ]; then
                n50=$length
                break
            fi
        done < contig_lengths.txt
        echo "N50: $n50 bp"
        rm contig_lengths.txt
    else
        echo "N50: 需要seqtk工具来计算"
    fi
    
    echo "✓ 组装成功完成"
else
    echo "错误: 输出文件未生成"
    exit 1
fi

echo ""
echo "=========================================="
echo "wtdbg2 CLR数据组装完成: $(date)"
echo "输出文件: clr_wtdbg.ctg.fasta"
echo "=========================================="
