% Get processing mode from user
mode = input('Enter processing mode (1 for plots + data, 2 for data only): ');
if ~ismember(mode, [1, 2])
    error('Invalid mode selected. Please choose 1 or 2.');
end

% Define ID range
start_id = 1;  % Starting subject ID
end_id = 57;    % Ending subject ID

varTypes = {'int8','string','double','double','double','double'};
varNames = {'No','condition','Threshold','Width','Slope','RT_mean'};
sz = [64 size(varTypes,2)];
H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Initialize summary table
all_H = table();

for j = start_id:end_id
    % Check if input file exists
    input_file = sprintf('Metrics/eachOutlier/mean_3sd/%d_outliers.csv', j);
    if ~isfile(input_file)
        fprintf('Skipping subject ID: %d (file not found)\n', j);
        continue;
    end
    
    fprintf('Processing ID: %d\n', j);  % Progress indicator
    no = j;
    T = readtable(input_file);
    conditions = ["u1","u2","f"];
    j_conditions = ["unknown1","unknown2","friend"];
    keySet = {0,10,20,30,35,40,45,50,55,60,65,70,80,90,100};
    valueSet = 1:15;
    M = containers.Map(keySet,valueSet);
    
    varTypes = {'int8','int8','int8'};
    varNames = {'u1','u2','f'};
    sz = [15 size(varTypes,2)];
    C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    C{:,:} = 0;  % Initialize all counts to zero
    
    for i = 1:height(T)
        if T{i,"judge"} == 1
            C{M(T{i,"percent"}),T{i,"condition"}} = C{M(T{i,"percent"}),T{i,"condition"}} + 1;
        end
    end
    
    for i = 1:3
        D = C{:,conditions(i)};
        data = zeros(15,3);
        data(:,1) = [0;10;20;30;35;40;45;50;55;60;65;70;80;90;100];
        data(:,2) = D;
        data(:,3) = 15;
        
        try
            options = struct;
            options.sigmoidName = 'norm';
            options.expType = 'YesNo';
            options.confP = .80;
            
            result = psignifit(data,options);
            
            % Only create and save plots if mode == 1
            if mode == 1
                % Create figure but make it invisible
                fig = figure('Visible', 'off');
                plotPsych(result);
                title(j_conditions(i));
                
                % Save figure and close it
                saveas(fig, sprintf('Metrics/pf/mean_3sd/psychometric_function/%d_%s_mean_3sd.png', no, conditions(i)));
                close(fig);
            end
            
            % Calculate metrics
            slope = getSlope(result, result.Fit(1));
            threshold = result.Fit(1);
            width = result.Fit(2);
            RT_mean = mean(T{strcmp(T.condition, conditions(i)), 'RT'}, 'omitnan');
            
            % Update table
            H{(no-1)*3+i, "No"} = no;
            H{(no-1)*3+i,"condition"} = conditions(i);
            H{(no-1)*3+i,"Threshold"} = threshold;
            H{(no-1)*3+i,"Width"} = width;
            H{(no-1)*3+i,"Slope"} = slope;
            H{(no-1)*3+i, "RT_mean"} = RT_mean;
            
        catch ME
            fprintf('Error processing condition %s for subject %d: %s\n', conditions(i), no, ME.message);
            continue;
        end
    end
end

% Save final results
writetable(H,"Metrics/pf/mean_3sd/psychometric_mean_3sd.csv");
fprintf('\nProcessing completed!\n');