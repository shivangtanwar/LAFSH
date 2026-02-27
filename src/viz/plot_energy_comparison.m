function plot_energy_comparison(results)
% PLOT_ENERGY_COMPARISON  Bar chart: energy per auth (microjoules).
%   plot_energy_comparison(results)

    figure('Name', 'Energy Comparison', 'Position', [100 100 800 500]);

    schemes = {'LAFSH', 'TLS', 'PKI'};
    per_device = [results.lafsh_per_device, results.tls_per_device, results.pki_per_device];

    % Use log scale since PKI is ~11000x more
    bar_data = per_device;
    b = bar(bar_data);
    b.FaceColor = 'flat';
    b.CData = [0.47 0.67 0.19; 0.85 0.33 0.1; 0.8 0 0];

    set(gca, 'XTickLabel', schemes, 'FontSize', 12, 'YScale', 'log');
    ylabel('Energy per Authentication (\muJ) [log scale]', 'FontSize', 13);
    title('Energy Consumption Comparison', 'FontSize', 14);
    grid on;

    % Add value labels
    for i = 1:length(bar_data)
        text(i, bar_data(i), sprintf('%.1f \x03BCJ', bar_data(i)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
    end

    saveas(gcf, fullfile('figures', 'energy_comparison.png'));
    fprintf('[VIZ] Energy comparison plot saved to figures/energy_comparison.png\n');
end
