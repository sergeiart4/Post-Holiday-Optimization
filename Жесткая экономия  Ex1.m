%% Эксперимент 1: Жесткая экономия
clear; clc; close all;

%% ПАРАМЕТРЫ
t = 0:0.5:30;       % дни с шагом 0.5 дня
B0 = -50;           % начальный долг
Income = 30;        % ежедневный доход
Spend_holiday = 45; % праздничные траты
Spend_min = 15;     % минимальные траты
E0 = 0.2;           % начальная энергия
k_rec = 0.08;       % коэффициент восстановления
k_stress = 0.15;    % чувствительность к ограничениям

%% СЦЕНАРИЙ: ЖЕСТКАЯ ЭКОНОМИЯ
Spend = Spend_min * ones(size(t)); % Постоянные минимальные траты

%% РАСЧЁТ
% Бюджет (линейная функция)
B = B0 + (Income - Spend_min) * t;

% Энергия (дискретное интегрирование)
E = zeros(size(t));
E(1) = E0;

for i = 2:length(t)
    % Депривация (снижение трат относительно праздников)
    deprivation = Spend_holiday - Spend_min;
    
    % Стресс от депривации (экспоненциально затухает)
    stress_penalty = k_stress * deprivation * exp(-0.05 * t(i));
    
    % Влияние долга (появляется только при отрицательном бюджете)
    if B(i) < 0
        debt_effect = abs(B(i)) / 200;
    else
        debt_effect = 0;
    end
    
    % Изменение энергии
    dE = k_rec * (1 - E(i-1)) - stress_penalty - debt_effect;
    
    % Ограничение энергии между 0.05 и 1.0
    E(i) = E(i-1) + dE * (t(i) - t(i-1));
    if E(i) < 0.05
        E(i) = 0.05;
    elseif E(i) > 1.0
        E(i) = 1.0;
    end
end

% Функционал качества J(t) (четвертое измерение)
J = (100 - B).^2 + 0.3 * (1 - E).^2;

%% ВИЗУАЛИЗАЦИЯ
figure('Position', [50, 50, 1200, 400]);

% 1) 3D ФАЗОВАЯ ТРАЕКТОРИЯ (B, E, t)
subplot(1, 3, 1);
hold on; grid on; box on;

% Рисуем траекторию отрезками
for i = 1:length(t)-1
    % Простой цветовой градиент (от синего к красному)
    color_ratio = i / length(t);
    color_vec = [color_ratio, 0, 1-color_ratio];
    
    plot3([B(i), B(i+1)], [E(i), E(i+1)], [t(i), t(i+1)], ...
          'Color', color_vec, 'LineWidth', 2);
end

% Начальная и конечная точки
plot3(B(1), E(1), t(1), 'go', 'MarkerSize', 10, ...
      'MarkerFaceColor', 'g', 'LineWidth', 2);
plot3(B(end), E(end), t(end), 'ro', 'MarkerSize', 10, ...
      'MarkerFaceColor', 'r', 'LineWidth', 2);

% Критические плоскости
[x1, y1] = meshgrid([min(B), max(B)], [0, 1]);
surf(x1, y1, zeros(2), 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', 'b'); % t=0
surf(100*ones(2), y1, [0, 0; 30, 30], 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', 'g'); % B=100
surf(x1, 0.3*ones(2), [0, 0; 30, 30], 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', 'r'); % E=0.3

xlabel('Бюджет B(t)');
ylabel('Энергия E(t)');
zlabel('Время t (дни)');
title('3D: Фазовая траектория');
view(40, 25);

% 2) 4D ВИЗУАЛИЗАЦИЯ (B, E, t как цвет, J как размер)
subplot(1, 3, 2);
hold on; grid on; box on;

% Нормализуем J для размера маркеров (от 10 до 100)
J_min = min(J);
J_max = max(J);
if J_max > J_min
    marker_sizes = 10 + 90 * (J - J_min) / (J_max - J_min);
else
    marker_sizes = 50 * ones(size(J));
end

% Рисуем маркеры с размером по J и цветом по времени
for i = 1:3:length(t)
    color_ratio = i / length(t);
    color_vec = [color_ratio, 0, 1-color_ratio];
    
    plot(B(i), E(i), 'o', 'MarkerSize', marker_sizes(i)/10, ...
         'MarkerFaceColor', color_vec, 'MarkerEdgeColor', 'k', ...
         'LineWidth', 1);
end

% Соединяющая линия
plot(B, E, 'k-', 'LineWidth', 0.5, 'Color', [0.5, 0.5, 0.5]);

% Критические линии
plot([0, 0], [0, 1], 'k--', 'LineWidth', 1);
plot([100, 100], [0, 1], 'g--', 'LineWidth', 1.5);
plot([min(B), max(B)], [0.5, 0.5], 'r--', 'LineWidth', 1);

xlabel('Бюджет B');
ylabel('Энергия E');
title('4D: B,E + Штраф(размер) + Время(цвет)');
axis([min(B) max(B) 0 1]);

% 3) ДИНАМИКА СИСТЕМЫ
subplot(1, 3, 3);
hold on; grid on; box on;

% Бюджет
plot(t, B, 'r-', 'LineWidth', 2.5);
plot(t, zeros(size(t)), 'k--', 'LineWidth', 1);
plot(t, 100*ones(size(t)), 'g--', 'LineWidth', 1.5);

% Энергия
plot(t, E, 'b-', 'LineWidth', 2.5);
plot(t, 0.5*ones(size(t)), 'r--', 'LineWidth', 1);

xlabel('Дни января');
ylabel('Значения');
title('Динамика B(t) и E(t)');
legend('Бюджет', 'Ноль', 'Цель B=100', 'Энергия', 'Крит. уровень E=0.5', ...
       'Location', 'northwest');

%% РЕЗУЛЬТАТЫ
fprintf('=== ЖЁСТКАЯ ЭКОНОМИЯ ===\n');
fprintf('Ежедневный профицит: %.1f (доход %d - траты %d)\n', ...
        Income - Spend_min, Income, Spend_min);
fprintf('К 30 января (t=%.1f):\n', t(end));
fprintf('  Бюджет: B = %.1f (цель: 100.0)\n', B(end));
fprintf('  Энергия: E = %.3f\n', E(end));
fprintf('  Минимальная энергия за период: %.3f\n', min(E));

% Время выхода в положительную зону
idx_positive = find(B > 0, 1);
if ~isempty(idx_positive)
    fprintf('  Бюджет стал положительным на день: %.1f\n', t(idx_positive));
else
    fprintf('  Бюджет остался отрицательным весь период\n');
end

% Время достижения цели
idx_target = find(B >= 100, 1);
if ~isempty(idx_target)
    fprintf('  Цель B>=100 достигнута на день: %.1f\n', t(idx_target));
end

% Анализ рисков
if min(E) < 0.3
    fprintf('⚠️  ВНИМАНИЕ: Энергия опускалась ниже 0.3 (высокий риск срыва)\n');
end

if B(end) >= 100
    if min(E) >= 0.4
        fprintf('✅ ОТЛИЧНО: Цель достигнута, энергия в безопасности\n');
    elseif min(E) >= 0.3
        fprintf('⚖️  ХОРОШО: Цель достигнута, но энергия на пределе\n');
    else
        fprintf('⚠️  РИСК: Цель достигнута, но энергия критически низка\n');
    end
else
    fprintf('❌ Цель по бюджету не достигнута\n');
end