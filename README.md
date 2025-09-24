# fukuilab_facial_recognition
R and MATLAB code for facial cognition research at Fukui Laboratory

## Dependencies
This project requires [psignifit](https://github.com/wichmann-lab/psignifit) for psychometric function fitting. 
To use this code:
1. Install psignifit following their installation instructions
2. Make sure psignifit is in your MATLAB path

## 実行中の警告は無視すればいい
## 新たなデータを処理する前に，元のファイルをrenameする

## MATLAB guidence
MyMatlab version:24.1.0.2628055 (R2024a) Update 4

Please ensure your folder structure matches:
/Matlab
/psignifit-master

put source.xlsx into /MatlabCode
put all "Name Metrics.tsv" into /Metrics/MetricsRaw
Excelの形は以下のように
<img width="232" alt="image" src="https://github.com/user-attachments/assets/6e11b5d1-5216-4baa-a040-0056246a1919">


#それぞれのスクリプトを実行する前に，start_id と end_idを変更したことをチェックする

実行する時必ずMATLABのpathは以下になる
<img width="392" alt="image" src="https://github.com/user-attachments/assets/d2f70bf6-72c7-40db-a4e4-964c82431f75">

注意！！！全部の三つのパスを追加したを確認する！！！
<img width="387" alt="image" src="https://github.com/user-attachments/assets/7bdea184-653c-472d-9910-77fe11d8cab6">
このようのなると，一部のExcelの書くはできない

##
tsvsyori_bwd_02.m will copy "Name Metrics.tsv" and rename to "ID.csv" in /Metrics/MetricsCsv

creat "ID_each.csv" in /Metrics/eachCsv

存在しないIDはスキップできない

##
pfsave_bwd_02.m
input 1 or 2
1は図とデータ　2はデータのみ(もっと速い)
処理した図はMatlab\Metrics\raw\psychometric_functionに保存する.データはMetrics/raw/psychometric_raw.csvに保存.
存在しないIDをスキップする機能と既に存在したもスキップする機能を追加した20241206
理由がわからないけど，psychometric_raw.csvに直接追加できない，renameした方がいい

##
eachOutlier_mean_3sd_bwd_03.m
input 1 or 2
1は図とデータ　2はデータのみ(もっと速い)
条件×パーセンテージ組み合わせごとに3SD基準で外れ値除去。
処理済みデータをMetrics/eachOutlier/stimulus_3sd/に保存。
サイコメトリック関数フィッティングで閾値・傾き・幅を計算しMetrics/Threshold/stimulus_3sd/Threshold_stimulus_3sd.csvに出力。

##
pf_mean_3sd_bwd_02.m
最終的には，こっちの結果を使われる

##
Threshold_plot

## R guidence
