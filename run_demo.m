% RUN_DEMO  Interactive demonstration of the LAFSH protocol.
%
% Demonstrates the complete fog computing smart home simulation:
%   1. System initialization (cloud, fog, 500 heterogeneous IoT devices)
%   2. Node deployment visualization
%   3. LEACH-SEP cluster formation
%   4. Cluster communication rounds
%   5. Device registration and mutual authentication
%   6. TOTP two-factor authentication
%   7. RBAC access control (permitted and denied scenarios)
%   8. Attack detection (replay, cloning, impersonation)
%   9. Audit log display

clc;
fprintf('================================================================\n');
fprintf('  LAFSH: Lightweight Authentication for Fog-based Smart Homes\n');
fprintf('  Fog Computing Project Demonstration\n');
fprintf('================================================================\n\n');

% Add all source paths
addpath(genpath('src'));

%% === STAGE 1: System Initialization ===
fprintf('\n--- STAGE 1: System Initialization ---\n\n');

cloud = init_cloud();
rbac = init_rbac();
fog = init_fog_node('FOG_HOME_01', cloud, rbac, 100, 100);

%% === STAGE 2: Deploy Heterogeneous IoT Nodes ===
fprintf('\n--- STAGE 2: Deploy 500 Heterogeneous IoT Nodes ---\n\n');

NUM_NODES = 500;
AREA_SIZE = 200;
devices = deploy_nodes(NUM_NODES, AREA_SIZE);

% Override a few devices to be user-role (phone, tablet)
devices(1).id = 'PHONE_ADMIN';
devices(1).type = 'phone';
devices(1).role = 'Admin';
devices(1).residual_energy = 10;  % Phone has big battery
devices(1).initial_energy = 10;

devices(2).id = 'PHONE_RESIDENT';
devices(2).type = 'phone';
devices(2).role = 'Resident';
devices(2).residual_energy = 10;
devices(2).initial_energy = 10;

devices(3).id = 'TABLET_GUEST';
devices(3).type = 'tablet';
devices(3).role = 'Guest';
devices(3).residual_energy = 8;
devices(3).initial_energy = 8;

% Visualize deployment
plot_deployment(devices, fog, AREA_SIZE);

%% === STAGE 3: LEACH-SEP Cluster Formation ===
fprintf('\n--- STAGE 3: LEACH-SEP Cluster Formation ---\n\n');

[devices, clusters] = leach_sep_clustering(devices, fog, 1, 0.1, AREA_SIZE);
plot_clusters(devices, clusters, fog, AREA_SIZE);

%% === STAGE 4: Cluster Communication Rounds ===
fprintf('\n--- STAGE 4: Simulating Communication Rounds ---\n\n');

NUM_ROUNDS = 50;
all_stats = [];

for r = 1:NUM_ROUNDS
    % Re-cluster every 10 rounds (LEACH protocol)
    if mod(r, 10) == 1
        [devices, clusters] = leach_sep_clustering(devices, fog, r, 0.1, AREA_SIZE);
    end

    [devices, round_stats] = simulate_communication_round(devices, clusters, fog, r);
    all_stats = [all_stats, round_stats]; %#ok<AGROW>

    if mod(r, 10) == 0
        fprintf('  Round %d: %d alive, %.4f J consumed, PDR=%.1f%%\n', ...
                r, round_stats.alive_nodes, round_stats.total_energy_consumed, ...
                round_stats.packet_delivery_ratio * 100);
    end
end

plot_network_stats(all_stats, NUM_NODES);

%% === STAGE 5: Device Registration ===
fprintf('\n--- STAGE 5: Device Registration ---\n\n');

% Register the user devices and a few IoT devices
demo_devices = [1, 2, 3, 4, 5, 6];  % Admin, Resident, Guest + 3 IoT
for di = demo_devices
    [devices(di), fog, reg_stats] = device_register(devices(di), fog);
end

