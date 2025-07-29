% 读取 CSV 文件
data = readtable('/psychometric_mean_3sd.csv');

% 确保"no"列存在
if ismember('No', data.Properties.VariableNames)
    % 分离奇数和偶数行
    oddData = data(mod(data.No, 2) == 1, :);  % "no”列值为奇数的行
    evenData = data(mod(data.No, 2) == 0, :); % "no”列值为偶数的行

    % 将分离后的数据写入新的 CSV 文件
    writetable(oddData, 'psychometric_mean_3sd_odd.csv');
    writetable(evenData, 'psychometric_mean_3sd_even.csv');
else
    error('列 "No" 不存在于数据中。');
end
%%
% 定义文件名
files = {'psychometric_mean_3sd_odd.csv', 'psychometric_mean_3sd_even.csv'};

% 遍历文件
for k = 1:length(files)
    % 读取数据
    data = readtable(files{k});

    % 提取No、condition和RT_mean列的数据
    No = data.No;
    condition = data.condition;
    RT_mean = data.RT_mean; % 更改Width为RT_mean

    % 筛选条件为 'u1' 和 'f' 的数据
    idx = strcmp(condition, 'u1') | strcmp(condition, 'f');
    No = No(idx);
    condition = condition(idx);
    RT_mean = RT_mean(idx); % 应用筛选

    % 获取唯一的No值
    unique_No = unique(No);

    % 初始化画布
    figure;
    hold on;

    % 计算并绘制每个条件的平均值
    mean_values = zeros(1, 2); % 初始化平均值数组，假设有两个条件
    conditions = {'u1', 'f'}; % 定义条件
    for i = 1:length(conditions)
        mean_values(i) = mean(RT_mean(strcmp(condition, conditions{i}))); % 更改Width为RT_mean
    end

    % 在同一图表中绘制平均值的柱状图
    bar_positions = [1, 2]; % 柱状图的位置
    bar(bar_positions, mean_values, 0.5, 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none'); % 绘制柱状图

    % 循环绘制每个人的数据
    for i = 1:numel(unique_No)
        % 提取当前人的数据
        cur_idx = No == unique_No(i);
        cur_condition = condition(cur_idx);
        cur_RT_mean = RT_mean(cur_idx); % 更改Width为RT_mean

        % 将condition转换为数值（u1->1，f->2）
        cur_condition_num = zeros(size(cur_condition));
        for j = 1:length(cur_condition)
            if strcmp(cur_condition{j}, 'u1')
                cur_condition_num(j) = 1;
            elseif strcmp(cur_condition{j}, 'f')
                cur_condition_num(j) = 2;
            end
        end

        % 使用不同颜色绘制点
        for j = 1:length(cur_condition_num)
            if cur_condition_num(j) == 1
                plot(cur_condition_num(j), cur_RT_mean(j), 'o', 'Color', [0.93, 0.63, 0.13], 'MarkerSize', 11, 'Linewidth', 1);
            else
                plot(cur_condition_num(j), cur_RT_mean(j), 'o', 'Color', [0.49, 0.18, 0.56], 'MarkerSize', 11, 'Linewidth', 1);
            end
        end

        % 绘制连线 
        for j = 1:length(cur_condition_num)-1
            line([cur_condition_num(j), cur_condition_num(j+1)], [cur_RT_mean(j), cur_RT_mean(j+1)], 'Color', 'k', 'Linewidth', 1);
        end
    end

    % 设置图表其他属性
    xlabel('Condition', 'FontSize', 40, 'FontWeight', 'bold');
    ylabel('RT', 'FontSize', 40, 'FontWeight', 'bold'); % 更改Width为RT_mean
    xticks([1 2]);
    xticklabels({'u1', 'f'});
    set(gca, 'FontSize', 16, 'FontWeight', 'bold');
    ax = gca;
    ax.FontWeight = 'bold';
    ax.LineWidth = 2;
    ax.TickDir = 'out';
    xlim([0.5 4]); % 优化x轴限制以匹配条件数量
    ylim([0, 1400]);
    yticks(0:200:1400);
    %ylim([min(RT_mean) - 5, max(RT_mean) + 5]); % 自动调整y轴限制以适应RT_mean的范围
    
    % 生成符合要求的文件名
    if contains(files{k}, 'odd')
        filename = 'RT_mean_3sd_odd.png';
    elseif contains(files{k}, 'even')
        filename = 'RT_mean_3sd_even.png';
    else
        % 如果文件名不包含'odd'或'even'，使用默认命名方式
        filename = sprintf('RT_mean_%s.png', files{k});
    end

    % 保存图像
    saveas(gcf, filename);
end