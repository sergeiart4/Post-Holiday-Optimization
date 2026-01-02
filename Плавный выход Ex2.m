%% Эксперимент 2: Плавный выход
clear; clc; close all;

%% ПАРАМЕТРЫ
t = 0:0.5:30;
B0 = -50;
Income = 30;
Spend_holiday = 45;
Spend_min = 15;
E0 = 0.2;
k_rec = 0.08;
k_stress = 0.15;
alpha = 0.15; % Параметр скорости снижения трат

%% СЦЕНАРИЙ: ЭКСПОНЕНЦИАЛЬНОЕ СНИЖЕНИЕ
Spend = Spend_min + (Spend_holiday - Spend_min) * exp(-alpha * t);

%% РАСЧЁТ ТРАЕКТОРИЙ
% Бюджет (численное интегрирование)
B = zeros(size(t));
B(1) = B0;
for i = 2:length(t)
    B(i) = B(i-1) + (Income - Spend(i-1)) * (t(i) - t(i-1));
end

% Энергия
E = zeros(size(t));
E(1) = E0;
for i = 2:length(t)
    deprivation = max(0, Spend_holiday - Spend(i));
    stress_penalty = k_stress * deprivation;
    if B(i) < 0
        debt_effect = abs(B(i)) / 200;
    else
        debt_effect = 0;
    end
    dE = k_rec*(1 - E(i-1)) - stress_penalty - debt_effect;
    E(i) = max(0.05, min(1, E(i-1) + dE*(t(i)-t(i-1))));
end

% Функционал качества
J = (100 - B).^2 + 0.3 * (1 - E).^2;

%% 4D ВИЗУАЛИЗАЦИЯ (t, B, E, J)
figure('Position', [50, 50, 1000, 400]);

% 1) Траектория в 3D (B, E, t) + цвет = J
subplot(1,2,1);
hold on; grid on; box on;

% Цвет по значению J
J_norm = (J - min(J)) / (max(J) - min(J));
cmap = jet(64);

for i = 1:length(t)-1
    color_idx = max(1, min(64, round(1 + 63*J_norm(i))));
    color = cmap(color_idx, :);
    
    plot3([B(i), B(i+1)], [E(i), E(i+1)], [t(i), t(i+1)], ...
          'Color', color, 'LineWidth', 2.5);
end

% Начало и конец
plot3(B(1), E(1), t(1), 'go', 'MarkerSize', 10, ...
      'MarkerFaceColor', 'g', 'LineWidth', 2);
plot3(B(end), E(end), t(end), 'ro', 'MarkerSize', 10, ...
      'MarkerFaceColor', 'r', 'LineWidth', 2);

% Критические плоскости
[x_plane, y_plane] = meshgrid([min(B), max(B)], [0, 1]);
surf(x_plane, y_plane, zeros(2), 'FaceAlpha', 0.1, ...
     'EdgeColor', 'none', 'FaceColor', 'b'); % t=0
surf(100*ones(2), y_plane, [0,0;30,30], 'FaceAlpha', 0.1, ...
     'EdgeColor', 'none', 'FaceColor', 'g'); % B=100

xlabel('Бюджет B(t)'); ylabel('Энергия E(t)'); zlabel('Время t');
title('3D траектория: цвет = штраф J');
view(40, 25);
colormap(jet); hc = colorbar; ylabel(hc, 'Штраф J');

% 2) Четырехмерная проекция
subplot(2,4,3);
plot(t, Spend, 'm-', 'LineWidth', 2);
hold on; grid on;
plot(t, Income*ones(size(t)), 'k--', 'LineWidth', 1.5);
xlabel('Дни'); ylabel('Траты');
title('Spend(t)'); legend('Траты', 'Доход');

subplot(2,4,4);
plot(t, B, 'r-', 'LineWidth', 2);
hold on; grid on;
plot(t, 100*ones(size(t)), 'g--', 'LineWidth', 1.5);
xlabel('Дни'); ylabel('Бюджет');
title('B(t)'); ylim([min(B)-20, max(B)+20]);

subplot(2,4,7);
plot(t, E, 'b-', 'LineWidth', 2);
hold on; grid on;
plot(t, 0.5*ones(size(t)), 'r--', 'LineWidth', 1.5);
xlabel('Дни'); ylabel('Энергия');
title('E(t)'); ylim([0, 1]);

subplot(2,4,8);
plot(t, J, 'k-', 'LineWidth', 2);
hold on; grid on;
xlabel('Дни'); ylabel('Штраф');
title('J(t) = (100-B)^2 + 0.3*(1-E)^2');

%% РЕЗУЛЬТАТЫ
fprintf('=== ПЛАВНЫЙ ВЫХОД (alpha=%.2f) ===\n', alpha);
fprintf('Начальные траты: %.1f\n', Spend(1));
fprintf('Траты к концу месяца: %.1f\n', Spend(end));
fprintf('К 30 января:\n');
fprintf('  Бюджет: B = %.1f\n', B(end));
fprintf('  Энергия: E = %.3f\n', E(end));
fprintf('  Суммарный штраф J: %.1f\n', sum(J));
fprintf('  Минимальная энергия: %.3f\n', min(E));

idx_goal = find(B >= 100, 1);
if ~isempty(idx_goal)
    fprintf('  Цель достигнута на день: %.1f\n', t(idx_goal));
end

if B(end) >= 100 && min(E) >= 0.4
    fprintf('✅ ОПТИМАЛЬНЫЙ КОМПРОМИСС\n');
elseif B(end) >= 100
    fprintf('⚖️  ХОРОШО, но энергия на пределе\n');
else
    fprintf('⚠️  Цель не достигнута\n');
end