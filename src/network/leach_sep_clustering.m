function [devices, clusters] = leach_sep_clustering(devices, fog_node, round_num, p_opt, area_size)
% LEACH_SEP_CLUSTERING  LEACH-SEP clustering for heterogeneous IoT nodes.
%   [devices, clusters] = leach_sep_clustering(devices, fog_node, round, p_opt)
%
%   Implements the Stable Election Protocol (SEP) which extends LEACH for
%   heterogeneous wireless sensor networks. In SEP, nodes with higher
%   energy have a higher probability of becoming cluster heads.
%
%   The algorithm has two phases:
%     1. SETUP PHASE: Cluster head election based on weighted probability
%     2. STEADY-STATE PHASE: Non-CH nodes join nearest CH, form clusters
%
%   Key SEP enhancement over LEACH:
%     - Nodes are classified as "advanced" (higher energy) or "normal"
%     - Advanced nodes have higher CH election probability
%     - This balances energy consumption across heterogeneous devices
%
%   Inputs:
%     devices   - struct array from deploy_nodes()
%     fog_node  - fog node struct with .x, .y position
%     round_num - current round number (affects election threshold)
%     p_opt     - optimal CH percentage (default: 0.1 = 10%)
%     area_size - deployment area size (default: 200)
%
%   Returns:
%     devices  - updated with cluster_id, is_cluster_head fields
%     clusters - struct array with CH info and member lists

    if nargin < 4, p_opt = 0.1; end
    if nargin < 5, area_size = 200; end

    N = length(devices);

    % --- SEP: Classify nodes as advanced or normal ---
    % Advanced nodes: cameras, locks (higher energy, more critical)
    % Normal nodes: lights, sensors, plugs (lower energy)
    avg_energy = mean([devices.residual_energy]);

    for i = 1:N
        if devices(i).residual_energy > avg_energy
            devices(i).node_class = 1;  % advanced
        else
            devices(i).node_class = 0;  % normal
        end
    end

    num_adv = sum([devices.node_class] == 1);
    num_nrm = N - num_adv;
    alpha = (mean([devices([devices.node_class]==1).residual_energy]) / ...
             mean([devices([devices.node_class]==0).residual_energy])) - 1;
    if isnan(alpha) || isinf(alpha), alpha = 0.5; end

    % --- SEP weighted probabilities ---
    p_nrm = p_opt / (1 + num_adv/N * alpha);
    p_adv = p_nrm * (1 + alpha);

    % --- SETUP PHASE: Cluster Head Election ---
    % Reset cluster assignments
    for i = 1:N
        devices(i).cluster_id = -1;
        devices(i).is_cluster_head = false;
    end

    cluster_heads = [];
    for i = 1:N
        % Skip dead nodes
        if devices(i).residual_energy <= 0
            continue;
        end

        % SEP threshold
        if devices(i).node_class == 1
            p_i = p_adv;
        else
            p_i = p_nrm;
        end

        % LEACH threshold formula: T(n) = p / (1 - p * mod(r, 1/p))
        r_mod = mod(round_num, round(1/p_i));
        if (1 - p_i * r_mod) == 0
            threshold = 1;
        else
            threshold = p_i / (1 - p_i * r_mod);
        end

        % Weighted by residual energy ratio (energy-aware enhancement)
        energy_weight = devices(i).residual_energy / devices(i).initial_energy;
        threshold = threshold * energy_weight;

        % Election
        if rand() < threshold
            devices(i).is_cluster_head = true;
            cluster_heads = [cluster_heads, i]; %#ok<AGROW>
        end
    end

    % Ensure at least a few CHs exist (fallback)
    if isempty(cluster_heads)
        [~, sorted_idx] = sort([devices.residual_energy], 'descend');
        num_fallback = max(3, round(p_opt * N));
        cluster_heads = sorted_idx(1:min(num_fallback, N));
        for ci = 1:length(cluster_heads)
            devices(cluster_heads(ci)).is_cluster_head = true;
        end
    end

    num_ch = length(cluster_heads);

    % Assign cluster IDs to CHs
    for ci = 1:num_ch
        devices(cluster_heads(ci)).cluster_id = ci;
    end

    % --- STEADY-STATE PHASE: Non-CH nodes join nearest CH ---
    ch_x = [devices(cluster_heads).x];
    ch_y = [devices(cluster_heads).y];

    for i = 1:N
        if devices(i).is_cluster_head || devices(i).residual_energy <= 0
            continue;
        end

        % Calculate distance to all CHs
        dists = sqrt((devices(i).x - ch_x).^2 + (devices(i).y - ch_y).^2);
        [~, nearest_ch] = min(dists);
        devices(i).cluster_id = nearest_ch;
    end

    % --- Build cluster structs ---
    clusters = struct();
    for ci = 1:num_ch
        ch_idx = cluster_heads(ci);
        member_indices = find([devices.cluster_id] == ci & ~[devices.is_cluster_head]);

        clusters(ci).id = ci;
        clusters(ci).head_index = ch_idx;
        clusters(ci).head_id = devices(ch_idx).id;
        clusters(ci).head_type = devices(ch_idx).type;
        clusters(ci).head_x = devices(ch_idx).x;
        clusters(ci).head_y = devices(ch_idx).y;
        clusters(ci).member_indices = member_indices;
        clusters(ci).num_members = length(member_indices);

        % Distance from CH to fog node
        clusters(ci).dist_to_fog = sqrt((devices(ch_idx).x - fog_node.x)^2 + ...
                                        (devices(ch_idx).y - fog_node.y)^2);

        % Cluster member types summary
        if ~isempty(member_indices)
            member_types = {devices(member_indices).type};
            unique_types = unique(member_types);
            type_counts = cellfun(@(t) sum(strcmp(member_types, t)), unique_types);
            clusters(ci).type_distribution = containers.Map(unique_types, num2cell(type_counts));
        else
            clusters(ci).type_distribution = containers.Map();
        end
    end

    fprintf('[CLUSTER] Round %d: %d cluster heads elected out of %d nodes\n', ...
            round_num, num_ch, N);
    fprintf('          Advanced nodes: %d | Normal nodes: %d\n', num_adv, num_nrm);
    fprintf('          Avg cluster size: %.1f members\n', ...
            mean([clusters.num_members]));
end
