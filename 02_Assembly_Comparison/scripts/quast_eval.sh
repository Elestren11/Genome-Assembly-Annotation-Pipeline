#!/bin/bash
#$ -S /bin/bash
#$ -N quast_eval
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=4G

# === 环境设置 ===
export PATH="/d3/scratch/fanxl/miniconda3/envs/genome_analysis/bin:$PATH"
export CONDA_PREFIX="/d3/scratch/fanxl/miniconda3/envs/genome_analysis"

echo "=========================================="
echo "组装结果评估开始: $(date)"
echo "作业ID: $JOB_ID"
echo "工作目录: $(pwd)"
echo "=========================================="

# === 修复：设置线程数 ===
if [ -n "$NSLOTS" ]; then
    THREADS=$NSLOTS
else
    THREADS=4  # 直接运行时的默认线程数
    echo "注意: 直接运行模式，使用默认线程数: $THREADS"
fi

echo "使用线程数: $THREADS"

# 验证环境
echo "=== 环境验证 ==="
command -v quast >/dev/null 2>&1 || { echo "错误: quast不可用"; exit 1; }
echo "✓ 所有工具可用"

# 检查输入文件
echo "=== 输入文件检查 ==="
assemblies=("clr_wtdbg.ctg.fasta" "ccs_hifiasm_high_mem_contig.fasta" "ccs_wtdbg_corrected.ctg.fa")
reference="Ecoli_genomic.fa"

missing_files=()
for file in "${assemblies[@]}" "$reference"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
        echo "✗ $file 不存在"
    else
        echo "✓ $file 存在 ($(ls -lh $file | awk '{print $5}'))"
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "错误: 以下文件缺失: ${missing_files[*]}"
    echo "请先运行组装脚本"
    exit 1
fi

# 运行QUAST评估
echo ""
echo "=== 开始QUAST评估 ==="
echo "时间: $(date)"
echo "评估的组装结果:"
printf "  - %s\n" "${assemblies[@]}"
echo "参考基因组: $reference"

quast -r "$reference" \
      -o quast_comprehensive_report \
      --threads $THREADS \
      --labels "wtdbg2_CLR,hifiasm_CCS,wtdbg2_CCS" \
      "${assemblies[@]}"

if [ $? -ne 0 ]; then
    echo "错误: QUAST评估失败"
    exit 1
fi

# 生成简化的比较报告
echo ""
echo "=== 生成比较报告 ==="
report_file="quast_comprehensive_report/report.txt"
if [ -f "$report_file" ]; then
    echo "主要评估指标:"
    echo "----------------------------"
    grep -E "(Total length|N50|L50|# contigs)" "$report_file" | head -20
    echo "----------------------------"
    echo "✓ 详细报告请查看: quast_comprehensive_report/"
else
    echo "警告: 报告文件未生成"
fi

echo ""
echo "=========================================="
echo "组装结果评估完成: $(date)"
echo "评估报告: quast_comprehensive_report/"
echo "=========================================="
