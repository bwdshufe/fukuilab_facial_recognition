# fukuilab_facial_recognition
R and MATLAB code for facial cognition research at Fukui Laboratory

## Dependencies
This project requires [psignifit](https://github.com/wichmann-lab/psignifit) for psychometric function fitting. 
To use this code:
1. Install psignifit following their [installation instructions](https://github.com/wichmann-lab/psignifit/wiki/Installation)
2. Make sure psignifit is in your MATLAB path

## 実行中の警告は無視すればいい

## MATLAB guidence
Please ensure your folder structure matches:
/MatlabCode
/Metrics
/psignifit-master

put source.xlsx into /MatlabCode
put all "Name Metrics.tsv" into /Metrics/MetricsRaw
Excelの形は以下のように
<img width="232" alt="image" src="https://github.com/user-attachments/assets/6e11b5d1-5216-4baa-a040-0056246a1919">


#それぞれのスクリプトを実行する前に，start_id と end_idを変更したことをチェックする

実行する時必ずMATLABのpathは以下になる
<img width="387" alt="image" src="https://github.com/user-attachments/assets/7bdea184-653c-472d-9910-77fe11d8cab6">


tsvsyori_bwd_02.m will copy "Name Metrics.tsv" and rename to "ID.csv" in /Metrics/MetricsCsv
#存在しないIDはスキップできない

pfsave_bwd_02.m
処理した図はMatlab\Metrics\raw\psychometric_functionに保存する
データはMetrics/raw/psychometric_raw.csvに保存
存在しないIDをスキップする機能と
既に存在したもスキップする機能を追加した20241206



## R guidence
