#!/bin/bash
echo "=== 基因组组装综合数据表 ==="
echo "生成时间: $(date)"
echo ""

# 参考基因组信息
REF_LENGTH=4641652
REF_GC=50.79

echo "| 评估指标 | wtdbg2_CLR | hifiasm_CCS | 参考基因组 | 单位 |"
echo "|---------|------------|-------------|------------|------|"

# 基础统计
for asm in "clr_wtdbg.ctg.fasta" "ccs_hifiasm_high_mem_contig.fasta"; do
    if [ -f "$asm" ]; then
        length=$(grep -v ">" "$asm" | tr -d '\n' | wc -c)
        contigs=$(grep -c ">" "$asm")
        
        # 计算GC含量
        gc_content=$(grep -v ">" "$asm" | tr -d '\n' | \
                    awk '{gcs = gsub(/[GC]/, ""); total = length($0); print (gcs/total)*100}' | \
                    head -1 | awk '{printf "%.2f", $1}')
        
        # 计算N50
        if command -v seqtk >/dev/null 2>&1; then
            seqtk comp "$asm" | awk '{print $2}' | sort -nr > temp_n50.txt
            total_bp=$(awk '{sum+=$1} END {print sum}' temp_n50.txt)
            half_total=$((total_bp / 2))
            cumulative=0
            n50=0
            while read len; do
                cumulative=$((cumulative + len))
                if [ $cumulative -ge $half_total ]; then
                    n50=$len
                    break
                fi
            done < temp_n50.txt
            rm temp_n50.txt
        else
            n50="N/A"
        fi
        
        if [[ "$asm" == *"clr"* ]]; then
            clr_length=$length
            clr_contigs=$contigs
            clr_gc=$gc_content
            clr_n50=$n50
        else
            ccs_length=$length
            ccs_contigs=$contigs
            ccs_gc=$gc_content
            ccs_n50=$n50
        fi
    fi
done

# 输出表格
echo "| Contig数量 | $clr_contigs | $ccs_contigs | 1 | 个 |"
echo "| 总长度 | $clr_length | $ccs_length | $REF_LENGTH | bp |"
echo "| N50 | $clr_n50 | $ccs_n50 | $REF_LENGTH | bp |"
echo "| GC含量 | $clr_gc | $ccs_gc | $REF_GC | % |"

# 计算覆盖度
clr_coverage=$(echo "scale=2; $clr_length / $REF_LENGTH * 100" | bc)
ccs_coverage=$(echo "scale=2; $ccs_length / $REF_LENGTH * 100" | bc)

echo "| 基因组覆盖度 | $clr_coverage | $ccs_coverage | 100 | % |"

echo ""
echo "=== 软件资源使用对比 ==="
echo "| 软件 | 数据 | 内存需求 | 运行时间 | 组装质量 |"
echo "|------|------|----------|----------|----------|"
echo "| wtdbg2 | CLR | 中等(~8GB) | 快(~2分钟) | 一般 |"
echo "| wtdbg2 | CCS | 中等(~8GB) | 快(~2分钟) | 失败 |"
echo "| hifiasm | CCS | 高(>64GB) | 中等(~30分钟) | 优秀 |"
echo "| hifiasm | CLR | 未测试 | 未测试 | 未测试 |"