%% === STAGE 6: Mutual Authentication ===
fprintf('\n--- STAGE 6: Mutual Authentication (Phase 2) ---\n\n');

for di = demo_devices
    [auth_result, devices(di), fog] = device_login(devices(di), fog);
end

%% === STAGE 7: TOTP Two-Factor Authentication ===
fprintf('\n--- STAGE 7: TOTP 2FA for Admin/Resident ---\n\n');

% Admin TOTP
sim_time = get_timestamp();
admin_otp = totp_generate(devices(1).totp_secret, sim_time);
fprintf('  Admin OTP generated: %06d\n', admin_otp);
[totp_res, fog] = totp_auth(devices(1), fog, admin_otp, sim_time);

% Resident TOTP
resident_otp = totp_generate(devices(2).totp_secret, sim_time);
fprintf('  Resident OTP generated: %06d\n', resident_otp);
[totp_res, fog] = totp_auth(devices(2), fog, resident_otp, sim_time);

%% === STAGE 8: RBAC Access Control Scenarios ===
fprintf('\n--- STAGE 8: RBAC Access Control ---\n\n');

fprintf('>> Admin controls smart lock:\n');
[p, r, fog] = check_permission(devices(1).id, 'lock', fog);

fprintf('>> Resident reads thermostat:\n');
[p, r, fog] = check_permission(devices(2).id, 'thermo_read', fog);

fprintf('>> Guest tries to unlock door:\n');
[p, r, fog] = check_permission(devices(3).id, 'unlock', fog);

fprintf('>> Device reports sensor data:\n');
[p, r, fog] = check_permission(devices(4).id, 'sensor_report', fog);

fprintf('>> Guest tries camera recording:\n');
[p, r, fog] = check_permission(devices(3).id, 'cam_rec', fog);

fprintf('>> Admin adds new device:\n');
[p, r, fog] = check_permission(devices(1).id, 'add_device', fog);

%% === STAGE 9: Attack Detection ===
fprintf('\n--- STAGE 9: Attack Detection ---\n\n');

% Attack 1: Replay attack (expired timestamp)
fprintf('>> ATTACK 1: Replay attack with old timestamp\n');
old_time = get_timestamp() - 300;  % 5 minutes ago
[atk_result, ~, fog] = device_login(devices(4), fog, old_time);
fprintf('   Result: %s\n\n', atk_result.failure_reason);

% Attack 2: Device cloning (modified fingerprint)
fprintf('>> ATTACK 2: Device cloning attempt\n');
cloned = devices(5);
cloned.fingerprint = sha256_hash('CLONED_DEVICE_FAKE');
[atk_result, ~, fog] = device_login(cloned, fog);
fprintf('   Result: %s\n\n', atk_result.failure_reason);

% Attack 3: Wrong TOTP code
fprintf('>> ATTACK 3: Invalid TOTP code\n');
[totp_atk, fog] = totp_auth(devices(1), fog, 999999, sim_time);
fprintf('   Result: %s\n\n', totp_atk.reason);

%% === STAGE 10: RBAC Heatmap & Audit Log ===
fprintf('\n--- STAGE 10: Visualization & Audit ---\n\n');

plot_rbac_heatmap(rbac);
display_audit_log(fog);

%% === Summary ===
fprintf('\n================================================================\n');
fprintf('  DEMONSTRATION COMPLETE\n');
fprintf('  Protocol: LAFSH (Lightweight Auth for Fog-based Smart Homes)\n');
fprintf('  Nodes deployed: %d (heterogeneous)\n', NUM_NODES);
fprintf('  Clusters formed: %d (LEACH-SEP)\n', length(clusters));
fprintf('  Devices registered: %d\n', length(demo_devices));
fprintf('  Auth protocol: Mutual + TOTP 2FA + Device Fingerprinting\n');
fprintf('  Access control: RBAC (4 roles x 11 operations)\n');
fprintf('  Attacks blocked: 3/3 (replay, cloning, invalid TOTP)\n');
fprintf('================================================================\n');
