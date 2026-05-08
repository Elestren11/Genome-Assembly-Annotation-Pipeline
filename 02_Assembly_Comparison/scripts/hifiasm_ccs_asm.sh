#!/bin/bash
#$ -S /bin/bash
#$ -N hifiasm_ccs_high_mem
#$ -cwd
#$ -j y
#$ -pe smp 16
#$ -l h_vmem=64G  # 增加到64GB内存

echo "=== hifiasm组装CCS数据（高内存版）==="
echo "开始时间: $(date)"
echo "工作目录: $(pwd)"

# 设置变量
INPUT="CCS.fastq"
OUTPUT_PREFIX="ccs_hifiasm"

echo "输入文件: $INPUT"
echo "文件大小: $(ls -lh $INPUT | awk '{print $5}')"
echo "序列数量: $(($(wc -l < $INPUT)/4))"

# hifiasm组装
echo "步骤1: hifiasm组装（使用64GB内存）..."
hifiasm -t 16 -o $OUTPUT_PREFIX $INPUT

# 检查结果
echo "检查生成的hifiasm文件:"
ls -la ${OUTPUT_PREFIX}.* 2>/dev/null || echo "未找到输出文件"

# 转换结果为fasta格式
for gfa_file in ${OUTPUT_PREFIX}.bp.p_ctg.gfa ${OUTPUT_PREFIX}.p_ctg.gfa ${OUTPUT_PREFIX}*.gfa; do
    if [ -f "$gfa_file" ]; then
        echo "找到GFA文件: $gfa_file"
        echo "步骤2: 转换GFA为FASTA..."
        awk '/^S/{print ">"$2"\n"$3}' $gfa_file > ${OUTPUT_PREFIX}_contig.fasta
        break
    fi
done

echo "hifiasm CCS组装完成!"
echo "结束时间: $(date)"

# 检查最终结果
if [ -f "${OUTPUT_PREFIX}_contig.fasta" ]; then
    echo "✓ 成功生成contig文件"
    echo "文件大小: $(ls -lh ${OUTPUT_PREFIX}_contig.fasta | awk '{print $5}')"
    echo "Contig数量: $(grep -c '^>' ${OUTPUT_PREFIX}_contig.fasta)"
else
    echo "✗ 未能生成contig文件"
    echo "可用的GFA文件:"
    ls -la ${OUTPUT_PREFIX}*.gfa 2>/dev/null || echo "无GFA文件"
fi
