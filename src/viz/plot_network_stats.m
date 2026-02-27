function plot_network_stats(all_round_stats, num_nodes)
% PLOT_NETWORK_STATS  Multi-panel plot of network simulation metrics.
%   plot_network_stats(all_round_stats, 500)
%
%   Panels: Alive nodes, Energy consumed, Packet delivery ratio, Clusters

    num_rounds = length(all_round_stats);
    rounds = 1:num_rounds;

    alive = [all_round_stats.alive_nodes];
    energy = [all_round_stats.total_energy_consumed];
    pdr = [all_round_stats.packet_delivery_ratio];
    clusters = [all_round_stats.num_clusters];

    figure('Name', 'Network Simulation', 'Position', [50 50 1000 800]);

    % Panel 1: Alive nodes over rounds
    subplot(2, 2, 1);
    plot(rounds, alive, '-', 'LineWidth', 2, 'Color', [0 0.45 0.74]);
    xlabel('Round'); ylabel('Alive Nodes');
    title(sprintf('Network Lifetime (%d nodes)', num_nodes));
    grid on;

    % Panel 2: Cumulative energy consumed
    subplot(2, 2, 2);
    plot(rounds, cumsum(energy)*1e6, '-', 'LineWidth', 2, 'Color', [0.85 0.33 0.1]);
    xlabel('Round'); ylabel('Cumulative Energy (\muJ)');
    title('Energy Consumption');
    grid on;

    % Panel 3: Packet delivery ratio
    subplot(2, 2, 3);
    plot(rounds, pdr * 100, '-', 'LineWidth', 2, 'Color', [0.47 0.67 0.19]);
    xlabel('Round'); ylabel('PDR (%)');
    title('Packet Delivery Ratio');
    ylim([0 105]); grid on;

    % Panel 4: Number of clusters per round
    subplot(2, 2, 4);
    plot(rounds, clusters, '-', 'LineWidth', 2, 'Color', [0.6 0.3 0.8]);
    xlabel('Round'); ylabel('Clusters');
    title('Cluster Count per Round');
    grid on;

    sgtitle('LEACH-SEP Network Simulation Results', 'FontSize', 15, 'FontWeight', 'bold');

    saveas(gcf, fullfile('figures', 'network_stats.png'));
    fprintf('[VIZ] Network stats plot saved to figures/network_stats.png\n');
end
