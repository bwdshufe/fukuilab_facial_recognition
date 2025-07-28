% Data analysis and filtering code
% Read all processed data, calculate validation accuracy by subject, and exclude specified IDs

% Set paths and parameters
processed_data_dir = 'ProcessedData/TE/';
exclude_ids = [14, 19, 20, 31, 38, 42, 47, 50, 55, 57, 59, 70, 73, 79, 83, 92, 96]; % List of IDs to exclude
accuracy_threshold = 1.5; % Threshold for valid accuracy data (data must be < this value)

% Check if directory exists
if ~exist(processed_data_dir, 'dir')
    error('Processed data directory does not exist: %s', processed_data_dir);
end

% Get all processed CSV files
csv_files = dir(fullfile(processed_data_dir, '*_processed.csv'));

if isempty(csv_files)
    error('No processed CSV files found in directory %s', processed_data_dir);
end

% Initialize statistical variables
all_data = [];

fprintf('Starting analysis of %d CSV files...\n', length(csv_files));

% Read all data files
for file_idx = 1:length(csv_files)
    file_path = fullfile(processed_data_dir, csv_files(file_idx).name);
    
    try
        % Read CSV file
        data = readtable(file_path);
        
        % Check if necessary columns exist
        required_columns = {'No', 'validation_accuracy', 'recording_name'};
        if ~all(ismember(required_columns, data.Properties.VariableNames))
            fprintf('Warning: File %s missing required columns, skipping\n', csv_files(file_idx).name);
            continue;
        end
        
        % Add to total data
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

% Data filtering: Remove specified IDs
if ~isempty(exclude_ids)
    % Apply ID filtering
    filtered_data = all_data(~ismember(all_data.No, exclude_ids), :);
else
    filtered_data = all_data;
end

% Function to check if accuracy value is valid
function is_valid = isValidAccuracy(accuracy, threshold)
    % Check if accuracy is valid (numeric, not NaN, not empty, and < threshold)
    is_valid = false;
    if isnumeric(accuracy) && ~isempty(accuracy) && ~any(isnan(accuracy)) && accuracy < threshold
        is_valid = true;
    end
end

% Basic statistics after ID filtering
filtered_subjects_list = unique(filtered_data.No);
filtered_subject_count = length(filtered_subjects_list);
expected_recordings_count = filtered_subject_count * 9; % Each participant should have 9 recordings

% Statistical analysis of actual recordings after ID filtering
filtered_subject_stats = [];
actual_recordings_count = 0;
valid_recordings_count = 0;  % Valid data (< threshold, not NaN, and not empty)
all_accuracies = [];

for i = 1:length(filtered_subjects_list)
    subject_id = filtered_subjects_list(i);
    subject_data = filtered_data(filtered_data.No == subject_id, :);
    subject_recordings = unique(subject_data.recording_name);
    
    % Count recording accuracies for this subject
    recording_accuracies = [];
    valid_recording_accuracies = []; % Only store valid accuracies for mean calculation
    
    for j = 1:length(subject_recordings)
        recording_name = subject_recordings{j};
        recording_data = subject_data(strcmp(subject_data.recording_name, recording_name), :);
        accuracy = recording_data.validation_accuracy(1);
        
        actual_recordings_count = actual_recordings_count + 1;
        
        % Check if accuracy is valid
        if isValidAccuracy(accuracy, accuracy_threshold)
            valid_recordings_count = valid_recordings_count + 1;
            recording_accuracies(end+1) = accuracy;
            valid_recording_accuracies(end+1) = accuracy;
            all_accuracies(end+1) = accuracy;
        else
        end
    end
    
    % Store subject statistics (for later sorting by mean accuracy in ascending order, lower is better)
    % Only calculate mean from valid accuracies
    filtered_subject_stats(i).id = subject_id;
    if ~isempty(valid_recording_accuracies)
        filtered_subject_stats(i).mean_accuracy = mean(valid_recording_accuracies);
    else
        filtered_subject_stats(i).mean_accuracy = NaN; % No valid recordings for this subject
    end
    filtered_subject_stats(i).recording_count = length(subject_recordings);
    filtered_subject_stats(i).valid_recording_count = length(valid_recording_accuracies);
end

% Calculate percentage of valid data out of total recordings
valid_percentage = (valid_recordings_count / expected_recordings_count) * 100;

% Calculate final mean accuracy of remaining data (recordings with accuracy < threshold, not NaN, and not empty)
valid_data_rows = [];
for i = 1:height(filtered_data)
    accuracy = filtered_data.validation_accuracy(i);
    if isValidAccuracy(accuracy, accuracy_threshold)
        valid_data_rows(end+1) = i;
    end
end

final_data = filtered_data(valid_data_rows, :);

if ~isempty(final_data)
    final_mean_accuracy = mean(final_data.validation_accuracy);
else
    final_mean_accuracy = NaN;
    fprintf('Warning: No valid data found after filtering!\n');
end

% Find subjects with lower accuracy (sort by mean accuracy in ascending order, take top 30%, lower is better)
% Only include subjects with valid mean accuracy (not NaN)
valid_subject_stats = filtered_subject_stats(~isnan([filtered_subject_stats.mean_accuracy]));

if ~isempty(valid_subject_stats)
    [~, sort_idx] = sort([valid_subject_stats.mean_accuracy], 'ascend');
    top_percentage = 0.3; % Take top 30% (best accuracy)
    top_count = max(1, round(length(valid_subject_stats) * top_percentage));
    best_subject_ids = [valid_subject_stats(sort_idx(1:top_count)).id];
else
    best_subject_ids = [];
    fprintf('Warning: No subjects with valid mean accuracy found!\n');
end

% Final concise output
fprintf('\n=== Final Statistical Results ===\n');
fprintf('Number of participants after ID filtering: %d\n', filtered_subject_count);
fprintf('Total recordings: %d\n', expected_recordings_count);
fprintf('Valid data count (accuracy < %.1f): %d\n', accuracy_threshold, valid_recordings_count);
fprintf('Percentage of valid data out of total recordings: %.2f%%\n', valid_percentage);

if ~isnan(final_mean_accuracy)
    fprintf('Mean accuracy of valid data: %.3f°\n', final_mean_accuracy);
else
    fprintf('Mean accuracy of valid data: N/A (no valid data)\n');
end

fprintf('\n=== Analysis Complete ===\n');