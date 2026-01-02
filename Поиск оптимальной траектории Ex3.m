%% Эксперимент 3: Поиск оптимальной траектории
clear; clc; close all;

%% ПАРАМЕТРЫ
t = 0:0.5:30;
B0 = -50; Income = 30; Spend_holiday = 45; Spend_min = 15;
E0 = 0.2; k_rec = 0.08; k_stress = 0.15;
w = 0.3; % Вес энергии в функционале

%% ОПТИМИЗАЦИЯ (перебор по alpha и начальному уровню трат)
alpha_grid = linspace(0.05, 0.5, 20); % Диапазон alpha
Spend_init_grid = linspace(20, 45, 15); % Начальный уровень трат
J_matrix = zeros(length(alpha_grid), length(Spend_init_grid));

% Перебор параметров
for a_idx = 1:length(alpha_grid)
    for s_idx = 1:length(Spend_init_grid)
        alpha = alpha_grid(a_idx);
        Spend_init = Spend_init_grid(s_idx);
        
        % Экспоненциальное снижение к минимуму
        Spend = Spend_min + (Spend_init - Spend_min) * exp(-alpha * t);
        
        % Симуляция
        B = B0 + (Income - Spend_min) * t - ...
            (Spend_init - Spend_min)/alpha .* (1 - exp(-alpha * t));
        E = zeros(size(t)); E(1) = E0;
        for i = 2:length(t)
            depr = max(0, Spend_holiday - Spend(i));
            stress = k_stress * depr;
            debt = (B(i) < 0) * abs(B(i))/200;
            dE = k_rec*(1-E(i-1)) - stress - debt;
            E(i) = max(0.05, min(1, E(i-1) + dE*(t(i)-t(i-1))));
        end
        
        % Функционал качества
        J_matrix(a_idx, s_idx) = sum((100 - B).^2 + w * (1 - E).^2);
    end
end

% Нахождение минимума
[min_J, idx] = min(J_matrix(:));
[a_opt_idx, s_opt_idx] = ind2sub(size(J_matrix), idx);
alpha_opt = alpha_grid(a_opt_idx);
Spend_init_opt = Spend_init_grid(s_opt_idx);

%% РАСЧЁТ ОПТИМАЛЬНОЙ ТРАЕКТОРИИ
Spend_opt = Spend_min + (Spend_init_opt - Spend_min) * exp(-alpha_opt * t);
B_opt = B0 + (Income - Spend_min) * t - ...
        (Spend_init_opt - Spend_min)/alpha_opt .* (1 - exp(-alpha_opt * t));
E_opt = zeros(size(t)); E_opt(1) = E0;
for i = 2:length(t)
    depr = max(0, Spend_holiday - Spend_opt(i));
    stress = k_stress * depr;
    debt = (B_opt(i) < 0) * abs(B_opt(i))/200;
    dE = k_rec*(1-E_opt(i-1)) - stress - debt;
    E_opt(i) = max(0.05, min(1, E_opt(i-1) + dE*(t(i)-t(i-1))));
end
J_opt = (100 - B_opt).^2 + w * (1 - E_opt).^2;

%% 4D ВИЗУАЛИЗАЦИЯ ОПТИМУМА
figure('Position', [50, 50, 1200, 400]);

% 1) Поверхность J(alpha, Spend_init)
subplot(1,3,1);
[X, Y] = meshgrid(Spend_init_grid, alpha_grid);
surf(X, Y, log10(J_matrix), 'EdgeColor', 'none', 'FaceAlpha', 0.8);
hold on; grid on;
plot3(Spend_init_opt, alpha_opt, log10(min_J), 'ro', ...
      'MarkerSize', 12, 'MarkerFaceColor', 'r', 'LineWidth', 2);
xlabel('Начальные траты'); ylabel('alpha'); zlabel('log10(J)');
title('Поверхность функционала J');
colormap(jet); colorbar;
view(-45, 30);

% 2) Оптимальная траектория в 3D (B, E, t)
subplot(1,3,2);
hold on; grid on; box on;

% Цвет по времени
for i = 1:length(t)-1
    color_ratio = i/length(t);
    color_vec = [color_ratio, 0.5-0.3*color_ratio, 1-color_ratio];
    plot3([B_opt(i), B_opt(i+1)], [E_opt(i), E_opt(i+1)], [t(i), t(i+1)], ...
          'Color', color_vec, 'LineWidth', 2.5);
end

plot3(B_opt(1), E_opt(1), t(1), 'go', 'MarkerSize', 10, ...
      'MarkerFaceColor', 'g', 'LineWidth', 2);
plot3(B_opt(end), E_opt(end), t(end), 'ro', 'MarkerSize', 10, ...
      'MarkerFaceColor', 'r', 'LineWidth', 2);

[x_plane, y_plane] = meshgrid([min(B_opt), max(B_opt)], [0, 1]);
surf(100*ones(2), y_plane, [0,0;30,30], 'FaceAlpha', 0.1, ...
     'EdgeColor', 'none', 'FaceColor', 'g');
surf(x_plane, 0.3*ones(2), [0,0;30,30], 'FaceAlpha', 0.1, ...
     'EdgeColor', 'none', 'FaceColor', 'r');

xlabel('Бюджет B(t)'); ylabel('Энергия E(t)'); zlabel('Время t');
title('Оптимальная траектория'); view(40, 25);

% 3) Сравнение стратегий
subplot(1,3,3);
yyaxis left;
plot(t, Spend_opt, 'm-', 'LineWidth', 3);
hold on; grid on;
plot(t, Income*ones(size(t)), 'k--', 'LineWidth', 1.5);
ylim([0, 50]); ylabel('Траты');

yyaxis right;
plot(t, B_opt, 'r-', 'LineWidth', 2);
hold on;
plot(t, E_opt*100, 'b-', 'LineWidth', 2); % Масштабируем E для графика
plot(t, 100*ones(size(t)), 'g--', 'LineWidth', 1.5);
plot(t, 30*ones(size(t)), 'r--', 'LineWidth', 1);
ylabel('Бюджет / Энергия×100');
xlabel('Дни января');
title('Оптимальные: траты, бюджет, энергия');
legend('Траты', 'Доход', 'Бюджет', 'Энергия×100', 'Цель', 'Критич. E=0.3', ...
       'Location', 'northwest');

%% РЕЗУЛЬТАТЫ ОПТИМИЗАЦИИ
fprintf('=== ОПТИМАЛЬНАЯ СТРАТЕГИЯ (w=%.1f) ===\n', w);
fprintf('Оптимальные параметры:\n');
fprintf('  alpha = %.3f\n', alpha_opt);
fprintf('  Начальные траты = %.1f\n', Spend_init_opt);
fprintf('  Конец месяца:\n');
fprintf('    Бюджет: B = %.1f\n', B_opt(end));
fprintf('    Энергия: E = %.3f\n', E_opt(end));
fprintf('    Минимальная энергия: %.3f\n', min(E_opt));
fprintf('    Суммарный штраф J: %.1f\n', sum(J_opt));

idx_target = find(B_opt >= 100, 1);
if ~isempty(idx_target)
    fprintf('  Цель B>=100 достигнута на день: %.1f\n', t(idx_target));
end

if min(E_opt) > 0.3 && B_opt(end) >= 100
    fprintf('🎯 УСПЕХ: Найден сбалансированный оптимум!\n');
    fprintf('   Стратегия: плавное снижение с %.0f до %.0f за %.0f дней\n', ...
            Spend_init_opt, Spend_min, 3/alpha_opt);
end