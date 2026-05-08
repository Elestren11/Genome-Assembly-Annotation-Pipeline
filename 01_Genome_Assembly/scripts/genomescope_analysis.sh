#!/bin/bash
#$ -S /bin/bash
#$ -N GenomeScope_analysis
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=4G

echo "=== 基因组特征评估 - GenomeScope2 ==="

# 设置变量
KMERS="19 21 31"
READ_LENGTH=150

echo "开始GenomeScope2分析..."

for k in $KMERS; do
    HIST_FILE="k${k}_histogram.txt"
    OUTPUT_DIR="genomescope_k${k}"
    
    if [ -f "$HIST_FILE" ]; then
        echo "分析 k=$k ..."
        genomescope2 -i $HIST_FILE -o $OUTPUT_DIR -k $k
        echo "k=$k 分析完成，结果在 $OUTPUT_DIR/"
    else
        echo "警告: 找不到文件 $HIST_FILE"
    fi
done

echo "GenomeScope2分析完成！"
echo "如果本地分析失败，建议使用在线工具: http://genomescope.org"
