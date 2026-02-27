function [devices, round_stats] = simulate_communication_round(devices, clusters, fog_node, round_num, data_bytes)
% SIMULATE_COMMUNICATION_ROUND  Simulate one round of cluster-based communication.
%   [devices, round_stats] = simulate_communication_round(devices, clusters, fog_node, round, data_bytes)
%
%   Communication flow per round:
%     1. Member nodes -> Cluster Head (intra-cluster data aggregation)
%     2. Cluster Head aggregates data
%     3. Cluster Head -> Fog Node (aggregated data forwarded)
%
%   Energy is consumed at each step using the first-order radio model.
%
%   Inputs:
%     devices    - struct array with current energy states
%     clusters   - cluster struct from leach_sep_clustering()
%     fog_node   - fog node struct with .x, .y
%     round_num  - current round
%     data_bytes - bytes per node per round (default: 128)
%
%   Returns:
%     devices     - updated residual energies
%     round_stats - struct with round-level metrics

    if nargin < 5, data_bytes = 128; end

    % Aggregation energy cost at CH (data fusion)
    E_DA = 5e-9;  % 5 nJ/bit/signal (data aggregation energy)

    total_tx_energy = 0;
    total_rx_energy = 0;
    total_da_energy = 0;
    total_packets = 0;
    failed_packets = 0;
    dead_nodes_before = sum([devices.residual_energy] <= 0);

    for ci = 1:length(clusters)
        ch_idx = clusters(ci).head_index;

        % Skip if CH is dead
        if devices(ch_idx).residual_energy <= 0
            continue;
        end

        members = clusters(ci).member_indices;
        received_count = 0;

        % --- Step 1: Members transmit to CH ---
        for mi = 1:length(members)
            m_idx = members(mi);
            if devices(m_idx).residual_energy <= 0
                continue;
            end

            [e_cost, success] = communicate(devices(m_idx), devices(ch_idx), data_bytes);
            total_packets = total_packets + 1;

            if success
                % Deduct energy from sender and receiver
                devices(m_idx).residual_energy = devices(m_idx).residual_energy - e_cost(1);
                devices(ch_idx).residual_energy = devices(ch_idx).residual_energy - e_cost(2);
                total_tx_energy = total_tx_energy + e_cost(1);
                total_rx_energy = total_rx_energy + e_cost(2);
                received_count = received_count + 1;
            else
                failed_packets = failed_packets + 1;
            end
        end

        % --- Step 2: CH performs data aggregation ---
        if received_count > 0
            da_energy = E_DA * data_bytes * 8 * received_count;
            devices(ch_idx).residual_energy = devices(ch_idx).residual_energy - da_energy;
            total_da_energy = total_da_energy + da_energy;
        end

        % --- Step 3: CH transmits aggregated data to Fog Node ---
        agg_bytes = data_bytes * 2;  % Aggregated packet (compressed)
        dist_to_fog = clusters(ci).dist_to_fog;
        [e_cost, success] = communicate(devices(ch_idx), fog_node, agg_bytes, dist_to_fog);
        total_packets = total_packets + 1;

        if success
            devices(ch_idx).residual_energy = devices(ch_idx).residual_energy - e_cost(1);
            total_tx_energy = total_tx_energy + e_cost(1);
        else
            failed_packets = failed_packets + 1;
        end
    end

    dead_nodes_after = sum([devices.residual_energy] <= 0);

    % --- Round statistics ---
    round_stats.round = round_num;
    round_stats.alive_nodes = sum([devices.residual_energy] > 0);
    round_stats.dead_nodes = dead_nodes_after;
    round_stats.new_dead = dead_nodes_after - dead_nodes_before;
    round_stats.total_energy_consumed = total_tx_energy + total_rx_energy + total_da_energy;
    round_stats.avg_residual_energy = mean([devices([devices.residual_energy]>0).residual_energy]);
    round_stats.total_packets = total_packets;
    round_stats.failed_packets = failed_packets;
    round_stats.packet_delivery_ratio = (total_packets - failed_packets) / max(total_packets, 1);
    round_stats.num_clusters = length(clusters);
end
