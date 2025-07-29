% 定义文件名 - 假设我们已经通过R导出了相应的CSV文件
files = {'result_Th.csv'};

% 创建单个figure
figure('Position', [100, 100, 1000, 800]);
hold on;

% 读取数据
data = readtable(files{1});

% 过滤掉应排除的参与者ID
% missing_ids = [19, 20, 38, 42, 55, 56, 57];
% data = data(~ismember(data.No, missing_ids), :);

% 修改x轴位置，考虑三个条件：
% U→F组：u1, f, u2 (位置1-3, 5-7)
% F→U组：f, u1, u2 (位置9-11, 13-15)
x_positions = {[1, 2, 3], [9, 10, 11]};      % Female: U→F组和F→U组
x_positions_m = {[5, 6, 7], [13, 14, 15]};   % Male: U→F组和F→U组

% 处理数据
orders = {'uf', 'fu'};  % 对应U→F和F→U两种顺序
% 根据不同的顺序定义条件序列
conditions_uf = {'u1', 'f', 'u2'};  % U→F顺序：u1, f, u2
conditions_fu = {'f', 'u1', 'u2'};  % F→U顺序：f, u1, u2

% 先处理女性数据，再处理男性数据
for k = 1:length(orders)
    for is_male = 0:1
        % 设置当前x轴位置
        if is_male
            current_x = x_positions_m{k};
        else
            current_x = x_positions{k};
        end
        
        % 设置性别过滤器
        if is_male
            gender_filter = strcmp(data.gender, 'm');
        else
            gender_filter = strcmp(data.gender, 'f');
        end
        
        % 设置顺序过滤器
        order_filter = strcmp(data.order, orders{k});
        
        % 根据当前顺序选择条件序列
        if strcmp(orders{k}, 'uf')
            current_conditions = conditions_uf;
        else
            current_conditions = conditions_fu;
        end
        
        % 计算平均值和标准误
        mean_values = zeros(1, 3);
        sem_values = zeros(1, 3);
        for i = 1:length(current_conditions)
            idx = strcmp(data.condition, current_conditions{i}) & gender_filter & order_filter;
            current_data = data.Width(idx);
            mean_values(i) = mean(current_data, 'omitnan');
            sem_values(i) = std(current_data, 'omitnan')/sqrt(sum(~isnan(current_data)));
        end
        
        % 绘制灰色柱状图
        b = bar(current_x, mean_values, 0.5, 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none');
        
        % 添加误差棒
        for i = 1:length(current_x)
            line([current_x(i) current_x(i)], ...
                [mean_values(i)-sem_values(i) mean_values(i)+sem_values(i)], ...
                'Color', 'k', 'LineWidth', 1.5);
            
            line([current_x(i)-0.1 current_x(i)+0.1], ...
                [mean_values(i)+sem_values(i) mean_values(i)+sem_values(i)], ...
                'Color', 'k', 'LineWidth', 1.5);
            
            line([current_x(i)-0.1 current_x(i)+0.1], ...
                [mean_values(i)-sem_values(i) mean_values(i)-sem_values(i)], ...
                'Color', 'k', 'LineWidth', 1.5);
        end
        
        % 获取当前性别和顺序的唯一No值
        unique_No_current = unique(data.No(gender_filter & order_filter));
        
        % 绘制个体数据
        for i = 1:numel(unique_No_current)
            cur_idx = data.No == unique_No_current(i) & gender_filter & order_filter;
            cur_condition = data.condition(cur_idx);
            cur_width = data.Width(cur_idx);
            
            % 准备x坐标 - 根据当前顺序映射到正确位置
            cur_x = zeros(size(cur_condition));
            for j = 1:length(cur_condition)
                condition_pos = find(strcmp(current_conditions, cur_condition{j}));
                if ~isempty(condition_pos)
                    cur_x(j) = current_x(condition_pos);
                end
            end
            
            % 连接同一个参与者的点
            if length(cur_width) >= 2
                % 按照当前条件顺序排列坐标
                [cur_x_sorted, sort_idx] = sort(cur_x);
                cur_width_sorted = cur_width(sort_idx);
                
                % 绘制连线
                line(cur_x_sorted, cur_width_sorted, 'Color', 'k', 'Linewidth', 1);
            end
            
            % 绘制各个条件的点
            for j = 1:length(cur_x)
                if strcmp(cur_condition{j}, 'u1')
                    % u1条件用橙色圆圈
                    plot(cur_x(j), cur_width(j), 'o', 'Color', [0.93, 0.63, 0.13], ...
                        'MarkerSize', 11, 'Linewidth', 1, 'MarkerFaceColor', 'none');
                elseif strcmp(cur_condition{j}, 'f')
                    % f条件用紫色圆圈
                    plot(cur_x(j), cur_width(j), 'o', 'Color', [0.49, 0.18, 0.56], ...
                        'MarkerSize', 11, 'Linewidth', 1, 'MarkerFaceColor', 'none');
                elseif strcmp(cur_condition{j}, 'u2')
                    % u2条件用蓝色圆圈
                    plot(cur_x(j), cur_width(j), 'o', 'Color', [0.0, 0.45, 0.74], ...
                        'MarkerSize', 11, 'Linewidth', 1, 'MarkerFaceColor', 'none');
                end
            end
        end
    end
end

% 设置图表属性
ylabel('Width', 'FontSize', 40, 'FontWeight', 'bold');
set(gca, 'FontSize', 20, 'FontWeight', 'bold');
ax = gca;
ax.FontWeight = 'bold';
ax.LineWidth = 2;
ax.TickDir = 'out';
xlim([0 16]);
ylim([0 70]);

% 调整图表位置
set(gca, 'Position', [0.13 0.2 0.775 0.65]);

% 设置x轴刻度和标签 - 注意F→U组的标签顺序已改为f, u1, u2
xticks([1 2 3 5 6 7 9 10 11 13 14 15]);
xticklabels({'u1', 'f', 'u2', 'u1', 'f', 'u2', 'f', 'u1', 'u2', 'f', 'u1', 'u2'});

% 添加组标签
text(2, -10, 'Female', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(6, -10, 'Male', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(4, -15, 'U→F', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(10, -10, 'Female', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(14, -10, 'Male', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(12, -15, 'F→U', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% 添加图例
legend_h = zeros(3,1);
legend_h(1) = plot(NaN, NaN, 'o', 'Color', [0.93, 0.63, 0.13], 'MarkerSize', 11, 'Linewidth', 1, 'MarkerFaceColor', 'none');
legend_h(2) = plot(NaN, NaN, 'o', 'Color', [0.49, 0.18, 0.56], 'MarkerSize', 11, 'Linewidth', 1, 'MarkerFaceColor', 'none');
legend_h(3) = plot(NaN, NaN, 'o', 'Color', [0.0, 0.45, 0.74], 'MarkerSize', 11, 'Linewidth', 1, 'MarkerFaceColor', 'none');
legend(legend_h, {'u1', 'f', 'u2'}, 'Location', 'northeast', 'FontSize', 16);

% 保存图像
saveas(gcf, 'width_visualization_three_cond_modified.png');