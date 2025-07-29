% Define ID range
start_id = 1;  % Starting subject ID
end_id = 36;    % Ending subject ID

varTypes = {'int8','string','double','double','double','double'};
varNames = {'No','condition','Threshold','Width','Slope','RT_mean'};
sz = [64 size(varTypes,2)];
H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Initialize summary table
all_H = table();

for j =start_id:end_id
    fprintf('Processing ID: %d\n', j);  % Simple progress indicator
    no = j;
    T = readtable("Metrics/eachOutlier/mean_3sd/" + num2str(no) + "_outliers.csv");
    conditions = ["u1","u2","f"];
    j_conditions = ["unknown1","unknown2","friend"];
    keySet = {0,10,20,30,35,40,45,50,55,60,65,70,80,90,100};
    valueSet = 1:15;
    M = containers.Map(keySet,valueSet);
    
    varTypes = {'int8','int8','int8'};
    varNames = {'u1','u2','f'};
    sz = [15 size(varTypes,2)];
    C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    
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
        
        options = struct;
        options.sigmoidName = 'norm';
        options.expType = 'YesNo';
        options.confP = .80;
        
        result = psignifit(data,options);
        
        % Create figure but make it invisible
        fig = figure('Visible', 'off');
        plotPsych(result);
        title(j_conditions(i));
        
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
        
        % Save figure and close it
        saveas(fig, "Metrics/pf/mean_3sd/psychometric_function/" + num2str(no) +"_"+ conditions(i) + "_mean_3sd.png");
        close(fig);
    end
end

writetable(H,"Metrics/pf/mean_3sd/psychometric_mean_3sd.csv");