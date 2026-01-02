%% Постпраздничная модель: сценарий "Продолжаем гулять"
clear; clc; close all;

%% ПАРАМЕТРЫ
t = 0:0.5:30;       % дни с шагом 0.5 (для гладкости)
B0 = -50;           % начальный долг
Income = 30;        % ежедневный доход
Spend = 45;         % постоянные траты
E0 = 0.2;           % начальная энергия
k_rec = 0.08;
k_stress = 0.12;

%% РАСЧЁТ
% Бюджет (точное решение)
B = B0 + (Income - Spend)*t;

% Энергия (численное интегрирование)
E = zeros(size(t));
E(1) = E0;
for i = 2:length(t)
    debt_penalty = max(0, -B(i)/80);  % штраф за долги
    dE = k_rec*(1-E(i-1)) - k_stress*debt_penalty;
    E(i) = max(0.05, min(1, E(i-1) + dE*(t(i)-t(i-1))));
end

%% 3D ВИЗУАЛИЗАЦИЯ
figure('Position', [100 100 900 400]);

% 3D фазовая траектория
subplot(1,2,1);
hold on; grid on; box on;
plot3(B, E, t, 'b-', 'LineWidth', 2.5);
scatter3(B(1), E(1), t(1), 120, 'g', 'filled', 'MarkerEdgeColor', 'k');
scatter3(B(end), E(end), t(end), 120, 'r', 'filled', 'MarkerEdgeColor', 'k');

% Цветовая градиентная линия по времени
cmap = parula(length(t));
for i = 1:length(t)-1
    plot3(B(i:i+1), E(i:i+1), t(i:i+1), ...
          'Color', cmap(i,:), 'LineWidth', 2);
end

% Плоскости
[X,Y] = meshgrid(linspace(min(B), max(B), 10), linspace(0,1,10));
surf(X, Y, zeros(size(X)), 'FaceAlpha', 0.1, 'EdgeColor', 'none');
surf(100*ones(size(X)), Y, X*0, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', 'g');

xlabel('Бюджет B(t)', 'FontWeight', 'bold');
ylabel('Энергия E(t)', 'FontWeight', 'bold');
zlabel('Время t (дни)', 'FontWeight', 'bold');
title('3D фазовая траектория', 'FontSize', 12);
view(45, 25);
colormap(parula);
colorbar('Ticks', [0 1], 'TickLabels', {'t=0', 't=30'});

%% ПРОЕКЦИИ
subplot(2,2,2);
plot(t, B, 'r-', 'LineWidth', 2); grid on;
yline(0, 'k--'); yline(100, 'g--', 'B_{target}');
xlabel('Дни'); ylabel('Бюджет');
title('Проекция: B(t) vs t');

subplot(2,2,4);
plot(t, E, 'b-', 'LineWidth', 2); grid on;
yline(0.5, 'r--', 'Критич. уровень');
xlabel('Дни'); ylabel('Энергия');
title('Проекция: E(t) vs t');

%% ВЫВОДЫ
fprintf('=== БАЗОВЫЙ СЦЕНАРИЙ ===\n');
fprintf('Ежедневный дефицит: %.1f\n', Income - Spend);
fprintf('К 30 января:\n');
fprintf('  Бюджет: B = %.1f (цель: %.1f)\n', B(end), 100);
fprintf('  Энергия: E = %.2f\n', E(end));
if B(end) < 0
    fprintf('❗ Состояние: ДОЛГ + ВЫГОРАНИЕ\n');
elseif E(end) < 0.3
    fprintf('❗ Состояние: Банкротство избежали, но силы на нуле\n');
end