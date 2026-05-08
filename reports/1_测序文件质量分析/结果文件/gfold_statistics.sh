#!/bin/bash
# 一键完成 GFOLD 表达量分析全流程
# 输入文件：gfold_expression.txt（原始结果）
# 输出文件：fanxl_*.txt 系列结果

set -e
NAME=fanxl
RAW=gfold_expression.txt

# a) 提取前9行作为示例头文件
head -n 9 "$RAW" > ${NAME}_gfold.head

# b) 删除前9行，生成干净数据
sed -n '10,$p' "$RAW" > ${NAME}_gfold_expression2.txt

# c) 提取 GeneName、GFOLD(0.01)、1stRPKM 三列
awk -F'\t' -v OFS='\t' '
    NR==1 {for(i=1;i<=NF;i++) h[$i]=i; print $h["GeneName"], $h["GFOLD(0.01)"], $h["1stRPKM"]}
    NR>1  {print $h["GeneName"], $h["GFOLD(0.01)"], $h["1stRPKM"]}
' ${NAME}_gfold_expression2.txt > ${NAME}_gfold_expression3.txt

# d) 按 GFOLD 值分上下调，含表头
awk -F'\t' -v OFS='\t' '
    NR==1 {print > "'${NAME}_gfold_up.txt'"; print > "'${NAME}_gfold_down.txt'"; next}
    $2>0  {print > "'${NAME}_gfold_up.txt'"}
    $2<0  {print > "'${NAME}_gfold_down.txt'"}
' ${NAME}_gfold_expression3.txt

# e) 统计基因数与 1stRPKM 均值
awk -F'\t' -v OFS='\t' '
    FNR==1 {next}
    {cnt[FILENAME]++; sum[FILENAME]+=$3}
    END {
        for(f in cnt) {
            printf "%s\t%d\t%.6f\n", f, cnt[f], sum[f]/cnt[f]
        }
    }
' ${NAME}_gfold_up.txt ${NAME}_gfold_down.txt > ${NAME}_statistics.txt

echo "✅ 全部完成！生成文件列表："
ls -lh ${NAME}_*
