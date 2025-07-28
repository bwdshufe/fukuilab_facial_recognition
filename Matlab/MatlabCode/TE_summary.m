% 统计每个percent的tag1_ratio平均值
% Author: Generated for eye-tracking data analysis
% Date: 2025-07-09

% ==================== Parameter Settings ====================
input_file = 'StatisticalResults/statistics_by_ID_condition_percent.csv';
% ==========================================================

% 检查输入文件是否存在
if ~exist(input_file, 'file')
    error('Input file does not exist: %s', input_file);
end

% 读取数据
fprintf('Reading data from: %s\n', input_file);
try
    data = readtable(input_file);
    fprintf('Successfully loaded data with %d rows\n', height(data));
catch ME
    error('Error reading input file: %s', ME.message);
end

% 检查必要的列是否存在
required_columns = {'percent', 'tag1_ratio'};
missing_columns = setdiff(required_columns, data.Properties.VariableNames);
if ~isempty(missing_columns)
    error('Missing required columns: %s', strjoin(missing_columns, ', '));
end

% 显示数据基本信息
fprintf('Data columns: %s\n', strjoin(data.Properties.VariableNames, ', '));
fprintf('Total data rows: %d\n', height(data));

% 获取唯一的percent值并排序
unique_percents = sort(unique(data.percent));
fprintf('Unique percent values: %s\n', mat2str(unique_percents'));

% ==================== 统计每个percent的平均值 ====================
fprintf('\n=== Statistics by Percent ===\n');
fprintf('%-8s %-12s %-12s %-12s %-12s %-12s\n', 'Percent', 'Count', 'Mean', 'Median', 'Std', 'Min/Max');
fprintf('%s\n', repmat('-', 1, 80));

% 初始化结果数组
results = [];

% 为每个percent值计算统计信息
for i = 1:length(unique_percents)
    current_percent = unique_percents(i);
    
    % 筛选当前percent的数据
    subset_data = data(data.percent == current_percent, :);
    
    % 提取tag1_ratio值并移除NaN
    tag1_ratios = subset_data.tag1_ratio;
    valid_ratios = tag1_ratios(~isnan(tag1_ratios));
    
    if ~isempty(valid_ratios)
        % 计算统计信息
        count = length(valid_ratios);
        mean_value = mean(valid_ratios);
        median_value = median(valid_ratios);
        std_value = std(valid_ratios);
        min_value = min(valid_ratios);
        max_value = max(valid_ratios);
        
        % 显示结果
        fprintf('%-8.0f %-12d %-12.4f %-12.4f %-12.4f %.4f-%.4f\n', ...
                current_percent, count, mean_value, median_value, std_value, min_value, max_value);
        
        % 保存结果到数组
        results = [results; current_percent, count, mean_value, median_value, std_value, min_value, max_value];
    else
        fprintf('%-8.0f %-12s %-12s %-12s %-12s %s\n', ...
                current_percent, 'No data', 'N/A', 'N/A', 'N/A', 'N/A');
    end
end

% ==================== 总体统计 ====================
fprintf('\n=== Overall Statistics ===\n');
all_valid_ratios = data.tag1_ratio(~isnan(data.tag1_ratio));
if ~isempty(all_valid_ratios)
    fprintf('Total valid data points: %d\n', length(all_valid_ratios));
    fprintf('Overall mean: %.4f\n', mean(all_valid_ratios));
    fprintf('Overall median: %.4f\n', median(all_valid_ratios));
    fprintf('Overall std: %.4f\n', std(all_valid_ratios));
    fprintf('Overall range: %.4f - %.4f\n', min(all_valid_ratios), max(all_valid_ratios));
end

% ==================== 按条件分组统计（可选） ====================
if ismember('condition', data.Properties.VariableNames)
    fprintf('\n=== Statistics by Condition and Percent ===\n');
    unique_conditions = unique(data.condition);
    
    for c = 1:length(unique_conditions)
        condition_name = unique_conditions{c};
        fprintf('\nCondition: %s\n', condition_name);
        fprintf('%-8s %-12s %-12s %-12s\n', 'Percent', 'Count', 'Mean', 'Std');
        fprintf('%s\n', repmat('-', 1, 50));
        
        condition_data = data(strcmp(data.condition, condition_name), :);
        
        for i = 1:length(unique_percents)
            current_percent = unique_percents(i);
            subset_data = condition_data(condition_data.percent == current_percent, :);
            
            tag1_ratios = subset_data.tag1_ratio;
            valid_ratios = tag1_ratios(~isnan(tag1_ratios));
            
            if ~isempty(valid_ratios)
                count = length(valid_ratios);
                mean_value = mean(valid_ratios);
                std_value = std(valid_ratios);
                
                fprintf('%-8.0f %-12d %-12.4f %-12.4f\n', ...
                        current_percent, count, mean_value, std_value);
            end
        end
    end
end

% ==================== 简化的汇总表 ====================
fprintf('\n=== Summary Table ===\n');
fprintf('Results stored in workspace variable ''results'':\n');
fprintf('Column 1: Percent\n');
fprintf('Column 2: Count\n');
fprintf('Column 3: Mean\n');
fprintf('Column 4: Median\n');
fprintf('Column 5: Std\n');
fprintf('Column 6: Min\n');
fprintf('Column 7: Max\n');

fprintf('\n=== Analysis Complete ===\n');
fprintf('No output file created - results displayed above\n');