% RUN_SECURITY_ANALYSIS  Demonstrate and verify security properties.
%
% Simulates 6 attack scenarios and verifies LAFSH defeats each one.

clc;
fprintf('================================================================\n');
fprintf('  LAFSH Security Analysis - Attack Scenario Testing\n');
fprintf('================================================================\n\n');

addpath(genpath('src'));

% Setup
cloud = init_cloud();
rbac = init_rbac();
fog = init_fog_node('FOG_SEC', cloud, rbac);
devices = deploy_nodes(10, 100);

% Make device 1 an Admin
devices(1).id = 'SEC_ADMIN';
devices(1).role = 'Admin';

% Register and authenticate device 1
[devices(1), fog, ~] = device_register(devices(1), fog);
[auth_res, devices(1), fog] = device_login(devices(1), fog);
sim_time = get_timestamp();
otp = totp_generate(devices(1).totp_secret, sim_time);
[~, fog] = totp_auth(devices(1), fog, otp, sim_time);

% Register device 2 as normal device
devices(2).id = 'SEC_LOCK';
devices(2).role = 'Device';
[devices(2), fog, ~] = device_register(devices(2), fog);
[~, devices(2), fog] = device_login(devices(2), fog);

passed = 0;
total = 6;

fprintf('\n\n========== ATTACK SCENARIOS ==========\n\n');

%% Attack 1: Replay Attack
fprintf('--- TEST 1: Replay Attack ---\n');
fprintf('Scenario: Attacker captures M1 and replays it 5 minutes later\n');
old_time = get_timestamp() - 300;
[result, ~, fog] = device_login(devices(2), fog, old_time);
if ~result.success && contains(result.failure_reason, 'Timestamp')
    fprintf('RESULT: ATTACK BLOCKED - %s\n', result.failure_reason);
    passed = passed + 1;
else
    fprintf('RESULT: VULNERABILITY - Attack not detected!\n');
end

%% Attack 2: Device Cloning
fprintf('\n--- TEST 2: Device Cloning ---\n');
fprintf('Scenario: Attacker creates clone with different hardware fingerprint\n');
clone = devices(2);
clone.fingerprint = sha256_hash('FAKE_CLONED_HARDWARE');
[result, ~, fog] = device_login(clone, fog);
if ~result.success && contains(result.failure_reason, 'CLONING')
    fprintf('RESULT: ATTACK BLOCKED - %s\n', result.failure_reason);
    passed = passed + 1;
else
    fprintf('RESULT: VULNERABILITY - Attack not detected!\n');
end

%% Attack 3: Impersonation (wrong password)
fprintf('\n--- TEST 3: Impersonation ---\n');
fprintf('Scenario: Attacker tries to login with wrong credentials\n');
impersonator = devices(2);
impersonator.credentials.A_device = sha256_hash('WRONG_SECRET');
[result, ~, fog] = device_login(impersonator, fog);
if ~result.success && contains(result.failure_reason, 'invalid')
    fprintf('RESULT: ATTACK BLOCKED - %s\n', result.failure_reason);
    passed = passed + 1;
else
    fprintf('RESULT: VULNERABILITY - Attack not detected!\n');
end

%% Attack 4: Invalid TOTP
fprintf('\n--- TEST 4: TOTP Brute Force ---\n');
fprintf('Scenario: Attacker guesses random 6-digit TOTP codes\n');
[result, fog] = totp_auth(devices(1), fog, 123456, sim_time);
if ~result.success
    fprintf('RESULT: ATTACK BLOCKED - %s\n', result.reason);
    passed = passed + 1;
else
    fprintf('RESULT: VULNERABILITY - Attack not detected!\n');
end

%% Attack 5: Privilege Escalation
fprintf('\n--- TEST 5: Privilege Escalation ---\n');
fprintf('Scenario: Device-role node tries Admin operation (firmware update)\n');
[permitted, reason, fog] = check_permission(devices(2).id, 'firmware', fog);
if ~permitted
    fprintf('RESULT: ATTACK BLOCKED - %s\n', reason);
    passed = passed + 1;
else
    fprintf('RESULT: VULNERABILITY - Privilege escalation possible!\n');
end

%% Attack 6: Unregistered Device
fprintf('\n--- TEST 6: Unregistered Device Access ---\n');
fprintf('Scenario: Unknown device tries to authenticate\n');
rogue = devices(5);
rogue.id = 'ROGUE_DEVICE';
rogue.registered = true;
rogue.credentials.A_device = sha256_hash('ROGUE');
rogue.credentials.RPW = sha256_hash('ROGUE_RPW');
[result, ~, fog] = device_login(rogue, fog);
if ~result.success
    fprintf('RESULT: ATTACK BLOCKED - %s\n', result.failure_reason);
    passed = passed + 1;
else
    fprintf('RESULT: VULNERABILITY - Rogue device accessed the system!\n');
end

%% Summary
fprintf('\n\n========== SECURITY ANALYSIS SUMMARY ==========\n');
fprintf('Tests passed: %d / %d\n', passed, total);
if passed == total
    fprintf('STATUS: ALL ATTACKS BLOCKED SUCCESSFULLY\n');
else
    fprintf('STATUS: %d VULNERABILITIES DETECTED\n', total - passed);
end
fprintf('================================================\n');
