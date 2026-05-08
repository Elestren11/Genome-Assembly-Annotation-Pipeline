#!/bin/bash
#$ -S /bin/bash
#$ -N trim_analysis
#$ -cwd
#$ -j y
#$ -pe smp 8
echo "=== 数据质控 - Trimmomatic ==="

# 设置变量
READ1=paired_date1.fq
READ2=paired_date2.fq
OUTPUT_PREFIX=clean
THREADS=8

echo "开始数据质控..."
trimmomatic PE -threads $THREADS \
  $READ1 $READ2 \
  ${OUTPUT_PREFIX}_1_paired.fq ${OUTPUT_PREFIX}_1_unpaired.fq \
  ${OUTPUT_PREFIX}_2_paired.fq ${OUTPUT_PREFIX}_2_unpaired.fq \
  ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 \
  LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:50

echo "质控完成！"
echo "输出文件:"
ls -lh ${OUTPUT_PREFIX}_*.fq
