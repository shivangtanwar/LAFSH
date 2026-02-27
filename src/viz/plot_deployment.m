function plot_deployment(devices, fog_nodes, area_size)
% PLOT_DEPLOYMENT  Visualize deployed nodes colored by device type.
%   plot_deployment(devices, fog_nodes, 200)
%
%   Shows all IoT nodes as colored markers and fog nodes as large red stars.

    if nargin < 3, area_size = 200; end
    if nargin < 2, fog_nodes = []; end

    figure('Name', 'Node Deployment', 'Position', [100 100 800 700]);
    hold on; grid on;

    types = {'light', 'thermostat', 'camera', 'lock', 'motion_sensor', 'smart_plug'};
    colors = [1 0.8 0; 0 0.7 0.3; 0.8 0 0; 0 0.4 0.8; 0.6 0.3 0.8; 0.5 0.5 0.5];
    markers = {'o', 's', '^', 'd', 'v', 'p'};
    marker_sizes = [30, 40, 50, 40, 25, 30];

    for t = 1:length(types)
        idx = arrayfun(@(d) strcmp(d.type, types{t}), devices);
        if any(idx)
            scatter([devices(idx).x], [devices(idx).y], marker_sizes(t), ...
                    colors(t,:), markers{t}, 'filled', 'MarkerEdgeColor', 'k', ...
                    'LineWidth', 0.5);
        end
    end

    % Plot fog nodes
    if ~isempty(fog_nodes)
        for f = 1:length(fog_nodes)
            scatter(fog_nodes(f).x, fog_nodes(f).y, 300, 'r', 'p', 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 2);
        end
        legend_entries = [types, {'Fog Node'}];
    else
        legend_entries = types;
    end

    legend(legend_entries, 'Location', 'eastoutside', 'FontSize', 9);
    xlabel('X Position (m)', 'FontSize', 12);
    ylabel('Y Position (m)', 'FontSize', 12);
    title(sprintf('Heterogeneous IoT Node Deployment (%d nodes)', length(devices)), 'FontSize', 14);
    xlim([0 area_size]); ylim([0 area_size]);
    hold off;

    saveas(gcf, fullfile('figures', 'node_deployment.png'));
    fprintf('[VIZ] Node deployment plot saved to figures/node_deployment.png\n');
end
