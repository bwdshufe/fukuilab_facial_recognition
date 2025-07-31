% Statistical analysis code - output results by two dimensions
% 1. ID and condition
% 2. ID, condition and percent
% Modified: Use cumulative values instead of averages, correctly handle NaN and empty values
% Added: recording_count column to show how many recordings were retained
% Added: tag1_tag3_gaze_x_gte960_sum statistics

% ==================== Parameter Settings ====================
processed_data_dir = 'ProcessedData_Modified/TE/';  % 修改为新的数据目录
exclude_ids = [14, 19, 20, 31, 38, 42, 47, 50, 55, 57, 59, 70, 73, 79, 83, 92, 96]; % List of IDs to exclude
accuracy_threshold = 2; % accuracy threshold, data above this value will be filtered
output_dir = 'StatisticalResults_Modified/'; % 修改为新的输出目录
% ==========================================================

% Check if directory exists
if ~exist(processed_data_dir, 'dir')
    error('Processed data directory does not exist: %s', processed_data_dir);
end

% Create output directory
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Get all processed CSV files
csv_files = dir(fullfile(processed_data_dir, '*_processed.csv'));

if isempty(csv_files)
    error('No processed CSV files found in directory %s', processed_data_dir);
end

% Initialize data storage
all_data = [];

fprintf('Starting to read %d CSV files...\n', length(csv_files));
fprintf('Current accuracy threshold setting: %.2f\n', accuracy_threshold);
fprintf('Exclude ID list: [%s]\n\n', num2str(exclude_ids));

% Function to check if accuracy value is valid
function is_valid = isValidAccuracy(accuracy, threshold)
    % Check if accuracy is valid (numeric, not NaN, not empty, and <= threshold)
    is_valid = false;
    if isnumeric(accuracy) && ~isempty(accuracy) && ~any(isnan(accuracy)) && accuracy <= threshold
        is_valid = true;
    end
end

% Read all data files
for file_idx = 1:length(csv_files)
    file_path = fullfile(processed_data_dir, csv_files(file_idx).name);
    
    try
        % Read CSV file
        data = readtable(file_path);
        
        % Check if required columns exist (添加新的列)
        required_columns = {'No', 'percent', 'condition', 'RT', 'fixation_count', ...
                           'eye_tag1_count', 'nose_tag2_count', 'mouth_tag3_count', 'tag1_only_no_tag2_count', ...
                           'validation_accuracy', 'recording_name', 'tag1_tag3_gaze_x_gte960_sum'};
        
        % Display column names for debugging
        fprintf('File %s column names: %s\n', csv_files(file_idx).name, strjoin(data.Properties.VariableNames, ', '));
        
        missing_columns = setdiff(required_columns, data.Properties.VariableNames);
        if ~isempty(missing_columns)
            fprintf('Warning: File %s missing required columns: %s, skipping\n', csv_files(file_idx).name, strjoin(missing_columns, ', '));
            continue;
        end
        
        % Merge to total data
        if isempty(all_data)
            all_data = data;
        else
            all_data = [all_data; data];
        end
        
    catch ME
        fprintf('Error reading file %s: %s\n', csv_files(file_idx).name, ME.message);
        continue;
    end
end

if isempty(all_data)
    error('Failed to read any data files');
end

fprintf('Successfully read data, total rows: %d\n', height(all_data));

% Display basic data information for debugging
fprintf('Data column names: %s\n', strjoin(all_data.Properties.VariableNames, ', '));
fprintf('First 5 rows preview:\n');
if height(all_data) >= 5
    disp(all_data(1:5, :));
else
    disp(all_data);
end
fprintf('\n');

% Step 1: Filter specified IDs
if ~isempty(exclude_ids)
    filtered_data = all_data(~ismember(all_data.No, exclude_ids), :);
    fprintf('Remaining data rows after ID filtering: %d\n', height(filtered_data));
else
    filtered_data = all_data;
end

% Step 2: Filter validation_accuracy
fprintf('Starting to filter validation_accuracy...\n');

