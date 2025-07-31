% 上位ディレクトリの取得
parent_dir = fileparts(pwd);
% 上位ディレクトリとそのすべてのサブフォルダをパスに追加
addpath(genpath(parent_dir));

% ID範囲の定義
start_id = 1; % 開始被験者ID
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
        pass = "Data Export/" + name + " Data Export.tsv";
        % インポートオプションの設定、文字列型を強制指定
        opts_read = detectImportOptions(pass, 'FileType', 'text');
        opts_read = setvartype(opts_read, 'EventValue', 'string'); 
        opts_read = setvartype(opts_read, 'eye', 'string'); 
        opts_read = setvartype(opts_read, 'mouth', 'string'); 
        opts_read = setvartype(opts_read, 'nose', 'string');
        opts_read = setvartype(opts_read, 'ValidityLeft', 'string');  % 新增
        opts_read = setvartype(opts_read, 'ValidityRight', 'string'); % 新增
        opts_read.VariableNamingRule = 'preserve';
        
        % TSVファイルの読み込み
        T = readtable(pass, opts_read);
        
        % 检查是否存在 calibration accuracy 列
        has_calibration = any(contains(T.Properties.VariableNames, 'calibration accuracy', 'IgnoreCase', true));
        has_validation = any(contains(T.Properties.VariableNames, 'validation accuracy', 'IgnoreCase', true));
        
        % 根据存在的列来构建提取的列名列表
        base_columns = {'Recording timestamp','Timeline name','Event','Event value','Eye movement type','eye','mouth','nose','Validity left','Validity right','Recording name'};
        
        % 添加Gaze point X列到基础列中
        if any(contains(T.Properties.VariableNames, 'Gaze point X', 'IgnoreCase', true))
            base_columns{end+1} = 'Gaze point X';
        end
        
        if has_validation
            base_columns{end+1} = 'Average validation accuracy (degrees)';
        end
        if has_calibration
            base_columns{end+1} = 'Average calibration accuracy (degrees)';
        end
        
        % 必要な列の抽出
        T2 = T(:, base_columns);
        TE = T2;

        % TEデータの処理（イベントデータ）
        % 必要なイベントタイプの絞り込み
        valid_events = {'ImageStimulusStart', 'ImageStimulusEnd'};
        TE_filtered = TE(ismember(TE.Event, valid_events), :);

        % 結果配列の初期化
        results = {};
        result_count = 0;

        % イベントペアの検索ループ
        i = 1;
        while i <= height(TE_filtered)
            % ImageStimulusStartイベントを検索
            if strcmp(TE_filtered.Event{i}, 'ImageStimulusStart')
                start_idx = i;
                start_timestamp = TE_filtered.('Recording timestamp')(i);
                start_timeline = TE_filtered.('Timeline name'){i};
                
                % Event valueを直接取得
                start_eventvalue = TE_filtered.('Event value'){start_idx};
                
                % 开始事件から recording_name を取得
                recording_name = TE_filtered.('Recording name'){start_idx};
                
                % **修改：获取validation和calibration accuracy并选择较小值**
                validation_accuracy = NaN;
                calibration_accuracy = NaN;
                final_accuracy = NaN;
                
                % 获取validation accuracy（如果存在）
                if has_validation
                    val_acc = TE_filtered.('Average validation accuracy (degrees)')(start_idx);
                    if isnumeric(val_acc) && ~isempty(val_acc) && ~any(isnan(val_acc))
                        validation_accuracy = val_acc;
                    end
                end
                
                % 获取calibration accuracy（如果存在）
                if has_calibration
                    cal_acc = TE_filtered.('Average calibration accuracy (degrees)')(start_idx);
                    if isnumeric(cal_acc) && ~isempty(cal_acc) && ~any(isnan(cal_acc))
                        calibration_accuracy = cal_acc;
                    end
                end
                
                % 选择最终的accuracy值
                if ~isnan(validation_accuracy) && ~isnan(calibration_accuracy)
                    % 两者都存在，取较小值
                    final_accuracy = min(validation_accuracy, calibration_accuracy);
                elseif ~isnan(validation_accuracy)
                    % 只有validation存在
                    final_accuracy = validation_accuracy;
                elseif ~isnan(calibration_accuracy)
                    % 只有calibration存在
                    final_accuracy = calibration_accuracy;
                else
                    % 两者都不存在，跳过此试验
                    fprintf('警告：被験者 %s 试验 %s 的 validation 和 calibration accuracy 都为无效值，跳过此试验\n', name, start_timeline);
                    i = i + 1;
                    continue;
                end
                
                % 対応するImageStimulusEndイベントを検索
                end_idx = -1;
                end_timestamp = -1;
                for j = i+1:height(TE_filtered)
                    if strcmp(TE_filtered.Event{j}, 'ImageStimulusEnd') && ...
                       strcmp(TE_filtered.('Timeline name'){j}, start_timeline)
                        end_idx = j;
                        end_timestamp = TE_filtered.('Recording timestamp')(j);
                        break;
                    end
                end
                
                % 修正：基于行数的数据提取
                if end_idx > 0
                    % 只为试验1输出调试信息
                    if result_count == 0  % 第一个试验
                        fprintf('\n=== 试验 1 调试信息 ===\n');
                        fprintf('原始TE数据总行数: %d\n', height(TE));
                    end
                    
                    % 在原始TE数据中找到对应的开始和结束行
                    % 找到开始事件在原始TE中的行号
                    start_row_in_TE = find(TE.('Recording timestamp') == start_timestamp & ...
                                          strcmp(TE.Event, 'ImageStimulusStart') & ...
                                          strcmp(TE.('Timeline name'), start_timeline), 1);
                    
                    % 找到结束事件在原始TE中的行号
                    end_row_in_TE = find(TE.('Recording timestamp') == end_timestamp & ...
                                        strcmp(TE.Event, 'ImageStimulusEnd') & ...
                                        strcmp(TE.('Timeline name'), start_timeline), 1);
                    
                    if result_count == 0  % 只为试验1输出详细信息
                        fprintf('开始事件行号: %d\n', start_row_in_TE);
                        fprintf('结束事件行号: %d\n', end_row_in_TE);
                    end
                    
                    if ~isempty(start_row_in_TE) && ~isempty(end_row_in_TE)
                        % 提取从开始行到结束行之间的数据（不包含开始和结束行本身）
                        trial_data = TE((start_row_in_TE+1):(end_row_in_TE-1), :);
                        
                        if result_count == 0  % 只为试验1输出详细信息
                            fprintf('提取的数据行数: %d (从第%d行到第%d行)\n', ...
                                    height(trial_data), start_row_in_TE+1, end_row_in_TE-1);
                        end
                    else
                        fprintf('警告：无法在原始数据中找到对应的事件行\n');
                        i = end_idx + 1;
                        continue;
                    end
                else
                    fprintf('警告：找不到对应的ImageStimulusEnd事件\n');
                    i = i + 1;
                    continue;
                end
                
                % Event valueの解析: a_b_c%
                % デフォルト値の設定
                a_name = '';
                b_condition = '';
                c_percent = NaN;
                
                % Event valueの解析
                % start_eventvalueが有効な文字列かどうかをチェック
                is_valid_eventvalue = ~isempty(start_eventvalue) && ...
                                     ~all(ismissing(start_eventvalue)) && ...
                                     ~strcmp(string(start_eventvalue), "");
                
                if is_valid_eventvalue
                    eventvalue_parts = strsplit(start_eventvalue, '_');
                    if length(eventvalue_parts) >= 3
                        a_name = eventvalue_parts{1};
                        b_condition = eventvalue_parts{2};
                        c_percent_str = eventvalue_parts{3};
                        
                        % パーセント数値の抽出（%記号を除去）
                        if endsWith(c_percent_str, '%')
                            c_percent = str2double(c_percent_str(1:end-1));
                        else
                            c_percent = str2double(c_percent_str);
                        end
                    end
                end
                
                % Timeline nameからconditionを抽出 (name_condition の形式)
                timeline_parts = strsplit(start_timeline, '_');
                if length(timeline_parts) >= 2
                    condition = timeline_parts{2}; % _の後の部分を取得
                else
                    condition = b_condition; % Event valueから取得したconditionを使用
                end
                
                % RT（反応時間）の計算
                RT = end_timestamp - start_timestamp;
                
                % 各カウントの計算
                valid_fixation_mask = strcmp(trial_data.('Eye movement type'), 'Fixation');
                fixation_count = sum(valid_fixation_mask);
                
                eye_tag1_count = sum(strcmp(trial_data.eye, 'Tag1'));
                nose_tag2_count = sum(strcmp(trial_data.nose, 'Tag2'));
                mouth_tag3_count = sum(strcmp(trial_data.mouth, 'Tag3'));
                
                % 新增：统计仅出现Tag1且不出现Tag2的次数
                % 找到所有Tag1出现的行
                tag1_rows = strcmp(trial_data.eye, 'Tag1');
                % 找到所有Tag2出现的行
                tag2_rows = strcmp(trial_data.nose, 'Tag2');
                % 统计仅有Tag1且没有Tag2的行数
                tag1_only_no_tag2_count = sum(tag1_rows & ~tag2_rows);
                
                % **新增：计算基于Gaze point X > 960的统计**
                tag1_gaze_x_gt960_count = 0;
                tag3_gaze_x_gt960_count = 0;
                
                % 检查是否存在Gaze point X列
                if any(contains(trial_data.Properties.VariableNames, 'Gaze point X', 'IgnoreCase', true))
                    gaze_x_raw = trial_data.('Gaze point X');
                    
                    % 将cell或string类型的数据转换为数值类型
                    if iscell(gaze_x_raw)
                        % 如果是cell类型，转换为数值
                        gaze_x_values = cellfun(@(x) str2double(x), gaze_x_raw);
                    elseif isstring(gaze_x_raw) || ischar(gaze_x_raw)
                        % 如果是string或char类型，转换为数值
                        gaze_x_values = str2double(gaze_x_raw);
                    else
                        % 如果已经是数值类型，直接使用
                        gaze_x_values = gaze_x_raw;
                    end
                    
                    % 创建有效数值的掩码（排除NaN值）
                    valid_gaze_mask = ~isnan(gaze_x_values);
                    
                    % 统计Tag1且Gaze point X <= 960的次数
                    tag1_mask = strcmp(trial_data.eye, 'Tag1');
                    gaze_x_gte960_mask = gaze_x_values <= 960;
                    tag1_gaze_x_gt960_count = sum(tag1_mask & gaze_x_gte960_mask & valid_gaze_mask);
                    
                    % 统计Tag3且Gaze point X >= 960的次数
                    tag3_mask = strcmp(trial_data.mouth, 'Tag3');
                    tag3_gaze_x_gt960_count = sum(tag3_mask & gaze_x_gte960_mask & valid_gaze_mask);
                else
                    fprintf('警告：被験者 %s 试验 %s 中未找到 Gaze point X 列\n', name, start_timeline);
                end
                
                % 计算两者相加
                tag1_tag3_gaze_x_gt960_sum = tag1_gaze_x_gt960_count + tag3_gaze_x_gt960_count;
                
                % 结果を配列に追加（新增三列）
                result_count = result_count + 1;
                results{result_count, 1} = no;
                results{result_count, 2} = name;
                results{result_count, 3} = c_percent;
                results{result_count, 4} = condition;
                results{result_count, 5} = RT;
                results{result_count, 6} = fixation_count;
                results{result_count, 7} = eye_tag1_count;
                results{result_count, 8} = nose_tag2_count;
                results{result_count, 9} = mouth_tag3_count;
                results{result_count, 10} = final_accuracy;
                results{result_count, 11} = recording_name;
                results{result_count, 12} = tag1_only_no_tag2_count;
                results{result_count, 13} = tag1_gaze_x_gt960_count;      % 新增：Tag1且Gaze point X >= 960
                results{result_count, 14} = tag3_gaze_x_gt960_count;      % 新增：Tag3且Gaze point X >= 960
                results{result_count, 15} = tag1_tag3_gaze_x_gt960_sum;   % 新增：两者相加
                
                % 次の検索は終了イベントの次から開始
                i = end_idx + 1;
            else
                i = i + 1;
            end
        end
        
        % 結果テーブルの作成と出力
        if result_count > 0
            result_table = cell2table(results(1:result_count, :), ...
                'VariableNames', {'No', 'name', 'percent', 'condition', 'RT', 'fixation_count', 'eye_tag1_count', ...
                'nose_tag2_count', 'mouth_tag3_count', 'validation_accuracy', 'recording_name', 'tag1_only_no_tag2_count', ...
                'tag1_gaze_x_gte960_count', 'tag3_gaze_x_gte960_count', 'tag1_tag3_gaze_x_gte960_sum'});
            
            % 新的输出文件夹：ProcessedData_Modified
            output_filename = sprintf('ProcessedData_Modified/TE/%d_%s_processed.csv', no, name);
            
            % 创建新的输出目录
            if ~exist('ProcessedData_Modified', 'dir')
                mkdir('ProcessedData_Modified');
            end
            if ~exist('ProcessedData_Modified/TE', 'dir')
                mkdir('ProcessedData_Modified/TE');
            end

            writetable(result_table, output_filename);
            
            fprintf('被験者 %s (番号: %d) のデータ処理が完了しました。処理試行数: %d\n', name, no, result_count);
            fprintf('新增统计项目已添加：Tag1_GazeX<=960=%d, Tag3_GazeX<=960=%d, 两者相加=%d\n', ...
                    sum([results{1:result_count, 13}]), sum([results{1:result_count, 14}]), sum([results{1:result_count, 15}]));
        else
            fprintf('被験者 %s (番号: %d) の有効な試行データが見つかりませんでした\n', name, no);
        end
        
        % 処理状況の表示
        fprintf('被験者 %s (番号: %d) の処理が完了しました\n', name, no);
    end
end