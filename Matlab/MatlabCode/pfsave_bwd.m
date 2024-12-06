% Add path to psignifit
addpath('C:\Users\bwdsh\OneDrive\桌面\実験\psignifit-master');

% Define ID range
start_id = 1;  % Starting subject ID
end_id = 36;    % Ending subject ID

% Initialize result table
varTypes = {'int8','string','double','double'};
varNames = {'No','condition','Threshold','slope'};
sz = [64 size(varTypes,2)];
H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Main loop for processing each subject
for j = start_id:end_id
    no = j;
    fprintf('Processing ID %d of 36...\n', no);  % 添加进度提示
    
    T = readtable("Metrics/eachCsv/" + num2str(no) + "_each.csv");
    conditions = ["u1","u2","f"];
    j_conditions = ["unknown1","unknown2","friend"];
    
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
        
        % Create and format plot (hidden)
        fig = figure('visible', 'off');
        plotPsych(result);
        title(j_conditions(i));
        
        % Calculate slope and store results
        resultSmall = rmfield(result,{'Posterior','weight'});
        slope = getSlope(result, result.Fit(1));
        Threshold(i,:) = [result.Fit(1) slope];
        
        % Store results in table
        H{(no-1)*4+i,"No"} = no;
        H{(no-1)*4+i,"condition"} = conditions(i);
        H{(no-1)*4+i,"Threshold"} = result.Fit(1);
        H{(no-1)*4+i,"slope"} = slope;
        
        % Format plot
        xlim([20 90]);
        xticks(0:10:100);
        yticks(0:0.2:1);
        
        % Set font properties
        ax = gca;
        ax.FontWeight = 'bold';
        ax.FontSize = 16;
        
        % Save figure and close it
        saveas(gcf, "Metrics/raw/psychometric_function/" + num2str(no) + "_" + conditions(i) + "_raw2.png");
        close(fig);
    end
end

fprintf('Processing complete! Results saved to psychometric_raw.csv\n');  % 添加完成提示
% Save results
writetable(H,"Metrics/raw/psychometric_raw.csv");