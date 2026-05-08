#!/bin/bash
echo "=== 组装错误和质量分析 ==="
echo ""

REPORT_FILE="quast_comprehensive_report/report.txt"

if [ -f "$REPORT_FILE" ]; then
    echo "1. 组装错误统计:"
    echo "----------------------------"
    
    # 提取错误相关指标
    misassemblies=$(grep "# misassemblies" "$REPORT_FILE")
    mismatches=$(grep "# mismatches per 100 kbp" "$REPORT_FILE")
    indels=$(grep "# indels per 100 kbp" "$REPORT_FILE")
    
    echo "$misassemblies"
    echo "$mismatches" 
    echo "$indels"
    echo ""
    
    echo "2. 错误类型分析:"
    echo "----------------------------"
    echo "misassemblies (错误组装): 指contig内部结构错误"
    echo "mismatches (错配): 单个碱基替换错误"
    echo "indels (插入缺失): 碱基插入或缺失错误"
    echo ""
    
    echo "3. 质量评估标准:"
    echo "----------------------------"
    echo "优秀组装: misassemblies < 5, mismatches < 100, indels < 100"
    echo "良好组装: misassemblies < 20, mismatches < 500, indels < 500"
    echo "一般组装: 超出上述范围"
else
    echo "错误: 找不到QUAST报告文件"
fi

echo ""
echo "4. 组装质量总结:"
echo "----------------------------"
echo "hifiasm_CCS: 近乎完美的单contig组装"
echo "wtdbg2_CLR: 碎片化但可用的组装"
echo "wtdbg2_CCS: 组装失败"
