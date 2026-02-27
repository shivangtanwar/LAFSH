function plot_auth_latency(results)
% PLOT_AUTH_LATENCY  Line plot: authentication latency vs device count.
%   plot_auth_latency(results)  % results from eval_auth_latency()

    figure('Name', 'Authentication Latency', 'Position', [100 100 800 500]);

    errorbar(results.num_devices, results.avg_reg_ms, results.std_reg_ms, ...
             '-s', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', [0 0.45 0.74]);
    hold on;
    errorbar(results.num_devices, results.avg_auth_ms, results.std_auth_ms, ...
             '-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', [0.85 0.33 0.1]);
    hold off;

    grid on;
    xlabel('Number of Devices', 'FontSize', 13);
    ylabel('Average Latency per Device (ms)', 'FontSize', 13);
    title('LAFSH Authentication Latency vs. Device Count', 'FontSize', 14);
    legend({'Registration (Phase 1)', 'Mutual Auth (Phase 2)'}, ...
           'Location', 'northwest', 'FontSize', 11);

    saveas(gcf, fullfile('figures', 'auth_latency.png'));
    fprintf('[VIZ] Auth latency plot saved to figures/auth_latency.png\n');
end
