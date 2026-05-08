#!/bin/bash
#$ -S /bin/bash
#$ -N SOAPdenovo_analysis
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l h_vmem=4G

echo "=== 基因组组装 - SOAPdenovo2 ==="

# 设置变量
CONFIG_FILE="soap_config.txt"
KMERS="19 21 31"
THREADS=4

echo "开始多kmer基因组组装..."

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 找不到配置文件 $CONFIG_FILE"
    echo "请创建SOAPdenovo2配置文件"
    exit 1
fi

for k in $KMERS; do
    echo "开始 k=$k 组装..."
    OUTPUT_PREFIX="soap_k${k}"
    
    SOAPdenovo-63mer all -s $CONFIG_FILE -K $k -R -o $OUTPUT_PREFIX -p $THREADS
    
    # 检查是否生成关键文件
    if [ -f "${OUTPUT_PREFIX}.contig" ]; then
        echo "k=$k 组装完成!"
        ls -lh ${OUTPUT_PREFIX}.contig
    else
        echo "警告: k=$k 可能未完成组装"
    fi
done

echo "基因组组装完成！"
echo "生成的contig文件:"
ls -la soap_k*.contig
