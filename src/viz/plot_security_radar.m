function plot_security_radar(results)
% PLOT_SECURITY_RADAR  Radar/spider chart of security features.
%   plot_security_radar(results)  % results from eval_security_comparison()

    figure('Name', 'Security Comparison Radar', 'Position', [100 100 700 650]);

    num_features = length(results.features);
    num_schemes = length(results.schemes);

    % Angles for each axis
    angles = linspace(0, 2*pi, num_features+1);
    angles = angles(1:end-1);

    colors = [0 0.45 0.74; 0.85 0.33 0.1; 0.47 0.67 0.19; 0.6 0.3 0.8];

    % Draw radar
    hold on;

    % Draw concentric circles (reference)
    for r = 1:3
        xc = r * cos(linspace(0, 2*pi, 100));
        yc = r * sin(linspace(0, 2*pi, 100));
        plot(xc, yc, ':', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
    end

    % Draw axes
    for a = 1:num_features
        plot([0 3.3*cos(angles(a))], [0 3.3*sin(angles(a))], '-', ...
             'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);
    end

    % Plot each scheme
    legend_handles = [];
    for s = 1:num_schemes
        scores = results.scores(:, s)';
        x = scores .* cos(angles);
        y = scores .* sin(angles);
        x = [x, x(1)]; %#ok<AGROW>
        y = [y, y(1)]; %#ok<AGROW>

        fill(x, y, colors(s,:), 'FaceAlpha', 0.1, 'EdgeColor', colors(s,:), 'LineWidth', 2);
        h = plot(x, y, '-o', 'Color', colors(s,:), 'LineWidth', 2, ...
                'MarkerSize', 6, 'MarkerFaceColor', colors(s,:));
        legend_handles = [legend_handles, h]; %#ok<AGROW>
    end

    % Labels
    label_radius = 3.6;
    for a = 1:num_features
        text(label_radius*cos(angles(a)), label_radius*sin(angles(a)), ...
             results.features{a}, 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold');
    end

    axis equal;
    axis([-4.5 4.5 -4.5 4.5]);
    axis off;
    title('Security Feature Comparison (0=None, 3=Full)', 'FontSize', 14);
    legend(legend_handles, results.schemes, 'Location', 'southoutside', ...
           'Orientation', 'horizontal', 'FontSize', 10);
    hold off;

    saveas(gcf, fullfile('figures', 'security_radar.png'));
    fprintf('[VIZ] Security radar plot saved to figures/security_radar.png\n');
end
