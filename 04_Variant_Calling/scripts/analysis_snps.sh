#!/bin/bash
echo "=== 快速检查 ==="
echo "文件行数:"
wc -l snps_annotated.vcf

echo "前5行内容:"
head -5 snps_annotated.vcf

echo "是否有注释信息(ANN字段):"
grep -v "^#" snps_annotated.vcf | head -1 | grep -o "ANN=[^;]*" | head -1

echo "=== 根瘤菌SNP检测分析报告 ==="
echo "分析日期: $(date)"
echo "基因组: Rhizobium (CP016286.1)"
echo ""

# 总SNP数量
TOTAL_SNPS=$(grep -v "^#" snps_annotated.vcf | wc -l)
echo "1. 总SNP数量: $TOTAL_SNPS"

# 突变类型统计
echo ""
echo "2. 突变类型统计:"
MISSENSE=$(grep -v "^#" snps_annotated.vcf | grep -c "missense_variant")
SYNONYMOUS=$(grep -v "^#" snps_annotated.vcf | grep -c "synonymous_variant")
UPSTREAM=$(grep -v "^#" snps_annotated.vcf | grep -c "upstream_gene_variant")
DOWNSTREAM=$(grep -v "^#" snps_annotated.vcf | grep -c "downstream_gene_variant")
INTRON=$(grep -v "^#" snps_annotated.vcf | grep -c "intron_variant")

echo "   错义突变: $MISSENSE"
echo "   同义突变: $SYNONYMOUS"
echo "   上游变异: $UPSTREAM"
echo "   下游变异: $DOWNSTREAM"
echo "   内含子变异: $INTRON"

# 突变类型分布
echo ""
echo "3. 详细突变类型分布:"
grep -v "^#" snps_annotated.vcf | grep -o "ANN=[^;]*" | cut -d "|" -f 2 | sort | uniq -c | sort -nr

# 错义突变示例
echo ""
echo "4. 错义突变示例 (前5个):"
COUNT=0
grep -v "^#" snps_annotated.vcf | grep "missense_variant" | head -5 | while read line; do
    COUNT=$((COUNT+1))
    chrom=$(echo "$line" | awk '{print $1}')
    pos=$(echo "$line" | awk '{print $2}')
    ref=$(echo "$line" | awk '{print $4}')
    alt=$(echo "$line" | awk '{print $5}')
    gene_name=$(echo "$line" | grep -o "ANN=[^;]*" | cut -d "|" -f 4 | head -1)
    aa_change=$(echo "$line" | grep -o "ANN=[^;]*" | cut -d "|" -f 10 | head -1)
    effect=$(echo "$line" | grep -o "ANN=[^;]*" | cut -d "|" -f 2 | head -1)
    echo "   $COUNT. $chrom:$pos $ref→$alt"
    echo "      基因: $gene_name, 效应: $effect"
    echo "      氨基酸变化: $aa_change"
done

# 固氮相关基因搜索
echo ""
echo "5. 固氮相关基因SNP搜索:"
for gene in nif nod fix nitro; do
    count=$(grep -v "^#" snps_annotated.vcf | grep -i "$gene" | wc -l)
    if [ $count -gt 0 ]; then
        echo "   找到 $gene 相关基因SNP: $count 个"
        grep -v "^#" snps_annotated.vcf | grep -i "$gene" | head -2 | while read line; do
            chrom=$(echo "$line" | awk '{print $1}')
            pos=$(echo "$line" | awk '{print $2}')
            ref=$(echo "$line" | awk '{print $4}')
            alt=$(echo "$line" | awk '{print $5}')
            effect=$(echo "$line" | grep -o "ANN=[^;]*" | cut -d "|" -f 2 | head -1)
            gene_name=$(echo "$line" | grep -o "ANN=[^;]*" | cut -d "|" -f 4 | head -1)
            echo "      - $chrom:$pos $ref→$alt ($effect) in $gene_name"
        done
    else
        echo "   未找到 $gene 相关基因SNP"
    fi
# 检查VCF文件的质量信息
echo "=== VCF文件质量检查 ==="
echo "QUAL值统计:"
grep -v "^#" snps_annotated.vcf | awk '{print $6}' | sort -n | uniq -c | head -10

echo "过滤状态统计:"
grep -v "^#" snps_annotated.vcf | awk '{print $7}' | sort | uniq -c

echo "深度(DP)统计:"
grep -v "^#" snps_annotated.vcf | grep -o "DP=[0-9]*" | cut -d= -f2 | sort -n | uniq -c | head -10
# 创建简单的文本可视化
echo "=== SNP分布统计 ==="
echo "按染色体分布:"
grep -v "^#" snps_annotated.vcf | awk '{print $1}' | sort | uniq -c

echo ""
echo "质量值分布:"
grep -v "^#" snps_annotated.vcf | awk '
{
    qual = $6 + 0;
    if (qual < 20) low++;
    else if (qual < 100) medium++;
    else high++;
}
END {
    total = low + medium + high;
    printf("低质量(<20): %d (%.1f%%)\n", low, low/total*100);
    printf("中等质量(20-99): %d (%.1f%%)\n", medium, medium/total*100);
    printf("高质量(>=100): %d (%.1f%%)\n", high, high/total*100);
}'


done