% Use improved validation function to check each row
valid_accuracy_indices = [];
nan_count = 0;
empty_count = 0;
above_threshold_count = 0;
non_numeric_count = 0;

for i = 1:height(filtered_data)
    accuracy = filtered_data.validation_accuracy(i);
    
    % Detailed check for each value
    if ~isnumeric(accuracy)
        non_numeric_count = non_numeric_count + 1;
    elseif isempty(accuracy)
        empty_count = empty_count + 1;
    elseif any(isnan(accuracy))
        nan_count = nan_count + 1;
    elseif accuracy > accuracy_threshold
        above_threshold_count = above_threshold_count + 1;
    else
        % This is a valid value
        valid_accuracy_indices(end+1) = i;
    end
end

% Extract valid data
valid_data = filtered_data(valid_accuracy_indices, :);

% Display detailed filtering statistics
total_after_id_filter = height(filtered_data);
valid_count = height(valid_data);

fprintf('Accuracy filtering statistics:\n');
fprintf('- Non-numeric data: %d rows (filtered)\n', non_numeric_count);
fprintf('- Empty data: %d rows (filtered)\n', empty_count);
fprintf('- NaN validation_accuracy data: %d rows (filtered)\n', nan_count);
fprintf('- validation_accuracy > %.2f data: %d rows (filtered)\n', accuracy_threshold, above_threshold_count);
fprintf('- Final valid data: %d rows (%.1f%% of total)\n\n', valid_count, (valid_count/total_after_id_filter)*100);

% Ensure there is valid data
if isempty(valid_data)
    error('No valid data after filtering');
end

% Display accuracy statistics for valid data
valid_accuracies = valid_data.validation_accuracy;
fprintf('Valid data accuracy statistics:\n');
fprintf('- Minimum: %.3f\n', min(valid_accuracies));
fprintf('- Maximum: %.3f\n', max(valid_accuracies));
fprintf('- Mean: %.3f\n', mean(valid_accuracies));
fprintf('- Median: %.3f\n\n', median(valid_accuracies));

% ==================== First dimension statistics: ID + condition ====================
fprintf('Starting statistics by ID and condition...\n');

% Get unique ID and condition combinations
unique_combinations_1 = unique(valid_data(:, {'No', 'condition'}), 'rows');
fprintf('Found %d unique ID-condition combinations\n', height(unique_combinations_1));

% Display first few combinations for debugging
fprintf('First few ID-condition combinations:\n');
if height(unique_combinations_1) >= 3
    disp(unique_combinations_1(1:3, :));
else
    disp(unique_combinations_1);
end
fprintf('\n');

% Initialize result table
result_table_1 = table();

