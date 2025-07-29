% 读取CSV文件
data = readtable('psychometric_mean_3sd.csv');

% 为每个 'condition' 类型创建一个单独的表格
data_u1 = data(strcmp(data.condition, 'u1'), :);
data_f = data(strcmp(data.condition, 'f'), :);
data_u2 = data(strcmp(data.condition, 'u2'), :);

% 确保所有表格行数相同，这可能需要一些数据清洗
% 比如，如果某个 'condition' 下的数据行数较少，可以考虑删除多余的行
% 这里假设所有 'condition' 下的行数相同

% 创建新的表格
newData = table;
newData.No = data_u1.No; % 假设每个 'condition' 类型下的 'No' 都是一样的
newData.u1 = data_u1.RT_mean;
newData.f = data_f.RT_mean;
newData.u2 = data_u2.RT_mean;

% 保存新的CSV文件
writetable(newData, 'RT_mean_3sd_T.csv');
%%
% 读取先前创建的CSV文件
data = readtable('RT_mean_3sd_T.csv');

% 分离出 No 为单数的行
data_odd = data(mod(data.No, 2) == 1, :);

% 分离出 No 为双数的行
data_even = data(mod(data.No, 2) == 0, :);

% 调整列的顺序
% 对于 No 为单数的数据，顺序是 u1, f, u2
% 对于 No 为双数的数据，顺序是 f, u1, u2
data_odd = data_odd(:, {'No', 'u1', 'f', 'u2'});
data_even = data_even(:, {'No', 'f', 'u1', 'u2'});

% 保存新的CSV文件
writetable(data_odd, 'RT_mean_3sd_T_Odd.csv');
writetable(data_even, 'RT_mean_3sd_T_Even.csv');
%%
% 读取数据
data_odd = readtable('psychometric_mean_3sd_T_Odd.csv');
data_even = readtable('psychometric_mean_3sd_T_Even.csv');

% 绘制并保存 No 为单数的数据折线图及汇总图
unique_nos_odd = unique(data_odd.No);
figure;  % 创建汇总图表 (u1->f->u2)
hold on;
legendInfo_odd = strings(length(unique_nos_odd), 1);  % 用于存储图例信息
for i = 1:length(unique_nos_odd)
    no = unique_nos_odd(i);
    subset = data_odd(data_odd.No == no, :);
    RT_means = [subset.u1, subset.f, subset.u2];
    plot(1:3, RT_means, '-o');
    legendInfo_odd(i) = ['No ' num2str(no)];  % 添加图例信息
    saveas(gcf, ['RT_mean_No_' num2str(no) '_u1->f->u2.png']);
end
title('Summary RT_mean (u1->f->u2)', 'FontWeight', 'bold');
xlabel('Condition', 'FontWeight', 'bold');
ylabel('RT_mean', 'FontWeight', 'bold');
ylim([200 1200]);
xlim([0.5 3.5]);
set(gca, 'xtick', 1:3, 'xticklabel', {'u1', 'f', 'u2'}, ...
    'FontSize', 16, 'FontWeight', 'bold', 'LineWidth', 2, 'TickDir', 'out');
legend(legendInfo_odd, 'Location', 'eastoutside');
grid on;
hold off;
saveas(gcf, 'RT_mean_Summary_u1->f->u2.png');

% 绘制并保存 No 为双数的数据折线图及汇总图
unique_nos_even = unique(data_even.No);
figure;  % 创建汇总图表 (f->u1->u2)
hold on;
legendInfo_even = strings(length(unique_nos_even), 1);  % 用于存储图例信息
for i = 1:length(unique_nos_even)
    no = unique_nos_even(i);
    subset = data_even(data_even.No == no, :);
    RT_means = [subset.f, subset.u1, subset.u2];
    plot(1:3, RT_means, '-o');
    legendInfo_even(i) = ['No ' num2str(no)];  % 添加图例信息
    saveas(gcf, ['RT_mean_No_' num2str(no) '_f->u1->u2.png']);
end
title('Summary RT_mean (f->u1->u2)', 'FontWeight', 'bold');
xlabel('Condition', 'FontWeight', 'bold');
ylabel('RT_mean', 'FontWeight', 'bold');
ylim([200 1200]);
xlim([0.5 3.5]);
set(gca, 'xtick', 1:3, 'xticklabel', {'f', 'u1', 'u2'}, ...
    'FontSize', 16, 'FontWeight', 'bold', 'LineWidth', 2, 'TickDir', 'out');
legend(legendInfo_even, 'Location', 'eastoutside');
grid on;
hold off;
saveas(gcf, 'RT_mean_Summary_f->u1->u2.png');