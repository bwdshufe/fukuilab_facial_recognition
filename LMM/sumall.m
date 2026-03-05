% まとめ処理：すべての分散CSVファイルを1つのファイルに統合
% 入力フォルダ：ProcessedData_Modified/TE/
% 出力ファイル：ProcessedData_Modified/all_subjects_combined.csv

%% ID範囲とフィルタリング設定
start_id = 1;
end_id = 20;

% 除外するIDの定義
missing_ids = [];
missing_ids = [5,18,20];

fprintf('=== フィルタリング設定 ===\n');
fprintf('ID範囲: %d ~ %d\n', start_id, end_id);
fprintf('除外ID数: %d\n', length(missing_ids));
fprintf('除外ID: %s\n\n', mat2str(missing_ids));

%% CSVファイルの読み込みと統合
% 入力フォルダのパス
input_folder = 'ProcessedData_Modified/TE';

% 出力フォルダの確認・作成
if ~exist('ProcessedData_Modified', 'dir')
    error('ProcessedData_Modified フォルダが存在しません。先にデータ処理を実行してください。');
end

% CSVファイルの一覧を取得
csv_files = dir(fullfile(input_folder, '*_processed.csv'));

if isempty(csv_files)
    error('処理済みCSVファイルが見つかりません。');
end

fprintf('=== CSVファイル統合処理開始 ===\n');
fprintf('検出されたファイル数: %d\n\n', length(csv_files));

% 統合テーブルの初期化
combined_table = table();

% 各CSVファイルを読み込んで統合
for file_idx = 1:length(csv_files)
    % ファイルパスの構築
    file_path = fullfile(input_folder, csv_files(file_idx).name);
    
    % CSVファイルの読み込み
    try
        current_table = readtable(file_path);
        
        % テーブルの統合
        if isempty(combined_table)
            combined_table = current_table;
        else
            combined_table = [combined_table; current_table];
        end
        
        fprintf('読み込み完了: %s (%d 行)\n', csv_files(file_idx).name, height(current_table));
    catch ME
        fprintf('警告: %s の読み込みに失敗しました: %s\n', csv_files(file_idx).name, ME.message);
    end
end

%% IDフィルタリング処理
fprintf('\n=== IDフィルタリング処理 ===\n');
fprintf('フィルタリング前の総行数: %d\n', height(combined_table));

% ID範囲でフィルタリング
if ismember('subject', combined_table.Properties.VariableNames)
    % ID範囲内のデータのみを保持
    range_mask = combined_table.subject >= start_id & combined_table.subject <= end_id;
    combined_table = combined_table(range_mask, :);
    fprintf('ID範囲フィルタ後の行数: %d\n', height(combined_table));
    
    % 除外IDを削除
    exclude_mask = ~ismember(combined_table.subject, missing_ids);
    filtered_table = combined_table(exclude_mask, :);
    fprintf('除外IDフィルタ後の行数: %d\n', height(filtered_table));
    
    % 除外された行数を表示
    excluded_count = height(combined_table) - height(filtered_table);
    fprintf('除外された行数: %d\n', excluded_count);
else
    warning('subject列が見つかりません。フィルタリングをスキップします。');
    filtered_table = combined_table;
end

%% subjectでソート
if ismember('subject', filtered_table.Properties.VariableNames) && ...
   ismember('trial', filtered_table.Properties.VariableNames)
    filtered_table = sortrows(filtered_table, {'subject', 'trial'});
end

%% 統合ファイルの出力
output_file = 'ProcessedData_Modified/all_subjects_combined_gaze.csv';
writetable(filtered_table, output_file);

fprintf('\n=== 統合処理完了 ===\n');
fprintf('統合ファイル: %s\n', output_file);
fprintf('総行数: %d\n', height(filtered_table));

% 簡単な統計情報の表示
if ismember('subject', filtered_table.Properties.VariableNames)
    unique_subjects = unique(filtered_table.subject);
    fprintf('ユニーク被験者数: %d\n', length(unique_subjects));
    
    % 含まれている被験者IDの一覧
    fprintf('含まれる被験者ID: %s\n', mat2str(unique_subjects'));
end