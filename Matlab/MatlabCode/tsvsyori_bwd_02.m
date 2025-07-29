% ID範囲の定義
start_id = 69; % 開始被験者ID
end_id = 100;   % 終了被験者ID

% Excelファイルの読み込み設定
opts = detectImportOptions('source.xlsx');
opts.VariableNames = {'name', 'key', 'no', 'sex'};
params = readtable('source.xlsx', opts);


% データ処理のメインループ
for param_idx = 1:height(params)
    % 指定したID範囲内のデータのみを処理
    if params.no(param_idx) >= start_id && params.no(param_idx) <= end_id
        % 現在の処理対象のパラメータを抽出
        name = params.name{param_idx};
        key = params.key{param_idx};
        no = params.no(param_idx);
        sex = params.sex{param_idx};
        
        % メトリクスファイルの読み込みと処理
        pass = "Metrics/MetricsRaw/" + name + " Metrics.tsv";
        T = readtable(pass,"FileType","text");
        T1 = T(:, {'Recording','Participant','Timeline','TOI','Interval','Media','Duration_of_interval','Start_of_interval','Last_key_press'});
        T2 = T1;
        
        % 名前が一致するデータの抽出
        gyo = 0;
        for i = 1:size(T1)
            if strlength(T1{i,"TOI"}) >= strlength(name)
                a = T1{i,"TOI"}{1}(1:strlength(name));
                if a == name
                    gyo = gyo + 1;
                    T2(gyo,:) = T1(i,:);
                end
            end
        end
        
        % データサイズの調整
        T2 = T2(1:675,:);
        B = sortrows(T2,["Recording" "Start_of_interval"]);
        
        % 新しいテーブルの作成
        sz = [675 6];
        varTypes = {'string','string','int8','int8','int8','string'};
        varNames = {'self_key','condition','percent','session','No','sex'};
        C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
        
        % 基本情報の設定
        C(:,'self_key') = {key};
        C(:,'No') = {no};
        C(:,'sex') = {sex};
        
        % メディア情報の解析とセッション情報の設定
        for i = 1:675
            mediaParts = strsplit(T2{i,"Media"}{1},"_");
            condition = mediaParts{2};
            percentString = mediaParts{3};
            percentValue = str2double(percentString(1:end-1));
            C{i, 'condition'} = {condition};
            C{i, 'percent'} = percentValue;
            
            % セッション番号の設定
            if i <= 225
                C{i,"session"} = 1;
            elseif i <= 450
                C{i,"session"} = 2;
            else
                C{i,"session"} = 3;
            end
        end
        
        % テーブルの結合と判定列の追加
        T3 = [T2 C];
        T3.judge = T3.Last_key_press == T3.self_key;
        
        % 第1出力ファイルの作成
        filename = "Metrics/MetricsCsv/" + no + ".csv";
        writetable(T3, filename);
        
        % 第2出力ファイルの作成
        T2 = T3(:,{'No','session','condition','percent','self_key','judge','Duration_of_interval','sex'});
        T2.Properties.VariableNames{'Duration_of_interval'} = 'RT';
        T2 = movevars(T2,'sex','After',"No");
        w_filename = "Metrics/eachCsv/" + no + "_each.csv";
        writetable(T2,w_filename);
        
        % 処理状況の表示
        fprintf('被験者 %s (番号: %d) の処理が完了しました\n', name, no);
    end
end