function plot_clusters(devices, clusters, fog_node, area_size)
% PLOT_CLUSTERS  Visualize cluster formation with CHs and members.
%   plot_clusters(devices, clusters, fog_node, 200)
%
%   Each cluster is shown in a distinct color. CHs are large filled stars.
%   Lines connect members to their CH. Fog node shown as red diamond.

    if nargin < 4, area_size = 200; end

    figure('Name', 'Cluster Formation', 'Position', [100 100 900 750]);
    hold on; grid on;

    num_clusters = length(clusters);

    % Generate distinct colors for clusters
    if num_clusters <= 10
        cmap = lines(num_clusters);
    else
        cmap = hsv(num_clusters);
    end

    % Plot each cluster
    for ci = 1:num_clusters
        ch_idx = clusters(ci).head_index;
        members = clusters(ci).member_indices;
        color = cmap(ci, :);

        % Plot members
        if ~isempty(members)
            mx = [devices(members).x];
            my = [devices(members).y];
            scatter(mx, my, 20, color, 'o', 'filled', 'MarkerEdgeColor', 'none', ...
                    'MarkerFaceAlpha', 0.6);

            % Lines from members to CH
            for mi = 1:length(members)
                plot([devices(members(mi)).x, devices(ch_idx).x], ...
                     [devices(members(mi)).y, devices(ch_idx).y], ...
                     '-', 'Color', [color 0.15], 'LineWidth', 0.5);
            end
        end

        % Plot CH as star
        scatter(devices(ch_idx).x, devices(ch_idx).y, 150, color, 'p', 'filled', ...
                'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    end

    % Plot fog node
    scatter(fog_node.x, fog_node.y, 400, 'r', 'd', 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 2);

    % Lines from CHs to fog node
    for ci = 1:num_clusters
        ch_idx = clusters(ci).head_index;
        plot([devices(ch_idx).x, fog_node.x], ...
             [devices(ch_idx).y, fog_node.y], ...
             '--', 'Color', [0.8 0 0 0.3], 'LineWidth', 1);
    end

    xlabel('X Position (m)', 'FontSize', 12);
    ylabel('Y Position (m)', 'FontSize', 12);
    title(sprintf('LEACH-SEP Cluster Formation (%d clusters, %d nodes)', ...
          num_clusters, length(devices)), 'FontSize', 14);
    xlim([0 area_size]); ylim([0 area_size]);

    % Custom legend
    h1 = scatter(nan, nan, 20, 'b', 'o', 'filled');
    h2 = scatter(nan, nan, 150, 'b', 'p', 'filled', 'MarkerEdgeColor', 'k');
    h3 = scatter(nan, nan, 400, 'r', 'd', 'filled', 'MarkerEdgeColor', 'k');
    legend([h1 h2 h3], {'Member Node', 'Cluster Head', 'Fog Node'}, ...
           'Location', 'eastoutside', 'FontSize', 10);
    hold off;

    saveas(gcf, fullfile('figures', 'cluster_formation.png'));
    fprintf('[VIZ] Cluster formation plot saved to figures/cluster_formation.png\n');
end
