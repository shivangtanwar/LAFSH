% RUN_EVALUATION  Run all performance evaluation experiments and generate plots.
%
% This script runs all eval_* functions, generates all plots, and saves results.
% Expected runtime: ~2-5 minutes depending on trial count.

clc;
fprintf('================================================================\n');
fprintf('  LAFSH Performance Evaluation Suite\n');
fprintf('================================================================\n\n');

addpath(genpath('src'));

% Create output directories
if ~exist('results', 'dir'), mkdir('results'); end
if ~exist('figures', 'dir'), mkdir('figures'); end

%% 1. Authentication Latency
fprintf('\n[1/5] Authentication Latency Evaluation...\n');
latency_results = eval_auth_latency([50, 100, 200, 300, 500], 3);
plot_auth_latency(latency_results);
save(fullfile('results', 'eval_latency_results.mat'), 'latency_results');

%% 2. Communication Overhead
fprintf('\n[2/5] Communication Overhead Evaluation...\n');
overhead_results = eval_communication_overhead();
plot_communication_overhead(overhead_results);
save(fullfile('results', 'eval_overhead_results.mat'), 'overhead_results');

%% 3. Energy Consumption
fprintf('\n[3/5] Energy Consumption Evaluation...\n');
energy_results = eval_energy_estimation([50, 100, 200, 300, 500]);
plot_energy_comparison(energy_results);
save(fullfile('results', 'eval_energy_results.mat'), 'energy_results');

%% 4. Security Comparison
fprintf('\n[4/5] Security Feature Comparison...\n');
security_results = eval_security_comparison();
plot_security_radar(security_results);
save(fullfile('results', 'eval_security_results.mat'), 'security_results');

%% 5. RBAC Heatmap
fprintf('\n[5/5] RBAC Visualization...\n');
rbac = init_rbac();
plot_rbac_heatmap(rbac);

%% Summary
fprintf('\n================================================================\n');
fprintf('  EVALUATION COMPLETE\n');
fprintf('  Results saved to: results/\n');
fprintf('  Figures saved to: figures/\n');
fprintf('================================================================\n');
fprintf('\nGenerated plots:\n');
fprintf('  - figures/auth_latency.png\n');
fprintf('  - figures/comm_overhead.png\n');
fprintf('  - figures/energy_comparison.png\n');
fprintf('  - figures/security_radar.png\n');
fprintf('  - figures/rbac_heatmap.png\n');
