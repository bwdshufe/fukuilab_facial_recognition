% Add path to psignifit
current_dir = pwd;
addpath(fullfile(current_dir, 'psignifit-master'));

% Get user choice
choice = input('Enter 1 for generating figures and data, or 2 for data only: ');

% Define ID range
start_id = 57;
end_id = 57;

% Check if output CSV exists and load it, otherwise create new table
csv_path = "Metrics/raw/psychometric_raw.csv";
if isfile(csv_path)
    H = readtable(csv_path);
else
    % Initialize result table
    varTypes = {'int8','string','double','double'};
    varNames = {'No','condition','Threshold','slope'};
    sz = [64 size(varTypes,2)];
    H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
end

% Main loop for processing each subject
for j = start_id:end_id
    no = j;
    filename = sprintf('Metrics/eachCsv/%d_each.csv', no);
    
    % Check if input file exists
    if ~isfile(filename)
        fprintf('Skipping ID %d - input file not found\n', no);
        continue;
    end
    
    % Only check existing files if generating figures (choice == 1)
    if choice == 1
        conditions = ["u1","u2","f"];
        all_files_exist = true;
        for i = 1:3
            output_file = sprintf('Metrics/raw/psychometric_function/%d_%s.png', no, conditions(i));
            if ~isfile(output_file)
                all_files_exist = false;
                break;
            end
        end
        if all_files_exist
            fprintf('Skipping ID %d - output files already exist\n', no);
            continue;
        end
    end
    
    fprintf('Processing ID %d of %d...\n', no, end_id);
    T = readtable("Metrics/eachCsv/" + num2str(no) + "_each.csv");
    j_conditions = ["unknown1","unknown2","friend"];
    conditions = ["u1","u2","f"];
    
    % Create mapping for percentage values
    keySet = {0,10,20,30,35,40,45,50,55,60,65,70,80,90,100};
    valueSet = 1:15;
    M = containers.Map(keySet,valueSet);
    
    % Initialize condition table
    varTypes = {'int8','int8','int8'};
    varNames = {'u1','u2','f'};
    sz = [15 size(varTypes,2)];
    C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    
    % Process judgments
    for i = 1:675
        if T{i,"judge"} == 1
            C{M(T{i,"percent"}),T{i,"condition"}} = C{M(T{i,"percent"}),T{i,"condition"}} + 1;
        end
    end
    
    % Initialize threshold matrix
    Threshold = zeros(4,2);
    
    % Process each condition
    for i = 1:3
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
        result.Fit;
        
        % Only plot and save figures if choice == 1
        if choice == 1
            fig = figure('visible', 'off');
            plotPsych(result);
            title(j_conditions(i));
            xlim([20 90]);
            xticks(0:10:100);
            yticks(0:0.2:1);
            ax = gca;
            ax.FontWeight = 'bold';
            ax.FontSize = 16;
            saveas(gcf, "Metrics/raw/psychometric_function/" + num2str(no) + "_" + conditions(i) + ".png");
            close(fig);
        end
        
        % Calculate and store results
        resultSmall = rmfield(result,{'Posterior','weight'});
        slope = getSlope(result, result.Fit(1));
        Threshold(i,:) = [result.Fit(1) slope];
        
        % Store in table
        H{(no-1)*4+i,"No"} = no;
        H{(no-1)*4+i,"condition"} = conditions(i);
        H{(no-1)*4+i,"Threshold"} = result.Fit(1);
        H{(no-1)*4+i,"slope"} = slope;
    end
    
    % Save results after processing each subject
    try
        writetable(H, csv_path);
        fprintf('Data saved for subject %d\n', no);
    catch ME
        fprintf('Error saving data for subject %d: %s\n', no, ME.message);
        % Create backup file if main save fails
        writetable(H, sprintf('Metrics/raw/psychometric_raw_backup_%d.csv', no));
    end
end

fprintf('All processing completed.\n');