for i = 1:height(unique_combinations_1)
    current_id = unique_combinations_1.No(i);
    current_condition = unique_combinations_1.condition{i};
    
    % Filter data for current ID and condition
    subset_data = valid_data(valid_data.No == current_id & ...
                            strcmp(valid_data.condition, current_condition), :);
    
    if height(subset_data) > 0
        % Calculate statistics - modified calculation logic
        % 1. Calculate number of unique recording_names
        unique_recordings = unique(subset_data.recording_name);
        num_recordings = length(unique_recordings);
        
        % 2. RT mean = RT cumulative / number of valid recordings
        mean_RT = sum(subset_data.RT) / num_recordings;
        
        % 3. Calculate cumulative values for each tag
        total_eye_tag1_count = sum(subset_data.eye_tag1_count);
        total_nose_tag2_count = sum(subset_data.nose_tag2_count);
        total_mouth_tag3_count = sum(subset_data.mouth_tag3_count);
        total_tag1_only_no_tag2_count = sum(subset_data.tag1_only_no_tag2_count);
        total_fixation_count = sum(subset_data.fixation_count);
        
        % 新增：计算tag1_tag3_gaze_x_gte960_sum的累积值
        total_tag1_tag3_gaze_x_gte960_sum = sum(subset_data.tag1_tag3_gaze_x_gte960_sum);
        
        % 4. Fixation mean = fixation cumulative / number of valid recordings
        mean_fixation_count = total_fixation_count / num_recordings;
        
        % 5. Calculate ratios (based on cumulative values)
        tag1_ratio = total_eye_tag1_count / total_fixation_count;
        if isnan(tag1_ratio) || isinf(tag1_ratio)
            tag1_ratio = 0;
        end
        
        tag2_ratio = total_nose_tag2_count / total_fixation_count;
        if isnan(tag2_ratio) || isinf(tag2_ratio)
            tag2_ratio = 0;
        end
        
        tag3_ratio = total_mouth_tag3_count / total_fixation_count;
        if isnan(tag3_ratio) || isinf(tag3_ratio)
            tag3_ratio = 0;
        end
        
        tag1_only_ratio = total_tag1_only_no_tag2_count / total_fixation_count;
        if isnan(tag1_only_ratio) || isinf(tag1_only_ratio)
            tag1_only_ratio = 0;
        end
        
        % 新增：计算gaze_x_gte960的比例
        gaze_x_gte960_ratio = total_tag1_tag3_gaze_x_gte960_sum / total_fixation_count;
        if isnan(gaze_x_gte960_ratio) || isinf(gaze_x_gte960_ratio)
            gaze_x_gte960_ratio = 0;
        end
        
        % Add to result table (添加新的列)
        new_row = table(current_id, {current_condition}, mean_RT, tag1_ratio, tag2_ratio, tag3_ratio, ...
                       tag1_only_ratio, gaze_x_gte960_ratio, mean_fixation_count, num_recordings, ...
                       'VariableNames', {'ID', 'condition', 'mean_RT', 'tag1_ratio', 'tag2_ratio', 'tag3_ratio', ...
                       'tag1_only_ratio', 'gaze_x_gte960_ratio', 'mean_fixation_count', 'recording_count'});
        result_table_1 = [result_table_1; new_row];
    end
end

% Create first result table
if height(result_table_1) > 0
    % Output first CSV file
    output_file_1 = fullfile(output_dir, 'statistics_by_ID_condition.csv');
    writetable(result_table_1, output_file_1);
    fprintf('First statistical result saved: %s\n', output_file_1);
    fprintf('Result rows: %d\n\n', height(result_table_1));
end

% ==================== Second dimension statistics: ID + condition + percent ====================
fprintf('Starting statistics by ID, condition and percent...\n');

% Get unique ID, condition and percent combinations
unique_combinations_2 = unique(valid_data(:, {'No', 'condition', 'percent'}), 'rows');
fprintf('Found %d unique ID-condition-percent combinations\n', height(unique_combinations_2));

% Initialize result table
result_table_2 = table();

