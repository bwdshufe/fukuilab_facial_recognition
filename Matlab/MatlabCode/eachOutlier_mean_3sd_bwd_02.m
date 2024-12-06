% User input for processing mode
mode = input('Enter processing mode (1 for plots + data, 2 for data only): ');
if ~ismember(mode, [1, 2])
    error('Invalid mode selected. Please choose 1 or 2.');
end

% Ask for starting ID
start_id = 55;
end_id = 57;   % Ending subject ID remains fixed

% Initialize table for all results
varTypes = {'int8','string','double','double','double'};
varNames = {'No','condition','Threshold','slope','Width'};
all_H = table('Size',[0 5],'VariableTypes',varTypes,'VariableNames',varNames);

% Process data for subjects
fprintf('Starting data processing...\n');
for no = start_id:end_id
    % Check if input file exists
    input_file = sprintf('Metrics/eachCsv/%d_each.csv', no);
    if ~isfile(input_file)
        fprintf('Skipping subject ID: %d (file not found)\n', no);
        continue;
    end
    
    fprintf('Processing subject ID: %d\n', no);
    % Read data from CSV
    data = readtable(input_file);

    % Define condition names
    cond_names = {'u1','f','u2'};

    % Initialize tables for processed data
    data_no_outliers = table();
    outliers_count = table();
    
    for i = 1:length(cond_names)
        % Get data for current condition
        cond_data = data(strcmp(data.condition, cond_names{i}), :);

        % Skip if no data for this condition
        if height(cond_data) == 0
            fprintf('  No data found for condition %s, subject %d\n', cond_names{i}, no);
            continue;
        end

        % Calculate mean and standard deviation
        mean_RT = mean(cond_data.RT);
        sd_RT = std(cond_data.RT);
    
        % Define outlier range
        outlier_lower = mean_RT - 3*sd_RT;
        outlier_upper = mean_RT + 3*sd_RT;

        % Remove outliers
        cond_data_no_outliers = cond_data(cond_data.RT >= outlier_lower & cond_data.RT <= outlier_upper, :);
        data_no_outliers = [data_no_outliers; cond_data_no_outliers];

        % Count outliers
        outliers = cond_data(cond_data.RT < outlier_lower | cond_data.RT > outlier_upper, :);
        outlier_count = size(outliers,1);
        outlier_info = table(string(cond_names{i}), mean_RT, sd_RT, outlier_lower, outlier_upper, outlier_count, ...
            'VariableNames', {'condition', 'mean_RT', 'sd_RT', 'outlier_lower', 'outlier_upper', 'outlier_count'});
        outliers_count = [outliers_count; outlier_info];
    end

    % Save processed data and outlier counts
    if height(data_no_outliers) > 0
        % Create directory if it doesn't exist
        if ~exist('Metrics/eachOutlier/mean_3sd', 'dir')
            mkdir('Metrics/eachOutlier/mean_3sd');
        end
        
        % Save outlier-removed data
        filename_outliers = sprintf('Metrics/eachOutlier/mean_3sd/%d_outliers.csv', no);
        writetable(data_no_outliers, filename_outliers);
        
        % Save outlier counts
        filename_outliers_count = sprintf('Metrics/eachOutlier/mean_3sd/%d_outliers_count.csv', no);
        writetable(outliers_count, filename_outliers_count);
    end

    % Process psychometric functions
    if height(data_no_outliers) > 0
        T = data_no_outliers;
        conditions = ["u1","u2","f"];
        j_conditions = ["unknown1","unknown2","friend"];
        
        % [Rest of the psychometric function processing remains the same...]

% Create mapping for percentages
        keySet = {0,10,20,30,35,40,45,50,55,60,65,70,80,90,100};
        valueSet = 1:15;
        M = containers.Map(keySet,valueSet);
        
        % Initialize count table
        varTypes = {'int8','int8','int8'};
        varNames = {'u1','u2','f'};
        sz = [15 size(varTypes,2)];
        C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
        C{:,:} = 0;  % Initialize all counts to zero
        
        % Count judgments
        for i = 1:height(T)
            curr_percent = T.percent(i);
            curr_condition = T.condition{i};
            if T.judge(i) == 1
                C{M(curr_percent),curr_condition} = C{M(curr_percent),curr_condition} + 1;
            end
        end

        % Process each condition
        for i = 1:3
            fprintf('  Processing condition: %s\n', conditions(i));
            D = C{:,conditions(i)};
            
            % Check if we have any data for this condition
            if all(D == 0)
                fprintf('  No data found for condition %s, subject %d\n', conditions(i), no);
                continue;
            end
            
            data = zeros(15,3);
            data(:,1) = [0;10;20;30;35;40;45;50;55;60;65;70;80;90;100];
            data(:,2) = D;
            data(:,3) = 15;
            
            try
                % Set psignifit options
                options = struct;
                options.sigmoidName = 'norm';
                options.expType = 'YesNo';
                options.confP = .80;
                
                % Fit psychometric function
                result = psignifit(data,options);
                
                % Only create and save plot if mode == 1
                if mode == 1
                    fig = figure('Visible', 'off');
                    plotPsych(result);
                    title(j_conditions(i));
                    saveas(fig, sprintf('Metrics/Threshold/mean_3sd/psychometric_function/%d_%s_mean_3sd.png', no, conditions(i)));
                    close(fig);
                end
                
                % Calculate slope and other metrics
                slope = getSlope(result, result.Fit(1));
                threshold = getThreshold(result, 0.5);
                width = result.Fit(2);
                
                % Add results to all_H
                new_row = table(no, string(conditions(i)), result.Fit(1), slope, width, ...
                    'VariableNames', {'No','condition','Threshold','slope','Width'});
                all_H = [all_H; new_row];
                
            catch ME
                fprintf('  Error processing condition %s for subject %d: %s\n', conditions(i), no, ME.message);
                continue;
            end
        end
    end
end

fprintf('\nProcessing completed!\n');

% Save final results
writetable(all_H,'Metrics/Threshold/mean_3sd/Threshold_mean_3sd.csv');