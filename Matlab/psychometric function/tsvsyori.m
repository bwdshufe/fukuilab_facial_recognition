name = "fukuyo";
key = "f";
no = 55;
sex = "f";
%%
pass = "Metrics/MetricsRaw/" + name + " Metrics.tsv";
T = readtable(pass,"FileType","text");
%%
T1 = T(:, {'Recording','Participant','Timeline','TOI','Interval','Media','Duration_of_interval','Start_of_interval','Last_key_press'});
%%
T2 = T1;
gyo = 0;
for i = 1:size(T1)
    if strlength(T1{i,"TOI"}) >= strlength(name)
        a =T1{i,"TOI"}{1}(1:strlength(name));
        if a == name
            gyo = gyo + 1;
            T2(gyo,:) = T1(i,:);
        end
    end
end
T2 = T2(1:675,:);
%%
B = sortrows(T2,["Recording" "Start_of_interval"]);
%%
sz = [675 6];
varTypes = {'string','string','int8','int8','int8','string'};
varNames = {'self_key','condition','percent','session','No','sex'};
C = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
C(:,'self_key') = {key};
C(:,'No') = {no};
C(:,'sex') = {sex};
%name= "yanokuchi";
for i = 1:675
    mediaParts = strsplit(T2{i,"Media"}{1},"_");
    condition = mediaParts{2};  % Assuming the second part after splitting is always the condition
    percentString = mediaParts{3};
    percentValue = str2double(percentString(1:end-1));  % Remove the '%' and convert to number

    C{i, 'condition'} = {condition};
    C{i, 'percent'} = percentValue;

    if i <= 225
        C{i,"session"} = 1;
    elseif i <= 450
        C{i,"session"} = 2;
    else
        C{i,"session"} = 3;
    end
end
%%
T3 = [T2 C];
%%
T3.judge = T3.Last_key_press == T3.self_key
%%
filename = "Metrics/MetricsCsv/" + no + ".csv"
writetable(T3, filename)
%%

for i = 55:55
no = i;
filename = "Metrics/MetricsCsv/" +  no + ".csv";
T = readtable(filename);
T2 = T(:,{'No','session','condition','percent','self_key','judge','Duration_of_interval','sex'});
T2.Properties.VariableNames{'Duration_of_interval'} = 'RT';
T2 = movevars(T2,'sex','After',"No");
%J = [J; T2];
w_filename = "Metrics/eachCsv/" + no + "_each.csv";
writetable(T2,w_filename);
end
