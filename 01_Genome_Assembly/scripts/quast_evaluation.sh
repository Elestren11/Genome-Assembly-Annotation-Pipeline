#!/bin/bash
#$ -S /bin/bash
#$ -N quast_analysis
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=4G

echo "=== 组装质量评估 - QUAST ==="

# 设置变量
REFERENCE="/d1/user/yinlj/02.genome_assembly/01.illumina/TAIR.chrom4.fa"
THREADS=4

echo "开始QUAST评估..."

# 检查参考基因组
if [ ! -f "$REFERENCE" ]; then
    echo "错误: 找不到参考基因组 $REFERENCE"
    echo "尝试查找参考基因组..."
    find /d1 -name "TAIR.chrom4.fa" 2>/dev/null
    exit 1
fi

# 检查组装文件
ASSEMBLY_FILES=$(ls soap_k*.contig 2>/dev/null)
if [ -z "$ASSEMBLY_FILES" ]; then
    echo "错误: 找不到组装contig文件"
    exit 1
fi

echo "找到组装文件: $ASSEMBLY_FILES"

# 单个评估
for assembly in $ASSEMBLY_FILES; do
    base_name=$(basename $assembly .contig)
    echo "评估 $assembly ..."
    quast.py -r $REFERENCE $assembly -o quast_${base_name} --threads $THREADS
done

# 对比评估（如果有多个组装）
if [ $(echo $ASSEMBLY_FILES | wc -w) -gt 1 ]; then
    echo "运行多组装对比评估..."
    quast.py -r $REFERENCE $ASSEMBLY_FILES -o quast_comparison --threads $THREADS
fi

echo "QUAST评估完成！"
echo "评估报告:"
ls -la quast_*/report.txt
