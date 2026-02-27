function plot_communication_overhead(results)
% PLOT_COMMUNICATION_OVERHEAD  Grouped bar chart: bytes per scheme.
%   plot_communication_overhead(results)

    figure('Name', 'Communication Overhead', 'Position', [100 100 800 500]);

    data = [results.registration_bytes; results.authentication_bytes; results.totp_bytes]';
    b = bar(data, 'grouped');
    b(1).FaceColor = [0 0.45 0.74];
    b(2).FaceColor = [0.85 0.33 0.1];
    b(3).FaceColor = [0.47 0.67 0.19];

    set(gca, 'XTickLabel', results.schemes, 'FontSize', 11);
    ylabel('Bytes Exchanged', 'FontSize', 13);
    title('Communication Overhead Comparison', 'FontSize', 14);
    legend({'Registration', 'Authentication', 'TOTP'}, 'Location', 'northwest', 'FontSize', 11);
    grid on;

    % Add value labels on bars
    for i = 1:length(b)
        xtips = b(i).XEndPoints;
        ytips = b(i).YEndPoints;
        labels = string(b(i).YData);
        text(xtips, ytips, labels, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 9);
    end

    saveas(gcf, fullfile('figures', 'comm_overhead.png'));
    fprintf('[VIZ] Communication overhead plot saved to figures/comm_overhead.png\n');
end
