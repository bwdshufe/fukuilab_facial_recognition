% Define ID range
start_id = 1;  % Starting subject ID
end_id = 36;    % Ending subject ID

% Initialize table for results
varTypes = {'int8','string','double','double'};
varNames = {'No','condition','PSE','slope'};
sz = [64 size(varTypes,2)];
H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Process data for subjects 41-42
fprintf('Starting data processing...\n');
for no = start_id:end_id
    fprintf('Processing subject ID: %d\n', no);
    % Read data from CSV
    data = readtable(sprintf('Metrics/eachCsv/%d_each.csv', no));

    % Define condition names
    cond_names = {'u1','f','u2'};

    % Combine condition and percent columns for grouping
    data.condition_percent = strcat(data.condition, '_', string(data.percent));

    % Calculate outliers by group
    cond_groups = findgroups(data.condition_percent);
    data_no_outliers = table();
    outliers_count = table();
    
    for i = 1:length(cond_names)
        % Get data for current condition
        cond_data = data(strcmp(data.condition, cond_names{i}),:);

        % Calculate mean and standard deviation
        mean_RT = mean(cond_data.RT);
        sd_RT = std(cond_data.RT);
    
        % Define outlier range
        outlier_lower = mean_RT - 3*sd_RT;
        outlier_upper = mean_RT + 3*sd_RT;

        % Remove outliers
        cond_data_no_outliers = cond_data(cond_data.RT >= outlier_lower & cond_data.RT <= outlier_upper,:);
        data_no_outliers = [data_no_outliers; cond_data_no_outliers];

        % Count outliers
        outliers = cond_data(cond_data.RT < outlier_lower | cond_data.RT > outlier_upper,:);
        outlier_count = size(outliers,1);
        outlier_info = table(string(cond_names{i}), mean_RT, sd_RT, outlier_lower, outlier_upper, outlier_count, ...
            'VariableNames', {'condition', 'mean_RT', 'sd_RT', 'outlier_lower', 'outlier_upper', 'outlier_count'});
        outliers_count = [outliers_count; outlier_info];
    end

    % Save processed data
    filename_outliers = sprintf('Metrics/eachOutlier/mean_3sd/%d_outliers.csv', no);
    writetable(data_no_outliers, filename_outliers);
    
    filename_outliers_count = sprintf('Metrics/eachOutlier/mean_3sd/%d_outliers_count.csv', no);
    writetable(outliers_count, filename_outliers_count);
end

% Initialize table for psychometric function analysis
varTypes = {'int8','string','double','double'};
varNames = {'No','condition','Threshold','slope'};
sz = [64 size(varTypes,2)];
H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Initialize table for all results
all_H = table();

% Process psychometric functions
fprintf('\nStarting psychometric function analysis...\n');
for j = start_id:end_id
    fprintf('Processing psychometric functions for subject ID: %d\n', j);
    % Read processed data
    T = readtable(sprintf('Metrics/eachOutlier/mean_3sd/%d_outliers.csv', j));

    conditions = ["u1","u2","f"];
    j_conditions = ["unknown1","unknown2","friend"];
    
    % Create mapping for percentages
    keySet = {0,10,20,30,35,40,45,50,55,60,65,70,80,90,100};
    valueSet = 1:15;
    M = containers.Map(keySet,valueSet);
    
    % Initialize count table
    varTypes = {'int8','int8','int8'};
    varNames = {'u1','u2','f'};
    sz = [15 size(varTypes,2)];
    C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    
    % Count judgments
    for i = 1:height(T)
        if T{i,"judge"} == 1
            C{M(T{i,"percent"}),T{i,"condition"}} = C{M(T{i,"percent"}),T{i,"condition"}} + 1;
        end
    end

    % Process each condition
    for i = 1:3
        fprintf('  Processing condition: %s\n', conditions(i));
        D = C{:,conditions(i)};
        data = zeros(15,3);
        data(:,1) = [0;10;20;30;35;40;45;50;55;60;65;70;80;90;100];
        data(:,2) = D;
        data(:,3) = 15;
        
        % Set psignifit options
        options = struct;
        options.sigmoidName = 'norm';
        options.expType = 'YesNo';
        options.confP = .80;
        
        % Fit psychometric function
        result = psignifit(data,options);
        
        % Create figure but don't display it
        fig = figure('Visible', 'off');
        plotPsych(result);
        title(j_conditions(i));
        
        % Calculate slope and other metrics
        slope = getSlope(result, result.Fit(1));
        threshold = getThreshold(result, 0.5);
        width = result.Fit(2);
        
        % Store results
        H{(j-1)*3+i, "No"} = j;
        H{(j-1)*3+i,"condition"} = conditions(i);
        H{(j-1)*3+i,"Threshold"} = result.Fit(1);
        H{(j-1)*3+i,"slope"} = slope;
        H{(j-1)*3+i,"Width"} = width;
        
        % Save plot and close figure
        saveas(fig, sprintf('Metrics/Threshold/mean_3sd/psychometric_function/%d_%s_mean_3sd.png', j, conditions(i)));
        close(fig);
        
        writetable(H, sprintf('Metrics/Threshold/mean_3sd/each_mean_3sd/Threshold_%d_mean_3sd.csv', j));
    end
    
    % Append results to all_H
    all_H = [all_H; H];
end

fprintf('\nProcessing completed!\n');

% Uncomment to save final results
% writetable(all_H,'Metrics/Threshold/mean_3sd/Threshold_mean_3sd.csv');