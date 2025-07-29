varTypes = {'int8','string','double','double','double','double'};
varNames = {'No','condition','Threshold','Width','Slope','RT_mean'};
sz = [64 size(varTypes,2)];
H = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
%%
% psychofunction
% すべてのデータを集計するための空のテーブルを初期化
all_H = table(); % この行は現在のコードでは使われていませんが、元のコードにあったので残します。

for j =90:90 % ループは92から92までなので、実質1回だけ実行されます
    no = j;
    % データファイルを読み込み
    T = readtable("C:\顔認知_実験\20240627_test/Metrics/eachOutlier/mean_3sd/" + num2str(no) + "_outliers.csv");

    conditions = ["u1","u2","f"];
    j_conditions = ["unknown1","unknown2","friend"];
    keySet = {0,10,20,30,35,40,45,50,55,60,65,70,80,90,100};
    valueSet = 1:15;
    M = containers.Map(keySet,valueSet); % パーセンテージをインデックスにマッピングするためのMap

    varTypes_C = {'int8','int8','int8'}; % Cテーブルの変数型
    varNames_C = {'u1','u2','f'}; % Cテーブルの変数名
    sz_C = [15 size(varTypes_C,2)]; % Cテーブルのサイズ

    C = table('Size',sz_C,'VariableTypes',varTypes_C,'VariableNames',varNames_C); % Cテーブルを初期化

    % 各パーセンテージと条件での正しい判断の数を集計
    for i = 1:height(T)
        if T{i,"judge"} == 1
            C{M(T{i,"percent"}),T{i,"condition"}} = C{M(T{i,"percent"}),T{i,"condition"}} + 1;
        end
    end
    % C; % この行は表示のためですが、セミコロンがあるので表示されません。

    % Threshold = zeros(3,2); % この行は現在のコードでは使われていません。
    for i = 1:3 % 各条件（u1, u2, f）に対してループ
        D = C{:,conditions(i)}; % 現在の条件のデータを取得
        data = zeros(15,3); % psignifitに渡すデータ形式を準備
        data(:,1) = [0;10;20;30;35;40;45;50;55;60;65;70;80;90;100]; % 刺激強度（パーセンテージ）
        data(:,2) = D; % 正しい判断の数
        data(:,3) = 15; % 試行回数 (各パーセンテージでの試行回数が15回と仮定)

        options = struct;
        options.sigmoidName = 'norm'; % シグモイド関数として正規分布を使用
        options.expType = 'YesNo'; % 実験タイプをYes/Noタスクとして設定
        options.confP = .80; % 信頼区間の確率を設定 (使われていませんが元のコードにあったので残します)
        result = psignifit(data,options); % psignifitを実行

        % result.Fit; % 適合パラメータを表示 (セミコロンがあるので表示されません)

        % 心理曲線図を描画
        figure;
        plotPsych(result);
        title(j_conditions(i)); % タイトルを条件名に設定

        % resultSmall = rmfield(result,{'Posterior','weight'}); % 後方分布と重みを削除 (使われていませんが元のコードにあったので残します)

        % 斜率を計算
        slope = getSlope(result, result.Fit(1)); % 閾値での傾きを計算
        % pse(i,:) = [result.Fit(1) slope]; % この行は現在のコードでは使われていません。

        % 50% 正しい判断の閾値を計算
        threshold = result.Fit(1);

        % 曲線幅を計算 (psignifitのFit(2)が幅に相当)
        width = result.Fit(2);

        % RT_mean (平均反応時間) を計算
        RT_mean = mean(T{strcmp(T.condition, conditions(i)), 'RT'}, 'omitnan');

        % グラフ上にThresholdとWidthの値を表示
        % 表示位置は、グラフの見た目に応じて調整してください。
        % ここでは、グラフの右下あたりに表示するように調整しました。
        % x座標とy座標は、グラフの範囲とデータの分布を考慮して調整する必要があります。
        xLimits = xlim; % 現在のx軸の範囲を取得
        yLimits = ylim; % 現在のy軸の範囲を取得
        % テキストのx座標はx軸の約80%の位置、y座標はy軸の約15%の位置に設定
        textX = xLimits(1) + (xLimits(2) - xLimits(1)) * 0.75;
        textY = yLimits(1) + (yLimits(2) - yLimits(1)) * 0.15;
        text(textX, textY, sprintf('Threhold: %.2f\nWidth: %.2f', threshold, width), ...
             'FontSize', 12, 'Color', 'red', 'HorizontalAlignment', 'left');

        % Hテーブルに結果を格納
        H{(no-1)*3+i, "No"} = no;
        H{(no-1)*3+i,"condition"} = conditions(i);
        H{(no-1)*3+i,"Threshold"} = result.Fit(1);
        H{(no-1)*3+i,"Width"} = width;
        H{(no-1)*3+i,"Slope"} = slope;
        H{(no-1)*3+i, "RT_mean"} = RT_mean;

        % グラフを画像ファイルとして保存
        saveas(gcf, "C:\顔認知_実験\20240627_test/Metrics/pf/mean_3sd/psychometric_function/" + num2str(no) +"_"+ conditions(i) + "_mean_3sd.png");
    end
    H; % 最終的なHテーブルを表示 (セミコロンがあるので表示されません)
end
%%
% 結果テーブルをCSVファイルに書き出し
writetable(H,"C:\顔認知_実験\20240627_test/Metrics/pf/mean_3sd/psychometric_mean_3sd.csv");