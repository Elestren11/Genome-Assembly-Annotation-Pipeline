#!/bin/bash
#$ -S /bin/bash
#$ -N FastQC_analysis
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=4G

echo "=== 质量评估 - FastQC ==="

# 设置变量
CLEAN_1=clean_1_paired.fq
CLEAN_2=clean_2_paired.fq
OUTPUT_DIR=fastqc_results
THREADS=4

echo "开始FastQC质量评估..."
mkdir -p $OUTPUT_DIR
fastqc $CLEAN_1 $CLEAN_2 -o $OUTPUT_DIR -t $THREADS

echo "FastQC完成！"
echo "报告位置: $OUTPUT_DIR/"
ls -la $OUTPUT_DIR/*.html
