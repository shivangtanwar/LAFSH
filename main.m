% MAIN  Entry point for the Fog Computing Smart Home Simulation.
%
% Open this file first in MATLAB Online, then run it.
% Presents a menu to choose between demo, evaluation, and analysis.

clc;
fprintf('================================================================\n');
fprintf('  LAFSH: Lightweight Authentication for Fog-based Smart Homes\n');
fprintf('  Fog Computing Course Project (CSE4702)\n');
fprintf('================================================================\n\n');

% Add source paths
addpath(genpath('src'));

% Create output directories
if ~exist('results', 'dir'), mkdir('results'); end
if ~exist('figures', 'dir'), mkdir('figures'); end

fprintf('Select an option:\n\n');
fprintf('  1. Run Interactive Demo (deployment + clustering + auth + RBAC)\n');
fprintf('  2. Run Performance Evaluation (latency, overhead, energy plots)\n');
fprintf('  3. Run Security Analysis (6 attack scenarios)\n');
fprintf('  4. Display RBAC Permission Matrix\n');
fprintf('  5. Quick Test (deploy 300 nodes + cluster + visualize)\n');
fprintf('  0. Exit\n\n');

choice = input('Enter choice [1-5]: ');

switch choice
    case 1
        run('run_demo');
    case 2
        run('run_evaluation');
    case 3
        run('run_security_analysis');
    case 4
        rbac = init_rbac();
        plot_rbac_heatmap(rbac);
        fprintf('\nPermission Matrix:\n');
        disp(array2table(rbac.permission_matrix, ...
            'VariableNames', rbac.operations, ...
            'RowNames', rbac.roles));
    case 5
        fprintf('\n--- Quick Test: 300 Nodes ---\n\n');
        cloud = init_cloud();
        rbac = init_rbac();
        fog = init_fog_node('FOG_TEST', cloud, rbac, 100, 100);
        devices = deploy_nodes(300, 200);
        plot_deployment(devices, fog, 200);
        [devices, clusters] = leach_sep_clustering(devices, fog, 1);
        plot_clusters(devices, clusters, fog, 200);
        fprintf('\nQuick test complete! Check the generated figures.\n');
    case 0
        fprintf('Goodbye!\n');
    otherwise
        fprintf('Invalid choice. Please run main.m again.\n');
end