for i = 1:height(unique_combinations_2)
    current_id = unique_combinations_2.No(i);
    current_condition = unique_combinations_2.condition{i};
    current_percent = unique_combinations_2.percent(i);
    
    % Filter data for current ID, condition and percent
    subset_data = valid_data(valid_data.No == current_id & ...
                            strcmp(valid_data.condition, current_condition) & ...
                            valid_data.percent == current_percent, :);
    
    if height(subset_data) > 0
        % Calculate number of recordings for this specific combination
        unique_recordings = unique(subset_data.recording_name);
        num_recordings = length(unique_recordings);
        
        % Direct calculation for each specific ID-condition-percent combination
        % Calculate mean values directly from this subset
        mean_RT = mean(subset_data.RT);
        mean_fixation_count = mean(subset_data.fixation_count);
        
        % Calculate cumulative values for tags
        total_eye_tag1_count = sum(subset_data.eye_tag1_count);
        total_nose_tag2_count = sum(subset_data.nose_tag2_count);
        total_mouth_tag3_count = sum(subset_data.mouth_tag3_count);
        total_tag1_only_no_tag2_count = sum(subset_data.tag1_only_no_tag2_count);
        total_fixation_count = sum(subset_data.fixation_count);
        
        % 新增：计算tag1_tag3_gaze_x_gte960_sum的累积值
        total_tag1_tag3_gaze_x_gte960_sum = sum(subset_data.tag1_tag3_gaze_x_gte960_sum);
        
        % Calculate ratios based on total counts for this specific combination
        tag1_ratio = total_eye_tag1_count / total_fixation_count;
        if isnan(tag1_ratio) || isinf(tag1_ratio)
            tag1_ratio = 0;
        end
        
        tag2_ratio = total_nose_tag2_count / total_fixation_count;
        if isnan(tag2_ratio) || isinf(tag2_ratio)
            tag2_ratio = 0;
        end
        
        tag3_ratio = total_mouth_tag3_count / total_fixation_count;
        if isnan(tag3_ratio) || isinf(tag3_ratio)
            tag3_ratio = 0;
        end
        
        tag1_only_ratio = total_tag1_only_no_tag2_count / total_fixation_count;
        if isnan(tag1_only_ratio) || isinf(tag1_only_ratio)
            tag1_only_ratio = 0;
        end
        
        % 新增：计算gaze_x_gte960的比例
        gaze_x_gte960_ratio = total_tag1_tag3_gaze_x_gte960_sum / total_fixation_count;
        if isnan(gaze_x_gte960_ratio) || isinf(gaze_x_gte960_ratio)
            gaze_x_gte960_ratio = 0;
        end
        
        % Add to result table (添加新的列)
        new_row = table(current_id, {current_condition}, current_percent, mean_RT, tag1_ratio, tag2_ratio, tag3_ratio, ...
                       tag1_only_ratio, gaze_x_gte960_ratio, mean_fixation_count, num_recordings, ...
                       'VariableNames', {'ID', 'condition', 'percent', 'mean_RT', 'tag1_ratio', 'tag2_ratio', 'tag3_ratio', ...
                       'tag1_only_ratio', 'gaze_x_gte960_ratio', 'mean_fixation_count', 'recording_count'});
        result_table_2 = [result_table_2; new_row];
    end
end

% Create second result table
if height(result_table_2) > 0
    % Output second CSV file
    output_file_2 = fullfile(output_dir, 'statistics_by_ID_condition_percent.csv');
    writetable(result_table_2, output_file_2);
    fprintf('Second statistical result saved: %s\n', output_file_2);
    fprintf('Result rows: %d\n\n', height(result_table_2));
end

% ==================== Summary Information ====================
fprintf('=== Statistical Analysis Complete ===\n');
fprintf('Accuracy threshold used: %.2f\n', accuracy_threshold);
fprintf('Number of excluded IDs: %d\n', length(exclude_ids));
fprintf('Final valid data rows: %d\n', height(valid_data));
fprintf('First dimension results (ID + condition): %d rows\n', height(result_table_1));
fprintf('Second dimension results (ID + condition + percent): %d rows\n', height(result_table_2));
fprintf('Output directory: %s\n', output_dir);
fprintf('\nFiltering rules explanation:\n');
fprintf('- Non-numeric, empty, NaN validation_accuracy are all filtered\n');
fprintf('- Only keep data with validation_accuracy <= %.2f\n', accuracy_threshold);
fprintf('\nOutput column explanation:\n');
fprintf('- mean_RT: Mean RT value for the combination\n');
fprintf('- tag1_ratio: Tag1(eye) count ratio to total fixation count\n');
fprintf('- tag2_ratio: Tag2(nose) count ratio to total fixation count\n');
fprintf('- tag3_ratio: Tag3(mouth) count ratio to total fixation count\n');
fprintf('- tag1_only_ratio: Tag1_only count ratio to total fixation count\n');
fprintf('- gaze_x_gte960_ratio: Tag1+Tag3 with Gaze X >= 960 ratio to total fixation count\n');
fprintf('- mean_fixation_count: Mean fixation count for the combination\n');
fprintf('- recording_count: Number of recordings retained for this combination\n');
fprintf('===================\n');