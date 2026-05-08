#!/bin/bash
#$ -S /bin/bash
#$ -N Jellyfish_analysis
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=4G

echo "=== Kmer分析 - Jellyfish ==="

# 设置变量
CLEAN_1=clean_1_paired.fq
CLEAN_2=clean_2_paired.fq
KMERS="19 21 31"  # 要分析的kmer大小
MEMORY="100M"
THREADS=8

echo "开始多kmer分析..."

for k in $KMERS; do
    echo "步骤1: k=$k kmer计数..."
    jellyfish count -m $k -s $MEMORY -t $THREADS -o k${k}_counts.jf $CLEAN_1 $CLEAN_2
    
    echo "步骤2: 生成k=$k直方图..."
    jellyfish histo -t $THREADS k${k}_counts.jf > k${k}_histogram.txt
    
    echo "k=$k 分析完成"
done

echo "Kmer分析完成！"
echo "生成的直方图文件:"
ls -la k*_histogram.txt

echo "请将直方图文件上传到 http://genomescope.org 进行基因组特征评估"
